import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:random_mu/l10n/l10n.dart';
import 'package:random_mu/pages/artwork_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:random_mu/main.dart';
import 'package:random_mu/client/subsonic_models.dart';
import 'package:random_mu/pages/playlist_actions.dart';
import 'package:random_mu/pages/tracks/track_list.dart';

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
                      child: ArtworkImage(
                        uri: metadata.artUri,
                        width: 56,
                        height: 56,
                        fallback: const _DefaultArtwork(),
                      ),
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
              subtitle: Text(metadata.artist ?? context.l10n.unknownArtist),
              onTap: () {
                audioPlayer.seek(Duration.zero, index: index);
              },
              onLongPress: () async {
                final song = _songFromMediaItem(metadata);
                if (song == null) {
                  await showAddToPlaylistSheet(
                    context,
                    ref,
                    songIds: [metadata.id],
                    songTitle: metadata.title,
                  );
                  return;
                }
                await showTrackActions(
                  context,
                  ref,
                  song: song,
                  onPlayNow: () =>
                      audioPlayer.seek(Duration.zero, index: index),
                  onRemoveFromQueue: () =>
                      playerService.removeFromQueue(index),
                );
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

/// Rebuilds the [Song] of a queued item; queue entries carry their song JSON in
/// `extras`, so the queue can offer the same track actions as the library.
Song? _songFromMediaItem(MediaItem item) {
  final raw = item.extras?['songJson'];
  if (raw is! String) return null;
  try {
    return Song.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
}
