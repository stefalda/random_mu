// Create the ConsumerWidget
import 'package:flutter/material.dart';
import 'package:random_mu/utils/error_text.dart';
import 'package:random_mu/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_mu/main.dart';
import 'package:random_mu/pages/download_button.dart';
import 'package:random_mu/pages/list_filter_field.dart';
import 'package:random_mu/pages/playlist_actions.dart';
import 'package:random_mu/pages/playlists/playlist_detail_page.dart';
import 'package:random_mu/services/download_models.dart';

class PlaylistsList extends ConsumerWidget {
  const PlaylistsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistAsync = ref.watch(playlistsProvider);

    return Column(
      children: [
        ListFilterField(
          hint: context.l10n.searchPlaylistsHint,
          compact: MediaQuery.orientationOf(context) ==
              Orientation.landscape,
          onChanged: (value) =>
              ref.read(playlistsProvider.notifier).updateSearchQuery(value),
        ),
        Expanded(
          child: playlistAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stackTrace) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.playlistsLoadFailed(
                      describeError(context, error)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(artistsProvider),
                    child: Text(context.l10n.retry),
                  ),
                ],
              ),
            ),
            data: (state) {
              final filteredPlaylists = state.filteredPlaylists;

              if (filteredPlaylists.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.search_off,
                        size: 60,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.searchQuery.isEmpty
                            ? context.l10n.emptyPlaylists
                            : context.l10n.playlistsEmptyFor(
                                state.searchQuery),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: filteredPlaylists.length,
                itemBuilder: (context, index) {
                  final playlist = filteredPlaylists[index];

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: ListTile(
                        leading: ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: const CircleAvatar(
                              radius: 25,
                              child: Icon(Icons.queue_music),
                            )
                            /*
                          Image.network(
                            artist.artistImageUrl!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const CircleAvatar(
                                radius: 25,
                                child: Icon(Icons.person),
                              );
                            },
                          ),*/
                            ),
                        title: Text(
                          playlist.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DownloadButton(
                              type: DownloadItemType.playlist,
                              sourceId: playlist.id,
                              title: playlist.name,
                            ),
                            PopupMenuButton<String>(
                              tooltip: context.l10n.managePlaylist,
                              onSelected: (value) async {
                                if (value == 'rename') {
                                  final name = await showPlaylistNameDialog(
                                    context,
                                    title: context.l10n.renamePlaylist,
                                    initialValue: playlist.name,
                                  );
                                  if (name == null || !context.mounted) return;
                                  if (name == playlist.name) return;
                                  await renamePlaylist(context, ref, playlist,
                                      name: name);
                                } else if (value == 'delete') {
                                  await deletePlaylist(context, ref, playlist);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'rename',
                                  child: ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: const Icon(Icons.edit_outlined),
                                    title: Text(context.l10n.rename),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(Icons.delete_outline),
                                    title: Text(context.l10n.delete),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlaylistDetailPage(
                              playlistId: playlist.id,
                              playlistName: playlist.name,
                            ),
                          ),
                        ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
