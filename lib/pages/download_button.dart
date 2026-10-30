import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:random_mu/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_mu/pages/downloads_page.dart';
import 'package:random_mu/providers/download_provider.dart';
import 'package:random_mu/services/download_models.dart';
import 'package:random_mu/services/download_service.dart';

/// Download control for a single library item (playlist, album, artist, favorites).
///
/// Shows the queue state of the item and starts/removes the download on tap.
class DownloadButton extends ConsumerWidget {
  final DownloadItemType type;
  final String sourceId;
  final String title;

  const DownloadButton({
    super.key,
    required this.type,
    required this.sourceId,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Offline downloads write files through path_provider: not available on web.
    if (kIsWeb) return const SizedBox.shrink();

    final downloadService = ref.watch(downloadServiceProvider);

    return ListenableBuilder(
      listenable: downloadService,
      builder: (context, _) {
        final item = downloadService.itemFor(type: type, sourceId: sourceId);

        switch (item?.status) {
          case null:
            return IconButton(
              icon: const Icon(Icons.cloud_download_outlined),
              tooltip: context.l10n.downloadForOffline,
              onPressed: () => _enqueue(context, downloadService),
            );
          case DownloadStatus.queued:
            return _BusyIcon(tooltip: context.l10n.downloadQueued);
          case DownloadStatus.downloading:
            return _BusyIcon(
              tooltip: context.l10n
                  .downloadingPercent('${(item!.progress * 100).toInt()}'),
              progress: item.progress,
            );
          case DownloadStatus.completed:
            return IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.teal),
              tooltip: context.l10n.downloadedTapToRemove,
              onPressed: () =>
                  _confirmDelete(context, downloadService, item!.id),
            );
          case DownloadStatus.failed:
            return IconButton(
              icon: const Icon(Icons.error_outline, color: Colors.red),
              tooltip: context.l10n.downloadFailedTapToRetry,
              onPressed: () => downloadService.retryItem(item!.id),
            );
        }
      },
    );
  }

  Future<void> _enqueue(
      BuildContext context, DownloadService downloadService) async {
    if (downloadService.storageInfo.isLimitReached) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.storageLimitReached),
          action: SnackBarAction(
            label: context.l10n.downloadsTitle,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DownloadsPage()),
            ),
          ),
        ),
      );
      return;
    }

    switch (type) {
      case DownloadItemType.playlist:
        await downloadService.enqueuePlaylist(sourceId, title);
        break;
      case DownloadItemType.album:
        await downloadService.enqueueAlbum(sourceId, title);
        break;
      case DownloadItemType.artist:
        await downloadService.enqueueArtist(sourceId, title);
        break;
      case DownloadItemType.favorites:
        await downloadService.enqueueFavorites();
        break;
    }
  }

  Future<void> _confirmDelete(BuildContext context,
      DownloadService downloadService, String itemId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.removeDownloadTitle),
        content: Text(context.l10n.removeDownloadBody(title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.remove),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await downloadService.removeItem(itemId);
    }
  }
}

class _BusyIcon extends StatelessWidget {
  final String tooltip;
  final double? progress;

  const _BusyIcon({required this.tooltip, this.progress});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: progress,
            ),
          ),
        ),
      ),
    );
  }
}
