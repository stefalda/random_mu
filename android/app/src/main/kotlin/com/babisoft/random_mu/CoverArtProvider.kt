package com.babisoft.random_mu

import android.content.ContentProvider
import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.ParcelFileDescriptor
import android.util.Base64
import android.util.Log
import java.io.File
import java.io.FileNotFoundException
import java.io.FileOutputStream
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest
import org.json.JSONObject

/**
 * Serves the Android Auto artwork through `content://` URIs.
 *
 * Android Auto only accepts local artwork URIs (`content://` or
 * `android.resource://`): the remote Subsonic cover URL the browse tree used to
 * hand over was ignored by the car (and carried the credentials in its query
 * string). The host also shows its loading state while the provider answers, so
 * the URI must resolve quickly and never block for long.
 *
 * A cover id resolves to a [COVER_SIZE_PX] JPEG:
 *
 *  1. the already resized copy in `cacheDir/aa_covers` (the common case, one
 *     file per cover id, not per song),
 *  2. the original downloaded with the offline songs
 *     (`app_flutter/offline_music/covers`, the file the phone player uses),
 *  3. `getCoverArt` with `size=[COVER_SIZE_PX]`, using the connection details
 *     the app stored in the shared preferences.
 *
 * Every network step has a short timeout and any failure is a plain "no
 * artwork" (404), never an error the car would retry.
 */
class CoverArtProvider : ContentProvider() {

    companion object {
        private const val TAG = "CoverArtProvider"

        /** Keep in sync with `lib/services/cover_art_uri.dart`. */
        const val AUTHORITY = "com.babisoft.random_mu.art"

        private const val COVER_SIZE_PX = 512
        private const val JPEG_QUALITY = 85

        private const val CONNECT_TIMEOUT_MS = 4000
        private const val READ_TIMEOUT_MS = 8000

        // Same store, key and prefix the shared_preferences plugin uses.
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val PREFS_KEY = "flutter.subsonic_connection_details"
        private const val CLIENT_NAME = "DartClient"
        private const val API_VERSION = "1.16.1"

        private const val CACHE_DIR = "aa_covers"
        private const val LOCAL_COVERS_DIR = "app_flutter/offline_music/covers"
    }

    override fun onCreate(): Boolean = true

    override fun openFile(uri: Uri, mode: String): ParcelFileDescriptor {
        val context = context ?: throw FileNotFoundException(uri.toString())
        val coverId = uri.lastPathSegment?.takeIf { it.isNotEmpty() }
            ?: throw FileNotFoundException("No cover id in $uri")
        val file = coverFile(context, coverId)
            ?: throw FileNotFoundException("No artwork for $coverId")
        return ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
    }

    override fun getType(uri: Uri): String = "image/jpeg"

    override fun query(
        uri: Uri,
        projection: Array<out String>?,
        selection: String?,
        selectionArgs: Array<out String>?,
        sortOrder: String?,
    ): Cursor? = null

    override fun insert(uri: Uri, values: ContentValues?): Uri? = null

    override fun update(
        uri: Uri,
        values: ContentValues?,
        selection: String?,
        selectionArgs: Array<out String>?,
    ): Int = 0

    override fun delete(
        uri: Uri,
        selection: String?,
        selectionArgs: Array<out String>?,
    ): Int = 0

    /** The resized cover for [coverId], or null when it cannot be obtained. */
    private fun coverFile(context: Context, coverId: String): File? {
        val cacheDir = File(context.cacheDir, CACHE_DIR)
        if (!cacheDir.isDirectory && !cacheDir.mkdirs()) return null

        val cached = File(cacheDir, sha1(coverId) + ".jpg")
        if (cached.length() > 0L) return cached

        // A song that was downloaded already has its cover on disk.
        val local = File(
            File(context.dataDir, LOCAL_COVERS_DIR),
            dartBase64Url(coverId) + ".img",
        )
        if (local.isFile && resize(local, cached)) return cached

        val bytes = download(context, coverId) ?: return null
        return try {
            val temporary = File.createTempFile("cover", ".img", cacheDir)
            try {
                temporary.writeBytes(bytes)
                if (resize(temporary, cached)) cached else null
            } finally {
                temporary.delete()
            }
        } catch (error: Exception) {
            Log.w(TAG, "Cannot cache the cover $coverId", error)
            null
        }
    }

