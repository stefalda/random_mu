import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:random_mu/client/audio_player_handler.dart';
import 'package:random_mu/client/subsonic_client.dart';
import 'package:random_mu/client/subsonic_models.dart';
import 'package:random_mu/services/browse_cache.dart';
import 'package:random_mu/services/download_models.dart';
import 'package:random_mu/services/notification_service.dart';

/// Manages offline downloads: queue, progress, storage, persistence.
///
/// Queue rules (see Spec 0001): FIFO, at most [maxConcurrent] parallel items,
/// [retryDelays]-driven retries per song, partial files never left behind, and a
/// user-configurable storage limit that blocks new work.
class DownloadService extends ChangeNotifier {
  final SubsonicClient client;

  /// Persistent Android Auto browse metadata, primed on completion.
  final BrowseCache browseCache;

  /// Optional download notifications.
  final NotificationService? notifications;

  /// Test seam: replaces the HTTP transport used to fetch audio bytes.
  final http.Client httpClient;

  /// Test seam: replaces `path_provider` for the storage directory.
  final Future<io.Directory?> Function()? storageDirOverride;

  /// Backoff delays after a failed attempt (3 retries by default).
  final List<Duration> retryDelays;

  /// Whether restored queue items start downloading on construction.
  final bool autoStart;

  List<DownloadItem> _queue = [];
  StorageInfo _storageInfo = const StorageInfo();
  final Set<String> _activeDownloads = {};
  final Completer<void> _ready = Completer<void>();
  bool _processing = false;
  bool _limitBlocked = false;
  bool _paused = false;

  static const int maxConcurrent = 2;

  static const List<Duration> defaultRetryDelays = [
    Duration(seconds: 5),
    Duration(seconds: 15),
    Duration(seconds: 45),
  ];

  DownloadService({
    required this.client,
    this.browseCache = const BrowseCache(),
    this.notifications,
    http.Client? httpClient,
    this.storageDirOverride,
    this.retryDelays = defaultRetryDelays,
    this.autoStart = true,
  }) : httpClient = httpClient ?? http.Client() {
    unawaited(_loadState());
  }

  /// Completes once the persisted queue has been restored.
  Future<void> get ready => _ready.future;

  // --- Getters ---

  List<DownloadItem> get queue => List.unmodifiable(_queue);
  StorageInfo get storageInfo => _storageInfo;

  /// True when queued work is waiting for space to be freed.
  bool get isBlockedByStorageLimit => _limitBlocked;

  /// True when the user paused the queue from the notification.
  bool get isPaused => _paused;

  /// Stops the item in flight and keeps the queue paused (persisted).
  void pauseQueue() {
    if (_paused) return;
    _paused = true;
    unawaited(_savePausedState(true));
    notifyListeners();
  }

  /// Resumes queue processing.
  void resumeQueue() {
    if (!_paused) return;
    _paused = false;
    unawaited(_savePausedState(false));
    notifyListeners();
    unawaited(_processQueue());
  }

