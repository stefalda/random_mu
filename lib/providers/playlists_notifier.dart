import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_mu/main.dart';
import 'package:random_mu/providers/playlists_state.dart';

class PlaylistsNotifier extends AsyncNotifier<PlaylistsState> {
  PlaylistsNotifier();

  // Load the initial data
  @override
  Future<PlaylistsState> build() async {
    final serviceProvider = ref.watch(playerServiceProvider);
    final playlists = await serviceProvider.getPlaylists();
    return PlaylistsState(playlists: playlists);
  }

  void updateSearchQuery(String query) {
    if (state.value == null) return;
    state = AsyncValue.data(state.value!.copyWith(searchQuery: query));
  }
}
