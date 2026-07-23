import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:random_mu/client/subsonic_client.dart';
import 'package:random_mu/client/subsonic_models.dart';
import 'package:random_mu/services/download_models.dart';

/// Manages offline downloads: queue, progress, storage, persistence.
class DownloadService extends ChangeNotifier {
  final SubsonicClient client;

  List<DownloadItem> _queue = [];
  StorageInfo _storageInfo = const StorageInfo();
  bool _isRunning = false;

  static const int maxConcurrent = 2;
  final Set<String> _activeDownloads = {};

  DownloadService({required this.client}) {
    _loadState();
  }

  // --- Getters ---

  List<DownloadItem> get queue => List.unmodifiable(_queue);
  StorageInfo get storageInfo => _storageInfo;

  // --- Queue Management ---

  Future<void> enqueuePlaylist(String playlistId, String title) async {
    _queue.add(DownloadItem(
      id: _nextId(),
      title: title,
      type: DownloadItemType.playlist,
      sourceId: playlistId,
    ));
    _saveState();
    notifyListeners();
    _processQueue();
  }

  Future<void> enqueueAlbum(String albumId, String title) async {
    _queue.add(DownloadItem(
      id: _nextId(),
      title: title,
      type: DownloadItemType.album,
      sourceId: albumId,
    ));
    _saveState();
    notifyListeners();
    _processQueue();
  }

  Future<void> enqueueArtist(String artistId, String title) async {
    _queue.add(DownloadItem(
      id: _nextId(),
      title: title,
      type: DownloadItemType.artist,
      sourceId: artistId,
    ));
    _saveState();
    notifyListeners();
    _processQueue();
  }

  Future<void> enqueueFavorites() async {
    final exists =
        _queue.any((item) => item.type == DownloadItemType.favorites);
    if (exists) return;

    _queue.add(DownloadItem(
      id: _nextId(),
      title: 'Favorites',
      type: DownloadItemType.favorites,
      sourceId: 'favorites',
    ));
    _saveState();
    notifyListeners();
    _processQueue();
  }

  Future<void> removeItem(String itemId) async {
    final item = _queue.firstWhere(
      (i) => i.id == itemId,
      orElse: () => throw Exception('Item not found'),
    );
    await _deleteItemFiles(item);
    _queue.removeWhere((i) => i.id == itemId);
    _saveState();
    notifyListeners();
  }

  Future<void> retryItem(String itemId) async {
    final index = _queue.indexWhere((i) => i.id == itemId);
    if (index == -1) return;
    _queue[index] = _queue[index].copyWith(
      status: DownloadStatus.queued,
      progress: 0.0,
      downloadedSongs: 0,
      errorMessage: null,
    );
    _saveState();
    notifyListeners();
    _processQueue();
  }

  Future<void> clearAll() async {
    for (final item in _queue) {
      await _deleteItemFiles(item);
    }
    _queue.clear();
    await _clearMetadataCache();
    _saveState();
    notifyListeners();
  }

  // --- Storage Limit ---

  Future<void> setStorageLimit(int? limitBytes) async {
    _storageInfo = _storageInfo.copyWith(limitBytes: limitBytes);
    await _saveStorageLimit(limitBytes);
    notifyListeners();
  }

  // --- Processing ---

  Future<void> _processQueue() async {
    if (_isRunning) return;
    _isRunning = true;

    while (_hasQueuedItems() && _activeDownloads.length < maxConcurrent) {
      if (_storageInfo.isLimitReached) {
        debugPrint('Storage limit reached. Blocking new downloads.');
        break;
      }

      final nextItem = _queue.firstWhere(
        (i) => i.status == DownloadStatus.queued,
        orElse: () => _queue.first,
      );

      if (_activeDownloads.contains(nextItem.id)) continue;

      _activeDownloads.add(nextItem.id);
      unawaited(_processItem(nextItem).then((_) {
        _activeDownloads.remove(nextItem.id);
        _processQueue();
      }));
    }

    _isRunning = false;
  }

  bool _hasQueuedItems() =>
      _queue.any((i) => i.status == DownloadStatus.queued);

