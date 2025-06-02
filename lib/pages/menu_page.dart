import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_mu/main.dart';
import 'package:random_mu/pages/albums/albums_page.dart';
import 'package:random_mu/pages/artists/artists_page.dart';
import 'package:random_mu/pages/header.dart';
import 'package:random_mu/pages/menu_button.dart';
import 'package:random_mu/pages/player_page.dart';
import 'package:random_mu/pages/playlists/playlists_page.dart';
import 'package:random_mu/services/update_checker.dart';

class MenuPage extends ConsumerWidget {
  MenuPage({super.key});
  static bool _initialCheckDone = false;
  bool _firstLoad = true;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerService = ref.read(playerServiceProvider);
    final playerStateAsyncValue = ref.watch(playerStateProvider);
    final isPlaying =
        playerStateAsyncValue.hasValue && playerService.isPlaying();

    // Run on first build only
    if (!_initialCheckDone) {
      _initialCheckDone = true;
      // Small delay to ensure the app is fully rendered
      Future.delayed(const Duration(seconds: 2), () {
        if (context.mounted) {
          checkForUpdates(context);
        }
      });
    }
    // After first build if playng go to the play screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_firstLoad && playerService.isPlaying()) {
        _firstLoad = false;
        _navigateToPlayer(context);
      }
    });

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 32,
        title: Header(),
        actions: [
          if (isPlaying)
            IconButton(
                onPressed: () => _navigateToPlayer(context),
                icon: Icon(Icons.music_note))
        ],
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
                  _navigateToPlayer(context);
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
              icon: Icons.library_music,
              text: 'Random by Album',
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AlbumsPage(),
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
                  _navigateToPlayer(context);
                  await playerService.randomFavorites();
                  ref.read(loadingProvider.notifier).setLoading(false);
                }
              },
            ),
            const SizedBox(height: 16),
            MenuButton(
              icon: Icons.shuffle,
              text: 'Random by Playing',
              onPressed: !isPlaying
                  ? null
                  : () async {
                      if (context.mounted) {
                        ref.read(loadingProvider.notifier).setLoading(true);
                        _navigateToPlayer(context);
                        await playerService.randomByPlayingSong();
                        ref.read(loadingProvider.notifier).setLoading(false);
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPlayer(BuildContext context) {
    unawaited(Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PlayerPage(),
        )));
  }
}
