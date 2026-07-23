import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:random_mu/client/subsonic_client.dart';
import 'package:random_mu/client/subsonic_models.dart';
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

  /// Global reference so providers can wire the PlayerService after init.
  static AudioPlayerHandler? instance;

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
    if (_browseCache.containsKey(parentMediaId)) {
      return _browseCache[parentMediaId]!;
    }

    final ps = _playerService;
    if (ps == null) return [];

    List<MediaItem> children;
    switch (parentMediaId) {
      case rootId:
        children = _buildRootCategories();
        break;
      case playlistsCategoryId:
        children = await _buildPlaylists(ps);
        break;
      case artistsCategoryId:
        children = await _buildArtists(ps);
        break;
      case albumsCategoryId:
        children = await _buildAlbums(ps);
        break;
      case favoritesCategoryId:
        children = await _buildFavorites(ps);
        break;
      default:
        if (parentMediaId.startsWith('playlist-')) {
          final playlistId = parentMediaId.substring('playlist-'.length);
          children = await _buildPlaylistSongs(ps, playlistId);
        } else if (parentMediaId.startsWith('artist-')) {
          final artistId = parentMediaId.substring('artist-'.length);
          children = await _buildArtistSongs(ps, artistId);
        } else if (parentMediaId.startsWith('album-')) {
          final albumId = parentMediaId.substring('album-'.length);
          children = await _buildAlbumSongs(ps, albumId);
        } else {
          children = [];
        }
    }

    _browseCache[parentMediaId] = children;
    return children;
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
      playable: true,
    );
  }

  @override
  Future<void> play() => _playerService?.play() ?? Future<void>.value();

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
  }
}
