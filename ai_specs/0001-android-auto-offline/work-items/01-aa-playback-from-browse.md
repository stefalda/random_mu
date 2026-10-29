---
type: Work Item
title: Playback from the Android Auto browse tree
parent: ../spec.md
---

## What to build

Make selecting a playable item in the Android Auto browse tree actually start playback.

`AudioPlayerHandler` currently implements only `getChildren`; tapping a song in the car UI calls the
default no-op `BaseAudioHandler.playMediaItem`, so nothing happens. Implement:

- Track the parent browse node of every child item produced by `getChildren`.
- Override `playMediaItem(MediaItem)`: resolve the parent container, fetch its songs, and start
  playback at the tapped song.
  - `playlist-<id>` → full playlist shuffled, start at tapped song.
  - `album-<id>` → full album shuffled, start at tapped song.
  - `artist-<id>` → all songs by the artist, shuffled, start at tapped song.
  - `favorites` → starred songs and starred-album songs, start at tapped song.
  - Unknown/absent parent → play the single item.
- Keep `skipToQueueItem`, `play`, `pause`, `seek`, `skipToNext`, `skipToPrevious` and the
  `playSimilar` custom action working through the already-published queue.
- Degrade gracefully when the network call fails (no crash, no stuck loading state).

## Required context

- `lib/client/audio_player_handler.dart` builds the browse tree (`getChildren`); child IDs are the
  Subsonic song IDs, containers use `playlist-`/`artist-`/`album-` prefixes.
- `lib/services/player_service.dart` owns `AudioPlayer` and already has
  `randomByPlaylist`/`randomByAlbum`/`randomByArtist`/`randomFavorites`, but they always start at
  index 0. Add a shuffled-start-at-song entry point instead of duplicating `_enqueueSongs`.
- `PlayerService._enqueueSongs` is the single place that resolves the stream URL / local file and
  publishes the queue, so all playback paths must go through it.
- `SubsonicClient` methods available: `getPlaylistSongs(id)`, `getSongsByAlbum(albumId:)`,
  `getArtistSongsRandomized(artistId, count:)`, `getStarred()` + `getAlbum(id)`.

## Acceptance criteria

- [ ] Tapping a song in a playlist browse node shuffles the whole playlist and starts at that song.
- [ ] Tapping a song in an album browse node shuffles the whole album and starts at that song.
- [ ] Tapping a song in an artist browse node shuffles all songs by the artist and starts at that song.
- [ ] Tapping a song in the favorites browse node starts playback at that song.
- [ ] `playMediaItem` does not throw when the client is unset, the parent is unknown, or the network
      call fails.
- [ ] No duplicate playback pipeline: playback still goes through `PlayerService._enqueueSongs`.
- [ ] `flutter analyze` reports no new issues in the touched files.

## Covers

- User Stories: 1, 2, 3, 4
- Requirements: 2, 3, 4, 5, 12, 13
- Interview Ledger: L2, L12, L20, L21

## Blocked by

None - ready to start
