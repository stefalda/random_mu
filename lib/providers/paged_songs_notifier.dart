import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_mu/client/subsonic_models.dart';
import 'package:random_mu/main.dart';
import 'package:random_mu/providers/paged_albums_notifier.dart';

/// The library's songs, one page per scroll.
///
/// The server order (artist, album, track on Navidrome) is kept because it is
/// stable across pages; sorting by title would require the whole library.
class PagedSongsNotifier extends AsyncNotifier<PagedList<Song>> {
  static const int pageSize = 200;

  @override
  Future<PagedList<Song>> build() async {
    final songs = await ref
        .read(playerServiceProvider)
        .client
        .getSongsPage(offset: 0, size: pageSize);
    return PagedList(items: songs, hasMore: songs.length == pageSize);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.loadingMore || !current.hasMore) return;

    state = AsyncValue.data(current.copyWith(loadingMore: true));
    try {
      final page = await ref.read(playerServiceProvider).client.getSongsPage(
            offset: current.items.length,
            size: pageSize,
          );
      state = AsyncValue.data(
        current.copyWith(
          items: appendUnique(current.items, page, (song) => song.id),
          hasMore: page.length == pageSize,
          loadingMore: false,
        ),
      );
    } catch (error) {
      state = AsyncValue.data(current.copyWith(loadingMore: false, hasMore: false));
      debugPrint('PagedSongs: cannot load more: $error');
    }
  }

  void setFilter(String value) {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(filter: value));
  }
}

final pagedSongsProvider =
    AsyncNotifierProvider<PagedSongsNotifier, PagedList<Song>>(() {
  return PagedSongsNotifier();
});
