import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_mu/main.dart';
import 'package:random_mu/providers/artists_state.dart';

class ArtistsNotifier extends AsyncNotifier<ArtistsState> {
  ArtistsNotifier();

  // Load the initial data
  @override
  Future<ArtistsState> build() async {
    final serviceProvider = ref.watch(playerServiceProvider);
    final artists = await serviceProvider.getArtists();
    return ArtistsState(artists: artists);
  }

  void updateSearchQuery(String query) {
    if (state.value == null) return;
    state = AsyncValue.data(state.value!.copyWith(searchQuery: query));
  }
}
