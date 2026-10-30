import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:random_mu/utils/error_text.dart';
import 'package:random_mu/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_mu/pages/download_button.dart';
import 'package:random_mu/providers/download_provider.dart';
import 'package:random_mu/services/download_models.dart';
import 'package:random_mu/services/download_service.dart';

class DownloadsPage extends ConsumerWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.downloadsTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(context.l10n.downloadsWebUnavailable,
                textAlign: TextAlign.center),
          ),
        ),
      );
    }

    final downloadService = ref.watch(downloadServiceProvider);

    // The page is built once (it lives in an IndexedStack) while the service is
    // still restoring its queue from disk, so it must listen for updates.
    return ListenableBuilder(
      listenable: downloadService,
      builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.downloadsTitle),
        actions: [
          if (downloadService.queue.any((item) =>
              item.status == DownloadStatus.queued ||
              item.status == DownloadStatus.downloading))
            IconButton(
              icon: Icon(
                  downloadService.isPaused ? Icons.play_arrow : Icons.pause),
              tooltip: downloadService.isPaused
                  ? context.l10n.resumeDownloads
                  : context.l10n.pauseDownloads,
              onPressed: () => downloadService.isPaused
                  ? downloadService.resumeQueue()
                  : downloadService.pauseQueue(),
            ),
          DownloadButton(
            type: DownloadItemType.favorites,
            sourceId: 'favorites',
            title: context.l10n.tabFavorites,
          ),
          if (downloadService.queue.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: context.l10n.clearAll,
              onPressed: () => _confirmClearAll(context, downloadService),
            ),
        ],
      ),
      body: Column(
        children: [
          _StorageLimitCard(downloadService: downloadService),
          Expanded(
            child: downloadService.queue.isEmpty
                ? Center(child: Text(context.l10n.noDownloadsYet))
                : ListView.builder(
                    itemCount: downloadService.queue.length,
                    itemBuilder: (context, index) {
                      return _DownloadItemTile(
                        item: downloadService.queue[index],
                        downloadService: downloadService,
                      );
                    },
                  ),
          ),
        ],
      ),
      ),
    );
  }

  void _confirmClearAll(BuildContext context, DownloadService ds) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.clearAllDownloadsTitle),
        content: Text(context.l10n.clearAllDownloadsBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              ds.clearAll();
              Navigator.pop(ctx);
            },
            child: Text(context.l10n.clearAll),
          ),
        ],
      ),
    );
  }
}

class _StorageLimitCard extends ConsumerWidget {
  final DownloadService downloadService;

  const _StorageLimitCard({required this.downloadService});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = downloadService.storageInfo;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: InkWell(
          onTap: () => _showLimitDialog(context, downloadService),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.storage,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.usedOfLimit(
                    info.usedFormatted, info.limitFormatted),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: info.limitBytes != null
                    ? info.usedFraction.clamp(0.0, 1.0)
                    : 0,
                backgroundColor: Colors.grey[800],
                valueColor: AlwaysStoppedAnimation<Color>(
                  info.isLimitReached ? Colors.red : Colors.teal,
                ),
              ),
              if (info.isLimitReached)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    context.l10n.storageLimitReached,
                    style: TextStyle(color: Colors.red[300], fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLimitDialog(BuildContext context, DownloadService ds) {
    final limits = <int?>[
      null, // Unlimited
      1024 * 1024 * 1024, // 1 GB
      2 * 1024 * 1024 * 1024, // 2 GB
      5 * 1024 * 1024 * 1024, // 5 GB
      10 * 1024 * 1024 * 1024, // 10 GB
      20 * 1024 * 1024 * 1024, // 20 GB
      50 * 1024 * 1024 * 1024, // 50 GB
    ];
    final labels = <String>[
      context.l10n.unlimited,
      '1 GB',
      '2 GB',
      '5 GB',
      '10 GB',
      '20 GB',
      '50 GB',
    ];

    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(context.l10n.storageLimit),
        children: List.generate(limits.length, (i) {
          final isSelected =
              ds.storageInfo.limitBytes == limits[i];
          return SimpleDialogOption(
            onPressed: () {
              ds.setStorageLimit(limits[i]);
              Navigator.pop(ctx);
            },
            child: Row(
              children: [
                if (isSelected) const Icon(Icons.check, size: 18),
                const SizedBox(width: 8),
                Text(labels[i]),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _DownloadItemTile extends StatelessWidget {
  final DownloadItem item;
  final DownloadService downloadService;

  const _DownloadItemTile({
    required this.item,
    required this.downloadService,
  });

  IconData _iconForType(DownloadItemType type) {
    switch (type) {
      case DownloadItemType.playlist:
        return Icons.queue_music;
      case DownloadItemType.album:
        return Icons.library_music;
      case DownloadItemType.artist:
        return Icons.person;
      case DownloadItemType.favorites:
        return Icons.favorite;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(_iconForType(item.type)),
      title: Text(item.title),
      subtitle: _buildSubtitle(context),
      trailing: _buildTrailing(context),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    switch (item.status) {
      case DownloadStatus.queued:
        return Text(context.l10n.downloadQueued);
      case DownloadStatus.downloading:
        final pct = (item.progress * 100).toInt();
        return Text(context.l10n.downloadingProgress(
            '$pct', item.downloadedSongs, item.totalSongs));
      case DownloadStatus.completed:
        return Text(context.l10n.downloadedSummary(
          item.downloadedSongs,
          item.totalSongs,
        ));
      case DownloadStatus.failed:
        return Text(
          context.l10n.downloadFailedWith(describeError(
              context,
              item.errorMessage ?? context.l10n.unknownError)),
          style: const TextStyle(color: Colors.red),
        );
    }
  }

  Widget _buildTrailing(BuildContext context) {
    switch (item.status) {
      case DownloadStatus.queued:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            _deleteButton(context),
          ],
        );
      case DownloadStatus.downloading:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: item.progress.clamp(0.0, 1.0),
              ),
            ),
            _deleteButton(context),
          ],
        );
      case DownloadStatus.completed:
        return _deleteButton(context);
      case DownloadStatus.failed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: context.l10n.retry,
              onPressed: () => downloadService.retryItem(item.id),
            ),
            _deleteButton(context),
          ],
        );
    }
  }

  Widget _deleteButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.delete_outline),
      tooltip: context.l10n.removeDownload,
      onPressed: () => _confirmRemove(context),
    );
  }

  Future<void> _confirmRemove(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.removeDownloadTitle),
        content: Text(context.l10n.removeDownloadBody(item.title)),
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
      await downloadService.removeItem(item.id);
    }
  }
}
