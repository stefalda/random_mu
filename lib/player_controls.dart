import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
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
    final iconSize = isHorizontal ? 60.0 : 50.0;
    return Column(children: [
      // Progress bar and time displays
      StreamBuilder<Duration?>(
        stream: audioPlayer.positionStream,
        builder: (context, snapshot) {
          final position = snapshot.data ?? Duration.zero;
          final totalDuration = audioPlayer.duration ?? Duration.zero;
          final remaining = totalDuration - position;

          return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                children: [
                  // Progress bar
                  Slider(
                    value: position.inSeconds.toDouble(),
                    max: totalDuration.inSeconds.toDouble(),
                    onChanged: (value) {
                      audioPlayer.seek(Duration(seconds: value.toInt()));
                    },
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
