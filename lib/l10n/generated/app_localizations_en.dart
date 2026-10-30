// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get create => 'Create';

  @override
  String get delete => 'Delete';

  @override
  String get rename => 'Rename';

  @override
  String get retry => 'Retry';

  @override
  String get reload => 'Reload';

  @override
  String get remove => 'Remove';

  @override
  String get close => 'Close';

  @override
  String get navLibrary => 'Library';

  @override
  String get navPlaylists => 'Playlists';

  @override
  String get navDownloads => 'Downloads';

  @override
  String get navSearch => 'Search';

  @override
  String get tabArtists => 'Artists';

  @override
  String get tabAlbums => 'Albums';

  @override
  String get tabSongs => 'Songs';

  @override
  String get tabFavorites => 'Favorites';

  @override
  String get tabGenres => 'Genres';

  @override
  String get searchArtistsHint => 'Search artists…';

  @override
  String get searchAlbumsHint => 'Search albums…';

  @override
  String get searchSongsHint => 'Search songs…';

  @override
  String get searchPlaylistsHint => 'Search playlists…';

  @override
  String get searchEverythingHint => 'Search artists, albums, songs…';

  @override
  String get searchLibraryHint => 'Search the library';

  @override
  String get searchingAlbums => 'Searching albums…';

  @override
  String get searchingSongs => 'Searching songs…';

  @override
  String get loadingSongs => 'Loading songs…';

  @override
  String get loadingPlaylists => 'Loading playlists…';

  @override
  String get emptyArtists => 'No artists available';

  @override
  String get emptyAlbums => 'No albums available';

  @override
  String emptyAlbumsFor(String query) {
    return 'No albums for \"$query\"';
  }

  @override
  String get emptySongs => 'No songs in the library';

  @override
  String emptySongsFor(String query) {
    return 'No songs for \"$query\"';
  }

  @override
  String get emptyGenres => 'No genres';

  @override
  String get emptyFavorites => 'No favorites yet';

  @override
  String get emptyResults => 'No results';

  @override
  String get emptyPlaylist => 'Empty playlist';

  @override
  String get emptyAlbum => 'Album with no tracks';

  @override
  String get emptyArtist => 'No albums for this artist';

  @override
  String get emptyGenre => 'No tracks in this genre';

  @override
  String get noSongPlaying => 'No song is currently playing';

  @override
  String get randomCommands => 'Shuffle';

  @override
  String get randomCommandsTooltip => 'One-off shuffle commands';

  @override
  String get allRandom => 'All Random';

  @override
  String get randomByPlaying => 'Random by Playing';

  @override
  String get randomByFavorites => 'Random by Favorites';

  @override
  String get play => 'Play';

  @override
  String get playAll => 'Play all';

  @override
  String get playNow => 'Play now';

  @override
  String get playNext => 'Play next';

  @override
  String get queue => 'Queue';

  @override
  String get addToPlaylist => 'Add to playlist…';

  @override
  String get addTo => 'Add to…';

  @override
  String get newPlaylist => 'New playlist';

  @override
  String get newPlaylistEllipsis => 'New playlist…';

  @override
  String get playlistName => 'Playlist name';

  @override
  String get lyrics => 'Lyrics';

  @override
  String get lyricsEmpty => 'No lyrics available for this track.';

  @override
  String lyricsError(String error) {
    return 'Cannot load the lyrics: $error';
  }

  @override
  String get modeSequential => 'Sequential';

  @override
  String get modeShuffled => 'Shuffled';

  @override
  String get playbackSequential => 'Sequential playback';

  @override
  String get playbackShuffled => 'Shuffled playback';

  @override
  String playbackModeTooltip(String mode) {
    return '$mode playback';
  }

  @override
  String get addedToQueue => 'Added to the queue';

  @override
  String get playingNext => 'Playing after the current track';

  @override
  String get albumAddedToQueue => 'Album added to the queue';

  @override
  String get playlistAddedToQueue => 'Playlist added to the queue';

  @override
  String get tracksAddedToQueue => 'Tracks added to the queue';

  @override
  String get similarSongsQueue => 'Queue replaced with similar songs';

  @override
  String get similarSongsTooltip => 'Similar songs (Play Similar)';

  @override
  String similarSongsError(String error) {
    return 'No similar songs found: $error';
  }

  @override
  String get addToFavorites => 'Add to favorites';

  @override
  String get removeFromFavorites => 'Remove from favorites';

  @override
  String favoriteAddFailed(String error) {
    return 'Cannot add to favorites: $error';
  }

  @override
  String favoriteRemoveFailed(String error) {
    return 'Cannot remove from favorites: $error';
  }

  @override
  String get albumAddedToFavorites => 'Album added to favorites';

  @override
  String get albumRemovedFromFavorites => 'Album removed from favorites';

  @override
  String favoritesUpdateFailed(String error) {
    return 'Cannot update favorites: $error';
  }

  @override
  String playlistCreated(String name) {
    return '\"$name\" created';
  }

  @override
  String playlistDeleted(String name) {
    return '\"$name\" deleted';
  }

  @override
  String playlistRenamed(String name) {
    return 'Playlist renamed to \"$name\"';
  }

  @override
  String playlistCreateFailed(String error) {
    return 'Cannot create the playlist: $error';
  }

  @override
  String playlistRenameFailed(String error) {
    return 'Cannot rename the playlist: $error';
  }

  @override
  String playlistDeleteFailed(String error) {
    return 'Cannot delete the playlist: $error';
  }

  @override
  String playlistAddFailed(String error) {
    return 'Cannot add to the playlist: $error';
  }

  @override
  String playlistLoadFailed(String error) {
    return 'Cannot load the playlist: $error';
  }

  @override
  String get deletePlaylistTitle => 'Delete the playlist?';

  @override
  String deletePlaylistBody(String name) {
    return '\"$name\" will be removed from Navidrome. The tracks stay in the library.';
  }

  @override
  String get renamePlaylist => 'Rename playlist';

  @override
  String get removeFromPlaylist => 'Remove from the playlist';

  @override
  String trackRemoved(String title) {
    return '\"$title\" removed';
  }

  @override
  String trackRemoveFailed(String error) {
    return 'Cannot remove the track: $error';
  }

  @override
  String playlistUnavailable(String error) {
    return 'Playlists unavailable: $error';
  }

  @override
  String get managePlaylist => 'Manage playlist';

  @override
  String tracksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks',
      one: '1 track',
    );
    return '$_temp0';
  }

  @override
  String albumsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count albums',
      one: '1 album',
    );
    return '$_temp0';
  }

  @override
  String songsAndAlbums(String songs, String albums) {
    return '$songs · $albums';
  }

  @override
  String get allTracks => 'All tracks';

  @override
  String albumLoadFailed(String error) {
    return 'Cannot load the album: $error';
  }

  @override
  String artistLoadFailed(String error) {
    return 'Cannot load the artist: $error';
  }

  @override
  String songsLoadFailed(String error) {
    return 'Cannot load the songs: $error';
  }

  @override
  String genresLoadFailed(String error) {
    return 'Cannot load the genres: $error';
  }

  @override
  String favoritesLoadFailed(String error) {
    return 'Cannot load the favorites: $error';
  }

  @override
  String searchFailed(String error) {
    return 'Search failed: $error';
  }

  @override
  String get unknownArtist => 'Unknown artist';

  @override
  String get unknownAlbum => 'Unknown album';

  @override
  String yearAndTracks(String year, String tracks) {
    return '$year · $tracks';
  }

  @override
  String albumsLoadFailed(String error) {
    return 'Cannot load the albums: $error';
  }

  @override
  String artistsLoadFailed(String error) {
    return 'Cannot load the artists: $error';
  }

  @override
  String emptyArtistsFor(String query) {
    return 'No artists found for \"$query\"';
  }

  @override
  String get downloadsTitle => 'Downloads';

  @override
  String get pauseDownloads => 'Pause downloads';

  @override
  String get resumeDownloads => 'Resume downloads';

  @override
  String get removeDownload => 'Remove download';

  @override
  String get removeDownloadTitle => 'Remove download?';

  @override
  String removeDownloadBody(String title) {
    return 'Remove \"$title\" and its downloaded files from this device?';
  }

  @override
  String get clearAllDownloads => 'Clear all downloads';

  @override
  String get clearAll => 'Clear all';

  @override
  String get downloadQueued => 'Queued';

  @override
  String downloadingProgress(String percent, int done, int total) {
    return 'Downloading $percent% ($done/$total)';
  }

  @override
  String downloadingPercent(String percent) {
    return 'Downloading $percent%';
  }

  @override
  String downloadFailedWith(String error) {
    return 'Failed: $error';
  }

  @override
  String get noDownloadsYet => 'No downloads yet';

  @override
  String get storage => 'Storage';

  @override
  String get storageLimit => 'Storage limit';

  @override
  String usedOfLimit(String used, String limit) {
    return 'Used: $used / Limit: $limit';
  }

  @override
  String get unlimited => 'Unlimited';

  @override
  String get downloadForOffline => 'Download for offline';

  @override
  String get downloadedTapToRemove => 'Downloaded - tap to remove';

  @override
  String get downloadFailedTapToRetry => 'Download failed - tap to retry';

  @override
  String get favoritesDownloaded => 'Favorites downloaded';

  @override
  String get favoritesDownloadFailed => 'Favorites download failed';

  @override
  String get offlineDownloadChannel => 'Offline download progress and results';

  @override
  String get connectTitle => 'Connect to Subsonic Server';

  @override
  String get serverUrl => 'Server URL';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get connect => 'Connect';

  @override
  String get pleaseEnterServerUrl => 'Please enter the server URL';

  @override
  String get pleaseEnterUsername => 'Please enter the username';

  @override
  String get pleaseEnterPassword => 'Please enter the password';

  @override
  String get invalidUrlFormat => 'Invalid URL format';

  @override
  String get invalidServerUrl => 'Invalid server URL';

  @override
  String get pleaseEnterValidUrl => 'Please enter a valid URL';

  @override
  String get storageLimitReached =>
      'Storage limit reached. Free up space to download more.';

  @override
  String get retryDownload => 'Retry';

  @override
  String get downloadsHeader => 'Downloads';

  @override
  String get clearAllDownloadsBody =>
      'This will remove all downloaded content and free up storage space.';

  @override
  String get unknownError => 'Unknown error';

  @override
  String get clearAllDownloadsTitle => 'Clear all downloads';

  @override
  String get tabPlaylists => 'Playlists';

  @override
  String downloadCompleted(String type, String title) {
    return '$type \'$title\' downloaded';
  }

  @override
  String downloadCompletedBatch(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count downloads completed',
      one: '1 download completed',
    );
    return '$_temp0';
  }

  @override
  String downloadFailed(String type, String title) {
    return '$type \'$title\' download failed';
  }

  @override
  String get typePlaylist => 'Playlist';

  @override
  String get typeAlbum => 'Album';

  @override
  String get typeArtist => 'Artist';

  @override
  String get typeFavorites => 'Favorites';

  @override
  String playlistsLoadFailed(String error) {
    return 'Cannot load the playlists: $error';
  }

  @override
  String get emptyPlaylists => 'No playlists available';

  @override
  String playlistsEmptyFor(String query) {
    return 'No playlists for \"$query\"';
  }

  @override
  String get allFieldsRequired => 'All fields are required';

  @override
  String get offlineShowingDownloads =>
      'Server unreachable: showing what is downloaded';

  @override
  String get offlineEmpty => 'Server unreachable and nothing is downloaded';

  @override
  String get offlineBanner => 'Offline';

  @override
  String downloadedSummary(int done, int total) {
    return 'Downloaded ($done/$total)';
  }

  @override
  String get errorNoConnection => 'Server unreachable';

  @override
  String get errorTimeout => 'The server is not responding';

  @override
  String errorServer(String status) {
    return 'Server error ($status)';
  }

  @override
  String get errorUnexpected => 'Unexpected error';

  @override
  String errorWithDetail(String detail) {
    return 'Error: $detail';
  }
}
