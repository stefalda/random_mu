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
- Publish the standard `shuffleMode`, but note that Android Auto 17.x does not render the platform
  shuffle control: the mode is therefore also exposed as a custom action (`togglePlaybackMode`)
  declared before "Play Similar", with icon/label describing the next state. "Play Similar" keeps
  working as is.

## Required context

- `lib/client/audio_player_handler.dart` builds the AA browse tree and implements `playMediaItem`,
  which currently shuffles the parent container unconditionally (`songs.shuffle()` for playlists and
  albums, `getArtistSongsRandomized` for artists).
- `stateToPlaybackState` is the single place where `PlaybackState` is published.
- This supersedes Spec `0001-android-auto-offline` requirements 2-4.

## Acceptance criteria

- [x] `dumpsys media_session` shows `shuffleMode` matching the app mode and the standard shuffle action in the actions bitmap.
- [x] Changing the mode from the car persists it, reorders the queue and updates the player page toggle.
- [x] Tapping a track in the car plays the container in order when the mode is `Sequenziale`, and shuffled when it is `Casuale`.
- [x] AA browse lists show songs in container order (no unconditional shuffle in `getChildren`).
- [x] Both custom actions are visible in the car bar: the mode toggle and "Play Similar".
- [x] Using the mode toggle from the car persists the mode, reorders the queue and updates the app toggle.

## Covers

- User Stories: 7, 8
- Requirements: 9-12
- Interview Ledger: L2, L7

## Blocked by

1

## Notes

Verified on the Desktop Head Unit: the car bar shows the mode toggle next to Play Similar and switching it from the car flipped the session to sequential while the track kept playing. Android Auto 17.x does not render the platform shuffle control, so the custom toggle is required (see ledger L7 Answer History).
