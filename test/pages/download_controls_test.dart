import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:random_mu/l10n/generated/app_localizations.dart';
import 'package:random_mu/client/subsonic_client.dart';
import 'package:random_mu/pages/download_button.dart';
import 'package:random_mu/pages/downloads_page.dart';
import 'package:random_mu/providers/download_provider.dart';
import 'package:random_mu/services/download_models.dart';
import 'package:random_mu/services/download_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// DownloadService with in-memory state, no network and no file system.
class _FakeDownloadService extends DownloadService {
  final List<DownloadItem> items;
  final StorageInfo fakeStorage;
  final List<String> enqueued = [];
  final List<String> removed = [];
  final List<String> retried = [];

  _FakeDownloadService({
    List<DownloadItem>? items,
    StorageInfo storage = const StorageInfo(),
  })  : items = items ?? [],
        fakeStorage = storage,
        super(
          client: SubsonicClient(
            baseUrl: 'http://localhost',
            username: 'user',
            password: 'pass',
          ),
        );

  @override
  List<DownloadItem> get queue => List.unmodifiable(items);

  @override
  StorageInfo get storageInfo => fakeStorage;

  @override
  DownloadItem? itemFor({
    required DownloadItemType type,
    required String sourceId,
  }) {
    for (final item in items) {
      if (item.type == type && item.sourceId == sourceId) return item;
    }
    return null;
  }

  @override
  Future<void> enqueuePlaylist(String playlistId, String title) async {
    enqueued.add('playlist:$playlistId');
    items.add(DownloadItem(
      id: 'new',
      title: title,
      type: DownloadItemType.playlist,
      sourceId: playlistId,
    ));
    notifyListeners();
  }

  @override
  Future<void> enqueueAlbum(String albumId, String title) async {
    enqueued.add('album:$albumId');
    notifyListeners();
  }

  @override
  Future<void> enqueueArtist(String artistId, String title) async {
    enqueued.add('artist:$artistId');
    notifyListeners();
  }

  @override
  Future<void> enqueueFavorites() async {
    enqueued.add('favorites');
    notifyListeners();
  }

  @override
  Future<void> removeItem(String itemId) async {
    removed.add(itemId);
    items.removeWhere((item) => item.id == itemId);
    notifyListeners();
  }

  @override
  Future<void> retryItem(String itemId) async {
    retried.add(itemId);
    notifyListeners();
  }
}

DownloadItem _item({
  String id = '1',
  DownloadItemType type = DownloadItemType.playlist,
  String sourceId = 'pl-1',
  String title = 'Playlist',
  DownloadStatus status = DownloadStatus.queued,
  double progress = 0,
  int totalSongs = 10,
  int downloadedSongs = 0,
}) {
  return DownloadItem(
    id: id,
    title: title,
    type: type,
    sourceId: sourceId,
    status: status,
    progress: progress,
    totalSongs: totalSongs,
    downloadedSongs: downloadedSongs,
  );
}

