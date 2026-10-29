---
type: Work Item
title: Album and artist details with ordered track lists
parent: ../spec.md
---

## What to build

- A reusable `TrackList` widget: rows with artwork, title, artist, duration; tap starts the container
  at that track in the current mode.
- Album detail: cover, title, artist, year, tracks in album order, header actions `Riproduci`,
  `Casuale`, `Accoda`, `Scarica`.
- Artist detail: artist header, albums grid, and an "all tracks" entry with the artist's tracks in
  album order.
- Wire the Library rows to these pages.

## Required context

- `getAlbum(id)`, `getSongsByAlbum(albumId:)`, `getArtist(id)` and `getSongsByAlbum` are available on
  `SubsonicClient`; `getArtistSongsRandomized` is only for the random commands.
- `PlayerService.playContainer` (Work Item 1) is the only playback entry point.
- `DownloadButton`/`DownloadItemType` and `showAddToPlaylistSheet` already exist and must be reused.

## Acceptance criteria

- [ ] Album detail lists tracks in album order; tapping a track starts playback there in the current mode.
- [ ] `Riproduci` and `Casuale` in the header set that mode and start the container accordingly.
- [ ] Artist detail lists albums and can play all artist tracks in album order.
- [ ] `Accoda` and `Scarica` work from both detail pages.
- [ ] `TrackList` is the single list widget used by these pages.

## Covers

- User Stories: 2, 3, 5
- Requirements: 18, 19, 21, 22
- Interview Ledger: L9

## Blocked by

3
