// First, create a state class to hold both search query and artists
import 'package:random_mu/client/subsonic_models.dart';

class ArtistsState {
  final List<Artist> artists;
  final String searchQuery;

  ArtistsState({
    required this.artists,
    this.searchQuery = '',
  });

  ArtistsState copyWith({
    List<Artist>? artists,
    String? searchQuery,
  }) {
    return ArtistsState(
      artists: artists ?? this.artists,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<Artist> get filteredArtists {
    if (searchQuery.isEmpty) return artists;
    return artists
        .where((artist) =>
            artist.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }
}
