import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_mu/client/subsonic_models.dart';
import 'package:random_mu/main.dart';

/// Starred songs, albums and artists.
///
/// Kept as a provider so starring a track or an album anywhere in the app can
/// invalidate it and the Favorites tab shows the change.
final starredProvider = FutureProvider<SearchResult>((ref) {
  return ref.read(playerServiceProvider).client.getStarred();
});
