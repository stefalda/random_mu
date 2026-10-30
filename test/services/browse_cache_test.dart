import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:random_mu/client/audio_player_handler.dart';
import 'package:random_mu/services/browse_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('BrowseCache', () {
    test('round-trips MediaItems through persistent storage', () async {
      const cache = BrowseCache();
      final items = [
        const MediaItem(
          id: 'song-1',
          title: 'One',
          artist: 'Artist',
          album: 'Album',
          duration: Duration(seconds: 123),
          artUri: null,
          extras: {'coverArt': 'ca-1'},
        ),
        const MediaItem(
          id: 'playlist-42',
          title: 'My List',
          playable: false,
        ),
      ];

      await cache.saveNode(playlistsCategoryId, items);

      final loaded = await cache.loadNode(playlistsCategoryId);

      expect(loaded, isNotNull);
      expect(loaded!.length, 2);
      expect(loaded.first.id, 'song-1');
      expect(loaded.first.title, 'One');
      expect(loaded.first.artist, 'Artist');
      expect(loaded.first.album, 'Album');
      expect(loaded.first.duration, const Duration(seconds: 123));
      expect(loaded.first.extras, {'coverArt': 'ca-1'});
      expect(loaded.last.playable, isFalse);
    });

    test('upsertInCategory replaces an existing entry', () async {
      const cache = BrowseCache();
      await cache.saveNode(albumsCategoryId, [
        const MediaItem(id: 'album-1', title: 'Old', playable: false),
      ]);

      await cache.upsertInCategory(
        albumsCategoryId,
        const MediaItem(id: 'album-1', title: 'New', playable: false),
      );

      final loaded = await cache.loadNode(albumsCategoryId);
      expect(loaded!.length, 1);
      expect(loaded.single.title, 'New');
    });

    test('removeFromCategory and removeNode drop cached data', () async {
      const cache = BrowseCache();
      await cache.saveNode(albumsCategoryId, [
        const MediaItem(id: 'album-1', title: 'A', playable: false),
        const MediaItem(id: 'album-2', title: 'B', playable: false),
      ]);
      await cache.saveNode('album-1', [
        const MediaItem(id: 'song-1', title: 'One'),
      ]);

      await cache.removeFromCategory(albumsCategoryId, 'album-1');
      await cache.removeNode('album-1');

      final category = await cache.loadNode(albumsCategoryId);
      expect(category!.map((i) => i.id), ['album-2']);
      expect(await cache.loadNode('album-1'), isNull);
    });

    test('clear drops every cached node', () async {
      const cache = BrowseCache();
      await cache.saveNode(playlistsCategoryId, [
        const MediaItem(id: 'playlist-1', title: 'P', playable: false),
      ]);
      await cache.saveNode('playlist-1', [
        const MediaItem(id: 'song-1', title: 'One'),
      ]);

      await cache.clear();

      expect(await cache.loadNode(playlistsCategoryId), isNull);
      expect(await cache.loadNode('playlist-1'), isNull);
    });
  });

  group('AudioPlayerHandler offline browse', () {
    test('falls back to cached nodes when the player service is absent',
        () async {
      const cache = BrowseCache();
      await cache.saveNode(playlistsCategoryId, [
        const MediaItem(
          id: 'playlist-1',
          title: 'Cached playlist',
          playable: false,
        ),
      ]);
      await cache.saveNode('playlist-1', [
        const MediaItem(id: 'song-1', title: 'Cached song'),
      ]);

      final handler = AudioPlayerHandler();

      final playlists = await handler.getChildren(playlistsCategoryId);
      expect(playlists.map((i) => i.id), ['playlist-1']);

      final songs = await handler.getChildren('playlist-1');
      expect(songs.map((i) => i.id), ['song-1']);
    });

    test('returns root categories without network', () async {
      final handler = AudioPlayerHandler();

      final root = await handler.getChildren(rootId);

      expect(
        root.map((i) => i.id),
        [playlistsCategoryId, artistsCategoryId, albumsCategoryId,
          favoritesCategoryId, songsCategoryId, downloadsCategoryId],
      );
    });

    test('returns an empty list when nothing is cached', () async {
      final handler = AudioPlayerHandler();

      expect(await handler.getChildren(artistsCategoryId), isEmpty);
    });
  });
}
