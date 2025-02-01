import 'package:flutter/material.dart';
import 'package:random_mu/pages/albums/albums_list.dart';
import 'package:random_mu/pages/header.dart';

class AlbumsPage extends StatelessWidget {
  const AlbumsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Header(title: "Albums"),
          actions: [
            SizedBox(
              width: 32,
            )
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: AlbumsList(),
        ));
  }
}
