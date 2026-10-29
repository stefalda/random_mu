---
type: Work Item
title: Track actions available from every list
parent: ../spec.md
---

## What to build

One long-press action sheet for tracks, reused by every list:

- `Riproduci ora`, `Riproduci dopo`, `Accoda`, `Aggiungi a playlist…` (existing picker), `Scarica`,
  `Testo`, plus `Vai all'album` / `Vai all'artista` where the context allows.
- Apply it to `TrackList` usages: album, artist, favorites, genre, search results, queue, downloads.
- Implement `Riproduci dopo` and `Accoda` on the live queue without dropping the current track.

## Required context

- `showAddToPlaylistSheet(context, ref, songIds:, songTitle:)` and `LyricsPage` already exist.
- The queue is a `just_audio` playlist; use `insertAudioSources` for "play next" and append for
  "queue", then keep `_containerOrder` consistent.

## Acceptance criteria

- [ ] Long press on any track row opens the same sheet with the context-appropriate entries.
- [ ] `Aggiungi a playlist` works from every list, including creating a playlist on the fly.
- [ ] `Riproduci dopo` inserts right after the current track and `Accoda` appends at the end, without interrupting playback.
- [ ] `Testo` opens the lyrics page for the selected track.
- [ ] Widget tests cover the sheet entries per context.

## Covers

- User Stories: 9
- Requirements: 23, 24
- Interview Ledger: L10

## Blocked by

4
