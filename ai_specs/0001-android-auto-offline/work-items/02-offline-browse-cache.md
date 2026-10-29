---
type: Work Item
title: Persistent browse metadata cache for offline Android Auto
parent: ../spec.md
---

## What to build

Make the Android Auto browse tree usable with no network connection for content that was downloaded.

Today `AudioPlayerHandler._browseCache` is an in-memory `Map` populated only after a successful
network call, so after an app restart or while offline every category resolves to an empty list.

- Add a persistent `BrowseCache` store (SharedPreferences-backed JSON; `MediaItem` has no built-in
  serialization in `audio_service` 0.18, so map the fields explicitly).
- `getChildren` writes every successfully built node to the cache and, when the network call fails
  or returns nothing, falls back to the cached node for that parent ID.
- `DownloadService` primes the cache when a download completes: the container node
  (`playlist-<id>` / `album-<id>` / `artist-<id>` / `favorites`) with its song `MediaItem`s, plus
  the entry inside its category node (`playlists` / `artists` / `albums`).
- Deleting a download item (single delete and "Clear All") removes its cached container node and its
  entry in the category node.

## Required context

- `lib/client/audio_player_handler.dart` — node IDs: `root`, `playlists`, `artists`, `albums`,
  `favorites`, `playlist-<id>`, `artist-<id>`, `album-<id>`; song items use the raw song ID.
- `lib/services/download_service.dart` already caches per-song records under the `song_<id>` pref
  key and knows the songs of every item it downloads.
- `lib/services/download_models.dart` — `DownloadItem`, `DownloadItemType`.
- Tests must not depend on the network: the cache store and the download service are injectable.

## Acceptance criteria

- [x] A successfully built browse node is written to persistent storage.
- [x] With the client failing (offline), `getChildren` returns the cached node for every previously
      built parent ID, including the four top categories and their children.
- [x] With no cache and no network, `getChildren` returns an empty list without throwing.
- [x] A completed playlist/album/artist/favorites download makes its browse nodes available offline
      without an intervening online browse.
- [x] Removing a downloaded item removes its container node and its category entry from the cache.
- [x] "Clear All" removes all cached browse nodes.
- [x] Unit tests cover cache round-trip, offline fallback and delete cleanup.

## Covers

- User Stories: 12
- Requirements: 7
- Interview Ledger: L10, L26

## Blocked by

None - ready to start

## Notes

Verified on device with the real Navidrome server: after downloading the "00.info" playlist the
browse cache contains `aa_browse_node_playlists` and `aa_browse_node_playlist-<id>` with the 11
song MediaItems. Offline fallback is covered by unit tests; the in-car view still needs a head unit.
