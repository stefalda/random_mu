// Create the ConsumerWidget
import 'package:flutter/material.dart';
import 'package:random_mu/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_mu/main.dart';
import 'package:random_mu/pages/artists/artist_detail_page.dart';
import 'package:random_mu/pages/download_button.dart';
import 'package:random_mu/pages/list_filter_field.dart';
import 'package:random_mu/services/download_models.dart';

class ArtistList extends ConsumerWidget {
  const ArtistList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistsAsync = ref.watch(artistsProvider);

    return Column(
      children: [
        ListFilterField(
          hint: context.l10n.searchArtistsHint,
          onChanged: (value) =>
              ref.read(artistsProvider.notifier).updateSearchQuery(value),
        ),
        Expanded(
          child: artistsAsync.when(
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
                    context.l10n.artistsLoadFailed('$error'),
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
              final filteredArtists = state.filteredArtists;

              if (filteredArtists.isEmpty) {
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
                            ? context.l10n.emptyArtists
                            : context.l10n.emptyArtistsFor(
                                state.searchQuery),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: filteredArtists.length,
                itemBuilder: (context, index) {
                  final artist = filteredArtists[index];

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: artist.artistImageUrl == null
                              ? const CircleAvatar(
                                  radius: 25,
                                  child: Icon(Icons.person),
                                )
                              : Image.network(
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
                                ),
                        ),
                        title: Text(
                          artist.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        trailing: DownloadButton(
                          type: DownloadItemType.artist,
                          sourceId: artist.id,
                          title: artist.name,
                        ),
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
