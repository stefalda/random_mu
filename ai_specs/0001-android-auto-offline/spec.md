---
type: Spec
title: Android Auto Browsing & Offline Support
---

## Problem

The app currently has no functional Android Auto integration. While some scaffolding exists (automotive_app_desc.xml, a custom MediaPlaybackService.kt using wrong imports, a Dart AudioPlayerHandler with an unused MethodChannel), Android Auto users cannot browse their music library or control playback from the car UI. Additionally, there is no offline playback capability — the app requires a network connection to stream every song.

When Android Auto users open the app in their car, they should be able to browse their Subsonic library (playlists, artists, albums, favorites), see now-playing info, control playback, and play songs offline that were previously downloaded on the phone.

## Proposed Outcome

Android Auto users can:

1. Browse the music library on the car screen with four top-level categories: Playlists, Artists, Albums, Favorites. [L1]
2. See album artwork, song titles, artists, and albums in the browse tree and now-playing display.
3. Control playback (play/pause/skip/seek) and trigger "Play Similar" (Random by Playing).
4. Play songs that were explicitly downloaded on the phone, with automatic fallback to local copies.
5. See the correct playback state and metadata synced between phone and car.

This Spec covers both online Android Auto functionality and offline download/support in a single specification. [L23]

Phone app users can:

1. Download playlists, albums, artists (all songs by that artist), or "All Favorites" for offline playback.
2. Monitor and manage downloads in a dedicated Downloads page with queue status, progress, and retry controls.
3. Configure a storage limit for offline content.
4. Receive notifications when background downloads complete.

## User Stories

1. As a driver, I want to browse my playlists on Android Auto and tap any song to shuffle-play the full playlist starting from that song.
2. As a driver, I want to browse all artists on Android Auto, open one, and see all their songs in random order. Tapping any song plays it.
3. As a driver, I want to browse all albums on Android Auto, open one, and see its tracks. Tapping any song shuffles the album starting from that song.
4. As a driver, I want to browse my starred favorites on Android Auto and play them.
5. As a driver, I want to see now-playing info (title, artist, album, artwork) on the car screen.
6. As a driver, I want to use the "Play Similar" action from the overflow menu to replace the current queue with similar songs (starting with the current song).
7. As a user, I want to download a playlist from the browse page by tapping a download icon, and see its progress.
8. As a user, I want to download an album or all songs by an artist for offline playback with one tap.
9. As a user, I want to view all downloaded content, see download progress, and manage (retry/delete) downloads from a dedicated Downloads page.
10. As a user, I want to set a maximum storage limit for offline content, and be blocked from downloading more when the limit is reached.
11. As a user, I want background downloads to continue even if I navigate away from the app, and receive a notification when they complete.
12. As a driver, I want offline-downloaded content to appear in the AA browse tree even when there is no network connection, and play from local files automatically.

## Requirements

### Android Auto Browse Tree

1. The AA browse tree root must expose four top-level categories: **Playlists**, **Artists**, **Albums**, **Favorites**. [L2]
2. **Playlists** must show all playlists from the Subsonic server (fetched via `client.getPlaylists()`). Selecting a playlist shows all songs in that playlist. Tapping a song must shuffle the full playlist and start playback at the selected song. [L20]
3. **Artists** must show all artists (fetched via `client.getArtists()`). Selecting an artist shows all songs by that artist in random order (re-shuffled each time the artist node is opened). Tapping a song must shuffle all songs by that artist and start playback at the selected song, matching the phone app's `randomByArtist` behavior. [L12][L21]
4. **Albums** must show all albums (fetched via `client.getAllAlbumsList()`). Selecting an album shows its tracks. Tapping a song must shuffle the full album and start playback at the selected song. [L20]
5. **Favorites** must show starred songs and songs in starred albums (fetched via `client.getStarred()`). Tapping a song must play it.
6. The browse tree must be implemented by overriding `BaseAudioHandler.onLoadChildren(String parentMediaId)` in `AudioPlayerHandler`, returning `List<MediaItem>` for each browse node. The root node and its children are managed via `AudioService.setBrowseMediaParent()`. No custom native `MediaBrowserService` implementation. [L3][L11]
7. Browse metadata (artist names, album titles, playlist names, song lists) must be cached locally so the tree is fully navigable without network access when the content was previously downloaded. [L10][L26]

### Android Auto Playback

8. The now-playing screen must display song title, artist name, album name, album artwork (from `mediaItem.artUri`), and playback progress.
9. Standard transport controls (play/pause, skip next, skip previous, seek) must function via the `MediaSession` managed by `audio_service`.
10. A custom **"Play Similar"** action must be available in the Android Auto overflow menu. When triggered, it must: [L14][L19]
    - Fetch similar songs via `client.getSimilarSongs(currentSongId)`.
    - Replace the current queue, starting with the current song.
    - Begin playback.
