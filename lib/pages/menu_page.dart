import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_mu/main.dart';
import 'package:random_mu/pages/artists/artists_page.dart';
import 'package:random_mu/pages/header.dart';
import 'package:random_mu/pages/menu_button.dart';
import 'package:random_mu/pages/player_page.dart';
import 'package:random_mu/pages/playlists/playlists_page.dart';

class MenuPage extends ConsumerWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerService = ref.read(playerServiceProvider);
    return Scaffold(
      appBar: AppBar(
        title: Header(),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MenuButton(
              icon: Icons.shuffle,
              text: 'All Random',
              onPressed: () async {
                if (context.mounted) {
                  ref.read(loadingProvider.notifier).setLoading(true);
                  unawaited(Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PlayerPage(),
                      )));
                  await playerService.randomAll();
                  ref.read(loadingProvider.notifier).setLoading(false);
                }
              },
            ),
            const SizedBox(height: 16),
            MenuButton(
              icon: Icons.queue_music,
              text: 'Random by Playlist',
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PlaylistsPage(),
                    ));
              },
            ),
            const SizedBox(height: 16),
            MenuButton(
              icon: Icons.person,
              text: 'Random by Artist',
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ArtistsPage(),
                    ));
              },
            ),
            const SizedBox(height: 16),
            MenuButton(
              icon: Icons.favorite,
              text: 'Random by Favorites',
              onPressed: () async {
                if (context.mounted) {
                  ref.read(loadingProvider.notifier).setLoading(true);
                  unawaited(Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PlayerPage(),
                      )));
                  await playerService.randomFavorites();
                  ref.read(loadingProvider.notifier).setLoading(false);
                }
              },
            ),
            /* const SizedBox(height: 16),
            MenuButton(
              icon: Icons.category,
              text: 'Random by Genre',
              onPressed: () => {},
            ),*/
          ],
        ),
      ),
    );
  }
}
