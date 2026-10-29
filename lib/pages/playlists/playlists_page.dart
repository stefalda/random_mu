import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_mu/pages/header.dart';
import 'package:random_mu/pages/playlist_actions.dart';
import 'package:random_mu/pages/playlists/playlists_list.dart';

class PlaylistsPage extends ConsumerWidget {
  const PlaylistsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
        appBar: AppBar(title: Header(title: "Playlists"), actions: [
          SizedBox(width: 32),
        ]),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final name = await showPlaylistNameDialog(
              context,
              title: 'Nuova playlist',
              confirmLabel: 'Crea',
            );
            if (name == null || !context.mounted) return;
            await createPlaylist(context, ref, name: name);
          },
          icon: const Icon(Icons.add),
          label: const Text('Nuova playlist'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: PlaylistsList(),
        ));
  }
}
