---
type: Work Item
title: Library shell with Artists and Albums tabs
parent: ../spec.md
---

## What to build

Replace the command menu with a navigable library.

- Shell with bottom navigation: `Libreria`, `Playlist`, `Downloads`, `Cerca`; the app opens on
  `Libreria`.
- `Libreria` with tabs `Artisti` and `Album` (the other two tabs arrive in Work Item 6):
  cover art, alphabetical list, own search controller and instant local filter per tab.
- Tapping an artist/album row opens its detail (Work Item 4); until then, tapping plays the container
  through `playContainer`.
- A `Casuale` entry exposing `All Random`, `Random by Playing`, `Random by Favorites`.
- Remove the shared `searchControllerProvider`; each list owns its filter state.

## Required context

- `lib/pages/*/…_list.dart` currently share `searchControllerProvider`, and `playlists_list.dart`
  drives `artistsProvider`: every list needs its own state.
- Existing providers: `artistsProvider`, `albumsProvider`, `playlistsProvider`.
- `Header` overflows in narrow AppBars; it is already fixed with an ellipsized `Flexible`.

## Acceptance criteria

- [ ] The app opens on `Libreria` with bottom navigation between the four destinations.
- [ ] `Artisti` and `Album` tabs list the library with artwork, and each filters independently.
- [ ] Typing in one tab never filters another tab (regression test for the shared controller).
- [ ] `Casuale` exposes the three random commands and does not change the playback mode.
- [ ] No yellow/black overflow stripes in any AppBar.

## Covers

- User Stories: 1, 12
- Requirements: 13, 14, 15, 16
- Interview Ledger: L3, L4, L9

## Blocked by

1
