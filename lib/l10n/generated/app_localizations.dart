import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it')
  ];

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @reload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get reload;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @navLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// No description provided for @navPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get navPlaylists;

  /// No description provided for @navDownloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get navDownloads;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @tabArtists.
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get tabArtists;

  /// No description provided for @tabAlbums.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get tabAlbums;

  /// No description provided for @tabSongs.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get tabSongs;

  /// No description provided for @tabFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get tabFavorites;

  /// No description provided for @tabGenres.
  ///
  /// In en, this message translates to:
  /// **'Genres'**
  String get tabGenres;

  /// No description provided for @searchArtistsHint.
  ///
  /// In en, this message translates to:
  /// **'Search artists…'**
  String get searchArtistsHint;

  /// No description provided for @searchAlbumsHint.
  ///
  /// In en, this message translates to:
  /// **'Search albums…'**
  String get searchAlbumsHint;

  /// No description provided for @searchSongsHint.
  ///
  /// In en, this message translates to:
  /// **'Search songs…'**
  String get searchSongsHint;

  /// No description provided for @searchPlaylistsHint.
  ///
  /// In en, this message translates to:
  /// **'Search playlists…'**
  String get searchPlaylistsHint;

  /// No description provided for @searchEverythingHint.
  ///
  /// In en, this message translates to:
  /// **'Search artists, albums, songs…'**
  String get searchEverythingHint;

  /// No description provided for @searchLibraryHint.
  ///
  /// In en, this message translates to:
  /// **'Search the library'**
  String get searchLibraryHint;

  /// No description provided for @searchingAlbums.
  ///
  /// In en, this message translates to:
  /// **'Searching albums…'**
  String get searchingAlbums;

  /// No description provided for @searchingSongs.
  ///
  /// In en, this message translates to:
  /// **'Searching songs…'**
  String get searchingSongs;

  /// No description provided for @loadingSongs.
  ///
  /// In en, this message translates to:
  /// **'Loading songs…'**
  String get loadingSongs;

  /// No description provided for @loadingPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Loading playlists…'**
  String get loadingPlaylists;

  /// No description provided for @emptyArtists.
  ///
  /// In en, this message translates to:
  /// **'No artists available'**
  String get emptyArtists;

  /// No description provided for @emptyAlbums.
  ///
  /// In en, this message translates to:
  /// **'No albums available'**
  String get emptyAlbums;

  /// No description provided for @emptyAlbumsFor.
  ///
  /// In en, this message translates to:
  /// **'No albums for \"{query}\"'**
  String emptyAlbumsFor(String query);

  /// No description provided for @emptySongs.
  ///
  /// In en, this message translates to:
  /// **'No songs in the library'**
  String get emptySongs;

  /// No description provided for @emptySongsFor.
  ///
  /// In en, this message translates to:
  /// **'No songs for \"{query}\"'**
  String emptySongsFor(String query);

  /// No description provided for @emptyGenres.
  ///
  /// In en, this message translates to:
  /// **'No genres'**
  String get emptyGenres;

  /// No description provided for @emptyFavorites.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get emptyFavorites;

  /// No description provided for @emptyResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get emptyResults;

  /// No description provided for @emptyPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Empty playlist'**
  String get emptyPlaylist;

  /// No description provided for @emptyAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album with no tracks'**
  String get emptyAlbum;

  /// No description provided for @emptyArtist.
  ///
  /// In en, this message translates to:
  /// **'No albums for this artist'**
  String get emptyArtist;

  /// No description provided for @emptyGenre.
  ///
  /// In en, this message translates to:
  /// **'No tracks in this genre'**
  String get emptyGenre;

  /// No description provided for @noSongPlaying.
  ///
  /// In en, this message translates to:
  /// **'No song is currently playing'**
  String get noSongPlaying;

  /// No description provided for @randomCommands.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get randomCommands;

  /// No description provided for @randomCommandsTooltip.
  ///
  /// In en, this message translates to:
  /// **'One-off shuffle commands'**
  String get randomCommandsTooltip;

  /// No description provided for @allRandom.
  ///
  /// In en, this message translates to:
  /// **'All Random'**
  String get allRandom;

  /// No description provided for @randomByPlaying.
  ///
  /// In en, this message translates to:
  /// **'Random by Playing'**
  String get randomByPlaying;

  /// No description provided for @randomByFavorites.
  ///
  /// In en, this message translates to:
  /// **'Random by Favorites'**
  String get randomByFavorites;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @playAll.
  ///
  /// In en, this message translates to:
  /// **'Play all'**
  String get playAll;

  /// No description provided for @playNow.
  ///
  /// In en, this message translates to:
  /// **'Play now'**
  String get playNow;

  /// No description provided for @playNext.
  ///
  /// In en, this message translates to:
  /// **'Play next'**
  String get playNext;

  /// No description provided for @queue.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get queue;

  /// No description provided for @addToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Add to playlist…'**
  String get addToPlaylist;

  /// No description provided for @addTo.
  ///
  /// In en, this message translates to:
  /// **'Add to…'**
  String get addTo;

  /// No description provided for @newPlaylist.
  ///
  /// In en, this message translates to:
  /// **'New playlist'**
  String get newPlaylist;

  /// No description provided for @newPlaylistEllipsis.
  ///
  /// In en, this message translates to:
  /// **'New playlist…'**
  String get newPlaylistEllipsis;

  /// No description provided for @playlistName.
  ///
  /// In en, this message translates to:
  /// **'Playlist name'**
  String get playlistName;

  /// No description provided for @lyrics.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get lyrics;

  /// No description provided for @lyricsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No lyrics available for this track.'**
  String get lyricsEmpty;

  /// No description provided for @lyricsError.
  ///
  /// In en, this message translates to:
  /// **'Cannot load the lyrics: {error}'**
  String lyricsError(String error);

  /// No description provided for @modeSequential.
  ///
  /// In en, this message translates to:
  /// **'Sequential'**
  String get modeSequential;

  /// No description provided for @modeShuffled.
  ///
  /// In en, this message translates to:
  /// **'Shuffled'**
  String get modeShuffled;

  /// No description provided for @playbackSequential.
  ///
  /// In en, this message translates to:
  /// **'Sequential playback'**
  String get playbackSequential;

  /// No description provided for @playbackShuffled.
  ///
  /// In en, this message translates to:
  /// **'Shuffled playback'**
  String get playbackShuffled;

  /// No description provided for @playbackModeTooltip.
  ///
  /// In en, this message translates to:
  /// **'{mode} playback'**
  String playbackModeTooltip(String mode);

  /// No description provided for @addedToQueue.
  ///
  /// In en, this message translates to:
  /// **'Added to the queue'**
  String get addedToQueue;

  /// No description provided for @playingNext.
  ///
  /// In en, this message translates to:
  /// **'Playing after the current track'**
  String get playingNext;

  /// No description provided for @albumAddedToQueue.
  ///
  /// In en, this message translates to:
  /// **'Album added to the queue'**
  String get albumAddedToQueue;

  /// No description provided for @playlistAddedToQueue.
  ///
  /// In en, this message translates to:
  /// **'Playlist added to the queue'**
  String get playlistAddedToQueue;

  /// No description provided for @tracksAddedToQueue.
  ///
  /// In en, this message translates to:
  /// **'Tracks added to the queue'**
  String get tracksAddedToQueue;

  /// No description provided for @similarSongsQueue.
  ///
  /// In en, this message translates to:
  /// **'Queue replaced with similar songs'**
  String get similarSongsQueue;

  /// No description provided for @similarSongsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Similar songs (Play Similar)'**
  String get similarSongsTooltip;

  /// No description provided for @similarSongsError.
  ///
  /// In en, this message translates to:
  /// **'No similar songs found: {error}'**
  String similarSongsError(String error);

  /// No description provided for @addToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addToFavorites;

  /// No description provided for @removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFromFavorites;

  /// No description provided for @favoriteAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Cannot add to favorites: {error}'**
  String favoriteAddFailed(String error);

  /// No description provided for @favoriteRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Cannot remove from favorites: {error}'**
  String favoriteRemoveFailed(String error);

  /// No description provided for @albumAddedToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Album added to favorites'**
  String get albumAddedToFavorites;

  /// No description provided for @albumRemovedFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Album removed from favorites'**
  String get albumRemovedFromFavorites;

  /// No description provided for @favoritesUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Cannot update favorites: {error}'**
  String favoritesUpdateFailed(String error);

  /// No description provided for @playlistCreated.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" created'**
  String playlistCreated(String name);

  /// No description provided for @playlistDeleted.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" deleted'**
  String playlistDeleted(String name);

  /// No description provided for @playlistRenamed.
  ///
  /// In en, this message translates to:
  /// **'Playlist renamed to \"{name}\"'**
  String playlistRenamed(String name);

  /// No description provided for @playlistCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Cannot create the playlist: {error}'**
  String playlistCreateFailed(String error);

  /// No description provided for @playlistRenameFailed.
  ///
  /// In en, this message translates to:
  /// **'Cannot rename the playlist: {error}'**
  String playlistRenameFailed(String error);

  /// No description provided for @playlistDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete the playlist: {error}'**
  String playlistDeleteFailed(String error);

  /// No description provided for @playlistAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Cannot add to the playlist: {error}'**
  String playlistAddFailed(String error);

  /// No description provided for @playlistLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Cannot load the playlist: {error}'**
  String playlistLoadFailed(String error);

  /// No description provided for @deletePlaylistTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete the playlist?'**
  String get deletePlaylistTitle;

  /// No description provided for @deletePlaylistBody.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be removed from Navidrome. The tracks stay in the library.'**
  String deletePlaylistBody(String name);

  /// No description provided for @renamePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Rename playlist'**
  String get renamePlaylist;

  /// No description provided for @removeFromPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Remove from the playlist'**
  String get removeFromPlaylist;

  /// No description provided for @trackRemoved.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" removed'**
  String trackRemoved(String title);

  /// No description provided for @trackRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Cannot remove the track: {error}'**
  String trackRemoveFailed(String error);

  /// No description provided for @playlistUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Playlists unavailable: {error}'**
  String playlistUnavailable(String error);

  /// No description provided for @managePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Manage playlist'**
  String get managePlaylist;

  /// No description provided for @tracksCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 track} other{{count} tracks}}'**
  String tracksCount(int count);

  /// No description provided for @albumsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 album} other{{count} albums}}'**
  String albumsCount(int count);

  /// No description provided for @songsAndAlbums.
  ///
  /// In en, this message translates to:
  /// **'{songs} · {albums}'**
  String songsAndAlbums(String songs, String albums);

  /// No description provided for @allTracks.
  ///
  /// In en, this message translates to:
  /// **'All tracks'**
  String get allTracks;

  /// No description provided for @albumLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Cannot load the album: {error}'**
  String albumLoadFailed(String error);

  /// No description provided for @artistLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Cannot load the artist: {error}'**
  String artistLoadFailed(String error);

  /// No description provided for @songsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Cannot load the songs: {error}'**
  String songsLoadFailed(String error);

  /// No description provided for @genresLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Cannot load the genres: {error}'**
  String genresLoadFailed(String error);

  /// No description provided for @favoritesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Cannot load the favorites: {error}'**
  String favoritesLoadFailed(String error);

  /// No description provided for @searchFailed.
  ///
  /// In en, this message translates to:
  /// **'Search failed: {error}'**
  String searchFailed(String error);

  /// No description provided for @unknownArtist.
  ///
  /// In en, this message translates to:
  /// **'Unknown artist'**
  String get unknownArtist;

  /// No description provided for @unknownAlbum.
  ///
  /// In en, this message translates to:
  /// **'Unknown album'**
  String get unknownAlbum;

  /// No description provided for @yearAndTracks.
  ///
  /// In en, this message translates to:
  /// **'{year} · {tracks}'**
  String yearAndTracks(String year, String tracks);

  /// No description provided for @albumsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Cannot load the albums: {error}'**
  String albumsLoadFailed(String error);

  /// No description provided for @artistsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Cannot load the artists: {error}'**
  String artistsLoadFailed(String error);

  /// No description provided for @emptyArtistsFor.
  ///
  /// In en, this message translates to:
  /// **'No artists found for \"{query}\"'**
  String emptyArtistsFor(String query);

  /// No description provided for @downloadsTitle.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloadsTitle;

  /// No description provided for @pauseDownloads.
  ///
  /// In en, this message translates to:
  /// **'Pause downloads'**
  String get pauseDownloads;

  /// No description provided for @resumeDownloads.
  ///
  /// In en, this message translates to:
  /// **'Resume downloads'**
  String get resumeDownloads;

  /// No description provided for @removeDownload.
  ///
  /// In en, this message translates to:
  /// **'Remove download'**
  String get removeDownload;

  /// No description provided for @removeDownloadTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove download?'**
  String get removeDownloadTitle;

  /// No description provided for @removeDownloadBody.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{title}\" and its downloaded files from this device?'**
  String removeDownloadBody(String title);

  /// No description provided for @clearAllDownloads.
  ///
  /// In en, this message translates to:
  /// **'Clear all downloads'**
  String get clearAllDownloads;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @downloadQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get downloadQueued;

  /// No description provided for @downloadingProgress.
  ///
  /// In en, this message translates to:
  /// **'Downloading {percent}% ({done}/{total})'**
  String downloadingProgress(String percent, int done, int total);

  /// No description provided for @downloadingPercent.
  ///
  /// In en, this message translates to:
  /// **'Downloading {percent}%'**
  String downloadingPercent(String percent);

  /// No description provided for @downloadFailedWith.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String downloadFailedWith(String error);

  /// No description provided for @noDownloadsYet.
  ///
  /// In en, this message translates to:
  /// **'No downloads yet'**
  String get noDownloadsYet;

  /// No description provided for @storage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storage;

  /// No description provided for @storageLimit.
  ///
  /// In en, this message translates to:
  /// **'Storage limit'**
  String get storageLimit;

  /// No description provided for @usedOfLimit.
  ///
  /// In en, this message translates to:
  /// **'Used: {used} / Limit: {limit}'**
  String usedOfLimit(String used, String limit);

  /// No description provided for @unlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get unlimited;

  /// No description provided for @downloadForOffline.
  ///
  /// In en, this message translates to:
  /// **'Download for offline'**
  String get downloadForOffline;

  /// No description provided for @downloadedTapToRemove.
  ///
  /// In en, this message translates to:
  /// **'Downloaded - tap to remove'**
  String get downloadedTapToRemove;

  /// No description provided for @downloadFailedTapToRetry.
  ///
  /// In en, this message translates to:
  /// **'Download failed - tap to retry'**
  String get downloadFailedTapToRetry;

  /// No description provided for @favoritesDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Favorites downloaded'**
  String get favoritesDownloaded;

  /// No description provided for @favoritesDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Favorites download failed'**
  String get favoritesDownloadFailed;

  /// No description provided for @offlineDownloadChannel.
  ///
  /// In en, this message translates to:
  /// **'Offline download progress and results'**
  String get offlineDownloadChannel;

  /// No description provided for @connectTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to Subsonic Server'**
  String get connectTitle;

  /// No description provided for @serverUrl.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get serverUrl;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @pleaseEnterServerUrl.
  ///
  /// In en, this message translates to:
  /// **'Please enter the server URL'**
  String get pleaseEnterServerUrl;

  /// No description provided for @pleaseEnterUsername.
  ///
  /// In en, this message translates to:
  /// **'Please enter the username'**
  String get pleaseEnterUsername;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter the password'**
  String get pleaseEnterPassword;

  /// No description provided for @invalidUrlFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid URL format'**
  String get invalidUrlFormat;

  /// No description provided for @invalidServerUrl.
  ///
  /// In en, this message translates to:
  /// **'Invalid server URL'**
  String get invalidServerUrl;

  /// No description provided for @pleaseEnterValidUrl.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid URL'**
  String get pleaseEnterValidUrl;

  /// No description provided for @storageLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Storage limit reached. Free up space to download more.'**
  String get storageLimitReached;

  /// No description provided for @retryDownload.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryDownload;

  /// No description provided for @downloadsHeader.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloadsHeader;

  /// No description provided for @clearAllDownloadsBody.
  ///
  /// In en, this message translates to:
  /// **'This will remove all downloaded content and free up storage space.'**
  String get clearAllDownloadsBody;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;

  /// No description provided for @clearAllDownloadsTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear all downloads'**
  String get clearAllDownloadsTitle;

  /// No description provided for @tabPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get tabPlaylists;

  /// No description provided for @downloadCompleted.
  ///
  /// In en, this message translates to:
  /// **'{type} \'{title}\' downloaded'**
  String downloadCompleted(String type, String title);

  /// No description provided for @downloadCompletedBatch.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 download completed} other{{count} downloads completed}}'**
  String downloadCompletedBatch(int count);

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'{type} \'{title}\' download failed'**
  String downloadFailed(String type, String title);

  /// No description provided for @typePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Playlist'**
  String get typePlaylist;

  /// No description provided for @typeAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get typeAlbum;

  /// No description provided for @typeArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get typeArtist;

  /// No description provided for @typeFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get typeFavorites;

  /// No description provided for @playlistsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Cannot load the playlists: {error}'**
  String playlistsLoadFailed(String error);

  /// No description provided for @emptyPlaylists.
  ///
  /// In en, this message translates to:
  /// **'No playlists available'**
  String get emptyPlaylists;

  /// No description provided for @playlistsEmptyFor.
  ///
  /// In en, this message translates to:
  /// **'No playlists for \"{query}\"'**
  String playlistsEmptyFor(String query);

  /// No description provided for @allFieldsRequired.
  ///
  /// In en, this message translates to:
  /// **'All fields are required'**
  String get allFieldsRequired;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
