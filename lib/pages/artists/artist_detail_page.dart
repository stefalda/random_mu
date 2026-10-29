import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_mu/client/subsonic_models.dart';
import 'package:random_mu/main.dart';
import 'package:random_mu/pages/albums/album_detail_page.dart';
import 'package:random_mu/pages/artwork_image.dart';
import 'package:random_mu/pages/download_button.dart';
import 'package:random_mu/pages/header.dart';
import 'package:random_mu/pages/player_page.dart';
import 'package:random_mu/pages/tracks/track_list.dart';
import 'package:random_mu/services/download_models.dart';
import 'package:random_mu/services/playback_mode.dart';
import 'package:random_mu/widgets/playback_mode_button.dart';

/// Artist detail: the artist's albums plus all of their tracks in album order.
class ArtistDetailPage extends ConsumerStatefulWidget {
  const ArtistDetailPage({
    super.key,
    required this.artistId,
    required this.artistName,
  });

  final String artistId;
  final String artistName;

  @override
  ConsumerState<ArtistDetailPage> createState() => _ArtistDetailPageState();
}

class _ArtistDetailPageState extends ConsumerState<ArtistDetailPage> {
  late Future<List<Album>> _albums;

  @override
  void initState() {
    super.initState();
    _albums = ref.read(playerServiceProvider).client.getArtistAlbums(
          widget.artistId,
        );
  }

  Future<void> _playAll({bool? shuffle}) async {
    final playerService = ref.read(playerServiceProvider);
    ref.read(loadingProvider.notifier).setLoading(true);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PlayerPage()),
    );
    try {
      await playerService.playContainer(
        await playerService.fetchArtistSongs(widget.artistId),
        modeOverride: shuffle == null
            ? null
            : (shuffle ? PlaybackMode.casuale : PlaybackMode.sequenziale),
      );
    } finally {
      ref.read(loadingProvider.notifier).setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Header(title: widget.artistName),
        actions: [
          const PlaybackModeButton(),
          IconButton(
            tooltip: 'Tutti i brani',
            icon: const Icon(Icons.queue_music),
            onPressed: () => _showAllTracks(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<Album>>(
        future: _albums,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final albums = snapshot.data ?? const <Album>[];
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Impossibile caricare l\'artista: ${snapshot.error}'),
              ),
            );
          }
          if (albums.isEmpty) {
            return const Center(child: Text('Nessun album per questo artista'));
          }

          final client = ref.read(playerServiceProvider).client;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Riproduci tutto'),
                      onPressed: () => _playAll(),
                    ),
                    DownloadButton(
                      type: DownloadItemType.artist,
                      sourceId: widget.artistId,
                      title: widget.artistName,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: albums.length,
                  itemBuilder: (context, index) {
                    final album = albums[index];
                    return InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AlbumDetailPage(
                            albumId: album.id,
                            albumName: album.name,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: ArtworkImage(
                                uri: album.coverArt == null
                                    ? null
                                    : Uri.parse(
                                        client.getCoverArtUrl(album.coverArt),
                                      ),
                                fallback: const Icon(Icons.album, size: 40),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            album.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (album.year != null)
                            Text(
                              '${album.year}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAllTracks(BuildContext context) async {
    final playerService = ref.read(playerServiceProvider);
    final songs = await playerService.fetchArtistSongs(widget.artistId);
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ArtistTracksPage(
          artistName: widget.artistName,
          songs: songs,
        ),
      ),
    );
  }
}

class _ArtistTracksPage extends ConsumerWidget {
  const _ArtistTracksPage({required this.artistName, required this.songs});

  final String artistName;
  final List<Song> songs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Header(title: artistName),
        actions: [
          IconButton(
            tooltip: 'Accoda',
            icon: const Icon(Icons.queue_music),
            onPressed: () async {
              await ref.read(playerServiceProvider).appendToQueue(songs);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Brani aggiunti alla coda')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: TrackList(
        songs: songs,
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
