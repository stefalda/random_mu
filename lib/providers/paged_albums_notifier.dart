import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_mu/client/subsonic_models.dart';
import 'package:random_mu/main.dart';

/// A page-sized window of a large library list.
@immutable
class PagedList<T> {
  const PagedList({
    this.items = const [],
    this.hasMore = true,
    this.loadingMore = false,
    this.offline = false,
    this.filter = '',
  });

  final List<T> items;
  final bool hasMore;
  final bool loadingMore;

  /// True when the list comes from the downloads because the server is down.
  final bool offline;

  /// Local filter applied to the items loaded so far.
  final String filter;

  PagedList<T> copyWith({
    List<T>? items,
    bool? hasMore,
    bool? loadingMore,
    bool? offline,
    String? filter,
  }) {
    return PagedList<T>(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      offline: offline ?? this.offline,
      filter: filter ?? this.filter,
    );
  }
}

/// Appends [next] to [current], keeping the order and dropping duplicates.
List<T> appendUnique<T>(List<T> current, List<T> next, Object Function(T) key) {
  final seen = current.map(key).toSet();
  return [
    ...current,
    for (final item in next)
      if (seen.add(key(item))) item,
  ];
}

/// Albums of the library, one page per scroll: `getAlbumList2` is sorted by the
/// server (`alphabeticalByName`), so pages stay in order.
class PagedAlbumsNotifier extends AsyncNotifier<PagedList<Album>> {
  static const int pageSize = 60;

  Timer? _debounce;

  @override
  Future<PagedList<Album>> build() async {
    ref.onDispose(() => _debounce?.cancel());
    final albums = await _fetchPage(query: '', offset: 0);
    return PagedList(items: albums, hasMore: albums.length == pageSize);
  }

  /// Without a query the server sorts by name; with one, `search3` does the
  /// matching so the result is not limited to the pages already loaded.
  Future<List<Album>> _fetchPage({
    required String query,
    required int offset,
  }) {
    final client = ref.read(playerServiceProvider).client;
    if (query.isEmpty) {
      return client.getAlbumList(
        type: AlbumListType.alphabeticalByName,
        size: pageSize,
        offset: offset,
      );
    }
    return client
        .search(
          query: query,
          albumCount: pageSize,
          albumOffset: offset,
          artistCount: 0,
          songCount: 0,
        )
        .then((result) => result.albums);
  }

  void setFilter(String value) {
    final query = value.trim();
    final current = state.value;
    if (current != null && current.filter == query) return;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final previous = state.value ?? const PagedList<Album>();
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
            items: appendUnique(const <Album>[], page, (album) => album.id),
            hasMore: page.length == pageSize,
            filter: query,
          ),
        );
      } catch (error) {
        state = AsyncValue.data(PagedList(filter: query, hasMore: false));
        debugPrint('PagedAlbums: search failed: $error');
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
          items: appendUnique(current.items, page, (album) => album.id),
          hasMore: page.length == pageSize,
          loadingMore: false,
        ),
      );
    } catch (error) {
      state =
          AsyncValue.data(current.copyWith(loadingMore: false, hasMore: false));
      debugPrint('PagedAlbums: cannot load more: $error');
    }
  }

  void clearFilter() => setFilter('');
}

final pagedAlbumsProvider =
    AsyncNotifierProvider<PagedAlbumsNotifier, PagedList<Album>>(() {
  return PagedAlbumsNotifier();
});
