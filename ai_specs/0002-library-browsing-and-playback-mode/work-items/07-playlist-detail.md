---
type: Work Item
title: Playlist detail with track removal
parent: ../spec.md
---

## What to build

- Playlist detail page: name, cover when available, tracks in playlist order, header actions
  (`Riproduci`, `Casuale`, `Accoda`, `Scarica`, `Rinomina`).
- Remove a track from the playlist, computing `songIndexToRemove` from the position in the displayed
  order, refreshing the list and invalidating the Android Auto caches for that playlist.
- No reordering affordance: the Subsonic API cannot reorder playlist entries.

## Required context

- `SubsonicClient.updatePlaylist(playlistId, removeSongIndexes:)` already implements removal by
  index; `PlayerService` has playlist mutations that invalidate the AA caches.
- The playlist row currently starts random playback on tap; it must open the detail instead.

## Acceptance criteria

- [ ] Playlist detail lists tracks in saved order and plays from the tapped track in the current mode.
- [ ] Removing a track updates the server (verified with `getPlaylist`) and the list refreshes.
- [ ] Android Auto browse cache for that playlist is invalidated after the removal.
- [ ] Rename is reachable from the detail page and from the list.

## Covers

- User Stories: 4, 10
- Requirements: 20, 25, 26
- Interview Ledger: L11

## Blocked by

4
