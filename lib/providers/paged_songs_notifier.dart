import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_mu/client/subsonic_models.dart';
import 'package:random_mu/main.dart';
import 'package:random_mu/providers/paged_albums_notifier.dart';

/// The library's songs, one page per scroll.
///
/// Without a query the order is the server's (artist, album, track on
/// Navidrome), which is stable across pages. As soon as a query is typed the
/// pages come from `search3`, so the server does the matching instead of
/// filtering only the pages already downloaded.
class PagedSongsNotifier extends AsyncNotifier<PagedList<Song>> {
  static const int pageSize = 200;

  Timer? _debounce;

  @override
  Future<PagedList<Song>> build() async {
    ref.onDispose(() => _debounce?.cancel());
    final songs = await _fetchPage(query: '', offset: 0);
    return PagedList(items: songs, hasMore: songs.length == pageSize);
  }

  Future<List<Song>> _fetchPage({
    required String query,
    required int offset,
  }) {
    final client = ref.read(playerServiceProvider).client;
    if (query.isEmpty) {
      return client.getSongsPage(offset: offset, size: pageSize);
    }
    return client
        .search(
          query: query,
          songCount: pageSize,
          songOffset: offset,
          artistCount: 0,
          albumCount: 0,
        )
        .then((result) => result.songs);
  }

  /// Starts a new page sequence for [value].
  ///
  /// Typing is debounced, so a search costs one request per pause, and the
  /// results always come from the server (never just from the loaded pages).
  void setFilter(String value) {
    final query = value.trim();
    final current = state.value;
    if (current != null && current.filter == query) return;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final previous = state.value ?? const PagedList<Song>();
      state = AsyncValue.data(
        previous.copyWith(
          items: const [],
          hasMore: true,
          loadingMore: true,
          filter: query,
        ),
      );
      try {
        final page = await _fetchPage(query: query, offset: 0);
        state = AsyncValue.data(
          PagedList(
            items: appendUnique(const <Song>[], page, (song) => song.id),
            hasMore: page.length == pageSize,
            filter: query,
          ),
        );
      } catch (error) {
        state = AsyncValue.data(
          PagedList(filter: query, hasMore: false),
        );
        debugPrint('PagedSongs: search failed: $error');
      }
    });
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.loadingMore || !current.hasMore) return;

    state = AsyncValue.data(current.copyWith(loadingMore: true));
    try {
      final page = await _fetchPage(
        query: current.filter,
        offset: current.items.length,
      );
      state = AsyncValue.data(
        current.copyWith(
          items: appendUnique(current.items, page, (song) => song.id),
          hasMore: page.length == pageSize,
          loadingMore: false,
        ),
      );
    } catch (error) {
      state =
          AsyncValue.data(current.copyWith(loadingMore: false, hasMore: false));
      debugPrint('PagedSongs: cannot load more: $error');
    }
  }

  /// Clears the query and goes back to browsing the library.
  void clearFilter() => setFilter('');
}

final pagedSongsProvider =
    AsyncNotifierProvider<PagedSongsNotifier, PagedList<Song>>(() {
  return PagedSongsNotifier();
});
