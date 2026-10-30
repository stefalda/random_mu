import 'package:flutter/material.dart';
import 'package:random_mu/utils/error_text.dart';
import 'package:random_mu/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_mu/client/subsonic_models.dart';
import 'package:random_mu/main.dart';
import 'package:random_mu/pages/albums/album_detail_page.dart';
import 'package:random_mu/pages/artists/artist_detail_page.dart';
import 'package:random_mu/pages/artwork_image.dart';
import 'package:random_mu/pages/header.dart';
import 'package:random_mu/pages/player_page.dart';
import 'package:random_mu/pages/tracks/track_list.dart';
import 'package:random_mu/providers/starred_provider.dart';

/// Starred tracks, albums and artists.
class FavoritesTab extends ConsumerWidget {
  const FavoritesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.read(playerServiceProvider).client;

    // No Scaffold/AppBar here: this tab lives inside the library, which already
    // provides the app bar and the tab bar.
    return ref.watch(starredProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(context.l10n
                  .favoritesLoadFailed(describeError(context, error))),
            ),
          ),
          data: (starred) {
            if (starred.songs.isEmpty &&
                starred.albums.isEmpty &&
                starred.artists.isEmpty) {
              return Center(child: Text(context.l10n.emptyFavorites));
            }
            return RefreshIndicator(
            onRefresh: () async => ref.invalidate(starredProvider),
            child: ListView(
            children: [
              if (starred.songs.isNotEmpty) ...[
                _SectionHeader(context.l10n.tabSongs),
                TrackList(
                  songs: starred.songs,
                  showAlbum: true,
                  shrinkWrap: true,
                  onPlay: (index) =>
                      _play(context, ref, starred.songs, index),
                ),
              ],
              if (starred.albums.isNotEmpty) ...[
                _SectionHeader(context.l10n.tabAlbums),
                for (final album in starred.albums)
                  ListTile(
                    leading: SizedBox(
                      width: 48,
                      height: 48,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: ArtworkImage(
                          uri: album.coverArt == null
                              ? null
                              : Uri.parse(
                                  client.getCoverArtUrl(album.coverArt)),
                          width: 48,
                          height: 48,
                          fallback: const Icon(Icons.album),
                        ),
                      ),
                    ),
                    title: Text(album.name,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(album.artist ?? ''),
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
              ],
              if (starred.artists.isNotEmpty) ...[
                _SectionHeader(context.l10n.tabArtists),
                for (final artist in starred.artists)
                  ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(artist.name),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ArtistDetailPage(
                          artistId: artist.id,
                          artistName: artist.name,
                        ),
                      ),
                    ),
                  ),
              ],
            ],
            ),
          );
          },
        );
  }

  void _play(BuildContext context, WidgetRef ref, List<Song> songs, int index) {
    final playerService = ref.read(playerServiceProvider);
    ref.read(loadingProvider.notifier).setLoading(true);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PlayerPage()),
    );
    playerService
        .playContainer(songs, startAtSongId: songs[index].id)
        .whenComplete(() => ref.read(loadingProvider.notifier).setLoading(false));
  }
}

/// Genre list, tapping one opens its tracks.
class GenresTab extends ConsumerStatefulWidget {
  const GenresTab({super.key});

  @override
  ConsumerState<GenresTab> createState() => _GenresTabState();
}

class _GenresTabState extends ConsumerState<GenresTab> {
  late Future<List<Genre>> _genres =
      ref.read(playerServiceProvider).client.getGenres();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Genre>>(
        future: _genres,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final genres = snapshot.data ?? const <Genre>[];
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(context.l10n
                    .genresLoadFailed(describeError(context, snapshot.error))),
              ),
            );
          }
          if (genres.isEmpty) {
            return Center(child: Text(context.l10n.emptyGenres));
          }
          genres.sort((a, b) => a.name.compareTo(b.name));
          return RefreshIndicator(
            onRefresh: () async => setState(() {
              _genres = ref.read(playerServiceProvider).client.getGenres();
            }),
            child: ListView.separated(
            itemCount: genres.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final genre = genres[index];
              return ListTile(
                title: Text(genre.name),
                subtitle: Text(
                  context.l10n.songsAndAlbums(
                    context.l10n.tracksCount(genre.songCount),
                    context.l10n.albumsCount(genre.albumCount),
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GenreTracksPage(genre: genre.name),
                  ),
                ),
              );
            },
            ),
          );
        },
      );
  }
}

class GenreTracksPage extends ConsumerStatefulWidget {
  const GenreTracksPage({super.key, required this.genre});

  final String genre;

  @override
  ConsumerState<GenreTracksPage> createState() => _GenreTracksPageState();
}

