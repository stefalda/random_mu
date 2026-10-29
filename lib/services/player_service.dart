import 'dart:async';
import 'dart:convert';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:inject_x/inject_x.dart';
import 'package:just_audio/just_audio.dart';
import 'package:random_mu/client/just_audio_client.dart';
import 'package:random_mu/client/audio_player_handler.dart';
import 'package:random_mu/client/subsonic_client.dart';
import 'package:random_mu/client/subsonic_models.dart';
import 'package:random_mu/services/browse_cache.dart';
import 'package:random_mu/services/download_service.dart';
import 'package:random_mu/services/offline_source.dart';
import 'package:random_mu/services/playback_mode.dart';
import 'package:random_mu/services/preference_service.dart';

const defaultCount = 50;

class PlayerService extends ChangeNotifier {
  final String serverUrl;
  final String username;
  final String password;

  final audioPlayer = AudioPlayer();
  //late AudioPlayerHandler audioPlayerHandler;
  late SubsonicClient client;
  StreamSubscription<int?>? _indexSubscription;

  int _lastPlayingSongIndex = 0;

  /// How a container becomes a queue. Persisted, restored on startup.
  PlaybackMode _mode = PlaybackMode.sequenziale;

  /// Songs of the container that produced the current queue, in its own order.
  ///
  /// Needed to restore sequential order after the user switches back from
  /// [PlaybackMode.casuale]. For queues without a container (Play Similar, a
  /// restored session) this is the order they were queued in.
  List<Song> _containerSongs = const [];

  PlaybackMode get mode => _mode;

  PlayerService(
      {required this.serverUrl,
      required this.username,
      required this.password}) {
    _setupAudio();
  }

  Future<void> _setupAudio() async {
    // Connect
    client = SubsonicClient(
      baseUrl: serverUrl,
      username: username,
      password: password,
    );
    // Listen for song index changes and store in preferences...
    _indexSubscription = audioPlayer.currentIndexStream.listen((index) {
      if (index != null) {
        debugPrint('Now playing track at index: $index');
        if (_lastPlayingSongIndex != index) {
          _lastPlayingSongIndex = index;
          final PreferenceService ps = inject<PreferenceService>();
          ps.storeCurrentPlayingSong(index);
        }
      }
    });

    //await restoreSongs();

    // Restore the last used playback mode.
    final PreferenceService prefs = inject<PreferenceService>();
    _mode = await prefs.retrievePlaybackMode();
    notifyListeners();
  }

  @override
  dispose() {
    _indexSubscription?.cancel();
    audioPlayer.dispose();
    super.dispose();
  }

  Future<List<Genre>> getGenres() async {
    final genres = await client.getGenres();
    for (var genre in genres) {
      debugPrint(genre.name);
    }
    return genres;
  }

  Future<List<Artist>> getArtists() async {
    final artists = await client.getArtists();
    /*for (var artist in artists) {
      debugPrint("${artist.name} - ${artist.artistImageUrl}");
    }*/
    return artists;
  }

  Future<List<Album>> getAlbums() async {
    final albums =
        await client.getAllAlbumsList(type: AlbumListType.alphabeticalByName);
    return albums;
  }

  Future<List<Playlist>> getPlaylists() async {
    final playlists = await client.getPlaylists();
    for (var playlist in playlists) {
      debugPrint(playlist.name);
    }
    return playlists;
  }

  Future randomAll({String? genre, count = defaultCount}) async {
    //await getGenres();
    //genre = "Cantautori Italiani";
    //await getArtists();
    //final result = await client.getStarred();
    //await _enqueueSongs(result.songs);

    final randomSongs = await client.getRandomSongs(count: count, genre: genre);
    await _enqueueSongs(randomSongs);
  }

  ///
  ///  Restore previous session playng song list
  ///
  Future restoreSongs() async {
    final PreferenceService ps = inject<PreferenceService>();
    if (!audioPlayer.playing && audioPlayer.sequence.isEmpty) {
      final List<Song>? songs = await ps.retrieveLatestPlaylist();
      if (songs != null) {
        final songIndex = await ps.retrieveCurrentPlayingSongIndex();
        await _enqueueSongs(songs, songIndex: songIndex, pause: true);
      }
    }
  }

