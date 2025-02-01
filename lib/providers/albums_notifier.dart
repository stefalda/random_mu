import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_mu/main.dart';
import 'package:random_mu/providers/albums_state.dart';

class AlbumsNotifier extends AsyncNotifier<AlbumsState> {
  AlbumsNotifier();

  // Load the initial data
  @override
  Future<AlbumsState> build() async {
    final playerService = ref.watch(playerServiceProvider);
    final albums = await playerService.getAlbums();
    return AlbumsState(albums: albums);
  }

  void updateSearchQuery(String query) {
    if (state.value == null) return;
    state = AsyncValue.data(state.value!.copyWith(searchQuery: query));
  }
}
