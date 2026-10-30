import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:random_mu/pages/downloads_page.dart';
import 'package:random_mu/pages/library/library_page.dart';
import 'package:random_mu/pages/mini_player_bar.dart';
import 'package:random_mu/pages/playlists/playlists_page.dart';
import 'package:random_mu/l10n/l10n.dart';
import 'package:random_mu/pages/search/search_tab.dart';

/// Top level destinations of the app.
enum LibraryDestination { libreria, playlist, downloads, cerca }

final selectedDestinationProvider =
    StateProvider<LibraryDestination>((ref) => LibraryDestination.libreria);

/// The app shell: bottom navigation between the library, playlists, downloads
/// and search. The app boots on the library.
class LibraryShell extends ConsumerWidget {
  const LibraryShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destination = ref.watch(selectedDestinationProvider);
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    final body = IndexedStack(
      index: destination.index,
      children: const [
        LibraryPage(),
        PlaylistsPage(),
        DownloadsPage(),
        SearchTab(),
      ],
    );

    // Landscape has very little vertical room: a rail on the side keeps the
    // lists usable instead of stacking app bar + tabs + search + bottom bar.
    if (isLandscape) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: destination.index,
              onDestinationSelected: (index) => ref
                  .read(selectedDestinationProvider.notifier)
                  .state = LibraryDestination.values[index],
              labelType: NavigationRailLabelType.none,
              destinations: [
                NavigationRailDestination(
                  icon: const Icon(Icons.library_music_outlined),
                  selectedIcon: const Icon(Icons.library_music),
                  label: Text(context.l10n.navLibrary),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.queue_music_outlined),
                  selectedIcon: const Icon(Icons.queue_music),
                  label: Text(context.l10n.navPlaylists),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.download_outlined),
                  selectedIcon: const Icon(Icons.download),
                  label: Text(context.l10n.navDownloads),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.search_outlined),
                  selectedIcon: const Icon(Icons.search),
                  label: Text(context.l10n.navSearch),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: body),
                  const MiniPlayerBar(),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayerBar(),
          NavigationBar(
            selectedIndex: destination.index,
            onDestinationSelected: (index) => ref
                .read(selectedDestinationProvider.notifier)
                .state = LibraryDestination.values[index],
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.library_music_outlined),
                selectedIcon: const Icon(Icons.library_music),
                label: context.l10n.navLibrary,
              ),
              NavigationDestination(
                icon: const Icon(Icons.queue_music_outlined),
                selectedIcon: const Icon(Icons.queue_music),
                label: context.l10n.navPlaylists,
              ),
              NavigationDestination(
                icon: const Icon(Icons.download_outlined),
                selectedIcon: const Icon(Icons.download),
                label: context.l10n.navDownloads,
              ),
              NavigationDestination(
                icon: const Icon(Icons.search_outlined),
                selectedIcon: const Icon(Icons.search),
                label: context.l10n.navSearch,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
