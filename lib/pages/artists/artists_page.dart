import 'package:flutter/material.dart';
import 'package:random_mu/pages/artists/artists_list.dart';
import 'package:random_mu/pages/header.dart';

class ArtistsPage extends StatelessWidget {
  const ArtistsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Header(title: "Artists"),
          actions: [SizedBox(width: 32,)],),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ArtistList(),
        ));
  }
}
