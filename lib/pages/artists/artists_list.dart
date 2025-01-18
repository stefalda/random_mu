// Create the ConsumerWidget
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_mu/main.dart';
import 'package:random_mu/pages/player_page.dart';

class ArtistList extends ConsumerWidget {
  const ArtistList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistsAsync = ref.watch(artistsProvider);
    final searchController = ref.watch(searchControllerProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search artists...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        ref
                            .read(artistsProvider.notifier)
                            .updateSearchQuery('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              ref.read(artistsProvider.notifier).updateSearchQuery(value);
            },
          ),
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
                    'Error loading artists: ${error.toString()}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(artistsProvider),
                    child: const Text('Retry'),
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
                            ? 'No artists available'
                            : 'No artists found for "${state.searchQuery}"',
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
                          child:
                              /* const CircleAvatar(
                              radius: 25,
                              child: Icon(Icons.person),
                            )
                            */
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
                          ),
                        ),
                        title: Text(
                          artist.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        onTap: () async {
                          // Handle artist selection
                          if (context.mounted) {
                            ref.read(loadingProvider.notifier).setLoading(true);
                            unawaited(Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PlayerPage(),
                                )));
                            final playerService =
                                ref.read(playerServiceProvider);
                            await playerService.randomByArtist(
                                artistId: artist.id);
                            ref
                                .read(loadingProvider.notifier)
                                .setLoading(false);
                          }
                        }),
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
