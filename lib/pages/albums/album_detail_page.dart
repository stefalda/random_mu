import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_mu/client/subsonic_models.dart';
import 'package:random_mu/main.dart';
import 'package:random_mu/pages/artwork_image.dart';
import 'package:random_mu/pages/download_button.dart';
import 'package:random_mu/pages/header.dart';
import 'package:random_mu/pages/player_page.dart';
import 'package:random_mu/pages/tracks/track_list.dart';
import 'package:random_mu/services/download_models.dart';
import 'package:random_mu/services/playback_mode.dart';

/// Album detail: cover, metadata and the track list in album order.
class AlbumDetailPage extends ConsumerStatefulWidget {
  const AlbumDetailPage({super.key, required this.albumId, this.albumName});

  final String albumId;
  final String? albumName;

  @override
  ConsumerState<AlbumDetailPage> createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends ConsumerState<AlbumDetailPage> {
  late Future<Album> _album;

  @override
  void initState() {
    super.initState();
    _album = ref.read(playerServiceProvider).client.getAlbum(widget.albumId);
  }

  Future<void> _play(List<Song> songs, {int startIndex = 0}) async {
    final playerService = ref.read(playerServiceProvider);
    ref.read(loadingProvider.notifier).setLoading(true);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PlayerPage()),
    );
    try {
      await playerService.playContainer(
        songs,
        startAtSongId: startIndex < songs.length ? songs[startIndex].id : null,
      );
    } finally {
      ref.read(loadingProvider.notifier).setLoading(false);
    }
  }

  Future<void> _playShuffled(List<Song> songs) async {
    final playerService = ref.read(playerServiceProvider);
    ref.read(loadingProvider.notifier).setLoading(true);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PlayerPage()),
    );
    try {
      await playerService.playContainer(
        songs,
        modeOverride: PlaybackMode.casuale,
      );
    } finally {
      ref.read(loadingProvider.notifier).setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Header(title: widget.albumName ?? 'Album'),
        actions: const [SizedBox(width: 8)],
      ),
      body: FutureBuilder<Album>(
        future: _album,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final album = snapshot.data;
          if (album == null || snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Impossibile caricare l\'album: ${snapshot.error}'),
              ),
            );
          }

          final songs = album.songs;
          final client = ref.read(playerServiceProvider).client;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: ArtworkImage(
                        uri: album.coverArt == null
                            ? null
                            : Uri.parse(client.getCoverArtUrl(album.coverArt)),
                        width: 110,
                        height: 110,
                        fallback: const Icon(Icons.album, size: 48),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            album.name,
                            style: Theme.of(context).textTheme.titleLarge,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (album.artist != null) Text(album.artist!),
                          const SizedBox(height: 4),
                          Text(
                            [
                              if (album.year != null) '${album.year}',
                              '${songs.length} brani',
                            ].join(' · '),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              FilledButton.icon(
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Riproduci'),
                                onPressed: songs.isEmpty
                                    ? null
                                    : () => _play(songs),
                              ),
                              IconButton(
                                tooltip: 'Casuale',
                                icon: const Icon(Icons.shuffle),
                                onPressed: songs.isEmpty
                                    ? null
                                    : () => _playShuffled(songs),
                              ),
                              IconButton(
                                tooltip: 'Accoda',
                                icon: const Icon(Icons.queue_music),
                                onPressed: songs.isEmpty
                                    ? null
                                    : () async {
                                        await ref
                                            .read(playerServiceProvider)
                                            .appendToQueue(songs);
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content:
                                                Text('Album aggiunto alla coda'),
                                          ),
                                        );
                                      },
                              ),
                              DownloadButton(
                                type: DownloadItemType.album,
                                sourceId: album.id,
                                title: album.name,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: songs.isEmpty
                    ? const Center(child: Text('Album senza brani'))
                    : TrackList(
                        songs: songs,
                        onPlay: (index) => _play(songs, startIndex: index),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
