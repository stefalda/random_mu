import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:random_mu/pages/downloads_page.dart';
import 'package:random_mu/pages/library/library_page.dart';
import 'package:random_mu/pages/playlists/playlists_page.dart';
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

    return Scaffold(
      body: IndexedStack(
        index: destination.index,
        children: const [
          LibraryPage(),
          PlaylistsPage(),
          DownloadsPage(),
          SearchTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: destination.index,
        onDestinationSelected: (index) => ref
            .read(selectedDestinationProvider.notifier)
            .state = LibraryDestination.values[index],
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined),
            selectedIcon: Icon(Icons.library_music),
            label: 'Libreria',
          ),
          NavigationDestination(
            icon: Icon(Icons.queue_music_outlined),
            selectedIcon: Icon(Icons.queue_music),
            label: 'Playlist',
          ),
          NavigationDestination(
            icon: Icon(Icons.download_outlined),
            selectedIcon: Icon(Icons.download),
            label: 'Downloads',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Cerca',
          ),
        ],
      ),
    );
  }
}
