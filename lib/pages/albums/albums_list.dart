import 'package:flutter/material.dart';
import 'package:random_mu/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_mu/client/subsonic_models.dart';
import 'package:random_mu/pages/albums/album_detail_page.dart';
import 'package:random_mu/pages/download_button.dart';
import 'package:random_mu/pages/list_filter_field.dart';
import 'package:random_mu/pages/offline/offline_view.dart';
import 'package:random_mu/providers/paged_albums_notifier.dart';
import 'package:random_mu/services/download_models.dart';

/// Albums of the library, loaded page by page while scrolling.
class AlbumsList extends ConsumerStatefulWidget {
  const AlbumsList({super.key});

  @override
  ConsumerState<AlbumsList> createState() => _AlbumsListState();
}

class _AlbumsListState extends ConsumerState<AlbumsList> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    if (_controller.position.extentAfter > 600) return;
    ref.read(pagedAlbumsProvider.notifier).loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final albumsAsync = ref.watch(pagedAlbumsProvider);

    return Column(
      children: [
        ListFilterField(
          hint: context.l10n.searchAlbumsHint,
          onChanged: (value) =>
              ref.read(pagedAlbumsProvider.notifier).setFilter(value),
        ),
        Expanded(
          child: albumsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            // No server: show the downloaded albums instead of an error.
            error: (error, stackTrace) => OfflineContainersList(
              onRetry: () => ref.invalidate(pagedAlbumsProvider),
            ),
            data: (state) {
              final albums = state.items;

              if (albums.isEmpty && state.loadingMore) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(context.l10n.searchingAlbums),
                    ],
                  ),
                );
              }

              if (albums.isEmpty) {
                return Center(
                  child: Text(
                    state.filter.isEmpty
                        ? context.l10n.emptyAlbums
                        : context.l10n.emptyAlbumsFor(state.filter),
                  ),
                );
              }

              // One extra row for the loading footer, only while loading.
              final showFooter = state.loadingMore;
              return ListView.builder(
                controller: _controller,
                itemCount: albums.length + (showFooter ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= albums.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return _AlbumRow(album: albums[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AlbumRow extends StatelessWidget {
  const _AlbumRow({required this.album});

  final Album album;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: album.coverArt == null || album.coverArt!.isEmpty
              ? const CircleAvatar(child: Icon(Icons.library_music))
              : Image.network(
                  album.coverArt!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const CircleAvatar(child: Icon(Icons.library_music)),
                ),
        ),
        title: Text(
          album.name,
          style: Theme.of(context).textTheme.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: album.artist == null
            ? null
            : Text(
                album.artist!,
                style: Theme.of(context).textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        trailing: DownloadButton(
          type: DownloadItemType.album,
          sourceId: album.id,
          title: album.name,
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AlbumDetailPage(
              albumId: album.id,
              albumName: album.name,
            ),
          ),
        ),
      ),
    );
  }
}