  Future<void> _processItem(DownloadItem item) async {
    final index = _queue.indexWhere((i) => i.id == item.id);
    if (index == -1) return;

    _queue[index] = _queue[index].copyWith(
      status: DownloadStatus.downloading,
      progress: 0.0,
    );
    notifyListeners();

    try {
      List<Song> songs;

      switch (item.type) {
        case DownloadItemType.playlist:
          songs = await client.getPlaylistSongs(item.sourceId);
          break;
        case DownloadItemType.album:
          songs = await client.getSongsByAlbum(albumId: item.sourceId);
          break;
        case DownloadItemType.artist:
          songs = await client.getArtistSongsRandomized(
            item.sourceId,
            count: null,
          );
          break;
        case DownloadItemType.favorites:
          final starred = await client.getStarred();
          songs = [...starred.songs];
          for (final album in starred.albums) {
            try {
              final albumDetail = await client.getAlbum(album.id);
              songs.addAll(albumDetail.songs);
            } catch (_) {}
          }
          break;
      }

      _queue[index] = _queue[index].copyWith(
        totalSongs: songs.length,
        progress: 0.0,
        downloadedSongs: 0,
      );
      notifyListeners();

      final dir = await _getStorageDir();
      if (dir == null) throw Exception('Cannot access storage directory');

      int attempt = 0;
      const maxRetries = 3;

      for (int i = 0; i < songs.length; i++) {
        final song = songs[i];
        bool success = false;

        while (!success && attempt < maxRetries) {
          try {
            final bytes = await _downloadSong(song);
            final filePath = '${song.id}.${song.suffix ?? 'mp3'}';
            final file = io.File('${dir.path}/$filePath');
            await file.writeAsBytes(bytes);

            await _cacheSongMetadata(song, filePath);

            success = true;
            attempt = 0;

            _queue[index] = _queue[index].copyWith(
              downloadedSongs: i + 1,
              progress: (i + 1) / songs.length,
            );
            notifyListeners();
          } catch (e) {
            attempt++;
            if (attempt >= maxRetries) {
              rethrow;
            }
            await Future.delayed(Duration(seconds: 5 * attempt));
          }
        }

        await _refreshStorageInfo();
        if (_storageInfo.isLimitReached) {
          _queue[index] = _queue[index].copyWith(
            status: DownloadStatus.failed,
            errorMessage: 'Storage limit reached during download.',
          );
          _saveState();
          notifyListeners();
          return;
        }
      }

      _queue[index] = _queue[index].copyWith(
        status: DownloadStatus.completed,
        progress: 1.0,
      );
      _saveState();
      notifyListeners();
    } catch (e) {
      _queue[index] = _queue[index].copyWith(
        status: DownloadStatus.failed,
        errorMessage: e.toString(),
      );
      _saveState();
      notifyListeners();
    }
  }

  Future<Uint8List> _downloadSong(Song song) async {
    final streamUrl = client.getStreamUrl(song.id);
    final response = await http.get(Uri.parse(streamUrl));
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to download ${song.title}: HTTP ${response.statusCode}');
    }
    return response.bodyBytes;
  }

  // --- Storage ---

  Future<io.Directory?> _getStorageDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final musicDir = io.Directory('${appDir.path}/offline_music');
    if (!await musicDir.exists()) {
      await musicDir.create(recursive: true);
    }
    return musicDir;
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
      final songIds = jsonDecode(metadata) as List<dynamic>;
      for (final songId in songIds) {
        await for (final entity in dir.list()) {
          if (entity is io.File && entity.path.contains(songId.toString())) {
            await entity.delete();
          }
        }
      }
      await prefs.remove('download_metadata_${item.id}');
    }
    await _refreshStorageInfo();
  }

  Future<void> _cacheSongMetadata(Song song, String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'song_${song.id}';
    await prefs.setString(key, jsonEncode({
      'id': song.id,
      'title': song.title,
      'artist': song.artist,
      'album': song.album,
      'coverArt': song.coverArt,
      'duration': song.duration,
      'filePath': filePath,
    }));
  }

  Future<void> _clearMetadataCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('song_'));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  /// Get the local file path for a song ID, or null if not downloaded.
  Future<String?> getLocalPath(String songId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'song_$songId';
    final data = prefs.getString(key);
    if (data == null) return null;

    final map = jsonDecode(data) as Map<String, dynamic>;
    final filePath = map['filePath'] as String;

    final dir = await _getStorageDir();
    if (dir == null) return null;

    final file = io.File('${dir.path}/$filePath');
    if (await file.exists()) return file.path;
    return null;
  }

  // --- Persistence ---

  String _nextId() => DateTime.now().millisecondsSinceEpoch.toString();

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _queue.map((item) => item.toJson()).toList();
    await prefs.setString('download_queue', jsonEncode(jsonList));
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

    final limitStr = prefs.getString('storage_limit');
    if (limitStr != null) {
      final limit = int.tryParse(limitStr);
      _storageInfo = StorageInfo(limitBytes: limit);
    }

    await _refreshStorageInfo();

    for (int i = 0; i < _queue.length; i++) {
      if (_queue[i].status == DownloadStatus.downloading) {
        _queue[i] = _queue[i].copyWith(
          status: DownloadStatus.queued,
          progress: 0.0,
          downloadedSongs: 0,
        );
      }
    }
    _saveState();
    notifyListeners();

    unawaited(_processQueue());
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
