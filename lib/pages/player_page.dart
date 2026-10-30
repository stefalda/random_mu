import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:random_mu/main.dart';
import 'package:random_mu/pages/header.dart';
import 'package:random_mu/pages/loading_indicator.dart';
import 'package:random_mu/pages/lyrics_page.dart';
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
          LoadingIndicator(),
          _LyricsButton(),
          IconButton(
              onPressed: () => _displayQueue(context), icon: Icon(Icons.list)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final playerService = ref.read(playerServiceProvider);
            final messenger = ScaffoldMessenger.of(context);
            ref.read(loadingProvider.notifier).setLoading(true);
            try {
              await playerService.randomByPlayingSong();
              messenger.showSnackBar(
                const SnackBar(
                  duration: Duration(milliseconds: 1200),
                  content: Text('Coda sostituita con brani simili'),
                ),
              );
            } catch (e) {
              debugPrint('Error in randomByPlayingSong: $e');
              messenger.showSnackBar(
                SnackBar(content: Text('Impossibile trovare brani simili: $e')),
              );
            } finally {
              ref.read(loadingProvider.notifier).setLoading(false);
            }
          },
          // Same glyph as the "Play Similar" action in Android Auto.
          tooltip: 'Brani simili (Play Similar)',
          child: const Icon(
            Icons.auto_awesome,
            size: 32,
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

/// Opens the lyrics of the track that is currently loaded, if any.
class _LyricsButton extends ConsumerWidget {
  const _LyricsButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioPlayer = ref.read(playerServiceProvider).audioPlayer;
    return StreamBuilder<SequenceState?>(
      stream: audioPlayer.sequenceStateStream,
      builder: (context, snapshot) {
        final mediaItem = snapshot.data?.currentSource?.tag as MediaItem?;
        return IconButton(
          tooltip: 'Testo',
          icon: const Icon(Icons.lyrics_outlined),
          onPressed: mediaItem == null
              ? null
              : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LyricsPage(
                        songId: mediaItem.id,
                        artist: mediaItem.artist,
                        title: mediaItem.title,
                      ),
                    ),
                  ),
        );
      },
    );
  }
}
