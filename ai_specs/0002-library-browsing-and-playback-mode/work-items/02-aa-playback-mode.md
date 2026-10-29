---
type: Work Item
title: Android Auto follows the playback mode
parent: ../spec.md
---

## What to build

Make the car follow the app's playback mode and switch it with the standard shuffle control.

- Publish `shuffleMode` in `PlaybackState` (`all` for `Casuale`, `none` for `Sequenziale`) and add
  `MediaAction.setShuffleMode` to `systemActions`.
- Implement `AudioHandler.setShuffleMode` by delegating to `PlayerService.setMode`, so a change from
  the car is the same decision as a change in the app (persisted, reordered, reflected in the UI).
- Android Auto browse/playback follow the mode: tapping a track in the car starts its container
  according to the mode instead of always shuffling; the browse song lists keep the container order.
- No custom action is added for the mode; "Play Similar" keeps working as is.

## Required context

- `lib/client/audio_player_handler.dart` builds the AA browse tree and implements `playMediaItem`,
  which currently shuffles the parent container unconditionally (`songs.shuffle()` for playlists and
  albums, `getArtistSongsRandomized` for artists).
- `stateToPlaybackState` is the single place where `PlaybackState` is published.
- This supersedes Spec `0001-android-auto-offline` requirements 2-4.

## Acceptance criteria

- [ ] `dumpsys media_session` shows `shuffleMode` matching the app mode and the standard shuffle action in the actions bitmap.
- [ ] Changing the mode from the car persists it, reorders the queue and updates the player page toggle.
- [ ] Tapping a track in the car plays the container in order when the mode is `Sequenziale`, and shuffled when it is `Casuale`.
- [ ] AA browse lists show songs in container order (no unconditional shuffle in `getChildren`).
- [ ] The "Play Similar" custom action still appears and works.

## Covers

- User Stories: 7, 8
- Requirements: 9-12
- Interview Ledger: L2, L7

## Blocked by

1
