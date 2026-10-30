# Changelog

All notable changes to Random Muu(sic) are documented here. The version follows
`pubspec.yaml`; releases are published on GitHub with the APK attached.

## [0.0.24] - 2026-10-30

A library release: the app is browsable, the playback mode is yours, playlists
and favorites are editable, and it keeps working without a connection.

### Added

- **Library browsing**: bottom navigation (`Library`, `Playlists`, `Downloads`,
  `Search`) with tabs for Artists, Albums, Songs, Favorites and Genres, each with
  its own instant filter. Albums and Songs load page by page while scrolling.
- **Detail pages** for albums, artists and playlists, with a single reusable
  track list: tap plays the container from that track, long press opens the
  track actions (play now, play next, queue, add to playlist, lyrics, remove from
  queue).
- **Playback mode**: sequential or shuffled, persisted across restarts, with a
  toggle in the title bar and in the player. Changing it reorders the live queue
  without interrupting playback; shuffled containers start on a random track.
- **Playlists on the server**: create, rename, delete, add tracks while browsing
  and remove them from the playlist detail (Navidrome stays the source of truth).
- **Favorites**: star/unstar tracks from any list and albums from the detail
  header, written through to the server.
- **Lyrics**: synced lyrics with the current line highlighted and followed, with
  a plain-text fallback.
- **Global search** over artists, albums and tracks, plus per-list filters.
- **Offline degradation**: when the server is unreachable the library falls back
  to the downloads, with a banner and a retry; playback uses the local files.
  Requests time out after 15 s so the fallback is reached quickly.
- **Android Auto**: new `Songs` and `Downloads` nodes, search (also offline over
  the downloads), content-style hints, and the playback mode exposed as a custom
  action next to "Play Similar". The browse tree follows the playback mode.
- **Now playing bar** above the navigation, so the player is always one tap away.
- **English and Italian** UI (ARB localizations, device language).

### Changed

- The command menu is gone; the one-shot random commands live in the `Shuffle`
  sheet of the library and never change the persisted playback mode.
- Play Similar keeps the current track playing and swaps only the queue: no
  reload, no silence, and the queue becomes the current track plus the similar
  ones.
- The playlist picker loads the playlist list on demand and can create a playlist
  on the fly.
- Tag padding is normalised (titles, albums, artists) so lists and the car show
  clean names.

### Fixed

- Downloads page showed "No downloads yet" after a restart even when files were
  on disk (it never rebuilt after the service restored the queue).
- Restoring a session whose track was not downloaded no longer throws
  "Source error" when offline; the session is published and retried on play.
- Downloads never start on their own after a restart: the queue waits for an
  explicit resume.
- Android Auto no longer drops out of the now playing screen when the queue is
  swapped (`STATE_NONE` from `stop()`).
- The player crashed (`Slider` assertion) when the stream duration was unknown.
- Landscape layout: navigation rail, compact headers, no overflow in the player.
- Release builds only: the Android Auto action icons were stripped by the
  resource shrinker (`res/raw/keep.xml`), and the media notification used an
  adaptive icon, which Android 14+ rejects, crashing the media service
  (`Invalid notification (no valid small icon)`).

## [0.0.23] - 2025-12-28

- Android Auto support with a browsable library (playlists, artists, albums,
  favorites), now playing metadata and a "Play Similar" action.
- Offline downloads for playlists, albums, artists and favorites, with a
  Downloads page, storage limit, background downloads, notifications and
  local-first playback.
- Cached artwork for offline browsing and playback.
