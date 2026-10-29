import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:random_mu/client/subsonic_client.dart';
import 'package:random_mu/client/subsonic_models.dart';
import 'package:random_mu/services/browse_cache.dart';
import 'package:random_mu/services/player_service.dart';

/// The root ID for Android Auto browsing.
const String rootId = 'root';

/// Browse category IDs.
const String playlistsCategoryId = 'playlists';
const String artistsCategoryId = 'artists';
const String albumsCategoryId = 'albums';
const String favoritesCategoryId = 'favorites';

class AudioPlayerHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  PlayerService? _playerService;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<SequenceState?>? _sequenceSubscription;

  /// Cached browse metadata for offline AA browsing.
  final Map<String, List<MediaItem>> _browseCache = {};

  /// Every item returned by [getChildren], indexable by id.
  final Map<String, MediaItem> _itemCache = {};

  /// The browse node that produced each item (used to rebuild a container).
  final Map<String, String> _itemParent = {};

  /// Global reference so providers can wire the PlayerService after init.
  static AudioPlayerHandler? instance;

  /// Persistent browse metadata, so the tree survives restarts and offline use.
  final BrowseCache _persistentCache = const BrowseCache();

  AudioPlayerHandler() {
    instance = this;
  }

  /// Set the PlayerService after it's created (lazy initialization).
  void setPlayerService(PlayerService service) {
    _playerService = service;
    _cancelListeners();
    _setupPlayerListeners();
  }

  void _cancelListeners() {
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _sequenceSubscription?.cancel();
  }

  void _setupPlayerListeners() {
    final ps = _playerService;
    if (ps == null) return;

    _playerStateSubscription =
        ps.audioPlayer.playerStateStream.listen((state) {
      playbackState.add(stateToPlaybackState(state));
    });

    _positionSubscription =
        ps.audioPlayer.positionStream.listen((position) {
      playbackState.add(playbackState.value.copyWith(
        updatePosition: position,
      ));
    });

    _sequenceSubscription =
        ps.audioPlayer.sequenceStateStream.listen((seqState) {
      final queue = seqState.sequence
          .map((source) => source.tag as MediaItem)
          .toList();
      this.queue.add(queue);
      final currentIndex = seqState.currentIndex;
      if (currentIndex != null) {
        mediaItem.add(queue[currentIndex]);
      }
    });
  }

  PlaybackState stateToPlaybackState(PlayerState state) {
    final isPlaying = state.playing;
    final processingState = state.processingState;
    return PlaybackState(
      playing: isPlaying,
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.play,
        MediaControl.pause,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      processingState: processingState == ProcessingState.completed
          ? AudioProcessingState.completed
          : isPlaying
              ? AudioProcessingState.ready
              : AudioProcessingState.idle,
      repeatMode: AudioServiceRepeatMode.none,
      shuffleMode: AudioServiceShuffleMode.none,
    );
  }

  @override
  Future<List<MediaItem>> getChildren(String parentMediaId,
      [Map<String, dynamic>? options]) async {
    final inMemory = _browseCache[parentMediaId];
    if (inMemory != null) return inMemory;

    List<MediaItem> children = const [];
    var loadedFromNetwork = false;

    final ps = _playerService;
    if (parentMediaId == rootId) {
      // Static node, no client needed.
      children = _buildRootCategories();
      loadedFromNetwork = true;
    } else if (ps != null) {
      try {
        children = await _loadChildrenFromNetwork(ps, parentMediaId);
        loadedFromNetwork = children.isNotEmpty;
      } catch (error) {
        debugPrint('Android Auto: cannot load children of $parentMediaId: $error');
      }
    }

    if (!loadedFromNetwork) {
      // Offline or failed fetch: fall back to what we cached before.
      children = await _persistentCache.loadNode(parentMediaId) ?? const [];
    } else if (parentMediaId != rootId) {
      await _persistentCache.saveNode(parentMediaId, children);
    }

    _browseCache[parentMediaId] = children;
    _registerChildren(parentMediaId, children);
    return children;
  }

  Future<List<MediaItem>> _loadChildrenFromNetwork(
      PlayerService ps, String parentMediaId) async {
    switch (parentMediaId) {
      case rootId:
        return _buildRootCategories();
      case playlistsCategoryId:
        return _buildPlaylists(ps);
      case artistsCategoryId:
        return _buildArtists(ps);
      case albumsCategoryId:
        return _buildAlbums(ps);
      case favoritesCategoryId:
        return _buildFavorites(ps);
      default:
        if (parentMediaId.startsWith('playlist-')) {
          final playlistId = parentMediaId.substring('playlist-'.length);
          return _buildPlaylistSongs(ps, playlistId);
        }
        if (parentMediaId.startsWith('artist-')) {
          final artistId = parentMediaId.substring('artist-'.length);
          return _buildArtistSongs(ps, artistId);
        }
        if (parentMediaId.startsWith('album-')) {
          final albumId = parentMediaId.substring('album-'.length);
          return _buildAlbumSongs(ps, albumId);
        }
        return const [];
    }
  }

  void _registerChildren(String parentId, List<MediaItem> children) {
    for (final child in children) {
      _itemCache[child.id] = child;
      _itemParent[child.id] = parentId;
    }
  }

  /// The top-level category that owns [parentId], if any.
  static String? categoryForParent(String? parentId) {
    if (parentId == null) return null;
    if (parentId == favoritesCategoryId) return favoritesCategoryId;
    if (parentId.startsWith('playlist-')) return playlistsCategoryId;
    if (parentId.startsWith('album-')) return albumsCategoryId;
    if (parentId.startsWith('artist-')) return artistsCategoryId;
    return null;
  }

  /// The Subsonic id inside a container node such as `playlist-<id>`.
  static String? containerIdForParent(String? parentId) {
    if (parentId == null) return null;
    for (final prefix in ['playlist-', 'album-', 'artist-']) {
      if (parentId.startsWith(prefix)) {
        return parentId.substring(prefix.length);
      }
    }
    return null;
  }

  List<MediaItem> _buildRootCategories() {
    return [
      MediaItem(id: playlistsCategoryId, title: 'Playlists', playable: false),
      MediaItem(id: artistsCategoryId, title: 'Artists', playable: false),
      MediaItem(id: albumsCategoryId, title: 'Albums', playable: false),
      MediaItem(id: favoritesCategoryId, title: 'Favorites', playable: false),
    ];
  }

  Future<List<MediaItem>> _buildPlaylists(PlayerService ps) async {
    try {
      final playlists = await ps.client.getPlaylists();
      return playlists.map((p) {
        return MediaItem(
          id: 'playlist-${p.id}',
          title: p.name,
          artUri: p.coverArt != null
              ? Uri.parse(ps.client.getCoverArtUrl(p.coverArt))
              : null,
          playable: false,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<MediaItem>> _buildArtists(PlayerService ps) async {
    try {
      final artists = await ps.client.getArtists();
      return artists.map((a) {
        return MediaItem(
          id: 'artist-${a.id}',
          title: a.name,
          artUri: a.artistImageUrl != null
              ? Uri.parse(a.artistImageUrl!)
              : null,
          playable: false,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<MediaItem>> _buildAlbums(PlayerService ps) async {
    try {
      final albums = await ps.client.getAllAlbumsList(
        type: AlbumListType.alphabeticalByName,
      );
      return albums.map((a) {
        return MediaItem(
          id: 'album-${a.id}',
          title: a.name,
          artist: a.artist,
          artUri: a.coverArt != null ? Uri.parse(a.coverArt!) : null,
          playable: false,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<MediaItem>> _buildFavorites(PlayerService ps) async {
    try {
      final starred = await ps.client.getStarred();
      final songs = <Song>[...starred.songs];
      for (final album in starred.albums) {
        try {
          final albumDetail = await ps.client.getAlbum(album.id);
          songs.addAll(albumDetail.songs);
        } catch (_) {
          // skip album if it fails
        }
      }
      return songs.map((s) => _songToMediaItem(s, ps.client)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<MediaItem>> _buildPlaylistSongs(
      PlayerService ps, String playlistId) async {
    try {
      final songs = await ps.client.getPlaylistSongs(playlistId);
      songs.shuffle();
      return songs.map((s) => _songToMediaItem(s, ps.client)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<MediaItem>> _buildArtistSongs(
      PlayerService ps, String artistId) async {
    try {
      final songs =
          await ps.client.getArtistSongsRandomized(artistId, count: null);
      return songs.map((s) => _songToMediaItem(s, ps.client)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<MediaItem>> _buildAlbumSongs(
      PlayerService ps, String albumId) async {
    try {
      final songs = await ps.client.getSongsByAlbum(albumId: albumId);
      songs.shuffle();
      return songs.map((s) => _songToMediaItem(s, ps.client)).toList();
    } catch (_) {
      return [];
    }
  }

  MediaItem _songToMediaItem(Song song, SubsonicClient client) {
    return MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist ?? '',
      album: song.album ?? '',
      duration:
          song.duration != null ? Duration(seconds: song.duration!) : null,
      artUri: song.coverArt != null
          ? Uri.parse(client.getCoverArtUrl(song.coverArt))
          : null,
      extras: song.coverArt != null ? {'coverArt': song.coverArt!} : null,
      playable: true,
    );
  }

  @override
  Future<void> play() => _playerService?.play() ?? Future<void>.value();

  @override
  Future<void> playFromMediaId(String mediaId,
      [Map<String, dynamic>? extras]) async {
    final item = _itemCache[mediaId];
    if (item == null) return;
    await playMediaItem(item);
  }

  @override
  Future<void> playMediaItem(MediaItem mediaItem) async {
    final ps = _playerService;
    if (ps == null) return;

    // Browse the item on demand so the AA now-playing sheet reacts on tap.
    this.mediaItem.add(mediaItem);

    final parentId = _itemParent[mediaItem.id];
    try {
      final songs = await ps.fetchContainerSongs(
        categoryId: categoryForParent(parentId),
        containerId: containerIdForParent(parentId),
      );

      if (songs.isEmpty) {
        await ps.playSongsStartingAt(
          [_songFromMediaItem(mediaItem)],
          songId: mediaItem.id,
          shuffle: false,
        );
        return;
      }

      await ps.playSongsStartingAt(
        songs,
        songId: mediaItem.id,
        // Favorites keep server order (Requirement 5); containers are shuffled.
        shuffle: parentId != favoritesCategoryId,
      );
    } catch (error) {
      debugPrint('Android Auto: cannot start playback for ${mediaItem.id}: $error');
    }
  }

  /// Minimal [Song] for an item selected without a known parent container.
  Song _songFromMediaItem(MediaItem item) {
    return Song(
      id: item.id,
      isDir: false,
      title: item.title,
      album: item.album,
      artist: item.artist,
      duration: item.duration?.inSeconds,
      coverArt: item.extras?['coverArt'] as String?,
    );
  }

  @override
  Future<void> pause() => _playerService?.pause() ?? Future<void>.value();

  @override
  Future<void> stop() => _playerService?.pause() ?? Future<void>.value();

  @override
  Future<void> seek(Duration position) =>
      _playerService?.audioPlayer.seek(position) ?? Future<void>.value();

  @override
  Future<void> skipToQueueItem(int index) =>
      _playerService?.audioPlayer.seek(Duration.zero, index: index) ??
      Future<void>.value();

  @override
  Future<void> skipToNext() => _playerService?.next() ?? Future<void>.value();

  @override
  Future<void> skipToPrevious() =>
      _playerService?.previous() ?? Future<void>.value();

  @override
  Future<dynamic> customAction(String name,
      [Map<String, dynamic>? extras]) async {
    if (name == 'playSimilar') {
      await _playerService?.randomByPlayingSong();
    }
  }

  /// Clears the browse cache (e.g., when refreshing).
  void clearBrowseCache() {
    _browseCache.clear();
    _itemCache.clear();
    _itemParent.clear();
  }
}
