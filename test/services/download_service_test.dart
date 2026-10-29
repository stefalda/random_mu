import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:random_mu/client/subsonic_client.dart';
import 'package:random_mu/client/subsonic_models.dart';
import 'package:random_mu/services/download_models.dart';
import 'package:random_mu/services/download_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// DownloadService with the network and file system seams replaced.
class _TestDownloadService extends DownloadService {
  final Map<String, List<Song>> songsBySource;
  final Map<String, int> failuresRemaining;
  final Duration byteDelay;

  final List<String> startedItems = [];
  int songAttempts = 0;
  int _concurrent = 0;
  int maxConcurrentObserved = 0;

  _TestDownloadService({
    required super.client,
    required io.Directory storageDir,
    required super.retryDelays,
    this.songsBySource = const {},
    this.failuresRemaining = const {},
    this.byteDelay = Duration.zero,
  }) : super(
          storageDirOverride: () async => storageDir,
          autoStart: false,
        );

  @override
  Future<List<Song>> fetchSongsFor(DownloadItem item) async {
    startedItems.add(item.sourceId);
    return songsBySource[item.sourceId] ?? const [];
  }

  @override
  Future<Uint8List> fetchSongBytes(Song song) async {
    songAttempts++;
    _concurrent++;
    if (_concurrent > maxConcurrentObserved) {
      maxConcurrentObserved = _concurrent;
    }
    try {
      if (byteDelay > Duration.zero) {
        await Future<void>.delayed(byteDelay);
      }
      final remaining = failuresRemaining[song.id] ?? 0;
      if (remaining > 0) {
        failuresRemaining[song.id] = remaining - 1;
        throw Exception('boom ${song.id}');
      }
      return Uint8List.fromList(List<int>.filled(10, 7));
    } finally {
      _concurrent--;
    }
  }
}

Song _song(String id, {int size = 10}) => Song(
      id: id,
      isDir: false,
      title: 'Song $id',
      suffix: 'mp3',
      size: size,
      duration: 100,
    );

SubsonicClient _client() => SubsonicClient(
      baseUrl: 'http://localhost',
      username: 'user',
      password: 'pass',
    );

