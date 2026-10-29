import 'package:flutter_test/flutter_test.dart';
import 'package:random_mu/services/download_models.dart';
import 'package:random_mu/services/notification_service.dart';

DownloadItem _item({
  DownloadItemType type = DownloadItemType.playlist,
  String title = 'Chill',
  String? errorMessage,
}) {
  return DownloadItem(
    id: title,
    title: title,
    type: type,
    sourceId: 'src',
    errorMessage: errorMessage,
  );
}

void main() {
  group('NotificationService messages', () {
    test('names the item in a single completion', () {
      expect(
        NotificationService.completionMessage(_item()),
        "Playlist 'Chill' downloaded",
      );
      expect(
        NotificationService.completionMessage(
            _item(type: DownloadItemType.album, title: 'Album X')),
        "Album 'Album X' downloaded",
      );
      expect(
        NotificationService.completionMessage(
            _item(type: DownloadItemType.favorites, title: 'Favorites')),
        'Favorites downloaded',
      );
    });

    test('summarises a batch', () {
      expect(NotificationService.batchMessage(1), '1 download completed');
      expect(NotificationService.batchMessage(3), '3 downloads completed');
      expect(
        NotificationService.batchBody(
            [_item(title: 'A'), _item(title: 'B')]),
        'A, B',
      );
    });

    test('names the item in a failure', () {
      expect(
        NotificationService.failureMessage(
            _item(type: DownloadItemType.artist, title: 'Band')),
        "Artist 'Band' download failed",
      );
    });
  });

  group('NotificationService batching', () {
    test('collapses completions inside the window into one summary', () async {
      final shown = <String>[];
      final service = NotificationService(
        batchWindow: const Duration(milliseconds: 1),
        showOverride: (title, body) async => shown.add(title),
      );

      service.downloadCompleted(_item(title: 'A'));
      service.downloadCompleted(_item(title: 'B'));
      service.downloadCompleted(_item(title: 'C'));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(shown, ['3 downloads completed']);
    });

    test('shows a single notification for a lone completion', () async {
      final shown = <String>[];
      final service = NotificationService(
        batchWindow: const Duration(hours: 1),
        showOverride: (title, body) async => shown.add(title),
      );

      service.downloadCompleted(_item(title: 'Chill'));
      await service.flushCompletions();

      expect(shown, ["Playlist 'Chill' downloaded"]);
    });

    test('reports failures immediately', () async {
      final shown = <String>[];
      final service = NotificationService(
        showOverride: (title, body) async => shown.add(title),
      );

      await service.downloadFailed(_item(title: 'Broken'));

      expect(shown, ["Playlist 'Broken' download failed"]);
    });
  });
}
