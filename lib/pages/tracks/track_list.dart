import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_mu/client/subsonic_models.dart';
import 'package:random_mu/main.dart';
import 'package:random_mu/pages/artwork_image.dart';
import 'package:random_mu/pages/lyrics_page.dart';
import 'package:random_mu/pages/playlist_actions.dart';

/// Track list shared by every browsing surface (album, artist, playlist,
/// favorites, genre, search results).
///
/// Tapping a row starts the container at that track in the current playback
/// mode; long pressing opens the track actions. Behaviour lives here once so no
/// screen can drift.
class TrackList extends ConsumerWidget {
  const TrackList({
    super.key,
    required this.songs,
    required this.onPlay,
    this.showAlbum = false,
    this.shrinkWrap = false,
    this.trailingBuilder,
  });

  final List<Song> songs;

  /// Starts the container at [index] in the current playback mode.
  final void Function(int index) onPlay;

  /// Shows the album name in the subtitle.
  final bool showAlbum;

  /// Wraps the list to its content, for use inside another scroll view.
  final bool shrinkWrap;

  /// Optional extra widget at the end of the row (e.g. a remove button).
  final Widget Function(BuildContext context, Song song, int index)?
      trailingBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.read(playerServiceProvider).client;

    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      itemCount: songs.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final song = songs[index];
        final subtitle = showAlbum
            ? [song.artist, song.album].whereType<String>().join(' · ')
            : (song.artist ?? '');
        final extra = trailingBuilder?.call(context, song, index);

        return ListTile(
          leading: SizedBox(
            width: 48,
            height: 48,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: ArtworkImage(
                uri: song.coverArt == null
                    ? null
                    : Uri.parse(client.getCoverArtUrl(song.coverArt)),
                width: 48,
                height: 48,
                fallback: const Icon(Icons.music_note),
              ),
            ),
          ),
          title: Text(
            song.title.trim(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: subtitle.isEmpty
              ? null
              : Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (extra != null) extra,
              Text(_formatDuration(song.duration)),
            ],
          ),
          onTap: () => onPlay(index),
          onLongPress: () => showTrackActions(
            context,
            ref,
            song: song,
            onPlayNow: () => onPlay(index),
          ),
        );
      },
    );
  }

  static String _formatDuration(int? seconds) {
    if (seconds == null) return '';
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    return '$minutes:${rest.toString().padLeft(2, '0')}';
  }
}

/// The track action sheet: play now / play next / queue / add to playlist /
/// lyrics. Used by every [TrackList].
Future<void> showTrackActions(
  BuildContext context,
  WidgetRef ref, {
  required Song song,
  required VoidCallback onPlayNow,
  List<Song> Function()? containerProvider,
}) async {
  final playerService = ref.read(playerServiceProvider);
  final messenger = ScaffoldMessenger.of(context);

  final action = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(
              song.title,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              [song.artist, song.album].whereType<String>().join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.play_arrow),
            title: const Text('Riproduci ora'),
            onTap: () => Navigator.of(context).pop('now'),
          ),
          ListTile(
            leading: const Icon(Icons.playlist_play),
            title: const Text('Riproduci dopo'),
            onTap: () => Navigator.of(context).pop('next'),
          ),
          ListTile(
            leading: const Icon(Icons.queue_music),
            title: const Text('Accoda'),
            onTap: () => Navigator.of(context).pop('queue'),
          ),
          ListTile(
            leading: const Icon(Icons.playlist_add),
            title: const Text('Aggiungi a playlist…'),
            onTap: () => Navigator.of(context).pop('playlist'),
          ),
          ListTile(
            leading: const Icon(Icons.lyrics_outlined),
            title: const Text('Testo'),
            onTap: () => Navigator.of(context).pop('lyrics'),
          ),
        ],
      ),
    ),
  );

  if (action == null) return;

  switch (action) {
    case 'now':
      onPlayNow();
    case 'next':
      await playerService.playNext([song]);
      messenger.showSnackBar(
        const SnackBar(content: Text('In riproduzione dopo questo brano')),
      );
    case 'queue':
      await playerService.appendToQueue([song]);
      messenger.showSnackBar(
        const SnackBar(content: Text('Aggiunto alla coda')),
      );
    case 'playlist':
      if (!context.mounted) return;
      await showAddToPlaylistSheet(
        context,
        ref,
        songIds: [song.id],
        songTitle: song.title,
      );
    case 'lyrics':
      if (!context.mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LyricsPage(
            songId: song.id,
            artist: song.artist,
            title: song.title,
          ),
        ),
      );
  }
}
