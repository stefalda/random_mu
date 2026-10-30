import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_mu/client/subsonic_models.dart';
import 'package:random_mu/main.dart';
import 'package:random_mu/providers/download_provider.dart';
import 'package:random_mu/services/download_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What is playable with no server: the downloaded songs, grouped in the
/// containers they were downloaded as.
///
/// Built from the metadata the [DownloadService] keeps on disk
/// (`download_queue`, `download_metadata_<item>`, `song_<id>`), so it works after
/// a restart and without any network call.
class OfflineLibrary {
  const OfflineLibrary({
    this.songs = const [],
    this.containers = const [],
  });

  /// Every downloaded song, sorted by title.
  final List<Song> songs;

  /// Downloaded containers (albums, playlists, artists, favorites) that still
  /// have songs on disk.
  final List<OfflineContainer> containers;

  bool get isEmpty => songs.isEmpty && containers.isEmpty;

  bool get isNotEmpty => !isEmpty;

  /// Songs of one album, matched by album name (id is not persisted).
  List<Song> songsOfAlbum(String album) =>
      songs.where((song) => song.album == album).toList();
}

class OfflineContainer {
  const OfflineContainer({required this.item, required this.songs});

  final DownloadItem item;
  final List<Song> songs;
}

/// Reads the downloads index from preferences.
///
/// Deliberately not a network call: this is the last resort when the server is
/// unreachable.
final offlineLibraryProvider = FutureProvider<OfflineLibrary>((ref) async {
  final service = ref.watch(downloadServiceProvider);
  await service.ready;

  final prefs = ref.read(sharedPreferencesProvider);
  final rawQueue = prefs.getString('download_queue');
  if (rawQueue == null) return const OfflineLibrary();

  final List<DownloadItem> items;
  try {
    items = (jsonDecode(rawQueue) as List<dynamic>)
        .map((entry) => DownloadItem.fromJson(entry as Map<String, dynamic>))
        .where((item) => item.status == DownloadStatus.completed)
        .toList();
  } catch (error) {
    debugPrint('OfflineLibrary: cannot read the download queue: $error');
    return const OfflineLibrary();
  }

  final songsById = <String, Song>{};
  final containers = <OfflineContainer>[];

  for (final item in items) {
    final rawIds = prefs.getString('download_metadata_${item.id}');
    if (rawIds == null) continue;

    final containerSongs = <Song>[];
    try {
      for (final songId in (jsonDecode(rawIds) as List<dynamic>).cast<String>()) {
        final cached = _songFrom(prefs, songId);
        if (cached == null) continue;
        songsById[songId] = cached;
        containerSongs.add(cached);
      }
    } catch (error) {
      debugPrint('OfflineLibrary: cannot read the songs of ${item.title}: $error');
    }

    if (containerSongs.isNotEmpty) {
      containers.add(OfflineContainer(item: item, songs: containerSongs));
    }
  }

  final songs = songsById.values.toList()
    ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

  return OfflineLibrary(songs: songs, containers: containers);
});

Song? _songFrom(SharedPreferences prefs, String songId) {
  final raw = prefs.getString('song_$songId');
  if (raw == null) return null;
  try {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return Song(
      id: json['id'] as String,
      isDir: false,
      title: cleanTag(json['title']),
      artist: cleanTagOrNull(json['artist']),
      album: cleanTagOrNull(json['album']),
      coverArt: json['coverArt'] as String?,
      duration: json['duration'] as int?,
    );
  } catch (_) {
    return null;
  }
}
