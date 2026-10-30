import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_mu/l10n/l10n.dart';
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
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: isLandscape ? 44 : null,
          title: const Header(),
          actions: [
            // The mode control lives here: everything else follows it.
            const PlaybackModeButton(),
            IconButton(
              tooltip: context.l10n.randomCommandsTooltip,
              icon: const Icon(Icons.casino_outlined),
              onPressed: () => _showRandomSheet(context, ref),
            ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelPadding:
                EdgeInsets.symmetric(horizontal: isLandscape ? 12 : 16),
            tabs: [
              Tab(text: context.l10n.tabArtists),
              Tab(text: context.l10n.tabAlbums),
              Tab(text: context.l10n.tabSongs),
              Tab(text: context.l10n.tabFavorites),
              Tab(text: context.l10n.tabGenres),
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
                context.l10n.randomCommands,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.shuffle),
              title: Text(context.l10n.allRandom),
              onTap: () => Navigator.of(context).pop('all'),
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: Text(context.l10n.randomByPlaying),
              onTap: () => Navigator.of(context).pop('playing'),
            ),
            ListTile(
              leading: const Icon(Icons.favorite_outline),
              title: Text(context.l10n.randomByFavorites),
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
