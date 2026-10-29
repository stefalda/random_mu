import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_mu/client/subsonic_models.dart';
import 'package:random_mu/main.dart';
import 'package:random_mu/pages/albums/album_detail_page.dart';
import 'package:random_mu/pages/artists/artist_detail_page.dart';
import 'package:random_mu/pages/artwork_image.dart';
import 'package:random_mu/pages/header.dart';
import 'package:random_mu/pages/player_page.dart';
import 'package:random_mu/pages/tracks/track_list.dart';

/// Starred tracks, albums and artists.
class FavoritesTab extends ConsumerStatefulWidget {
  const FavoritesTab({super.key});

  @override
  ConsumerState<FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends ConsumerState<FavoritesTab> {
  late Future<SearchResult> _starred = _load();

  Future<SearchResult> _load() =>
      ref.read(playerServiceProvider).client.getStarred();

  void _reload() => setState(() {
    _starred = _load();
  });

  @override
  Widget build(BuildContext context) {
    final client = ref.read(playerServiceProvider).client;

    return Scaffold(
      appBar: AppBar(
        title: const Header(title: 'Preferiti'),
        actions: [
          IconButton(
            tooltip: 'Ricarica',
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<SearchResult>(
        future: _starred,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Impossibile caricare i preferiti: '
                    '${snapshot.error}'),
              ),
            );
          }
          final starred = snapshot.data ??
              SearchResult(artists: const [], albums: const [], songs: const []);
          if (starred.songs.isEmpty &&
              starred.albums.isEmpty &&
              starred.artists.isEmpty) {
            return const Center(child: Text('Nessun preferito'));
          }

          return ListView(
            children: [
              if (starred.songs.isNotEmpty) ...[
                const _SectionHeader('Brani'),
                SizedBox(
                  height: 320,
                  child: TrackList(songs: starred.songs, showAlbum: true,
                      onPlay: (index) => _play(starred.songs, index)),
                ),
              ],
              if (starred.albums.isNotEmpty) ...[
                const _SectionHeader('Album'),
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
                const _SectionHeader('Artisti'),
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
          );
        },
      ),
    );
  }

  void _play(List<Song> songs, int index) {
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
  late final Future<List<Genre>> _genres =
      ref.read(playerServiceProvider).client.getGenres();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Header(title: 'Generi')),
      body: FutureBuilder<List<Genre>>(
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
                child: Text('Impossibile caricare i generi: ${snapshot.error}'),
              ),
            );
          }
          if (genres.isEmpty) {
            return const Center(child: Text('Nessun genere'));
          }
          genres.sort((a, b) => a.name.compareTo(b.name));
          return ListView.separated(
            itemCount: genres.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final genre = genres[index];
              return ListTile(
                title: Text(genre.name),
                subtitle: Text('${genre.songCount} brani · '
                    '${genre.albumCount} album'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GenreTracksPage(genre: genre.name),
                  ),
                ),
              );
            },
          );
        },
      ),
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
            return const Center(child: Text('Nessun brano per questo genere'));
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
        title: const Header(title: 'Cerca'),
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
                hintText: 'Cerca artisti, album, brani…',
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
                  return const Center(
                    child: Text('Cerca nella libreria'),
                  );
                }
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text('Ricerca fallita: ${snapshot.error}'),
                    ),
                  );
                }
                final result = snapshot.data ??
                    SearchResult(
                        artists: const [], albums: const [], songs: const []);
                if (result.artists.isEmpty &&
                    result.albums.isEmpty &&
                    result.songs.isEmpty) {
                  return const Center(child: Text('Nessun risultato'));
                }

                return ListView(
                  children: [
                    if (result.artists.isNotEmpty) ...[
                      const _SectionHeader('Artisti'),
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
                      const _SectionHeader('Album'),
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
                      const _SectionHeader('Brani'),
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
