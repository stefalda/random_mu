import 'package:flutter/material.dart';
import 'package:random_mu/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:random_mu/l10n/playback_mode_l10n.dart';
import 'package:random_mu/main.dart';
import 'package:random_mu/services/player_service.dart';

class PlayerControls extends ConsumerWidget {
  const PlayerControls({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PlayerService playerService = ref.read(playerServiceProvider);
    final AudioPlayer audioPlayer = playerService.audioPlayer;
    bool isHorizontal =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final iconSize = isHorizontal ? 42.0 : 50.0;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      // Progress bar and time displays
      StreamBuilder<Duration?>(
        stream: audioPlayer.positionStream,
        builder: (context, snapshot) {
          final position = snapshot.data ?? Duration.zero;
          final totalDuration = audioPlayer.duration ?? Duration.zero;
          final remaining = totalDuration - position;
          // The duration is unknown until the source is prepared (and stays
          // unknown for a live stream): keep the slider valid and read-only.
          final knownDuration = totalDuration.inSeconds > 0;
          final sliderMax =
              knownDuration ? totalDuration.inSeconds.toDouble() : 1.0;
          final sliderValue = position.inSeconds.toDouble().clamp(0.0, sliderMax);

          return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                children: [
                  // Progress bar
                  Slider(
                    padding: isHorizontal
                        ? const EdgeInsets.symmetric(vertical: 4)
                        : null,
                    value: sliderValue,
                    max: sliderMax,
                    onChanged: knownDuration
                        ? (value) {
                            audioPlayer.seek(Duration(seconds: value.toInt()));
                          }
                        : null,
                  ),

                  // Time labels
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(position),
                          style: TextStyle(fontSize: 14),
                        ),
                        Text(
                          _formatDuration(remaining > Duration.zero
                              ? remaining
                              : Duration.zero),
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ));
        },
      ),
      // Player controls
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous Button
          IconButton(
            icon: Icon(
              Icons.skip_previous,
              size: iconSize,
            ),
            onPressed: () async {
              await playerService.previous();
            },
          ),
          // Play/Pause Button
          StreamBuilder<PlayerState>(
            stream: audioPlayer.playerStateStream,
            builder: (context, snapshot) {
              final playerState = snapshot.data;
              final processingState = playerState?.processingState;
              final playing = playerState?.playing ?? false;

              if (processingState == ProcessingState.loading ||
                  processingState == ProcessingState.buffering) {
                return CircularProgressIndicator();
              } else if (playing) {
                return IconButton(
                  icon: Icon(
                    Icons.pause,
                    size: iconSize,
                  ),
                  onPressed: playerService.pause,
                );
              } else {
                return IconButton(
                  icon: Icon(
                    Icons.play_arrow,
                    size: iconSize,
                  ),
                  onPressed: playerService.play,
                );
              }
            },
          ),
          // Next Button
          IconButton(
              icon: Icon(
                Icons.skip_next,
                size: iconSize,
              ),
              onPressed: playerService.next),
          // Playback mode toggle (sequential / shuffled)
          ListenableBuilder(
            listenable: playerService,
            builder: (context, _) {
              final shuffled = playerService.mode.isShuffle;
              return IconButton(
                tooltip: context.l10n.playbackModeTooltip(playerService.mode.localizedLabel(context)),
                icon: Icon(
                  // Same glyph pair as the Android Auto mode action.
                  shuffled ? Icons.shuffle : Icons.playlist_play,
                  size: iconSize * 0.8,
                  color: shuffled ? Theme.of(context).colorScheme.primary : null,
                ),
                onPressed: () async {
                  await playerService.toggleMode();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(
                        SnackBar(
                          duration: const Duration(milliseconds: 1200),
                          content: Text(
                            playerService.mode
                                .localizedPlaybackMessage(context),
                          ),
                        ),
                      );
                  }
                },
              );
            },
          ),
        ],
      )
    ]);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
