package com.babisoft.random_mu

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodChannel

/**
 * Keeps the app process alive while offline downloads are running.
 *
 * The download queue itself lives in the Dart isolate (it owns the HTTP client,
 * the Subsea client and the queue state). This service only exists so Android
 * does not kill the process in the background, mirrors progress in a
 * non-dismissible notification and forwards the "pause" action back to Dart.
 */
class OfflineDownloadService : Service() {

    companion object {
        private const val TAG = "RandomMuuDownloads"
        private const val CHANNEL_ID = "random_mu_offline_downloads"
        private const val CHANNEL_NAME = "Offline downloads"
        private const val NOTIFICATION_ID = 4711

        const val ACTION_START = "com.babisoft.random_mu.action.DOWNLOAD_START"
        const val ACTION_UPDATE = "com.babisoft.random_mu.action.DOWNLOAD_UPDATE"
        const val ACTION_PAUSE = "com.babisoft.random_mu.action.DOWNLOAD_PAUSE"
        const val ACTION_STOP = "com.babisoft.random_mu.action.DOWNLOAD_STOP"

        private const val EXTRA_TITLE = "title"
        private const val EXTRA_TEXT = "text"

        /** Method channel used to talk back to Dart (pause action). */
        @Volatile
        var channel: MethodChannel? = null

        @Volatile
        private var instance: OfflineDownloadService? = null

        fun isRunning(): Boolean = instance != null

        fun start(context: Context, title: String, text: String) {
            val intent = Intent(context, OfflineDownloadService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_TITLE, title)
                putExtra(EXTRA_TEXT, text)
            }
            ContextCompat.startForegroundService(context, intent)
        }

        fun update(context: Context, title: String, text: String) {
            if (!isRunning()) return
            val intent = Intent(context, OfflineDownloadService::class.java).apply {
                action = ACTION_UPDATE
                putExtra(EXTRA_TITLE, title)
                putExtra(EXTRA_TEXT, text)
            }
            context.startService(intent)
        }

        fun stop(context: Context) {
            val running = instance
            if (running != null) {
                running.stopForegroundCompat()
                running.stopSelf()
            } else {
                context.stopService(Intent(context, OfflineDownloadService::class.java))
            }
        }
    }

    private var title = "Downloading"
    private var text = ""

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        instance = this
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopForegroundCompat()
                stopSelf()
                return START_NOT_STICKY
            }

            ACTION_PAUSE -> {
                runCatching { channel?.invokeMethod("pause", null) }
                text = "Paused"
                notifyProgress()
                return START_NOT_STICKY
            }

            ACTION_UPDATE -> {
                title = intent.getStringExtra(EXTRA_TITLE) ?: title
                text = intent.getStringExtra(EXTRA_TEXT) ?: text
                notifyProgress()
                return START_NOT_STICKY
            }

            else -> {
                title = intent?.getStringExtra(EXTRA_TITLE) ?: title
                text = intent?.getStringExtra(EXTRA_TEXT) ?: text
                if (!promoteToForeground()) return START_NOT_STICKY
                // The queue lives in the app process: if it is gone there is
                // nothing to resume, so never ask Android to restart us.
                return START_NOT_STICKY
            }
        }
    }

    override fun onDestroy() {
        instance = null
        channel = null
        super.onDestroy()
    }

    // ------------------------------------------------------------- notification

    private fun createNotificationChannel() {
        val manager = getSystemService(NotificationManager::class.java) ?: return
        val channel = NotificationChannel(
            CHANNEL_ID,
            CHANNEL_NAME,
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Shown while offline downloads are running"
            setShowBadge(false)
            enableVibration(false)
            setSound(null, null)
        }
        manager.createNotificationChannel(channel)
    }

    private fun promoteToForeground(): Boolean {
        return try {
            val notification = buildNotification()
            ServiceCompat.startForeground(
                this,
                NOTIFICATION_ID,
                notification,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
                } else {
                    0
                },
            )
            true
        } catch (t: Throwable) {
            Log.e(TAG, "Cannot start the download foreground service", t)
            stopSelf()
            false
        }
    }

    private fun notifyProgress() {
        val manager = getSystemService(NotificationManager::class.java) ?: return
        runCatching { manager.notify(NOTIFICATION_ID, buildNotification()) }
    }

    private fun buildNotification(): Notification {
        val openApp = packageManager.getLaunchIntentForPackage(packageName)
        val contentIntent = openApp?.let {
            PendingIntent.getActivity(
                this,
                0,
                it,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
        }

        val pauseIntent = Intent(this, OfflineDownloadService::class.java).apply {
            action = ACTION_PAUSE
        }
        val pauseAction = PendingIntent.getService(
            this,
            1,
            pauseIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_download)
            .setContentTitle(title)
            .setContentText(text)
            .setOngoing(true)
            .setShowWhen(false)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setContentIntent(contentIntent)
            .addAction(0, "Pause", pauseAction)
            .build()
    }

    private fun stopForegroundCompat() {
        runCatching { ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE) }
    }
}
