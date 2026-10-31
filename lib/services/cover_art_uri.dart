/// Authority of the native content provider that serves car artwork.
///
/// Keep it in sync with `CoverArtProvider.AUTHORITY` in
/// `android/app/src/main/kotlin/com/babisoft/random_mu/CoverArtProvider.kt` and
/// with the `android:authorities` of the provider in the manifest.
const String carCoverArtAuthority = 'com.babisoft.random_mu.art';

/// The size, in pixels, of the artwork handed to Android Auto.
///
/// The provider resizes and caches the covers at this size (it is also what the
/// media notification uses), so the car never decodes an original cover.
const int carCoverArtSize = 512;

/// A `content://` URI for the Subsonic [coverId], readable by Android Auto.
///
/// Android Auto only accepts artwork through a local URI (`content://` or
/// `android.resource://`): the remote cover URL the browse tree used to pass was
/// ignored by the car and carried the Subsonic credentials in its query string.
/// [CoverArtProvider](../android/app/src/main/kotlin/com/babisoft/random_mu/CoverArtProvider.kt)
/// downloads the cover once, resizes it to [carCoverArtSize] and serves the
/// cached file, so the car reads a small image from disk instead of decoding a
/// full-resolution one for every row it scrolls past.
Uri? carCoverArtUri(String? coverId) {
  if (coverId == null || coverId.isEmpty) return null;
  // Built as a string on purpose: `Uri(pathSegments: [...])` would re-encode the
  // escapes and turn a cover id containing `/` into extra path segments.
  return Uri.parse(
    'content://$carCoverArtAuthority/${Uri.encodeComponent(coverId)}',
  );
}

/// The cover id behind [coverIdOrUrl].
///
/// `SubsonicClient.getAlbumList` turns `Album.coverArt` into a ready URL, while
/// songs and playlists keep the plain id: accept both so a browse node can
/// always publish a `content://` URI.
String? coverArtIdOf(String? coverIdOrUrl) {
  if (coverIdOrUrl == null || coverIdOrUrl.isEmpty) return null;
  if (!coverIdOrUrl.contains('://')) return coverIdOrUrl;
  final id = Uri.tryParse(coverIdOrUrl)?.queryParameters['id'];
  return (id == null || id.isEmpty) ? null : id;
}
