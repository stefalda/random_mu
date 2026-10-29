import 'package:flutter/material.dart';
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
    final downloadService = ref.watch(downloadServiceProvider);

    return ListenableBuilder(
      listenable: downloadService,
      builder: (context, _) {
        final item = downloadService.itemFor(type: type, sourceId: sourceId);

        switch (item?.status) {
          case null:
            return IconButton(
              icon: const Icon(Icons.cloud_download_outlined),
              tooltip: 'Download for offline',
              onPressed: () => _enqueue(context, downloadService),
            );
          case DownloadStatus.queued:
            return const _BusyIcon(tooltip: 'Queued');
          case DownloadStatus.downloading:
            return _BusyIcon(
              tooltip: 'Downloading ${((item!.progress) * 100).toInt()}%',
              progress: item.progress,
            );
          case DownloadStatus.completed:
            return IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.teal),
              tooltip: 'Downloaded - tap to remove',
              onPressed: () =>
                  _confirmDelete(context, downloadService, item!.id),
            );
          case DownloadStatus.failed:
            return IconButton(
              icon: const Icon(Icons.error_outline, color: Colors.red),
              tooltip: 'Download failed - tap to retry',
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
          content: const Text(
              'Storage limit reached. Free up space in Downloads to continue.'),
          action: SnackBarAction(
            label: 'Downloads',
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
        title: const Text('Remove download'),
        content: Text(
            'Remove "$title" and its downloaded files from this device?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
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
