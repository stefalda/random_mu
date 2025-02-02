import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_mu/main.dart';
import 'package:random_mu/pages/header.dart';
import 'package:random_mu/pages/loading_indicator.dart';
import 'package:random_mu/pages/music_player.dart';
import 'package:random_mu/pages/queue/queue_page.dart';

class PlayerPage extends ConsumerWidget {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Header(),
        actions: [
          IconButton(
              onPressed: () => _displayQueue(context), icon: Icon(Icons.list)),
          LoadingIndicator()
        ],
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final playerService = ref.read(playerServiceProvider);
            ref.read(loadingProvider.notifier).setLoading(true);
            try {
              await playerService.randomByPlayingSong();
            } catch (e) {
              // Handle the error appropriately (e.g., show a snackbar)
              debugPrint('Error in randomByPlayingSong: $e');
            } finally {
              ref.read(loadingProvider.notifier).setLoading(false);
              debugPrint('Loading set to false');
            }
          },
          tooltip: 'Randomize',
          child: const Icon(
            Icons.refresh,
            size: 40,
          )),
      body: SafeArea(child: Center(child: MusicPlayerScreen())),
    );
  }

  void _displayQueue(BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const QueuePage(),
        ));
  }
}
