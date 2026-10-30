import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:random_mu/client/audio_player_handler.dart';
import 'package:random_mu/l10n/l10n.dart';
import 'package:random_mu/main.dart';
import 'package:random_mu/pages/artwork_image.dart';
import 'package:random_mu/pages/player_page.dart';

/// The "now playing" bar above the navigation.
///
/// Without it the app opened on the library with no way to reach the player
/// while something was playing: the only entries were an album or a playlist.
class MiniPlayerBar extends ConsumerWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerService = ref.read(playerServiceProvider);
    final audioPlayer = playerService.audioPlayer;
    final handler = AudioPlayerHandler.instance;

    // The handler keeps the metadata even when the source is not loaded (offline
    // restore), so it is the reliable source for the bar.
    return StreamBuilder<MediaItem?>(
      stream: handler?.mediaItem,
      builder: (context, mediaSnapshot) {
        final mediaItem = mediaSnapshot.data ?? handler?.mediaItem.value;
        if (mediaItem == null) return const SizedBox.shrink();

        return Material(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PlayerPage()),
            ),
            child: SizedBox(
              height: 60,
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: ArtworkImage(
                      uri: mediaItem.artUri,
                      width: 44,
                      height: 44,
                      fallback: const Icon(Icons.music_note),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mediaItem.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (mediaItem.artist != null)
                          Text(
                            mediaItem.artist!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  StreamBuilder<PlayerState>(
                    stream: audioPlayer.playerStateStream,
                    builder: (context, stateSnapshot) {
                      final state = stateSnapshot.data;
                      final processing = state?.processingState;
                      if (processing == ProcessingState.loading ||
                          processing == ProcessingState.buffering) {
                        return const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      final playing = state?.playing ?? false;
                      return IconButton(
                        tooltip: playing ? 'Pause' : 'Play',
                        icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                        onPressed: () =>
                            playing ? playerService.pause() : playerService.play(),
                      );
                    },
                  ),
                  IconButton(
                    tooltip: context.l10n.playNext,
                    icon: const Icon(Icons.skip_next),
                    onPressed: () => playerService.next(),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