11. The `AudioPlayerHandler` (Dart) must be properly initialized via `AudioService.init()` in `main.dart`, replacing the current `JustAudioBackground.init()` call. [L3]
12. The `AudioPlayerHandler` must extend `BaseAudioHandler` with `QueueHandler` and `SeekHandler` mixins and must NOT use MethodChannel communication (remove existing MethodChannel in `AudioPlayerHandler`). [L11]
13. Playback state (playing/paused), position, and media metadata must be published via `AudioPlayerHandler`'s `MediaSession` callbacks to stay in sync between the phone and the car.

### Offline Download — Phone UI

14. A **Downloads** entry must appear on the menu page (`MenuPage`) alongside existing entries. Tapping it navigates to a `DownloadsPage`. [L8]
15. The `DownloadsPage` must show:
    - A list of all downloaded items grouped by type (playlist, album, artist, favorites), with item names.
    - Per-item download status: queued, downloading (with progress %), complete, failed.
    - Per-item delete action.
    - A "Used: X.X GB / Limit: Y.Y GB" card at the top. Tapping it opens a dialog to change the limit.
    - An overall "Clear All" option to remove all downloaded content (must show a confirmation dialog before deleting).
16. On the existing browse pages (Playlists, Artists, Albums), each item row must show a **download icon** (cloud-download). Tapping it adds the item to the download queue. The icon changes to a progress indicator while downloading, then a checkmark when complete. [L8]
17. On the Favorites browse, a single **"Download All Favorites"** button must be available.
18. When a download is already complete, the icon must show a checkmark. Tapping the checkmark must offer to delete the download (confirm dialog). [L13]

### Offline Download — Queue & Storage

19. The download queue must process items in **FIFO order**. [L15]
20. Up to **2 downloads** must run concurrently. [L7]
21. The queue must **persist across app restarts** — incomplete downloads resume when the app reopens. [L7]
22. If a download fails mid-file, the partial file must be **deleted**. [L7]
23. Auto-retry up to **3 times** with exponential backoff (e.g., 5s, 15s, 45s). After the third failure, mark the item as failed with an error message. The user can tap to retry from the Downloads page. [L16]
24. Downloaded audio files must be stored in the **app's internal documents directory** (`getApplicationDocumentsDirectory()` from `path_provider`). [L5]
25. Downloaded files must be stored in the **original format** served by the Subsonic server (no transcoding). [L9][L25]
26. On download completion, a **system notification** must be posted (e.g., "Playlist 'X' downloaded" or "3 items downloaded"). [L18]

### Offline Download — Storage Limit

27. A **user-configurable storage limit** must be accessible from the Downloads page. [L17]
28. Default limit: **10 GB**.
29. Supported limit options: 1 GB, 2 GB, 5 GB, 10 GB, 20 GB, 50 GB, Unlimited. [L6]
30. When the storage limit is **reached** (or exceeded by the next queued item), **block new downloads** and display a message: "Storage limit reached. Free up space in Downloads to continue." with a button navigating to the Downloads page. [L24]
31. The Downloads page must show current usage: "Used: X.X GB / Limit: Y.Y GB". Update this in real-time as downloads complete.

### Offline Playback — Auto Fallback

32. When the `PlayerService` is about to play a song, it must check if a local file exists for that song ID. [L4]
33. If a local file exists, play from the local file path instead of the stream URL.
34. If no local file exists, fall back to the normal stream URL from the Subsonic server. No user prompt is required.
35. The auto-fallback must work transparently in both the phone app and Android Auto.

### Code Cleanup

36. Remove `android/app/src/main/kotlin/com/example/random_mu/MediaPlaybackService.kt`. [L11]
37. Remove `android/app/src/main/kotlin/com/example/random_mu/FlutterMediaChannel.kt`. [L11]
38. Remove the `MethodChannel` (`com.babisoft.randommu/android_auto`) from `AudioPlayerHandler` and `MainActivity.kt`. [L11]
39. Replace `JustAudioBackground.init()` in `main.dart` with `AudioService.init(builder: () => AudioPlayerHandler(...), config: ...)`. `AudioService.init()` handles the `MediaSession`, `MediaBrowserService`, and notification setup. The `createMediaItem` helper from `just_audio_background` may be kept or migrated to use `MediaItem` from `audio_service` (they are the same type, re-exported).
40. Upgrade `audio_service` and `just_audio_background` to the latest compatible versions that support Android Auto media browsing via `onLoadChildren`. [L22]

## Technical Decisions

