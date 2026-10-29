import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_mu/client/subsonic_models.dart';
import 'package:random_mu/main.dart';
import 'package:random_mu/pages/player_page.dart';
import 'package:random_mu/pages/tracks/track_list.dart';

/// Every song of the library, alphabetical.
///
/// The list is fetched once per app run: it is the only surface that needs the
/// whole library, and paginating it again on every visit would hammer the
/// server.
final allSongsProvider = FutureProvider<List<Song>>((ref) {
  return ref.read(playerServiceProvider).client.getAllSongs();
});

class SongsTab extends ConsumerWidget {
  const SongsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(allSongsProvider);

    return songsAsync.when(
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carico tutti i brani…'),
          ],
        ),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Impossibile caricare i brani: $error', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(allSongsProvider),
                child: const Text('Riprova'),
              ),
            ],
          ),
        ),
      ),
      data: (songs) {
        if (songs.isEmpty) {
          return const Center(child: Text('Nessun brano nella libreria'));
        }
        return TrackList(
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
        );
      },
    );
  }
}