  /// Return all the favorited songs and songs in favorited albums
  Future randomFavorites({int count = defaultCount}) async {
    final starredSongs = await fetchFavoriteSongs();
    starredSongs.shuffle();
    await _enqueueSongs(starredSongs);
  }

  /// All favorited songs plus all songs of favorited albums.
  Future<List<Song>> fetchFavoriteSongs() async {
    final searchResult = await client.getStarred();
    final songs = <Song>[...searchResult.songs];
    for (final Album album in searchResult.albums) {
      final albumDetail = await client.getAlbum(album.id);
      songs.addAll(albumDetail.songs);
    }
    return songs;
  }

  /// Songs of the container identified by [categoryId] and [containerId].
  Future<List<Song>> fetchContainerSongs(
      {String? categoryId, String? containerId}) async {
    if (categoryId == 'favorites') return fetchFavoriteSongs();
    if (containerId == null) return [];
    switch (categoryId) {
      case 'playlists':
        return client.getPlaylistSongs(containerId);
      case 'albums':
        return client.getSongsByAlbum(albumId: containerId);
      case 'artists':
        return client.getArtistSongsRandomized(containerId, count: null);
      default:
        return [];
    }
  }

  /// Play [songs] starting at [songId].
  ///
  /// Kept for the Android Auto playback path: when [shuffle] is true the
  /// container is shuffled, otherwise it follows [PlaybackMode].
  Future<void> playSongsStartingAt(List<Song> songs,
      {required String songId, bool shuffle = true}) async {
    if (songs.isEmpty) return;
    await playContainer(
      songs,
      startAtSongId: songId,
      modeOverride: shuffle ? PlaybackMode.casuale : PlaybackMode.sequenziale,
    );
  }

  /// Plays [songs] (a container in its own order) starting at [startAtSongId].
  ///
  /// The queue follows the playback mode: sequential keeps the container order
  /// and plays from the tapped track, casuale puts the tapped track first and
  /// shuffles the rest. Passing [modeOverride] also persists that mode, which
  /// is what an explicit "Riproduci / Casuale" choice in the UI means.
  Future<void> playContainer(
    List<Song> songs, {
    String? startAtSongId,
    PlaybackMode? modeOverride,
  }) async {
    if (songs.isEmpty) return;

    if (modeOverride != null && modeOverride != _mode) {
      await setMode(modeOverride);
    }

    final container = List<Song>.of(songs);
    final tappedIndex = startAtSongId == null
        ? 0
        : container.indexWhere((song) => song.id == startAtSongId);

    final plan = planQueue(
      container,
      shuffle: _mode.isShuffle,
      startIndex: tappedIndex,
    );

    await _enqueueSongs(
      plan.queue,
      songIndex: plan.index,
      containerSongs: container,
    );
  }

  /// Switches the playback mode, persists it and reorders the live queue.
  ///
  /// The current track keeps playing: it keeps its index when switching to
  /// [PlaybackMode.casuale] and returns to its container position when
  /// switching back to [PlaybackMode.sequenziale].
  Future<void> setMode(PlaybackMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    final PreferenceService prefs = inject<PreferenceService>();
    await prefs.storePlaybackMode(mode);
    notifyListeners();
    await _applyModeToQueue();
  }

  Future<void> toggleMode() => setMode(_mode.toggled);