    /** Decodes [source] at the car size and writes it to [target] as JPEG. */
    private fun resize(source: File, target: File): Boolean {
        return try {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(source.path, bounds)
            if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return false

            val options = BitmapFactory.Options().apply {
                inSampleSize = sampleSize(bounds.outWidth, bounds.outHeight)
            }
            val decoded = BitmapFactory.decodeFile(source.path, options) ?: return false
            val bitmap = scaled(decoded)

            val temporary = File.createTempFile("cover", ".jpg", target.parentFile)
            FileOutputStream(temporary).use { stream ->
                bitmap.compress(Bitmap.CompressFormat.JPEG, JPEG_QUALITY, stream)
            }
            if (bitmap !== decoded) decoded.recycle()
            bitmap.recycle()

            // A concurrent request may have written the same file first.
            val renamed = temporary.renameTo(target)
            if (!renamed) temporary.delete()
            renamed || target.length() > 0L
        } catch (error: Exception) {
            Log.w(TAG, "Cannot resize ${source.name}", error)
            false
        }
    }

    /** Largest power of two that keeps the decoded image at or above the target. */
    private fun sampleSize(width: Int, height: Int): Int {
        var sample = 1
        while (width / (sample * 2) >= COVER_SIZE_PX ||
            height / (sample * 2) >= COVER_SIZE_PX
        ) {
            sample *= 2
        }
        return sample
    }

    private fun scaled(bitmap: Bitmap): Bitmap {
        val longestSide = maxOf(bitmap.width, bitmap.height)
        if (longestSide <= COVER_SIZE_PX) return bitmap
        val scale = COVER_SIZE_PX.toFloat() / longestSide
        return Bitmap.createScaledBitmap(
            bitmap,
            (bitmap.width * scale).toInt().coerceAtLeast(1),
            (bitmap.height * scale).toInt().coerceAtLeast(1),
            true,
        )
    }

    private fun download(context: Context, coverId: String): ByteArray? {
        val url = coverUrl(context, coverId) ?: return null
        var connection: HttpURLConnection? = null
        return try {
            connection = (URL(url).openConnection() as HttpURLConnection).apply {
                connectTimeout = CONNECT_TIMEOUT_MS
                readTimeout = READ_TIMEOUT_MS
                instanceFollowRedirects = true
            }
            val status = connection.responseCode
            if (status != HttpURLConnection.HTTP_OK) {
                Log.w(TAG, "getCoverArt for $coverId returned $status")
                return null
            }
            connection.inputStream.use { it.readBytes() }
        } catch (error: Exception) {
            Log.w(TAG, "Cannot download the cover $coverId", error)
            null
        } finally {
            connection?.disconnect()
        }
    }

    /** `getCoverArt` URL for [coverId], built like `SubsonicClient` does. */
    private fun coverUrl(context: Context, coverId: String): String? {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val raw = prefs.getString(PREFS_KEY, null) ?: return null
        return try {
            val details = JSONObject(raw)
            val baseUrl = details.optString("serverUrl").trimEnd('/')
            if (baseUrl.isEmpty()) return null
            Uri.parse("$baseUrl/rest/getCoverArt.view")
                .buildUpon()
                .appendQueryParameter("id", coverId)
                .appendQueryParameter("u", details.optString("username"))
                .appendQueryParameter("p", details.optString("password"))
                .appendQueryParameter("c", CLIENT_NAME)
                .appendQueryParameter("v", API_VERSION)
                .appendQueryParameter("size", COVER_SIZE_PX.toString())
                .build()
                .toString()
        } catch (error: Exception) {
            Log.w(TAG, "Cannot read the Subsonic connection details", error)
            null
        }
    }

    private fun sha1(value: String): String =
        MessageDigest.getInstance("SHA-1")
            .digest(value.toByteArray(Charsets.UTF_8))
            .joinToString("") { "%02x".format(it.toInt() and 0xff) }

    /** The file name `DownloadService` uses for a cover id. */
    private fun dartBase64Url(value: String): String =
        Base64.encodeToString(
            value.toByteArray(Charsets.UTF_8),
            Base64.URL_SAFE or Base64.NO_WRAP,
        )
}
