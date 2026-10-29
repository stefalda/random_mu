---
type: Work Item
title: Favorites, Genres and global search
parent: ../spec.md
---

## What to build

- `Preferiti` tab: starred tracks, albums (navigable to album detail) and artists.
- `Generi` tab: genre list, tapping a genre lists its tracks.
- `Cerca` tab: global `search3` with Artists, Albums and Tracks sections.

## Required context

- `getStarred()`, `getGenres()`, `getSongsByGenre(...)` and `search(...)` exist on `SubsonicClient`.
- Reuse `TrackList` and its actions so results behave like any other list.

## Acceptance criteria

- [x] `Preferiti` shows three sections; starred albums open the album detail.
- [x] `Generi` lists genres and plays a genre's tracks in the current mode.
- [x] `Cerca` queries the server and shows Artists/Albums/Tracks sections with artwork.
- [x] Every track in these lists supports the track actions.

## Covers

- User Stories: 1, 11
- Requirements: 14, 17
- Interview Ledger: L3

## Blocked by

3, 5

## Notes

Verified on device: Preferiti lists starred tracks and albums, and searching "blur" returns the Blur artist plus The Best Of Blur with navigable album results.
