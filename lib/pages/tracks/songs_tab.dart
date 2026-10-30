import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_mu/main.dart';
import 'package:random_mu/pages/list_filter_field.dart';
import 'package:random_mu/pages/player_page.dart';
import 'package:random_mu/pages/tracks/track_list.dart';
import 'package:random_mu/providers/paged_songs_notifier.dart';

/// Every song of the library, loaded page by page while scrolling.
///
/// The order is the server's (artist, album, track on Navidrome): it is stable
/// across pages, while an alphabetical order would need the whole library first.
class SongsTab extends ConsumerStatefulWidget {
  const SongsTab({super.key});

  @override
  ConsumerState<SongsTab> createState() => _SongsTabState();
}

class _SongsTabState extends ConsumerState<SongsTab> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    if (_controller.position.extentAfter > 600) return;
    ref.read(pagedSongsProvider.notifier).loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final songsAsync = ref.watch(pagedSongsProvider);

    return Column(
      children: [
        ListFilterField(
          hint: 'Cerca brani…',
          onChanged: (value) =>
              ref.read(pagedSongsProvider.notifier).setFilter(value),
        ),
        Expanded(
          child: songsAsync.when(
            loading: () => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Carico i brani…'),
                ],
              ),
            ),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Impossibile caricare i brani: $error',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(pagedSongsProvider),
                      child: const Text('Riprova'),
                    ),
                  ],
                ),
              ),
            ),
            data: (state) {
              final query = state.filter.trim().toLowerCase();
              final songs = query.isEmpty
                  ? state.items
                  : state.items
                      .where((song) =>
                          song.title.toLowerCase().contains(query) ||
                          (song.artist?.toLowerCase().contains(query) ??
                              false) ||
                          (song.album?.toLowerCase().contains(query) ?? false))
                      .toList();

              if (songs.isEmpty) {
                return Center(
                  child: Text(
                    query.isEmpty
                        ? 'Nessun brano nella libreria'
                        : 'Nessun brano per "$query"',
                  ),
                );
              }

              final showFooter = state.hasMore || state.loadingMore;
              return NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification.metrics.extentAfter < 600) {
                    ref.read(pagedSongsProvider.notifier).loadMore();
                  }
                  return false;
                },
                child: TrackList(
                  songs: songs,
                  showAlbum: true,
                  controller: _controller,
                  footer: showFooter
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : null,
                  onPlay: (index) async {
                    final playerService = ref.read(playerServiceProvider);
                    ref.read(loadingProvider.notifier).setLoading(true);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PlayerPage()),
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
            },
          ),
        ),
      ],
    );
  }
}
