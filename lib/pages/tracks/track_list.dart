import 'package:flutter/material.dart';
import 'package:random_mu/utils/error_text.dart';
import 'package:random_mu/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_mu/client/subsonic_models.dart';
import 'package:random_mu/main.dart';
import 'package:random_mu/pages/artwork_image.dart';
import 'package:random_mu/pages/lyrics_page.dart';
import 'package:random_mu/pages/playlist_actions.dart';
import 'package:random_mu/providers/starred_provider.dart';

/// Track list shared by every browsing surface (album, artist, playlist,
/// favorites, genre, search results).
///
/// Tapping a row starts the container at that track in the current playback
/// mode; long pressing opens the track actions. Behaviour lives here once so no
/// screen can drift.
class TrackList extends ConsumerStatefulWidget {
  const TrackList({
    super.key,
    required this.songs,
    required this.onPlay,
    this.showAlbum = false,
    this.shrinkWrap = false,
    this.controller,
    this.footer,
    this.trailingBuilder,
  });

  final List<Song> songs;

  /// Starts the container at [index] in the current playback mode.
  final void Function(int index) onPlay;

  /// Shows the album name in the subtitle.
  final bool showAlbum;

  /// Wraps the list to its content, for use inside another scroll view.
  final bool shrinkWrap;

  /// Scroll controller, used by paginated lists to detect the end of the list.
  final ScrollController? controller;

  /// Extra row rendered after the last track (e.g. a loading footer).
  final Widget? footer;

  /// Optional extra widget at the end of the row (e.g. a remove button).
  final Widget Function(BuildContext context, Song song, int index)?
      trailingBuilder;

  @override
  ConsumerState<TrackList> createState() => _TrackListState();
}

class _TrackListState extends ConsumerState<TrackList> {
  /// Optimistic star state per song id, so the icon flips before the server
  /// answers and reverts if the call fails.
  final Map<String, bool> _starred = {};

  bool _isStarred(Song song) => _starred[song.id] ?? (song.starred != null);

  Future<void> _toggleStar(Song song) async {
    final playerService = ref.read(playerServiceProvider);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final target = !_isStarred(song);
    setState(() => _starred[song.id] = target);
    try {
      await playerService.setStarred(songId: song.id, starred: target);
      ref.invalidate(starredProvider);
    } catch (error) {
      if (mounted) setState(() => _starred[song.id] = !target);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            target
                ? l10n.favoriteAddFailed(describeErrorFor(l10n, error))
                : l10n.favoriteRemoveFailed(describeErrorFor(l10n, error)),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final songs = widget.songs;
    final client = ref.read(playerServiceProvider).client;

    return ListView.separated(
      shrinkWrap: widget.shrinkWrap,
      physics: widget.shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      controller: widget.controller,
      itemCount: songs.length + (widget.footer == null ? 0 : 1),
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index >= songs.length) return widget.footer;
        final song = songs[index];
        final subtitle = widget.showAlbum
            ? [song.artist, song.album].whereType<String>().join(' · ')
            : (song.artist ?? '');
        final extra = widget.trailingBuilder?.call(context, song, index);

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
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: _isStarred(song)
                    ? context.l10n.removeFromFavorites
                    : context.l10n.addToFavorites,
                icon: Icon(
                  _isStarred(song) ? Icons.favorite : Icons.favorite_border,
                  size: 20,
                  color: _isStarred(song)
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                onPressed: () => _toggleStar(song),
              ),
            ],
          ),
          onTap: () => widget.onPlay(index),
          onLongPress: () => showTrackActions(
            context,
            ref,
            song: song,
            onPlayNow: () => widget.onPlay(index),
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
  final l10n = context.l10n;

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
            title: Text(l10n.playNow),
            onTap: () => Navigator.of(context).pop('now'),
          ),
          ListTile(
            leading: const Icon(Icons.playlist_play),
            title: Text(l10n.playNext),
            onTap: () => Navigator.of(context).pop('next'),
          ),
          ListTile(
            leading: const Icon(Icons.queue_music),
            title: Text(l10n.queue),
            onTap: () => Navigator.of(context).pop('queue'),
          ),
          ListTile(
            leading: const Icon(Icons.playlist_add),
            title: Text(l10n.addToPlaylist),
            onTap: () => Navigator.of(context).pop('playlist'),
          ),
          ListTile(
            leading: const Icon(Icons.lyrics_outlined),
            title: Text(l10n.lyrics),
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
        SnackBar(content: Text(l10n.playingNext)),
      );
    case 'queue':
      await playerService.appendToQueue([song]);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.addedToQueue)),
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
