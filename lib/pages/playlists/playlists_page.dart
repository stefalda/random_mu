import 'package:flutter/material.dart';
import 'package:random_mu/pages/header.dart';
import 'package:random_mu/pages/playlists/playlists_list.dart';

class PlaylistsPage extends StatelessWidget {
  const PlaylistsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Header(title: "Playlists"),
            actions: [SizedBox(width: 32,)]),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: PlaylistsList(),
        ));
  }
}