Widget _wrap(Widget child, DownloadService service) {
  return ProviderScope(
    overrides: [downloadServiceProvider.overrideWithValue(service)],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DownloadButton', () {
    testWidgets('shows the idle icon and enqueues the item on tap',
        (tester) async {
      final service = _FakeDownloadService();
      await tester.pumpWidget(_wrap(
        const DownloadButton(
          type: DownloadItemType.playlist,
          sourceId: 'pl-1',
          title: 'Playlist',
        ),
        service,
      ));

      expect(find.byIcon(Icons.cloud_download_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.cloud_download_outlined));
      await tester.pump();

      expect(service.enqueued, ['playlist:pl-1']);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows progress while downloading', (tester) async {
      final service = _FakeDownloadService(items: [
        _item(status: DownloadStatus.downloading, progress: 0.5),
      ]);
      await tester.pumpWidget(_wrap(
        const DownloadButton(
          type: DownloadItemType.playlist,
          sourceId: 'pl-1',
          title: 'Playlist',
        ),
        service,
      ));

      final indicator = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator));
      expect(indicator.value, 0.5);
    });

    testWidgets('completed item asks for confirmation before removing',
        (tester) async {
      final service = _FakeDownloadService(items: [
        _item(status: DownloadStatus.completed, progress: 1),
      ]);
      await tester.pumpWidget(_wrap(
        const DownloadButton(
          type: DownloadItemType.playlist,
          sourceId: 'pl-1',
          title: 'Playlist',
        ),
        service,
      ));

      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      await tester.tap(find.byIcon(Icons.check_circle));
      await tester.pumpAndSettle();

      expect(find.text('Remove download?'), findsOneWidget);

      // Cancelling keeps the download.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(service.removed, isEmpty);

      await tester.tap(find.byIcon(Icons.check_circle));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      expect(service.removed, ['1']);
    });

    testWidgets('failed item retries on tap', (tester) async {
      final service = _FakeDownloadService(items: [
        _item(status: DownloadStatus.failed),
      ]);
      await tester.pumpWidget(_wrap(
        const DownloadButton(
          type: DownloadItemType.playlist,
          sourceId: 'pl-1',
          title: 'Playlist',
        ),
        service,
      ));

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      await tester.tap(find.byIcon(Icons.error_outline));
      await tester.pump();

      expect(service.retried, ['1']);
    });

    testWidgets('blocks the download when the storage limit is reached',
        (tester) async {
      final service = _FakeDownloadService(
        storage: const StorageInfo(usedBytes: 1024, limitBytes: 1024),
      );
      await tester.pumpWidget(_wrap(
        const DownloadButton(
          type: DownloadItemType.album,
          sourceId: 'al-1',
          title: 'Album',
        ),
        service,
      ));

      await tester.tap(find.byIcon(Icons.cloud_download_outlined));
      await tester.pump();

      expect(service.enqueued, isEmpty);
      expect(
        find.text(
            'Storage limit reached. Free up space to download more.'),
        findsOneWidget,
      );
      expect(find.text('Downloads'), findsOneWidget);
    });
  });

  group('DownloadsPage', () {
    testWidgets('lists queue items with their status', (tester) async {
      final service = _FakeDownloadService(items: [
        _item(
          id: '1',
          status: DownloadStatus.completed,
          progress: 1,
          downloadedSongs: 10,
        ),
        _item(
          id: '2',
          type: DownloadItemType.album,
          sourceId: 'al-1',
          title: 'Album',
          status: DownloadStatus.downloading,
          progress: 0.3,
          downloadedSongs: 3,
        ),
        _item(
          id: '3',
          type: DownloadItemType.artist,
          sourceId: 'ar-1',
          title: 'Artist',
          status: DownloadStatus.failed,
        ),
      ], storage: const StorageInfo(usedBytes: 2048, limitBytes: 4096));

      await tester.pumpWidget(_wrap(const DownloadsPage(), service));
      await tester.pump();

      expect(find.text('Playlist'), findsOneWidget);
      expect(find.text('Album'), findsOneWidget);
      expect(find.text('Artist'), findsOneWidget);
      expect(find.text('Downloading 30% (3/10)'), findsOneWidget);
      expect(find.textContaining('Failed:'), findsOneWidget);
      expect(find.textContaining('Used:'), findsOneWidget);
    });

    testWidgets('exposes the Download All Favorites action', (tester) async {
      final service = _FakeDownloadService();
      await tester.pumpWidget(_wrap(const DownloadsPage(), service));
      await tester.pump();

      expect(find.byIcon(Icons.cloud_download_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.cloud_download_outlined));
      await tester.pump();

      expect(service.enqueued, ['favorites']);
    });

    testWidgets('can remove a queued or in-progress item', (tester) async {
      final service = _FakeDownloadService(items: [
        _item(id: '1', status: DownloadStatus.queued),
        _item(
          id: '2',
          type: DownloadItemType.album,
          sourceId: 'al-1',
          title: 'Album',
          status: DownloadStatus.downloading,
          progress: 0.4,
        ),
      ]);

      await tester.pumpWidget(_wrap(const DownloadsPage(), service));
      await tester.pump();

      expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));

      // The queued tile spins an indeterminate indicator: pump fixed frames
      // instead of waiting for the tree to settle.
      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Remove download?'), findsOneWidget);

      await tester.tap(find.text('Remove'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(service.removed, ['1']);
    });

    testWidgets('shows the limit message when the limit is reached',
        (tester) async {
      final service = _FakeDownloadService(
        storage: const StorageInfo(usedBytes: 4096, limitBytes: 4096),
      );
      await tester.pumpWidget(_wrap(const DownloadsPage(), service));
      await tester.pump();

      expect(
        find.text('Storage limit reached. Free up space to download more.'),
        findsOneWidget,
      );
    });
  });
}
