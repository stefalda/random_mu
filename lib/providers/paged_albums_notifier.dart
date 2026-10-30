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
    this.filter = '',
  });

  final List<T> items;
  final bool hasMore;
  final bool loadingMore;

  /// Local filter applied to the items loaded so far.
  final String filter;

  PagedList<T> copyWith({
    List<T>? items,
    bool? hasMore,
    bool? loadingMore,
    String? filter,
  }) {
    return PagedList<T>(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
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

  @override
  Future<PagedList<Album>> build() async {
    final albums = await ref.read(playerServiceProvider).client.getAlbumList(
          type: AlbumListType.alphabeticalByName,
          size: pageSize,
          offset: 0,
        );
    return PagedList(items: albums, hasMore: albums.length == pageSize);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.loadingMore || !current.hasMore) return;

    state = AsyncValue.data(current.copyWith(loadingMore: true));
    try {
      final page = await ref.read(playerServiceProvider).client.getAlbumList(
            type: AlbumListType.alphabeticalByName,
            size: pageSize,
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
      state = AsyncValue.data(current.copyWith(loadingMore: false, hasMore: false));
      debugPrint('PagedAlbums: cannot load more: $error');
    }
  }

  void setFilter(String value) {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(filter: value));
  }
}

final pagedAlbumsProvider =
    AsyncNotifierProvider<PagedAlbumsNotifier, PagedList<Album>>(() {
  return PagedAlbumsNotifier();
});