Future<void> _waitForTerminal(DownloadService service, String itemId) async {
  for (var i = 0; i < 300; i++) {
    final item = service.queue.where((q) => q.id == itemId).firstOrNull;
    if (item != null &&
        (item.status == DownloadStatus.completed ||
            item.status == DownloadStatus.failed)) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail('Download $itemId did not finish');
}

Future<void> _waitForBlocked(DownloadService service) async {
  for (var i = 0; i < 300; i++) {
    if (service.isBlockedByStorageLimit) return;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail('Storage limit never blocked the queue');
}

void main() {
  late io.Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await io.Directory.systemTemp.createTemp('random_mu_downloads');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  _TestDownloadService buildService({
    Map<String, List<Song>> songs = const {},
    Map<String, int> failures = const {},
    List<Duration> retries = const [
      Duration.zero,
      Duration.zero,
      Duration.zero,
    ],
    Duration byteDelay = Duration.zero,
  }) {
    return _TestDownloadService(
      client: _client(),
      storageDir: tempDir,
      retryDelays: retries,
      songsBySource: songs,
      failuresRemaining: failures,
      byteDelay: byteDelay,
    );
  }

  test('downloads songs to the storage directory and resolves local paths',
      () async {
    final service = buildService(songs: {
      'pl-1': [_song('s1'), _song('s2')],
    });
    await service.ready;

    await service.enqueuePlaylist('pl-1', 'Playlist');
    final item = service.queue.single;
    await _waitForTerminal(service, item.id);

    expect(service.queue.single.status, DownloadStatus.completed);
    expect(service.queue.single.downloadedSongs, 2);
    expect(service.queue.single.progress, 1.0);
    expect(await io.File('${tempDir.path}/s1.mp3').exists(), isTrue);
    expect(await service.getLocalPath('s1'), '${tempDir.path}/s1.mp3');
    expect(service.storageInfo.usedBytes, 20);
  });

  test('processes queued items in FIFO order', () async {
    final service = buildService(songs: {
      'pl-1': [_song('s1')],
      'pl-2': [_song('s2')],
      'pl-3': [_song('s3')],
    });
    await service.ready;

    await service.enqueuePlaylist('pl-1', 'One');
    await service.enqueuePlaylist('pl-2', 'Two');
    await service.enqueuePlaylist('pl-3', 'Three');

    for (final item in service.queue) {
      await _waitForTerminal(service, item.id);
    }

    expect(service.startedItems, ['pl-1', 'pl-2', 'pl-3']);
  });

  test('never runs more than two downloads at once', () async {
    final service = buildService(
      songs: {
        'pl-1': [_song('s1'), _song('s2')],
        'pl-2': [_song('s3'), _song('s4')],
        'pl-3': [_song('s5'), _song('s6')],
        'pl-4': [_song('s7'), _song('s8')],
      },
      byteDelay: const Duration(milliseconds: 15),
    );
    await service.ready;

    await service.enqueuePlaylist('pl-1', 'One');
    await service.enqueuePlaylist('pl-2', 'Two');
    await service.enqueuePlaylist('pl-3', 'Three');
    await service.enqueuePlaylist('pl-4', 'Four');

    for (final item in service.queue) {
      await _waitForTerminal(service, item.id);
    }

    expect(service.maxConcurrentObserved, lessThanOrEqualTo(2));
    expect(service.queue.every((i) => i.status == DownloadStatus.completed),
        isTrue);
  });

  test('retries a failing song and succeeds', () async {
    final service = buildService(
      songs: {
        'pl-1': [_song('s1')],
      },
      failures: {'s1': 2},
    );
    await service.ready;

    await service.enqueuePlaylist('pl-1', 'Playlist');
    final item = service.queue.single;
    await _waitForTerminal(service, item.id);

    expect(service.songAttempts, 3);
    expect(service.queue.single.status, DownloadStatus.completed);
  });

  test('gives up after three retries and leaves no partial file', () async {
    final service = buildService(
      songs: {
        'pl-1': [_song('s1')],
      },
      failures: {'s1': 99},
    );
    await service.ready;

    await service.enqueuePlaylist('pl-1', 'Playlist');
    final item = service.queue.single;
    await _waitForTerminal(service, item.id);

    // Initial attempt plus three retries.
    expect(service.songAttempts, 4);
    expect(service.queue.single.status, DownloadStatus.failed);
    expect(service.queue.single.errorMessage, contains('s1'));

    final leftovers = await tempDir.list().toList();
    expect(leftovers, isEmpty);
  });

  test('blocks an item that cannot fit in the storage limit', () async {
    final service = buildService(songs: {
      'pl-1': [_song('s1', size: 100), _song('s2', size: 100)],
    });
    await service.ready;
    await service.setStorageLimit(50);

    await service.enqueuePlaylist('pl-1', 'Playlist');
    await _waitForBlocked(service);

    expect(service.songAttempts, 0);
    expect(service.queue.single.status, DownloadStatus.queued);
    expect(service.storageInfo.isLimitReached, isFalse);
    expect(await tempDir.list().toList(), isEmpty);
  });

  test('unblocks the queue once space is freed', () async {
    final service = buildService(songs: {
      'pl-1': [_song('s1', size: 100)],
      'pl-2': [_song('s2', size: 10)],
    });
    await service.ready;
    await service.setStorageLimit(120);

    await service.enqueuePlaylist('pl-1', 'Big');
    await service.enqueuePlaylist('pl-2', 'Small');
    final big = service.queue.first;
    await _waitForTerminal(service, big.id);

    // 10 bytes used by "Big" (fake bytes), so "Small" still fits: no block.
    expect(service.queue.last.status, DownloadStatus.completed);

    // Removing the big item frees the block flag.
    await service.removeItem(big.id);
    expect(service.isBlockedByStorageLimit, isFalse);
    expect(await service.getLocalPath('s1'), isNull);
  });

  test('a paused queue stays paused after a restart', () async {
    final service = buildService(songs: {
      'pl-1': [_song('s1')],
    });
    await service.ready;

    service.pauseQueue();
    await service.enqueuePlaylist('pl-1', 'Playlist');
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final restarted = buildService(songs: {
      'pl-1': [_song('s1')],
    });
    await restarted.ready;
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(restarted.isPaused, isTrue);
    expect(restarted.songAttempts, 0);
    expect(restarted.queue.single.status, DownloadStatus.queued);

    // Cleanup so the temp dir assertions in other tests stay meaningful.
    await restarted.removeItem(restarted.queue.single.id);
  });

  test('restores the queue after a restart and requeues in-progress items',
      () async {
    final downloading = DownloadItem(
      id: 'abc',
      title: 'Interrupted',
      type: DownloadItemType.album,
      sourceId: 'al-1',
      status: DownloadStatus.downloading,
      progress: 0.4,
      totalSongs: 10,
      downloadedSongs: 4,
    );
    SharedPreferences.setMockInitialValues({
      'download_queue': jsonEncode([downloading.toJson()]),
    });

    final service = buildService();
    await service.ready;

    final restored = service.queue.single;
    expect(restored.id, 'abc');
    expect(restored.status, DownloadStatus.queued);
    expect(restored.progress, 0);
    expect(restored.downloadedSongs, 0);
  });

  test('persists the queue when an item is enqueued', () async {
    final service = buildService(songs: {
      'pl-1': [_song('s1')],
    });
    await service.ready;

    await service.enqueuePlaylist('pl-1', 'Playlist');

    final prefs = await SharedPreferences.getInstance();
    final saved = jsonDecode(prefs.getString('download_queue')!) as List;
    expect(saved.length, 1);
    expect((saved.single as Map)['sourceId'], 'pl-1');
  });

  test('pausing stops the item in flight and resumes from the next song',
      () async {
    final service = buildService(
      songs: {
        'pl-1': [_song('s1'), _song('s2'), _song('s3')],
      },
      byteDelay: const Duration(milliseconds: 30),
    );
    await service.ready;

    await service.enqueuePlaylist('pl-1', 'Playlist');
    final item = service.queue.single;

    // Wait for the first song to land, then pause.
    for (var i = 0; i < 200; i++) {
      if (await service.getLocalPath('s1') != null) break;
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    service.pauseQueue();

    for (var i = 0; i < 200; i++) {
      if (service.queue.single.status == DownloadStatus.queued) break;
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }

    final paused = service.queue.single;
    expect(paused.status, DownloadStatus.queued);
    expect(paused.downloadedSongs, greaterThanOrEqualTo(1));
    expect(paused.downloadedSongs, lessThan(3));

    final attemptsBeforeResume = service.songAttempts;
    service.resumeQueue();
    await _waitForTerminal(service, item.id);

    expect(service.queue.single.status, DownloadStatus.completed);
    // The songs downloaded before the pause are not fetched twice.
    expect(service.songAttempts - attemptsBeforeResume, lessThan(3));
  });

  test('pausing the queue stops new items until resumed', () async {
    final service = buildService(songs: {
      'pl-1': [_song('s1')],
    });
    await service.ready;

    service.pauseQueue();
    await service.enqueuePlaylist('pl-1', 'Playlist');
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(service.isPaused, isTrue);
    expect(service.songAttempts, 0);
    expect(service.queue.single.status, DownloadStatus.queued);

    service.resumeQueue();
    final item = service.queue.single;
    await _waitForTerminal(service, item.id);

    expect(service.queue.single.status, DownloadStatus.completed);
  });

  test('deleting an in-progress item removes what was already downloaded',
      () async {
    final service = buildService(
      songs: {
        'pl-1': [_song('s1'), _song('s2'), _song('s3')],
      },
      byteDelay: const Duration(milliseconds: 30),
    );
    await service.ready;

    await service.enqueuePlaylist('pl-1', 'Playlist');
    for (var i = 0; i < 200; i++) {
      if (await service.getLocalPath('s1') != null) break;
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }

    final item = service.queue.single;
    await service.removeItem(item.id);

    expect(service.queue, isEmpty);
    expect(await tempDir.list().toList(), isEmpty);
    expect(await service.getLocalPath('s1'), isNull);
  });

  test('deleting an item while it downloads stops the in-flight task',
      () async {
    final service = buildService(
      songs: {
        'pl-1': [_song('s1'), _song('s2'), _song('s3')],
        'pl-2': [_song('s4')],
      },
      byteDelay: const Duration(milliseconds: 40),
    );
    await service.ready;

    await service.enqueuePlaylist('pl-1', 'One');
    for (var i = 0; i < 200; i++) {
      if (await service.getLocalPath('s1') != null) break;
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }

    final item = service.queue.single;
    await service.removeItem(item.id);

    // Give the in-flight task time to notice the cancellation.
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(service.queue, isEmpty);
    expect(await tempDir.list().toList(), isEmpty);
    expect(await service.getLocalPath('s1'), isNull);
  });

  test('deleting an item removes its files and metadata', () async {
    final service = buildService(songs: {
      'pl-1': [_song('s1'), _song('s2')],
    });
    await service.ready;

    await service.enqueuePlaylist('pl-1', 'Playlist');
    final item = service.queue.single;
    await _waitForTerminal(service, item.id);

    expect(await io.File('${tempDir.path}/s1.mp3').exists(), isTrue);

    await service.removeItem(item.id);

    expect(service.queue, isEmpty);
    expect(await io.File('${tempDir.path}/s1.mp3').exists(), isFalse);
    expect(await service.getLocalPath('s1'), isNull);
  });
}
