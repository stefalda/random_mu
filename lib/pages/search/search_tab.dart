import 'package:flutter/material.dart';
import 'package:random_mu/pages/header.dart';

/// Global library search (Artists, Albums, Tracks).
///
/// Implemented in the "Favorites, Genres and global search" work item; until
/// then it points the user at the browsable tabs.
class SearchTab extends StatelessWidget {
  const SearchTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Header(title: 'Cerca')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search, size: 56, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'La ricerca in tutta la libreria arriva con il prossimo passo.\n'
                'Nel frattempo usa Libreria e Playlist.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
