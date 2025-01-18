// First, create a state class to hold both search query and Playlists
import 'package:random_mu/client/subsonic_models.dart';

class PlaylistsState {
  final List<Playlist> playlists;
  final String searchQuery;

  PlaylistsState({
    required this.playlists,
    this.searchQuery = '',
  });

  PlaylistsState copyWith({
    List<Playlist>? playlists,
    String? searchQuery,
  }) {
    return PlaylistsState(
      playlists: playlists ?? this.playlists,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<Playlist> get filteredPlaylists {
    if (searchQuery.isEmpty) return playlists;
    return playlists
        .where((playlist) =>
            playlist.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }
}
