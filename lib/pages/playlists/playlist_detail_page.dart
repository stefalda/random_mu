import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_mu/client/subsonic_models.dart';
import 'package:random_mu/main.dart';
import 'package:random_mu/pages/artwork_image.dart';
import 'package:random_mu/pages/download_button.dart';
import 'package:random_mu/pages/header.dart';
import 'package:random_mu/pages/player_page.dart';
import 'package:random_mu/pages/playlist_actions.dart';
import 'package:random_mu/pages/tracks/track_list.dart';
import 'package:random_mu/services/download_models.dart';
import 'package:random_mu/services/playback_mode.dart';
import 'package:random_mu/widgets/playback_mode_button.dart';

/// Playlist detail: tracks in the saved order, playable, removable and
/// augmented from the playlist picker.
class PlaylistDetailPage extends ConsumerStatefulWidget {
  const PlaylistDetailPage({
    super.key,
    required this.playlistId,
    required this.playlistName,
  });

  final String playlistId;
  final String playlistName;

  @override
  ConsumerState<PlaylistDetailPage> createState() =>
      _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends ConsumerState<PlaylistDetailPage> {
  late String _name = widget.playlistName;
  late Future<List<Song>> _songs = _load();

  Future<List<Song>> _load() =>
      ref.read(playerServiceProvider).client.getPlaylistSongs(widget.playlistId);

  void _reload() => setState(() {
    _songs = _load();
  });

  Future<void> _play(List<Song> songs,
      {String? startAtSongId, bool? shuffle}) async {
    final messenger = ScaffoldMessenger.of(context);
    var tracks = songs;
    if (tracks.isEmpty) {
      try {
        tracks = await _songs;
      } catch (error) {
        messenger.showSnackBar(
          SnackBar(content: Text('Impossibile caricare la playlist: $error')),
        );
        return;
      }
    }
    if (tracks.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Questa playlist è vuota')),
      );
      return;
    }
    final playerService = ref.read(playerServiceProvider);
    ref.read(loadingProvider.notifier).setLoading(true);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PlayerPage()),
    );
    try {
      await playerService.playContainer(
        tracks,
        startAtSongId: startAtSongId,
        modeOverride: shuffle == null
            ? null
            : (shuffle ? PlaybackMode.casuale : PlaybackMode.sequenziale),
      );
      messenger.showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1200),
          content: Text('Riproduzione ${playerService.mode.label}'),
        ),
      );
    } finally {
      ref.read(loadingProvider.notifier).setLoading(false);
    }
  }

  Future<void> _remove(List<Song> songs, int index) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(playerServiceProvider)
          .removeSongsFromPlaylist(widget.playlistId, [index]);
      messenger.showSnackBar(
        SnackBar(content: Text('"${songs[index].title}" rimosso')),
      );
      _reload();
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Impossibile rimuovere il brano: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = ref.read(playerServiceProvider).client;

    return Scaffold(
      appBar: AppBar(
        title: Header(title: _name),
        actions: [
          const PlaybackModeButton(),
          IconButton(
            tooltip: 'Rinomina',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final name = await showPlaylistNameDialog(
                context,
                title: 'Rinomina playlist',
                initialValue: _name,
              );
              if (name == null || name == _name || !context.mounted) return;
              await renamePlaylist(
                context,
                ref,
                Playlist(
                  id: widget.playlistId,
                  name: _name,
                  songCount: 0,
                  duration: 0,
                  created: DateTime.now(),
                  changed: DateTime.now(),
                  allowedUsers: const [],
                ),
                name: name,
              );
              if (mounted) setState(() => _name = name);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<Song>>(
        future: _songs,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Impossibile caricare la playlist: '
                    '${snapshot.error}'),
              ),
            );
          }
          final songs = snapshot.data ?? const <Song>[];

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: ArtworkImage(
                        uri: songs.isEmpty || songs.first.coverArt == null
                            ? null
                            : Uri.parse(
                                client.getCoverArtUrl(songs.first.coverArt),
                              ),
                        width: 84,
                        height: 84,
                        fallback: const Icon(Icons.queue_music, size: 40),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _name,
                            style: Theme.of(context).textTheme.titleLarge,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${songs.length} brani',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              FilledButton.icon(
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Riproduci'),
                                onPressed: () => _play(songs),
                              ),
                              IconButton(
                                tooltip: 'Accoda',
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
                                          const SnackBar(
                                            content: Text(
                                                'Playlist aggiunta alla coda'),
                                          ),
                                        );
                                      },
                              ),
                              DownloadButton(
                                type: DownloadItemType.playlist,
                                sourceId: widget.playlistId,
                                title: _name,
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
                    ? const Center(child: Text('Playlist vuota'))
                    : TrackList(
                        songs: songs,
                        showAlbum: true,
                        onPlay: (index) =>
                            _play(songs, startAtSongId: songs[index].id),
                        trailingBuilder: (context, song, index) => IconButton(
                          tooltip: 'Rimuovi dalla playlist',
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => _remove(songs, index),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