  /// Reorders the queue that is already loaded, without touching playback.
  Future<void> _applyModeToQueue() async {
    final sources = List<AudioSource>.of(audioPlayer.audioSources);
    final currentIndex = audioPlayer.currentIndex;
    if (sources.isEmpty ||
        currentIndex == null ||
        currentIndex < 0 ||
        currentIndex >= sources.length) {
      return;
    }

    final List<AudioSource> target;
    if (_mode.isShuffle) {
      final order = shuffledKeepingCurrent(sources.length, currentIndex);
      target = [for (final index in order) sources[index]];
    } else {
      if (_containerSongs.isEmpty) return;
      final bySongId = <String, AudioSource>{};
      for (final source in sources) {
        if (source is UriAudioSource) {
          final tag = source.tag;
          if (tag is MediaItem) bySongId[tag.id] = source;
        }
      }
      target = [
        for (final song in _containerSongs)
          if (bySongId.containsKey(song.id)) bySongId[song.id]!,
      ];
      // Keep anything the container does not know about (should not happen).
      for (final source in sources) {
        if (!target.contains(source)) target.add(source);
      }
      if (target.length != sources.length) return;
    }

    await _moveIntoOrder(target);
  }

  /// Reorders the just_audio playlist with gapless moves, so audio keeps
  /// playing from the same position.
  Future<void> _moveIntoOrder(List<AudioSource> target) async {
    for (var index = 0; index < target.length; index++) {
      final wanted = target[index];
      final sources = audioPlayer.audioSources;
      final at = sources.indexOf(wanted);
      if (at < 0 || at == index) continue;
      await audioPlayer.moveAudioSource(at, index);
    }
  }

  Future randomByArtist(
      {required String artistId, count = defaultCount}) async {
    final randomSongs =
        await client.getArtistSongsRandomized(artistId, count: count);

    await _enqueueSongs(randomSongs);
  }

  // --- Container playback -------------------------------------------------
  //
  // These fetch the container in its own order and let the playback mode decide
  // the queue. They are the entry points used by the app UI and by Android Auto.

  Future<void> playPlaylist(String playlistId, {String? startAtSongId}) async {
    final songs = await client.getPlaylistSongs(playlistId);
    await playContainer(songs, startAtSongId: startAtSongId);
  }

  Future<void> playAlbum(String albumId, {String? startAtSongId}) async {
    final songs = await client.getSongsByAlbum(albumId: albumId);
    await playContainer(songs, startAtSongId: startAtSongId);
  }

  Future<void> playArtist(String artistId, {String? startAtSongId}) async {
    final songs = await fetchArtistSongs(artistId);
    await playContainer(songs, startAtSongId: startAtSongId);
  }

  /// All songs of [artistId] in album order (not shuffled).
  Future<List<Song>> fetchArtistSongs(String artistId) async {
    final albums = await client.getArtistAlbums(artistId);
    final songs = <Song>[];
    for (final album in albums) {
      songs.addAll(await client.getSongsByAlbum(albumId: album.id));
    }
    return songs;
  }

  Future randomByAlbum({required String albumId}) async {
    final randomSongs = await client.getSongsByAlbum(albumId: albumId);
    randomSongs.shuffle();
    await _enqueueSongs(randomSongs);
  }

  Future randomByPlaylist({required String playlistId}) async {
    final randomSongs = await client.getPlaylistSongs(playlistId);
    randomSongs.shuffle();
    await _enqueueSongs(randomSongs);
  }

  Future randomByPlayingSong() async {
    final playingSongIndex = audioPlayer.currentIndex;
    if (playingSongIndex == null) return;
    final AudioSource playingSong = audioPlayer.audioSources[playingSongIndex];
    //audioPlayer.audioSource!.sequence.elementAt(playingSongIndex);
    final String currentSongId = (playingSong as ProgressiveAudioSource).tag.id;
    final similarSongs = await client.getSimilarSongs(currentSongId);
    if (similarSongs.isEmpty) return;
    // Check if the source soung is included
    late Song currentSong;
    int idx = similarSongs.indexWhere((song) => song.id == currentSongId);
    if (idx >= 0) {
      debugPrint("Current playing song index in new List = $idx");
      currentSong = similarSongs[idx];
      similarSongs.removeAt(idx);
    } else {
      final json = jsonDecode(playingSong.tag.extras['songJson']);
      currentSong = Song.fromJson(json);
    }
    // Move in first
    similarSongs.insert(0, currentSong);
    Duration? position;
    if (audioPlayer.playing) {
      position = await audioPlayer.positionStream.first;
    }
    await _enqueueSongs(similarSongs, restartAt: position);
  }

