# Changelog

All notable changes to Random Muu(sic) are documented here. The version follows
`pubspec.yaml`; releases are published on GitHub with the APK attached.

## [0.0.28] - 2026-10-31

Covers in the car, from a local provider.

### Added

- **Artwork in Android Auto**: the browse tree and the queue now publish a
  `content://` URI served by a new `CoverArtProvider`, which fetches each cover
  once at 512 px, caches it in `cacheDir/aa_covers` and reuses the cover file of
  downloaded songs when there is no connection. Android Auto only accepts local
  artwork URIs, so the remote cover URL the tree used to publish was ignored by
  the car — and it carried the Subsonic credentials in the query string.

### Changed

- The Android Auto queue rows carry their thumbnail again: it now comes from the
  local provider (a cached, resized JPEG), not from a full-size remote image.

## [0.0.27] - 2026-10-31

The car lists stop fighting the user: scrolling the queue works with music
playing.

### Fixed

- **Android Auto lists no longer snap back to the top**: the car resets the
  scroll position of its lists on every playback state change (a known Android
  Auto bug — see androidx/media#2192; the Media3 workaround is disabling
  periodic position updates). The app published a new state on every position
  and buffered-position tick — up to 5 times a second while playing — so the
  queue (and any long list) kept jumping back to the first row instead of
  scrolling. The state is now published only on real transitions: play/pause,
  buffering, seeks and track changes. The car extrapolates the progress from the
  state's `updateTime`, so the progress bar stays correct.

## [0.0.26] - 2026-10-31

The car's queue screen is usable again.

### Fixed

- **The Android Auto queue screen no longer freezes**: every queue row carried
  a cover art URI, so the car fetched and decoded a full-size image for each
  track it scrolled past. The queue rows now ship text only (id, title, artist,
  album, duration) — which also cuts the payload from ~139 KiB to ~76 KiB for a
  500-track queue — while the now-playing screen keeps its artwork.
- **Queue updates are coalesced**: reordering the queue publishes it once per
  moved track (a playback mode toggle does one move per song), so the car used
  to receive the whole list hundreds of times in a few seconds. It now receives
  at most one update every 400 ms.

## [0.0.25] - 2026-10-31

A performance release for the car: browsing Artists, Songs and the other nodes no
longer fights the playback updates for the Android Auto host's main thread.

### Fixed

- **Android Auto scrolling is smooth again**: the whole queue and the
  now-playing item were republished to the `MediaSession` on *every* playback
  event (about twice a second while streaming) because `just_audio` re-emits its
  sequence state on every buffer update. With 500 tracks that was ~170 KiB of
  binder traffic plus a notification rebuild and N queue items for the car,
  twice a second, on the same thread that scrolls the car list. They are now
  published only when the queue or the playing item actually changes.
- **Now-playing artwork is downscaled to 512 px** before it goes into the media
  metadata and the notification, instead of shipping the original cover
  (megabytes of pixels) on every metadata update.

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
- Web: the download buttons and the Downloads page no longer pretend to work
  (they are Android-only), the stray `Platform._operatingSystem` error is gone,
  and the library, details, search and playback (with the browser Media Session)
  work as on Android.
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
