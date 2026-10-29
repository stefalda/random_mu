import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_mu/main.dart';
import 'package:random_mu/pages/albums/albums_list.dart';
import 'package:random_mu/pages/artists/artists_list.dart';
import 'package:random_mu/pages/header.dart';
import 'package:random_mu/pages/player_page.dart';
import 'package:random_mu/pages/search/search_tab.dart';
import 'package:random_mu/pages/tracks/songs_tab.dart';
import 'package:random_mu/widgets/playback_mode_button.dart';

/// The library: rows of content, alphabetical, with a per-tab filter.
class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Header(),
          actions: [
            // The mode control lives here: everything else follows it.
            const PlaybackModeButton(),
            IconButton(
              tooltip: 'Comandi casuali (una tantum)',
              icon: const Icon(Icons.casino_outlined),
              onPressed: () => _showRandomSheet(context, ref),
            ),
            const SizedBox(width: 8),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Artisti'),
              Tab(text: 'Album'),
              Tab(text: 'Brani'),
              Tab(text: 'Preferiti'),
              Tab(text: 'Generi'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ArtistList(),
            AlbumsList(),
            SongsTab(),
            FavoritesTab(),
            GenresTab(),
          ],
        ),
      ),
    );
  }

  /// One-shot random commands. They never change the persisted playback mode.
  Future<void> _showRandomSheet(BuildContext context, WidgetRef ref) async {
    final playerService = ref.read(playerServiceProvider);
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                'Casuale',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: const Text('Una tantum: non cambia la modalità'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.shuffle),
              title: const Text('All Random'),
              onTap: () => Navigator.of(context).pop('all'),
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('Random by Playing'),
              onTap: () => Navigator.of(context).pop('playing'),
            ),
            ListTile(
              leading: const Icon(Icons.favorite_outline),
              title: const Text('Random by Favorites'),
              onTap: () => Navigator.of(context).pop('favorites'),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) return;

    ref.read(loadingProvider.notifier).setLoading(true);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PlayerPage()),
    );
    try {
      switch (choice) {
        case 'all':
          await playerService.randomAll();
        case 'playing':
          await playerService.randomByPlayingSong();
        case 'favorites':
          await playerService.randomFavorites();
      }
    } finally {
      ref.read(loadingProvider.notifier).setLoading(false);
    }
  }
}