  /// Appends [songs] at the end of the queue without touching playback.
  Future<void> appendToQueue(List<Song> songs) async {
    if (songs.isEmpty) return;
    final sources = await _buildAudioSources(songs);
    await audioPlayer.addAudioSources(sources);
    _containerSongs = [..._containerSongs, ...songs];
    notifyListeners();
  }

  /// Inserts [songs] right after the current track.
  Future<void> playNext(List<Song> songs) async {
    if (songs.isEmpty) return;
    final sources = await _buildAudioSources(songs);
    final currentIndex = audioPlayer.currentIndex;
    final insertAt = (currentIndex ?? audioPlayer.audioSources.length) + 1;
    await audioPlayer.insertAudioSources(insertAt, sources);

    // Keep the container order consistent: place the songs after the current one.
    final order = List<Song>.of(_containerSongs);
    final currentSource =
        currentIndex == null ? null : audioPlayer.audioSources[currentIndex];
    final currentId = currentSource is UriAudioSource
        ? (currentSource.tag as MediaItem?)?.id
        : null;
    final position = currentId == null
        ? order.length
        : order.indexWhere((song) => song.id == currentId);
    order.insertAll(position < 0 ? order.length : position + 1, songs);
    _containerSongs = order;
    notifyListeners();
  }

  Future<List<AudioSource>> _buildAudioSources(List<Song> songs) async {
    // Try to create download service for offline file resolution
    DownloadService? ds;
    try {
      ds = inject<DownloadService>();
    } catch (_) {
      // DownloadService may not be registered yet
    }

    return Future.wait(songs.map((song) async {
      var mediaItem = createMediaItem(song, client);

      // Downloaded songs play from disk, everything else streams.
      final localPath = ds == null ? null : await ds.getLocalPath(song.id);
      if (localPath != null) {
        debugPrint('Offline playback: ${song.title} -> $localPath');
      }

      // Same for the artwork, so the now-playing screen works offline too.
      final localCover = ds?.localCoverPath(song.coverArt);
      final artUri = resolveArtUri(
        remoteUrl: mediaItem.artUri?.toString(),
        localPath: localCover,
      );
      if (artUri != null) mediaItem = mediaItem.copyWith(artUri: artUri);

      return AudioSource.uri(
        resolveSongUri(mediaItem: mediaItem, localPath: localPath),
        tag: mediaItem,
      );
    }));
  }

  Future<void> _enqueueSongs(List<Song> songs,
      {Duration? restartAt,
      songIndex = 0,
      pause = false,
      List<Song>? containerSongs}) async {
    final audioSources = await _buildAudioSources(songs);
    debugPrint("AudioSources enqueued: ${audioSources.length}");
    // Remember the container order so the mode toggle can restore it. Queues
    // without a container use their own queued order.
    _containerSongs = List<Song>.of(containerSongs ?? songs);
    // Set up a playlist with metadata.
    //final AudioSource playlist = ConcatenatingAudioSource(
    //    children: audioSources, useLazyPreparation: true);
    // Do NOT stop() here: stopping publishes ProcessingState.idle, which Android
    // maps to PlaybackState.STATE_NONE, and Android Auto then drops out of its
    // now playing screen back to the browse list. Replacing the sources already
    // stops the previous audio, so the session only goes through loading/ready.
    //await audioPlayer.setAudioSources(audioSources, initialPosition: restartAt);
    //await audioPlayer.setAudioSource(playlist, initialPosition: restartAt);
    await audioPlayer.setAudioSources(
      audioSources,
      initialIndex: songIndex, // Which track to start with (0-based)
      initialPosition: restartAt,
    );
    if (!pause) {
      // Play
      unawaited(play());
    } else {
      // A restored session must stay *paused and ready*: stopping the player
      // resets the platform state to idle, which hides the now playing metadata
      // on the lock screen, in the notification and in Android Auto.
      unawaited(play());
      await Future.delayed(const Duration(milliseconds: 700));
      await audioPlayer.pause();
    }
    // Store in preferences the current audio sources...
    final PreferenceService ps = inject<PreferenceService>();
    await ps.storeLatestPlaylist(songs);
  }

