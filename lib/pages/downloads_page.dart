import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inject_x/inject_x.dart';
import 'package:random_mu/services/download_models.dart';
import 'package:random_mu/services/download_service.dart';

/// Provider for the DownloadService (shared instance from main.dart).
final downloadServiceProvider = Provider<DownloadService>((ref) {
  return inject<DownloadService>();
});

class DownloadsPage extends ConsumerWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadService = ref.watch(downloadServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        actions: [
          if (downloadService.queue.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear All',
              onPressed: () => _confirmClearAll(context, downloadService),
            ),
        ],
      ),
      body: Column(
        children: [
          _StorageLimitCard(downloadService: downloadService),
          Expanded(
            child: downloadService.queue.isEmpty
                ? const Center(child: Text('No downloads yet'))
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
    );
  }

  void _confirmClearAll(BuildContext context, DownloadService ds) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Downloads'),
        content: const Text(
            'This will remove all downloaded content and free up storage space.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ds.clearAll();
              Navigator.pop(ctx);
            },
            child: const Text('Clear All'),
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
                'Storage',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Used: ${info.usedFormatted} / Limit: ${info.limitFormatted}',
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
                    'Storage limit reached. Free up space to download more.',
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
      'Unlimited',
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
        title: const Text('Storage Limit'),
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
      subtitle: _buildSubtitle(),
      trailing: _buildTrailing(context),
    );
  }

  Widget _buildSubtitle() {
    switch (item.status) {
      case DownloadStatus.queued:
        return const Text('Queued');
      case DownloadStatus.downloading:
        final pct = (item.progress * 100).toInt();
        return Text('Downloading $pct% (${item.downloadedSongs}/${item.totalSongs})');
      case DownloadStatus.completed:
        return Text('${item.totalSongs} songs - ${item.downloadedSongs} downloaded');
      case DownloadStatus.failed:
        return Text(
          'Failed: ${item.errorMessage ?? 'Unknown error'}',
          style: const TextStyle(color: Colors.red),
        );
    }
  }

  Widget _buildTrailing(BuildContext context) {
    switch (item.status) {
      case DownloadStatus.queued:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case DownloadStatus.downloading:
        return SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            value: item.progress.clamp(0.0, 1.0),
          ),
        );
      case DownloadStatus.completed:
        return IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => downloadService.removeItem(item.id),
        );
      case DownloadStatus.failed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => downloadService.retryItem(item.id),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => downloadService.removeItem(item.id),
            ),
          ],
        );
    }
  }
}
