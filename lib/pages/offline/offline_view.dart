import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_mu/client/subsonic_models.dart';
import 'package:random_mu/l10n/l10n.dart';
import 'package:random_mu/main.dart';
import 'package:random_mu/pages/header.dart';
import 'package:random_mu/pages/player_page.dart';
import 'package:random_mu/pages/tracks/track_list.dart';
import 'package:random_mu/services/download_models.dart';
import 'package:random_mu/services/offline_library.dart';

/// Shows that the list comes from the downloads because the server is not
/// reachable, with a retry that rebuilds the network-backed provider.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        child: Row(
          children: [
            const Icon(Icons.cloud_off, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: theme.textTheme.bodySmall),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                child: Text(context.l10n.retry),
              ),
          ],
        ),
      ),
    );
  }
}

/// Downloaded containers (albums, playlists, artists, favorites) as the offline
/// fallback for a server-backed list.
class OfflineContainersList extends ConsumerWidget {
  const OfflineContainersList({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(offlineLibraryProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('${context.l10n.noDownloadsYet}\n$error',
                  textAlign: TextAlign.center),
            ),
          ),
          data: (library) {
            if (library.containers.isEmpty) {
              return Column(
                children: [
                  OfflineBanner(
                    message: context.l10n.offlineEmpty,
                    onRetry: onRetry,
                  ),
                  Expanded(
                    child: Center(child: Text(context.l10n.noDownloadsYet)),
                  ),
                ],
              );
            }
            return Column(
              children: [
                OfflineBanner(
                  message: context.l10n.offlineShowingDownloads,
                  onRetry: onRetry,
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: library.containers.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final container = library.containers[index];
                      return ListTile(
                        leading: Icon(_iconFor(container.item.type)),
                        title: Text(container.item.title),
                        subtitle: Text(
                          context.l10n.tracksCount(container.songs.length),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OfflineContainerPage(
                              container: container,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
  }

  static IconData _iconFor(DownloadItemType type) {
    switch (type) {
      case DownloadItemType.playlist:
        return Icons.queue_music;
      case DownloadItemType.album:
        return Icons.album;
      case DownloadItemType.artist:
        return Icons.person;
      case DownloadItemType.favorites:
        return Icons.favorite_outline;
    }
  }
}

/// The downloaded songs of one container, playable with no connection.
class OfflineContainerPage extends ConsumerWidget {
  const OfflineContainerPage({super.key, required this.container});

  final OfflineContainer container;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songs = container.songs;
    return Scaffold(
      appBar: AppBar(title: Header(title: container.item.title)),
      body: songs.isEmpty
          ? Center(child: Text(context.l10n.emptyPlaylist))
          : TrackList(
              songs: songs,
              showAlbum: true,
              onPlay: (index) async {
                final playerService = ref.read(playerServiceProvider);
                ref.read(loadingProvider.notifier).setLoading(true);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PlayerPage()),
                );
                try {
                  await playerService.playContainer(
                    songs,
                    startAtSongId: songs[index].id,
                  );
                } finally {
                  ref.read(loadingProvider.notifier).setLoading(false);
                }
              },
            ),
    );
  }
}

/// All downloaded songs, alphabetical.
class OfflineSongsView extends ConsumerWidget {
  const OfflineSongsView({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(offlineLibraryProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('$error')),
          data: (library) {
            final songs = library.songs;
            return Column(
              children: [
                OfflineBanner(
                  message: songs.isEmpty
                      ? context.l10n.offlineEmpty
                      : context.l10n.offlineShowingDownloads,
                  onRetry: onRetry,
                ),
                Expanded(
                  child: songs.isEmpty
                      ? Center(child: Text(context.l10n.noDownloadsYet))
                      : TrackList(
                          songs: songs,
                          showAlbum: true,
                          onPlay: (index) => _play(context, ref, songs, index),
                        ),
                ),
              ],
            );
          },
        );
  }

  void _play(
      BuildContext context, WidgetRef ref, List<Song> songs, int index) async {
    final playerService = ref.read(playerServiceProvider);
    ref.read(loadingProvider.notifier).setLoading(true);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PlayerPage()),
    );
    try {
      await playerService.playContainer(songs, startAtSongId: songs[index].id);
    } finally {
      ref.read(loadingProvider.notifier).setLoading(false);
    }
  }
}
