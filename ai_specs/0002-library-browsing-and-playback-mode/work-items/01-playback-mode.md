---
type: Work Item
title: Playback mode in the app
parent: ../spec.md
---

## What to build

Introduce a persisted `PlaybackMode` (`Sequenziale` / `Casuale`) owned by `PlayerService`, and make it
the single rule that turns a container into a queue.

- Enumerate the mode, persist it in `PreferenceService`, restore it at startup; default
  `Sequenziale` when nothing is stored.
- One entry point `playContainer(songs, {startAtSongId, mode})`:
  - `Sequenziale` → queue = container order, index = tapped track;
  - `Casuale` → tapped track first, remaining tracks shuffled;
  - passing `mode` also persists it (explicit user choice from a detail page or the player).
- Keep the container order of the current queue in memory so `setMode` can reorder the live queue:
  - to `Casuale`: the current track keeps its index, the rest is shuffled;
  - to `Sequenziale`: the queue returns to the container order, still playing the current track;
  - reorder with `AudioPlayer.moveAudioSource` so audio never stops and the position is kept.
- Player page: shuffle toggle that reflects the mode and switches it.
- One-shot random commands (`randomAll`, `randomByPlaylist/Artist/Album/Favorites`,
  `randomByPlayingSong`) keep producing shuffled queues but never change the persisted mode.

## Required context

- `lib/services/player_service.dart` owns `AudioPlayer`; `_enqueueSongs` is the only place that
  resolves stream/local URLs and publishes the queue.
- `just_audio` 0.10.6 exposes `audioSources`, `moveAudioSource(from, to)` and `setAudioSources`;
  moves are gapless and keep the current item playing.
- `randomByPlaylist`/`randomByAlbum` currently shuffle inside themselves before queuing; keep that
  behaviour for the one-shot commands (the queued order is then their "container order").
- `PreferenceService` already stores the latest playlist and the current index.

## Acceptance criteria

- [ ] `PlaybackMode` is persisted; after a restart the last used mode is active, and a fresh install starts on `Sequenziale`.
- [ ] Starting an album/playlist/artist/favorites sequentially keeps the container order and starts at the tapped track.
- [ ] Starting the same container in `Casuale` starts at the tapped track with the rest shuffled.
- [ ] Toggling the mode while playing reorders the queue without stopping audio and without losing the playback position; two consecutive toggles return to the original order.
- [ ] Queues that do not come from a container (Play Similar, restored session) treat their queued order as the original order.
- [ ] The random commands leave the persisted mode untouched.
- [ ] Unit tests cover persistence, both queue-building modes, and the reorder round-trip.
- [ ] `flutter analyze` and `flutter test` are clean.

## Covers

- User Stories: 5, 6, 8
- Requirements: 1-8
- Interview Ledger: L1, L6, L8

## Blocked by

None - ready to start
