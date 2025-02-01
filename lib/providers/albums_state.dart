// First, create a state class to hold both search query and albums
import 'package:random_mu/client/subsonic_models.dart';

class AlbumsState {
  final List<Album> albums;
  final String searchQuery;

  AlbumsState({
    required this.albums,
    this.searchQuery = '',
  });

  AlbumsState copyWith({
    List<Album>? albums,
    String? searchQuery,
  }) {
    return AlbumsState(
      albums: albums ?? this.albums,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<Album> get filteredAlbums {
    if (searchQuery.isEmpty) return albums;
    return albums
        .where((album) =>
            album.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            (album.artist?.toLowerCase().contains(searchQuery.toLowerCase()) ??
                false))
        .toList();
  }
}
