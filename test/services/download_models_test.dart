import 'package:flutter_test/flutter_test.dart';
import 'package:random_mu/services/download_models.dart';

void main() {
  group('DownloadItem serialization', () {
    test('round-trips through JSON', () {
      const item = DownloadItem(
        id: '1',
        title: 'Chill',
        type: DownloadItemType.album,
        sourceId: 'al-9',
        status: DownloadStatus.downloading,
        progress: 0.25,
        totalSongs: 8,
        downloadedSongs: 2,
        errorMessage: 'oops',
      );

      final restored = DownloadItem.fromJson(item.toJson());

      expect(restored.id, item.id);
      expect(restored.title, item.title);
      expect(restored.type, item.type);
      expect(restored.sourceId, item.sourceId);
      expect(restored.status, item.status);
      expect(restored.progress, item.progress);
      expect(restored.totalSongs, item.totalSongs);
      expect(restored.downloadedSongs, item.downloadedSongs);
      expect(restored.errorMessage, item.errorMessage);
    });

    test('copyWith can clear the error message', () {
      const item = DownloadItem(
        id: '1',
        title: 'Chill',
        type: DownloadItemType.playlist,
        sourceId: 'pl-1',
        status: DownloadStatus.failed,
        errorMessage: 'oops',
      );

      final retried = item.copyWith(
        status: DownloadStatus.queued,
        progress: 0,
        clearError: true,
      );

      expect(retried.status, DownloadStatus.queued);
      expect(retried.errorMessage, isNull);
      expect(item.errorMessage, 'oops');
    });
  });

  group('StorageInfo', () {
    test('reports unlimited storage', () {
      const info = StorageInfo(usedBytes: 1024);
      expect(info.isUnlimited, isTrue);
      expect(info.isLimitReached, isFalse);
      expect(info.usedFraction, 0);
      expect(info.limitFormatted, 'Unlimited');
    });

    test('detects a reached limit', () {
      const info = StorageInfo(usedBytes: 2048, limitBytes: 2048);
      expect(info.isLimitReached, isTrue);
      expect(info.usedFraction, 1.0);
      expect(info.usedFormatted, '2.0 KB');
      expect(info.limitFormatted, '2.0 KB');
    });

    test('keeps the limit when only usage changes', () {
      const info = StorageInfo(usedBytes: 10, limitBytes: 100);
      final updated = info.copyWith(usedBytes: 50);
      expect(updated.limitBytes, 100);
      expect(updated.usedFraction, 0.5);
    });

    test('formats byte sizes', () {
      expect(const StorageInfo(usedBytes: 512).usedFormatted, '512 B');
      expect(const StorageInfo(usedBytes: 1536).usedFormatted, '1.5 KB');
      expect(
        const StorageInfo(usedBytes: 3 * 1024 * 1024).usedFormatted,
        '3.0 MB',
      );
      expect(
        const StorageInfo(usedBytes: 5 * 1024 * 1024 * 1024).usedFormatted,
        '5.0 GB',
      );
    });
  });
}
