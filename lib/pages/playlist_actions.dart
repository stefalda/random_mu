import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_mu/client/subsonic_models.dart';
import 'package:random_mu/main.dart';

/// Asks for a playlist name. Returns the trimmed name, or null when cancelled.
Future<String?> showPlaylistNameDialog(
  BuildContext context, {
  required String title,
  String initialValue = '',
  String confirmLabel = 'Salva',
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
  final String confirmLabel;

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
        decoration: const InputDecoration(labelText: 'Nome playlist'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.confirmLabel),
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
  final playerService = ref.read(playerServiceProvider);
  try {
    final playlist =
        await playerService.createPlaylist(name, songIds: songIds);
    ref.invalidate(playlistsProvider);
    messenger.showSnackBar(
      SnackBar(content: Text('Playlist "${playlist.name}" creata')),
    );
    return playlist;
  } catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text('Impossibile creare la playlist: $error')),
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
  final playerService = ref.read(playerServiceProvider);
  try {
    await playerService.renamePlaylist(playlist.id, name);
    ref.invalidate(playlistsProvider);
    messenger.showSnackBar(
      SnackBar(content: Text('Playlist rinominata in "$name"')),
    );
  } catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text('Impossibile rinominare la playlist: $error')),
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
      title: const Text('Eliminare la playlist?'),
      content: Text(
        '"${playlist.name}" verrà eliminata da Navidrome. I brani restano nella '
        'libreria.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Elimina'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  final playerService = ref.read(playerServiceProvider);
  try {
    await playerService.deletePlaylist(playlist.id);
    ref.invalidate(playlistsProvider);
    messenger.showSnackBar(
      SnackBar(content: Text('Playlist "${playlist.name}" eliminata')),
    );
  } catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text('Impossibile eliminare la playlist: $error')),
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
      title: 'Nuova playlist',
      confirmLabel: 'Crea',
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
      SnackBar(content: Text('Impossibile aggiungere alla playlist: $error')),
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
            subtitle: const Text('Aggiungi a…'),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  leading: const Icon(Icons.playlist_add),
                  title: const Text('Nuova playlist…'),
                  onTap: () =>
                      Navigator.of(context).pop(const _AddTarget.create()),
                ),
                ...playlistsAsync.when(
                  loading: () => const [
                    ListTile(
                      leading: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      title: Text('Caricamento playlist…'),
                    ),
                  ],
                  error: (error, _) => [
                    ListTile(
                      leading: const Icon(Icons.error_outline),
                      title: Text('Playlist non disponibili: $error'),
                    ),
                  ],
                  data: (state) => [
                    for (final playlist in state.playlists)
                      ListTile(
                        leading: const Icon(Icons.queue_music),
                        title: Text(playlist.name),
                        subtitle: Text('${playlist.songCount} brani'),
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