1. **Android Auto browsing via `audio_service`'s `onLoadChildren`.** The `audio_service` package (upgraded as needed) natively implements `MediaBrowserService` on Android. The browse hierarchy is defined in Dart by overriding `BaseAudioHandler.onLoadChildren(String parentMediaId)` to return `List<MediaItem>` for each node. The root and current browse context are managed via `AudioService.setBrowseMediaParent()`. This avoids maintaining custom native `MediaBrowserService` Kotlin code and keeps the browsing logic in Flutter/Dart. [L3]
2. **Storage layer: `path_provider` + SQLite/Hive for metadata.** Downloaded audio files stored in `getApplicationDocumentsDirectory()` as `<songId>.<extension>`. Metadata cache stored using a local database (Hive or SQLite) mapping song IDs to local file paths, and item-to-song relationships for the AA browse tree.
3. **Download service: Dart isolate or `workmanager`.** Use a Flutter background work plugin to ensure downloads continue after the app is backgrounded. The download queue state persisted in the local database.
4. **Player adaptation.** `PlayerService._enqueueSongs` already creates stream URLs. It must be extended to check local file paths first and use `AudioSource.file()` or `AudioSource.uri()` accordingly. The `createMediaItem` function must accept an optional local path.
5. **Download from Subsonic.** Use the existing `http` client to `GET` the stream URL (`client.getStreamUrl(song.id)`) and write bytes to the local file. Track progress via streamed response.
6. **AudioPlayerHandler wiring.** Initialize `AudioService` with a `AudioPlayerHandler` instance in `main.dart`. The handler wraps `PlayerService` and publishes state/metadata changes through `MediaSession`. The existing `PlayerService` continues to manage the `AudioPlayer` directly; the handler delegates to it.

## Testing Strategy

Test Seam target: Replace the Subsonic network layer with a controlled fake for all automated tests.

- **Unit tests (recommended):**
  - `PlayerService` auto-fallback logic: mock local file existence check; verify `AudioSource.file()` vs `AudioSource.uri()` selection.
  - Download queue logic: enqueue items, verify FIFO ordering, concurrency cap at 2, retry count, failure marking.
  - Storage limit logic: verify blocking behavior at limit, correct used-space tracking.
  - Metadata cache: verify read/write of browse tree metadata, offline availability.
- **Widget tests:**
  - Downloads page: render with mocked download list, verify status display, delete action, limit configuration.
  - Browse page download icons: verify icon states (not downloaded / queued / downloading / complete / failed).
  - Menu page: verify "Downloads" entry is present.
- **Integration tests:**
  - End-to-end download flow: tap download on a playlist -> queue processes -> files appear locally -> playback uses local files.
- **Android Auto (manual):**
  - Browse tree renders correctly on AA head unit or Android Auto emulator.
  - Playback controls, "Play Similar" action, now-playing metadata sync.
  - Offline browse: airplane mode + verify tree shows cached content and plays local files.

No existing Test Seams found in the project. The above adds new Test Seams at the network layer (fake `SubsonicClient`) and file-system layer (fake `path_provider` / local file store).

## Out of Scope

- Transcoding of audio files. Downloaded files use the original server format. [L9]
- Automatic caching of streamed songs (e.g., LRU cache). Only explicit user-initiated downloads are stored.
- Reordering of the download queue. FIFO only. [L15]
- Car UI customization beyond what Android Auto's `MediaBrowserService` provides (e.g., custom layouts, theming).
- Support for other Android Autos features such as messaging, navigation, or voice commands beyond media browsing.
- Downloading from other sources — only Subsonic server downloads are supported.
- iOS CarPlay support.

## Open Questions

- Should the app show a "Download size" estimate before the user confirms the download?
- Should the "Play Similar" action on AA be limited to a maximum number of similar songs (e.g., 50)?
- What happens to offline content if the Subsonic server credentials change? (Potential auto-purge or re-auth prompt.)
- Should the download queue show estimated remaining time?

## Follow-Ups

- After implementing this Spec, consider adding reorderable download queue, estimated download size before confirming, and iOS CarPlay support in a follow-up.

## Notes

- All references to `audio_service` assume version `0.18.x` or later, with `onLoadChildren` support verified after upgrade.
- The current `just_audio_background` `createMediaItem` function produces `MediaItem` objects with `extras['streamUrl']`. This must continue to work; `extras['localPath']` (optional) can be added for offline playback.
- The existing `PlayerService.restoreSongs()` method restores the last playing session. Offline cache must be integrated with this flow — if restored songs have local copies, use local paths.
- New `pubspec.yaml` dependencies required: `path_provider` (for offline storage), plus a background-work plugin (`flutter_background_service` recommended for long-running download daemon, or `workmanager` for periodic tasks).
- The `app/build.gradle` has `androidx.car.app:app-automotive` commented out. This may need to be uncommented or added for Android Auto to recognize the app on API 30+ devices. Verify during implementation.
- `AudioService.init()` and `JustAudioBackground.init()` both manage Android notification channels. When migrating to `AudioService.init()`, ensure the notification channel is configured via `AudioServiceConfig` to avoid duplicate channel registration errors.