class _GenreTracksPageState extends ConsumerState<GenreTracksPage> {
  late final Future<List<Song>> _songs = ref
      .read(playerServiceProvider)
      .client
      .getSongsByGenre(count: 500, genre: widget.genre);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Header(title: widget.genre)),
      body: FutureBuilder<List<Song>>(
        future: _songs,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final songs = snapshot.data ?? const <Song>[];
          if (songs.isEmpty) {
            return Center(child: Text(context.l10n.emptyGenre));
          }
          return TrackList(
            songs: songs,
            showAlbum: true,
            onPlay: (index) async {
              final playerService = ref.read(playerServiceProvider);
              ref.read(loadingProvider.notifier).setLoading(true);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PlayerPage()),
              );
              try {
                await playerService.playContainer(
                  songs,
                  startAtSongId: songs[index].id,
                );
              } finally {
                ref.read(loadingProvider.notifier).setLoading(false);
              }
            },
          );
        },
      ),
    );
  }
}

/// Global search across artists, albums and tracks.
class SearchTab extends ConsumerStatefulWidget {
  const SearchTab({super.key});

  @override
  ConsumerState<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends ConsumerState<SearchTab> {
  final TextEditingController _controller = TextEditingController();
  Future<SearchResult>? _results;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String query) {
    final client = ref.read(playerServiceProvider).client;
    setState(() {
      _results = query.trim().isEmpty
          ? null
          : client.search(
              query: query.trim(),
              artistCount: 20,
              albumCount: 20,
              songCount: 50,
            );
    });
  }

  @override
  Widget build(BuildContext context) {
    final client = ref.read(playerServiceProvider).client;
    return Scaffold(
      appBar: AppBar(
        title: Header(title: context.l10n.navSearch),
        actions: const [SizedBox(width: 8)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: context.l10n.searchEverythingHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          _search('');
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _search,
              onSubmitted: _search,
            ),
          ),
          Expanded(
            child: FutureBuilder<SearchResult>(
              future: _results,
              builder: (context, snapshot) {
                if (_results == null) {
                  return Center(
                    child: Text(context.l10n.searchLibraryHint),
                  );
                }
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(context.l10n
                          .searchFailed(describeError(context, snapshot.error))),
                    ),
                  );
                }
                final result = snapshot.data ??
                    SearchResult(
                        artists: const [], albums: const [], songs: const []);
                if (result.artists.isEmpty &&
                    result.albums.isEmpty &&
                    result.songs.isEmpty) {
                  return Center(child: Text(context.l10n.emptyResults));
                }

                return ListView(
                  children: [
                    if (result.artists.isNotEmpty) ...[
                      _SectionHeader(context.l10n.tabArtists),
                      for (final artist in result.artists)
                        ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(artist.name),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ArtistDetailPage(
                                artistId: artist.id,
                                artistName: artist.name,
                              ),
                            ),
                          ),
                        ),
                    ],
                    if (result.albums.isNotEmpty) ...[
                      _SectionHeader(context.l10n.tabAlbums),
                      for (final album in result.albums)
                        ListTile(
                          leading: SizedBox(
                            width: 48,
                            height: 48,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: ArtworkImage(
                                uri: album.coverArt == null
                                    ? null
                                    : Uri.parse(
                                        client.getCoverArtUrl(album.coverArt)),
                                width: 48,
                                height: 48,
                                fallback: const Icon(Icons.album),
                              ),
                            ),
                          ),
                          title: Text(album.name,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(album.artist ?? ''),
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
                    ],
                    if (result.songs.isNotEmpty) ...[
                      _SectionHeader(context.l10n.tabSongs),
                      for (final song in result.songs)
                        ListTile(
                          leading: SizedBox(
                            width: 48,
                            height: 48,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: ArtworkImage(
                                uri: song.coverArt == null
                                    ? null
                                    : Uri.parse(
                                        client.getCoverArtUrl(song.coverArt)),
                                width: 48,
                                height: 48,
                                fallback: const Icon(Icons.music_note),
                              ),
                            ),
                          ),
                          title: Text(song.title,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                            [song.artist, song.album]
                                .whereType<String>()
                                .join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _play(result.songs, song),
                          onLongPress: () => showTrackActions(
                            context,
                            ref,
                            song: song,
                            onPlayNow: () => _play(result.songs, song),
                          ),
                        ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _play(List<Song> songs, Song song) {
    final playerService = ref.read(playerServiceProvider);
    ref.read(loadingProvider.notifier).setLoading(true);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PlayerPage()),
    );
    playerService
        .playContainer(songs, startAtSongId: song.id)
        .whenComplete(() => ref.read(loadingProvider.notifier).setLoading(false));
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}
