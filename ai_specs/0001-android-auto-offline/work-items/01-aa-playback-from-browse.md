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

- [x] Tapping a song in a playlist browse node shuffles the whole playlist and starts at that song.
- [x] Tapping a song in an album browse node shuffles the whole album and starts at that song.
- [x] Tapping a song in an artist browse node shuffles all songs by the artist and starts at that song.
- [x] Tapping a song in the favorites browse node starts playback at that song.
- [x] `playMediaItem` does not throw when the client is unset, the parent is unknown, or the network
      call fails.
- [x] No duplicate playback pipeline: playback still goes through `PlayerService._enqueueSongs`.
- [x] `flutter analyze` reports no new issues in the touched files.

## Covers

- User Stories: 1, 2, 3, 4
- Requirements: 2, 3, 4, 5, 12, 13
- Interview Ledger: L2, L12, L20, L21

## Blocked by

None - ready to start

## Notes

Implementation complete and covered by the browse-cache tests; playback goes through
`PlayerService.playSongsStartingAt` -> `_enqueueSongs`, so the offline file fallback applies.

Verified in the car UI with the Android Auto Desktop Head Unit (DHU over USB/AOA on the Poco F1):
the browse tree exposes Playlists/Artists/Albums/Favorites with artwork, opening a playlist lists its
songs, tapping a song starts playback at that song with a shuffled queue (checked in the AA Queue
view), and the now-playing screen shows artwork, title, artist, progress and transport controls.

Gap found while driving the car UI: `customAction('playSimilar')` was handled but no custom control
was ever declared, so the action never reached Android Auto. `stateToPlaybackState` now declares
`MediaControl.custom(name: 'playSimilar')` and
`android/app/src/main/res/drawable/ic_play_similar.xml` provides the shuffle icon. With that, AA
shows the shuffle button in the now-playing bar and tapping it replaces the queue with similar songs
starting from the current one. The vector drawable must not use a theme `android:tint`, otherwise AA
falls back to a placeholder icon.
