import 'package:flutter/material.dart';
import 'package:random_mu/utils/error_text.dart';
import 'package:random_mu/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_mu/client/subsonic_models.dart';
import 'package:random_mu/main.dart';
import 'package:random_mu/pages/artwork_image.dart';
import 'package:random_mu/pages/download_button.dart';
import 'package:random_mu/pages/header.dart';
import 'package:random_mu/pages/player_page.dart';
import 'package:random_mu/pages/tracks/track_list.dart';
import 'package:random_mu/services/download_models.dart';
import 'package:random_mu/providers/starred_provider.dart';
import 'package:random_mu/l10n/playback_mode_l10n.dart';
import 'package:random_mu/services/playback_mode.dart';
import 'package:random_mu/widgets/playback_mode_button.dart';

/// Album detail: cover, metadata and the track list in album order.
class AlbumDetailPage extends ConsumerStatefulWidget {
  const AlbumDetailPage({super.key, required this.albumId, this.albumName});

  final String albumId;
  final String? albumName;

  @override
  ConsumerState<AlbumDetailPage> createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends ConsumerState<AlbumDetailPage> {
  late Future<Album> _album;
  List<Song>? _cachedSongs;

  /// Optimistic star state for the album.
  bool? _starred;

  @override
  void initState() {
    super.initState();
    _album = ref.read(playerServiceProvider).client.getAlbum(widget.albumId);
    // Cache the tracks so the header actions work even if tapped before the
    // page has finished loading.
    _album.then((album) {
      _cachedSongs = album.songs;
      if (mounted) setState(() => _starred ??= album.starred != null);
    }).catchError((_) {});
  }

  bool get _albumStarred => _starred ?? false;

  Future<void> _toggleStarred() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final target = !_albumStarred;
    setState(() => _starred = target);
    try {
      await ref
          .read(playerServiceProvider)
          .setStarred(albumId: widget.albumId, starred: target);
      ref.invalidate(starredProvider);
      messenger.showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1200),
          content: Text(
            target
                ? l10n.albumAddedToFavorites
                : l10n.albumRemovedFromFavorites,
          ),
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _starred = !target);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
              l10n.favoritesUpdateFailed(describeError(context, error))),
        ),
      );
    }
  }

  /// Plays the album starting at [startIndex], in the current mode or in the
  /// mode given by [shuffle].
  ///
  /// The tracks are fetched on demand, so the button is never a silent no-op
  /// while the page is still loading.
  Future<void> _play(
    List<Song> songs, {
    String? startAtSongId,
    bool? shuffle,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    var tracks = songs;
    if (tracks.isEmpty) {
      try {
        tracks = _cachedSongs ?? (await _album).songs;
      } catch (error) {
        messenger.showSnackBar(
          SnackBar(
          content: Text(l10n.albumLoadFailed(describeError(context, error))),
        ),
        );
        return;
      }
    }
    if (tracks.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.emptyAlbum)),
      );
      return;
    }

    final playerService = ref.read(playerServiceProvider);
    ref.read(loadingProvider.notifier).setLoading(true);
    final mode = shuffle == null
        ? null
        : (shuffle ? PlaybackMode.casuale : PlaybackMode.sequenziale);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PlayerPage()),
    );
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1200),
        content: Text(
          (mode ?? playerService.mode).localizedPlaybackMessage(context),
        ),
      ),
    );
    try {
      await playerService.playContainer(
        tracks,
        // No explicit track (header "Riproduci") lets the mode decide: shuffled
        // playback starts on a random track instead of the first one.
        startAtSongId: startAtSongId,
        modeOverride: mode,
      );
    } finally {
      ref.read(loadingProvider.notifier).setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Header(title: widget.albumName ?? context.l10n.tabAlbums),
        actions: [
          IconButton(
            tooltip: _albumStarred
                ? context.l10n.removeFromFavorites
                : context.l10n.addToFavorites,
            icon: Icon(
              _albumStarred ? Icons.favorite : Icons.favorite_border,
            ),
            onPressed: _toggleStarred,
          ),
          const PlaybackModeButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<Album>(
        future: _album,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final album = snapshot.data;
          if (album == null || snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(context.l10n.albumLoadFailed(
                    describeError(context, snapshot.error))),
              ),
            );
          }

          final songs = album.songs;
          final client = ref.read(playerServiceProvider).client;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: ArtworkImage(
                        uri: album.coverArt == null
                            ? null
                            : Uri.parse(client.getCoverArtUrl(album.coverArt)),
                        width: 110,
                        height: 110,
                        fallback: const Icon(Icons.album, size: 48),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            album.name,
                            style: Theme.of(context).textTheme.titleLarge,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (album.artist != null) Text(album.artist!),
                          const SizedBox(height: 4),
                          Text(
                            [
                              if (album.year != null) '${album.year}',
                              context.l10n.tracksCount(songs.length),
                            ].join(' · '),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              FilledButton.icon(
                                icon: const Icon(Icons.play_arrow),
                                label: Text(context.l10n.play),
                                // Follows the title bar mode toggle.
                                onPressed: () => _play(songs),
                              ),
                              IconButton(
                                tooltip: context.l10n.queue,
                                icon: const Icon(Icons.queue_music),
                                onPressed: songs.isEmpty
                                    ? null
                                    : () async {
                                        await ref
                                            .read(playerServiceProvider)
                                            .appendToQueue(songs);
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                context.l10n.albumAddedToQueue),
                                          ),
                                        );
                                      },
                              ),
                              DownloadButton(
                                type: DownloadItemType.album,
                                sourceId: album.id,
                                title: album.name,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: songs.isEmpty
                    ? Center(child: Text(context.l10n.emptyAlbum))
                    : TrackList(
                        songs: songs,
                        onPlay: (index) =>
                            _play(songs, startAtSongId: songs[index].id),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
