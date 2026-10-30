import 'package:flutter/material.dart';
import 'package:random_mu/utils/error_text.dart';
import 'package:random_mu/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_mu/client/subsonic_models.dart';
import 'package:random_mu/main.dart';

/// Asks for a playlist name. Returns the trimmed name, or null when cancelled.
Future<String?> showPlaylistNameDialog(
  BuildContext context, {
  required String title,
  String initialValue = '',
  String? confirmLabel,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _PlaylistNameDialog(
      title: title,
      initialValue: initialValue,
      confirmLabel: confirmLabel,
    ),
  );
}

/// Owns its [TextEditingController] so it is disposed with the dialog, not
/// while the route is still animating out.
class _PlaylistNameDialog extends StatefulWidget {
  const _PlaylistNameDialog({
    required this.title,
    required this.initialValue,
    required this.confirmLabel,
  });

  final String title;
  final String initialValue;
  final String? confirmLabel;

  @override
  State<_PlaylistNameDialog> createState() => _PlaylistNameDialogState();
}

class _PlaylistNameDialogState extends State<_PlaylistNameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: context.l10n.playlistName),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.confirmLabel ?? context.l10n.save),
        ),
      ],
    );
  }
}

/// Creates a playlist with [name] and refreshes the playlist list.
Future<Playlist?> createPlaylist(
  BuildContext context,
  WidgetRef ref, {
  required String name,
  List<String> songIds = const [],
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  final playerService = ref.read(playerServiceProvider);
  try {
    final playlist =
        await playerService.createPlaylist(name, songIds: songIds);
    ref.invalidate(playlistsProvider);
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.playlistCreated(playlist.name))),
    );
    return playlist;
  } catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.playlistCreateFailed(describeError(context, error)))),
    );
    return null;
  }
}

/// Renames [playlist] on the server.
Future<void> renamePlaylist(
  BuildContext context,
  WidgetRef ref,
  Playlist playlist, {
  required String name,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  final playerService = ref.read(playerServiceProvider);
  try {
    await playerService.renamePlaylist(playlist.id, name);
    ref.invalidate(playlistsProvider);
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.playlistRenamed(name))),
    );
  } catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.playlistRenameFailed(describeError(context, error)))),
    );
  }
}

/// Deletes [playlist] from the server after a confirmation.
Future<void> deletePlaylist(
  BuildContext context,
  WidgetRef ref,
  Playlist playlist,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.l10n.deletePlaylistTitle),
      content: Text(context.l10n.deletePlaylistBody(playlist.name)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(context.l10n.delete),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  final playerService = ref.read(playerServiceProvider);
  try {
    await playerService.deletePlaylist(playlist.id);
    ref.invalidate(playlistsProvider);
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.playlistDeleted(playlist.name))),
    );
  } catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.playlistDeleteFailed(describeError(context, error)))),
    );
  }
}

/// Lets the user pick (or create) a playlist and appends [songIds] to it.
Future<void> showAddToPlaylistSheet(
  BuildContext context,
  WidgetRef ref, {
  required List<String> songIds,
  required String songTitle,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  final playerService = ref.read(playerServiceProvider);

  final selected = await showModalBottomSheet<_AddTarget>(
    context: context,
    showDragHandle: true,
    builder: (context) => _AddToPlaylistSheet(
      songIds: songIds,
      songTitle: songTitle,
    ),
  );

  if (selected == null) return;

  if (selected.createNew) {
    if (!context.mounted) return;
    final name = await showPlaylistNameDialog(
      context,
      title: context.l10n.newPlaylist,
      confirmLabel: context.l10n.create,
    );
    if (name == null) return;
    if (!context.mounted) return;
    await createPlaylist(context, ref, name: name, songIds: songIds);
    return;
  }

  try {
    await playerService.addSongsToPlaylist(selected.playlistId!, songIds);
    ref.invalidate(playlistsProvider);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          songIds.length == 1
              ? '"$songTitle" aggiunto alla playlist'
              : '${songIds.length} brani aggiunti alla playlist',
        ),
      ),
    );
  } catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.playlistAddFailed(describeError(context, error)))),
    );
  }
}

class _AddTarget {
  final String? playlistId;
  final bool createNew;

  const _AddTarget.existing(String this.playlistId) : createNew = false;
  const _AddTarget.create()
      : playlistId = null,
        createNew = true;
}

/// Watches [playlistsProvider] so the list loads on demand, even when the user
/// never opened the Playlists page.
class _AddToPlaylistSheet extends ConsumerWidget {
  const _AddToPlaylistSheet({
    required this.songIds,
    required this.songTitle,
  });

  final List<String> songIds;
  final String songTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistsProvider);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(
              songIds.length == 1 ? songTitle : '${songIds.length} brani',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Text(context.l10n.addTo),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  leading: const Icon(Icons.playlist_add),
                  title: Text(context.l10n.newPlaylistEllipsis),
                  onTap: () =>
                      Navigator.of(context).pop(const _AddTarget.create()),
                ),
                ...playlistsAsync.when(
                  loading: () => [
                    ListTile(
                      leading: const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      title: Text(context.l10n.loadingPlaylists),
                    ),
                  ],
                  error: (error, _) => [
                    ListTile(
                      leading: const Icon(Icons.error_outline),
                      title: Text(context.l10n.playlistUnavailable('$error')),
                    ),
                  ],
                  data: (state) => [
                    for (final playlist in state.playlists)
                      ListTile(
                        leading: const Icon(Icons.queue_music),
                        title: Text(playlist.name),
                        subtitle: Text(
                            context.l10n.tracksCount(playlist.songCount)),
                        onTap: () => Navigator.of(context)
                            .pop(_AddTarget.existing(playlist.id)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
