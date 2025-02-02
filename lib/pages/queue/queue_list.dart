import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:random_mu/main.dart';

class QueueList extends ConsumerWidget {
  const QueueList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerService = ref.read(playerServiceProvider);
    final audioPlayer = playerService.audioPlayer;

    return StreamBuilder<SequenceState?>(
      stream: audioPlayer.sequenceStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data;
        final sequence = state?.sequence ?? [];

        return ListView.builder(
          itemCount: sequence.length,
          itemBuilder: (context, index) {
            final metadata = sequence[index].tag as MediaItem;
            final isCurrentItem = state?.currentIndex == index;

            return ListTile(
              leading: SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  children: [
                    // Album artwork
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: metadata.artUri != null
                          ? Image.network(
                              metadata.artUri.toString(),
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const _DefaultArtwork();
                              },
                            )
                          : const _DefaultArtwork(),
                    ),
                    // Play indicator overlay
                    if (isCurrentItem)
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                  ],
                ),
              ),
              title: Text(
                metadata.title,
                style: TextStyle(
                  fontWeight:
                      isCurrentItem ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(metadata.artist ?? 'Unknown Artist'),
              onTap: () {
                audioPlayer.seek(Duration.zero, index: index);
              },
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Duration display
                  StreamBuilder<Duration>(
                    stream: audioPlayer.positionStream,
                    builder: (context, snapshot) {
                      final position = isCurrentItem
                          ? (snapshot.data ?? Duration.zero)
                          : Duration.zero;
                      final duration = metadata.duration ?? Duration.zero;

                      return Text(
                        isCurrentItem
                            ? '${_formatDuration(position)} / ${_formatDuration(duration)}'
                            : _formatDuration(duration),
                      );
                    },
                  ),
                  // Reorder handle
                  // ReorderableDragStartListener(
                  //   index: index,
                  //   child: const Icon(Icons.drag_handle),
                  // ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

class _DefaultArtwork extends StatelessWidget {
  const _DefaultArtwork();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      color: Colors.grey[300],
      child: Icon(
        Icons.music_note,
        color: Colors.grey[600],
      ),
    );
  }
}