  Future<void> _savePausedState(bool paused) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('download_paused', paused);
  }

  /// Queue item for a library item, or null when it was never enqueued.
  DownloadItem? itemFor({
    required DownloadItemType type,
    required String sourceId,
  }) {
    for (final item in _queue) {
      if (item.type == type && item.sourceId == sourceId) return item;
    }
    return null;
  }

  /// Whether a library item is queued, downloading or completed.
  bool isDownloadedOrPending({
    required DownloadItemType type,
    required String sourceId,
  }) {
    final item = itemFor(type: type, sourceId: sourceId);
    return item != null && item.status != DownloadStatus.failed;
  }

  // --- Queue Management ---

  Future<void> enqueuePlaylist(String playlistId, String title) {
    return _enqueue(DownloadItemType.playlist, playlistId, title);
  }

  Future<void> enqueueAlbum(String albumId, String title) {
    return _enqueue(DownloadItemType.album, albumId, title);
  }

  Future<void> enqueueArtist(String artistId, String title) {
    return _enqueue(DownloadItemType.artist, artistId, title);
  }

  Future<void> enqueueFavorites() {
    final exists = _queue.any((item) => item.type == DownloadItemType.favorites);
    if (exists) return Future<void>.value();
    return _enqueue(DownloadItemType.favorites, 'favorites', 'Favorites');
  }

  Future<void> _enqueue(
      DownloadItemType type, String sourceId, String title) async {
    final existing = itemFor(type: type, sourceId: sourceId);
    if (existing != null) return;

    _queue.add(DownloadItem(
      id: _nextId(),
      title: title,
      type: type,
      sourceId: sourceId,
    ));
    _limitBlocked = _limitBlocked && !_storageInfo.isLimitReached;
    await _saveState();
    notifyListeners();
    unawaited(notifications?.ensurePermission() ?? Future<void>.value());
    unawaited(_processQueue());
  }

  Future<void> removeItem(String itemId) async {
    final index = _queue.indexWhere((i) => i.id == itemId);
    if (index == -1) return;

    final item = _queue[index];
    await _deleteItemFiles(item);
    await _removeCachedBrowseNodes(item);
    _queue.removeAt(index);
    // Freeing space can unblock the queue.
    _limitBlocked = false;
    await _refreshStorageInfo();
    await _saveState();
    notifyListeners();
    unawaited(_processQueue());
  }

  Future<void> retryItem(String itemId) async {
    final index = _queue.indexWhere((i) => i.id == itemId);
    if (index == -1) return;
    _queue[index] = _queue[index].copyWith(
      status: DownloadStatus.queued,
      progress: 0.0,
      downloadedSongs: 0,
      clearError: true,
    );
    _limitBlocked = false;
    await _saveState();
    notifyListeners();
    unawaited(_processQueue());
  }

  Future<void> clearAll() async {
    for (final item in _queue) {
      await _deleteItemFiles(item);
      await _removeCachedBrowseNodes(item);
    }
    _queue.clear();
    await _clearMetadataCache();
    await browseCache.clear();
    _invalidateBrowserCache();
    _limitBlocked = false;
    await _refreshStorageInfo();
    await _saveState();
    notifyListeners();
  }

  // --- Storage Limit ---

  Future<void> setStorageLimit(int? limitBytes) async {
    _storageInfo = _storageInfo.copyWith(limitBytes: limitBytes);
    _limitBlocked = false;
    await _saveStorageLimit(limitBytes);
    notifyListeners();
    unawaited(_processQueue());
  }

  // --- Processing ---

  Future<void> _processQueue() async {
    if (_processing) return;
    _processing = true;
    try {
      while (_activeDownloads.length < maxConcurrent) {
        final next = _nextQueuedItem();
        if (next == null) break;

        if (_storageInfo.isLimitReached) {
          _limitBlocked = true;
          debugPrint('Storage limit reached, not starting "${next.title}".');
          break;
        }

        _activeDownloads.add(next.id);
        unawaited(_runItem(next));
      }
    } finally {
      _processing = false;
    }
  }

  DownloadItem? _nextQueuedItem() {
    if (_limitBlocked || _paused) return null;
    for (final item in _queue) {
      if (item.status == DownloadStatus.queued &&
          !_activeDownloads.contains(item.id)) {
        return item;
      }
    }
    return null;
  }

  Future<void> _runItem(DownloadItem item) async {
    try {
      await _processItem(item);
    } finally {
      _activeDownloads.remove(item.id);
      unawaited(_processQueue());
    }
  }

  Future<void> _processItem(DownloadItem item) async {
    final index = _queue.indexWhere((i) => i.id == item.id);
    if (index == -1) return;

    _queue[index] = _queue[index]
        .copyWith(status: DownloadStatus.downloading, progress: 0.0);
    notifyListeners();

    try {
      final songs = await fetchSongsFor(_queue[index]);
      if (songs.isEmpty) {
        await _completeItem(index, songs);
        return;
      }

      // Block before starting work that cannot fit in the configured limit.
      final estimatedSize = songs.fold<int>(
          0, (total, song) => total + (song.size ?? 0));
      if (_wouldExceedLimit(estimatedSize)) {
        _queue[index] = _queue[index].copyWith(
          status: DownloadStatus.queued,
          progress: 0.0,
          clearError: true,
        );
        _limitBlocked = true;
        debugPrint('Not enough space to download "${item.title}".');
        notifyListeners();
        return;
      }

      _queue[index] = _queue[index].copyWith(
        totalSongs: songs.length,
        progress: 0.0,
        downloadedSongs: 0,
        clearError: true,
      );
      // Record the songs up front: a download that is paused or deleted before
      // completion must still know which files belong to it.
      await _storeItemSongIds(_queue[index], songs);
      await _saveState();
      notifyListeners();

      final dir = await _getStorageDir();
      if (dir == null) throw Exception('Cannot access storage directory');

      for (int i = 0; i < songs.length; i++) {
        // A pause (notification action or Downloads page) stops the item in
        // flight: it goes back to the queue and resumes from the next song.
        if (_paused) {
          _queue[index] = _queue[index].copyWith(
            status: DownloadStatus.queued,
            downloadedSongs: i,
            progress: songs.isEmpty ? 0.0 : i / songs.length,
          );
          await _saveState();
          notifyListeners();
          return;
        }

        // Songs already on disk (resume after pause/restart) are not fetched
        // again.
        if (await getLocalPath(songs[i].id) == null) {
          await _downloadSongWithRetries(songs[i], dir);
        }

        await _refreshStorageInfo();
        _queue[index] = _queue[index].copyWith(
          downloadedSongs: i + 1,
          progress: (i + 1) / songs.length,
        );
        await _saveState();
        notifyListeners();

        if (_storageInfo.isLimitReached) {
          _queue[index] = _queue[index].copyWith(
            status: DownloadStatus.failed,
            errorMessage: 'Storage limit reached during download.',
          );
          _limitBlocked = true;
          await _storeItemSongIds(_queue[index], songs);
          await _primeBrowseCache(_queue[index], songs);
          unawaited(_notifyFailure(_queue[index]));
          await _saveState();
          notifyListeners();
          return;
        }
      }

      await _completeItem(index, songs);
    } catch (error) {
      _queue[index] = _queue[index].copyWith(
        status: DownloadStatus.failed,
        errorMessage: error.toString(),
      );
      unawaited(_notifyFailure(_queue[index]));
      await _saveState();
      notifyListeners();
    }
  }

  Future<void> _completeItem(int index, List<Song> songs) async {
    _queue[index] = _queue[index].copyWith(
      status: DownloadStatus.completed,
      progress: 1.0,
      downloadedSongs: songs.length,
      totalSongs: songs.length,
      clearError: true,
    );
    await _storeItemSongIds(_queue[index], songs);
    await _primeBrowseCache(_queue[index], songs);
    notifications?.downloadCompleted(_queue[index]);
    await _saveState();
    notifyListeners();
  }

  /// Songs belonging to the item. Test seam overrides this to avoid the network.
  @protected
  Future<List<Song>> fetchSongsFor(DownloadItem item) async {
    switch (item.type) {
      case DownloadItemType.playlist:
        return client.getPlaylistSongs(item.sourceId);
      case DownloadItemType.album:
        return client.getSongsByAlbum(albumId: item.sourceId);
      case DownloadItemType.artist:
        return client.getArtistSongsRandomized(item.sourceId, count: null);
      case DownloadItemType.favorites:
        final starred = await client.getStarred();
        final songs = <Song>[...starred.songs];
        for (final album in starred.albums) {
          try {
            final albumDetail = await client.getAlbum(album.id);
            songs.addAll(albumDetail.songs);
          } catch (_) {
            // Skip albums that fail: the rest of the favorites still download.
          }
        }
        return songs;
    }
  }

  /// Raw bytes of a song. Test seam overrides this to avoid the network.
  @protected
  Future<Uint8List> fetchSongBytes(Song song) async {
    final streamUrl = client.getStreamUrl(song.id);
    final response = await httpClient.get(Uri.parse(streamUrl));
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to download ${song.title}: HTTP ${response.statusCode}');
    }
    return response.bodyBytes;
  }

  /// Downloads one song, retrying up to [retryDelays].length times.
  Future<void> _downloadSongWithRetries(Song song, io.Directory dir) async {
    Object? lastError;
    for (var attempt = 0; attempt <= retryDelays.length; attempt++) {
      try {
        await _downloadSongToFile(song, dir);
        return;
      } catch (error) {
        lastError = error;
        if (attempt == retryDelays.length) break;
        await Future<void>.delayed(retryDelays[attempt]);
      }
    }
    throw Exception('Failed to download "${song.title}": $lastError');
  }

  Future<void> _downloadSongToFile(Song song, io.Directory dir) async {
    final filePath = '${song.id}.${song.suffix ?? 'mp3'}';
    final finalFile = io.File('${dir.path}/$filePath');
    final partFile = io.File('${finalFile.path}.part');

    try {
      final bytes = await fetchSongBytes(song);
      await partFile.writeAsBytes(bytes, flush: true);
      if (await finalFile.exists()) {
        await finalFile.delete();
      }
      await partFile.rename(finalFile.path);
      await _cacheSongMetadata(song, filePath);
    } catch (_) {
      // Never leave a partial file behind.
      if (await partFile.exists()) {
        await partFile.delete();
      }
      rethrow;
    }
  }

  bool _wouldExceedLimit(int additionalBytes) {
    final limit = _storageInfo.limitBytes;
    if (limit == null) return false;
    return _storageInfo.usedBytes + additionalBytes > limit;
  }

  // --- Android Auto browse metadata ---

  /// Caches the browse nodes of a finished download so the tree works offline.
  Future<void> _primeBrowseCache(DownloadItem item, List<Song> songs) async {
    final songItems = songs.map(_songToMediaItem).toList();
    final nodeId = _browseNodeId(item);
    await browseCache.saveNode(nodeId, songItems);

    final categoryId = _browseCategoryId(item);
    if (categoryId != null) {
      await browseCache.upsertInCategory(
        categoryId,
        MediaItem(id: nodeId, title: item.title, playable: false),
      );
    }

    _invalidateBrowserCache();
  }

  Future<void> _removeCachedBrowseNodes(DownloadItem item) async {
    final nodeId = _browseNodeId(item);
    await browseCache.removeNode(nodeId);
    final categoryId = _browseCategoryId(item);
    if (categoryId != null) {
      await browseCache.removeFromCategory(categoryId, nodeId);
    }
    _invalidateBrowserCache();
  }

  /// Browse node id for a download item (favorites use the category itself).
  String _browseNodeId(DownloadItem item) {
    switch (item.type) {
      case DownloadItemType.playlist:
        return 'playlist-${item.sourceId}';
      case DownloadItemType.album:
        return 'album-${item.sourceId}';
      case DownloadItemType.artist:
        return 'artist-${item.sourceId}';
      case DownloadItemType.favorites:
        return favoritesCategoryId;
    }
  }

  /// Parent category of the item in the browse tree, null for favorites.
  String? _browseCategoryId(DownloadItem item) {
    switch (item.type) {
      case DownloadItemType.playlist:
        return playlistsCategoryId;
      case DownloadItemType.album:
        return albumsCategoryId;
      case DownloadItemType.artist:
        return artistsCategoryId;
      case DownloadItemType.favorites:
        return null;
    }
  }

  MediaItem _songToMediaItem(Song song) {
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

  void _invalidateBrowserCache() {
    AudioPlayerHandler.instance?.clearBrowseCache();
  }

  Future<void> _notifyFailure(DownloadItem item) async {
    await notifications?.downloadFailed(item);
  }

  // --- Storage ---

  Future<io.Directory?> _getStorageDir() async {
    final override = storageDirOverride;
    if (override != null) return override();
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final musicDir = io.Directory('${appDir.path}/offline_music');
      if (!await musicDir.exists()) {
        await musicDir.create(recursive: true);
      }
      return musicDir;
    } catch (_) {
      // No documents directory (e.g. unsupported platform or tests).
      return null;
    }
  }

  Future<void> _refreshStorageInfo() async {
    final dir = await _getStorageDir();
    if (dir == null) return;
    int totalBytes = 0;
    await for (final entity in dir.list()) {
      if (entity is io.File) {
        totalBytes += await entity.length();
      }
    }
    _storageInfo = _storageInfo.copyWith(usedBytes: totalBytes);
  }

  Future<void> _deleteItemFiles(DownloadItem item) async {
    final dir = await _getStorageDir();
    if (dir == null) return;

    final prefs = await SharedPreferences.getInstance();
    final metadata = prefs.getString('download_metadata_${item.id}');
    if (metadata != null) {
      final songIds = (jsonDecode(metadata) as List<dynamic>).cast<String>();
      for (final songId in songIds) {
        final songKey = 'song_$songId';
        final data = prefs.getString(songKey);
        if (data != null) {
          final filePath =
              (jsonDecode(data) as Map<String, dynamic>)['filePath'] as String?;
          if (filePath != null) {
            final file = io.File('${dir.path}/$filePath');
            if (await file.exists()) {
              await file.delete();
            }
          }
          await prefs.remove(songKey);
        }
      }
      await prefs.remove('download_metadata_${item.id}');
    }
    await _refreshStorageInfo();
  }

  Future<void> _storeItemSongIds(
      DownloadItem item, List<Song> songs) async {
    if (songs.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'download_metadata_${item.id}',
      jsonEncode(songs.map((song) => song.id).toList()),
    );
  }

  Future<void> _cacheSongMetadata(Song song, String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'song_${song.id}',
      jsonEncode({
        'id': song.id,
        'title': song.title,
        'artist': song.artist,
        'album': song.album,
        'coverArt': song.coverArt,
        'duration': song.duration,
        'filePath': filePath,
      }),
    );
  }

  Future<void> _clearMetadataCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs
        .getKeys()
        .where((k) => k.startsWith('song_') || k.startsWith('download_metadata_'))
        .toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  /// Get the local file path for a song ID, or null if not downloaded.
  Future<String?> getLocalPath(String songId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('song_$songId');
    if (data == null) return null;

    final map = jsonDecode(data) as Map<String, dynamic>;
    final filePath = map['filePath'] as String?;
    if (filePath == null) return null;

    final dir = await _getStorageDir();
    if (dir == null) return null;

    final file = io.File('${dir.path}/$filePath');
    if (await file.exists()) return file.path;
    return null;
  }

  // --- Persistence ---

  String _nextId() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'download_queue',
      jsonEncode(_queue.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('download_queue');
    if (data != null) {
      try {
        final list = jsonDecode(data) as List<dynamic>;
        _queue = list
            .map((e) => DownloadItem.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _queue = [];
      }
    }

    _paused = prefs.getBool('download_paused') ?? false;

    final limitStr = prefs.getString('storage_limit');
    if (limitStr != null) {
      _storageInfo = StorageInfo(limitBytes: int.tryParse(limitStr));
    }

    await _refreshStorageInfo();
    await _cleanupPartialFiles();

    for (int i = 0; i < _queue.length; i++) {
      if (_queue[i].status == DownloadStatus.downloading) {
        _queue[i] = _queue[i].copyWith(
          status: DownloadStatus.queued,
          progress: 0.0,
          downloadedSongs: 0,
        );
      }
    }
    await _saveState();
    if (!_ready.isCompleted) _ready.complete();
    notifyListeners();

    if (autoStart) unawaited(_processQueue());
  }

  /// A crashing download can leave `<song>.part` files behind: the queue is
  /// restored before any download restarts, so they are always orphans.
  Future<void> _cleanupPartialFiles() async {
    final dir = await _getStorageDir();
    if (dir == null) return;
    try {
      await for (final entity in dir.list()) {
        if (entity is io.File && entity.path.endsWith('.part')) {
          await entity.delete();
        }
      }
    } catch (error) {
      debugPrint('Cannot clean up partial downloads: $error');
    }
  }

  Future<void> _saveStorageLimit(int? limitBytes) async {
    final prefs = await SharedPreferences.getInstance();
    if (limitBytes != null) {
      await prefs.setString('storage_limit', limitBytes.toString());
    } else {
      await prefs.remove('storage_limit');
    }
  }
}