  // --- Playlist mutations -------------------------------------------------
  //
  // Navidrome stays the source of truth: these calls write through the Subsonic
  // API and then drop the Android Auto browse caches, which otherwise keep
  // serving the old playlist name/song list (in memory for 5 minutes and, for
  // downloaded playlists, from the persistent offline copy).

  Future<Playlist> createPlaylist(String name,
      {List<String> songIds = const []}) async {
    final playlist =
        await client.createPlaylist(name: name, songIds: songIds);
    await _invalidatePlaylistCaches();
    return playlist;
  }

  /// Removes the tracks at [indexes] (positions in the playlist order) from
  /// [playlistId]. The Subsonic API removes by index, not by song id.
  Future<void> removeSongsFromPlaylist(
      String playlistId, List<int> indexes) async {
    if (indexes.isEmpty) return;
    final sorted = List<int>.of(indexes)..sort();
    await client.updatePlaylist(playlistId, removeSongIndexes: sorted);
    await _invalidatePlaylistCaches(playlistId: playlistId);
  }

  Future<void> addSongsToPlaylist(String playlistId,
      List<String> songIds) async {
    if (songIds.isEmpty) return;
    await client.updatePlaylist(playlistId, addSongIds: songIds);
    await _invalidatePlaylistCaches(playlistId: playlistId);
  }

  Future<void> renamePlaylist(String playlistId, String name) async {
    await client.updatePlaylist(playlistId, name: name);
    await _invalidatePlaylistCaches(playlistId: playlistId);
  }

  Future<void> deletePlaylist(String playlistId) async {
    await client.deletePlaylist(playlistId);
    await _invalidatePlaylistCaches(playlistId: playlistId);
  }

  /// Drops every cached copy of the playlist list and, when given, of one
  /// playlist node (its name and its song list).
  Future<void> _invalidatePlaylistCaches({String? playlistId}) async {
    const cache = BrowseCache();
    await cache.removeNode(playlistsCategoryId);
    if (playlistId != null) {
      await cache.removeNode('playlist-$playlistId');
    }
    AudioPlayerHandler.instance?.clearBrowseCache();
  }

  Future<String> fetchData() async {
    await Future.delayed(Duration(seconds: 2)); // Simula un ritardo
    return "Dati caricati dall'API!";
  }

  Future play() async {
    //await audioPlayerHandler.play();
    await audioPlayer.play();
  }

  Future pause() async {
    await audioPlayer.pause();
  }

  Future previous() async {
    await audioPlayer.seekToPrevious();
  }

  Future next() async {
    await audioPlayer.seekToNext();
  }

  bool isPlaying() {
    return audioPlayer.playing;
  }

  Future updatePlayingInfo(MediaItem mediaItem) async {
    // if (kIsWeb) return;
    // await audioPlayerHandler.updateMediaMetadata(
    //   title: mediaItem.title,
    //   artist: mediaItem.artist ?? 'Unknown Artist',
    //   album: mediaItem.album ?? 'Unknown Album',
    //   artworkUri: mediaItem.artUri.toString(),
    //   duration: mediaItem.duration,
    // );
  }

  /*xw

// Get music folders
    final artists = await client.searchArtists("Mor");
    debugPrint("Artists: ${artists.length}");
    for (var artist in artists) {
      debugPrint(" ${artist.name} - ${artist.id}");
    }
    // Get all songs by an artist
    final artistId = "ac92d51e195168f06754633327663964";
    final randomSongs =
        await client.getArtistSongsRandomized(artistId, count: defaultCount);
    for (var randomSong in randomSongs) {
      debugPrint(randomSong.title);
    }
    // Play the first song
    final player = AudioPlayer();
    final mediaItem = createMediaItem(randomSongs.first, client);
    await player.setAudioSource(AudioSource.uri(
      Uri.parse(mediaItem.extras!['streamUrl']),
      tag: mediaItem,
    ));
    await player.play();

// Get playlist
//final playlist = await client.getPlaylist('playlist-id');
*/
}
