---
type: Interview Ledger
parent: spec.md
---

## Records

### L1

Status: current

Question: What level of Android Auto integration do you want?

Recommended Answer: Full browsing — Android Auto users can browse the music library (artists, albums, playlists, favorites) directly from the car UI, not just see now-playing.

Answer: b (Full browsing)

Decision: Android Auto must support both playback controls and browsable content browsing.

---

### L2

Status: current

Question: What should the Android Auto browse tree structure look like?

Recommended Answer:
```
Root
├──▶ Playlists   → [list of playlists] → songs in playlist
├──▶ Artists     → [list of artists]   → songs by artist (randomized)
├──▶ Albums      → [list of albums]    → album tracks
└──▶ Favorites   → starred songs + songs in starred albums
```

Answer: ok

Decision: The AA browse tree must follow this structure with four top-level categories.

---

### L3

Status: current

Question: Should the app use audio_service's built-in browsable content support (BrowseMediaSource) or the custom native MediaPlaybackService.kt?

Recommended Answer: Use audio_service's built-in BrowseMediaSource support via the Dart AudioPlayerHandler. Remove the custom MediaPlaybackService.kt and its MethodChannel bridge. audio_service already implements MediaBrowserService natively.

Answer: Yes, remove custom native code.

Decision: Rely on audio_service for AA browsing. Remove MediaPlaybackService.kt, FlutterMediaChannel.kt, and the MethodChannel from AudioPlayerHandler.

---

### L4

Status: current

Question: How should offline availability work?

Recommended Answer: Explicit download — users choose content (playlists, albums, artists) to download for offline use from the phone app. Downloaded content stays until explicitly removed.

Answer: ok

Decision: Offline content is managed via explicit user-initiated downloads. No automatic caching of played songs.

---

### L5

Status: current

Question: Where should downloaded audio files be stored?

Recommended Answer: App's internal documents directory via path_provider (getApplicationDocumentsDirectory()). Keeps files private, no runtime storage permissions needed.

Answer: ok

Decision: Downloaded audio files must be stored in the app's internal documents directory.

---

### L6

Status: current

Question: Should there be a storage limit for offline content?

Recommended Answer: Yes, a user-configurable limit shown on the Downloads page. When the limit is reached, block new downloads with a clear message and a link to manage space.

Answer: ok

Decision: A user-configurable storage limit must exist. When reached, block new downloads and show a message linking to the Downloads page.

---

### L7

Status: current

Question: Should downloads support background downloading and queuing?

Recommended Answer: Yes to both. Downloads should run in the background (using workmanager or flutter_background_service). Multiple items can be queued. Queue persists across app restarts. 2 concurrent downloads max. Partial files on failure are deleted.

Answer: ok

Decision: Background downloads with a persistent queue, 2 max concurrent, partial files deleted on failure.

---

### L8

Status: current

Question: Where should the download UI live in the phone app?

Recommended Answer: Both — add download buttons to existing browse pages (Artists, Albums, Playlists, Favorites) AND add a new "Downloads" entry on the menu page for viewing/managing offline content.

Answer: ok

Decision: Download controls on browse pages + dedicated Downloads page accessible from the menu.

---

### L9

Status: current

Question: Should downloaded files be transcoded to a compact format or kept in the original server format?

Recommended Answer: Original server format. No transcoding — avoids quality loss, extra dependencies, and complexity.

Answer: ok

Decision: Downloaded audio files must be stored in the original format served by the Subsonic server.

---

### L10

Status: current

Question: Should the AA browse tree work when the device is fully offline?

Recommended Answer: Yes — when downloading content (playlist/album/artist), also cache the metadata needed to display it in the AA browse tree. This enables full offline browse of all downloaded content without any network.

Answer: ok

Decision: AA browse metadata must be cached alongside downloaded files so the browse tree is fully functional offline.

---

### L11

Status: current

Question: Should we keep or remove the custom MediaPlaybackService.kt?

Recommended Answer: Remove it. It duplicates what audio_service's AudioService already provides (MediaBrowserService). Also remove FlutterMediaChannel.kt and the MethodChannel from AudioPlayerHandler.

Answer: ok

Decision: Remove MediaPlaybackService.kt and FlutterMediaChannel.kt. Remove the MethodChannel from AudioPlayerHandler.

---

### L12

Status: current

Question: When browsing an Artist on AA, should songs be shown in random order or fixed order?

Recommended Answer: Random order, consistent with the phone app's existing randomized behavior.

Answer: ok

Decision: Artist songs in the AA browse tree must appear in random order (shuffled each time).

---

### L13

Status: current

Question: When deleting downloaded content, should metadata only or metadata + files be removed?

Recommended Answer: Remove both metadata and all associated audio files.

Answer: ok

Decision: Deleting downloaded content must remove both the metadata reference and all local audio files.

---

### L14

Status: current

Question: On AA, when "Play Similar" (Random by Playing) is triggered, should it replace the current queue or append?

Recommended Answer: Replace the current queue with similar songs, starting with the current song first (matching the phone app's behavior).

Answer: ok

Decision: "Play Similar" on AA must replace the current queue, starting with the current song.

---

### L15

Status: current

Question: Download queue ordering — FIFO or reorderable?

Recommended Answer: FIFO (first added = first downloaded). Reordering can be added later.

Answer: ok

Decision: Download queue processes items in FIFO order.

---

### L16

Status: current

Question: How should failed downloads be handled?

Recommended Answer: 3 auto-retries with backoff, then mark as failed. User can manually retry from the Downloads page.

Answer: ok

Decision: Downloads auto-retry up to 3 times, then show as failed with a manual retry option.

---

### L17

Status: current

Question: Where should the storage limit configuration live?

Recommended Answer: On the Downloads page itself — a "Used: X GB / Limit: Y GB" display, tappable to change the limit.

Answer: ok

Decision: Storage limit configuration must be accessible from the Downloads page.

---

### L18

Status: current

Question: Should the user get a notification when background downloads complete?

Recommended Answer: Yes — a notification like "Album X downloaded" or "3 downloads complete".

Answer: ok

Decision: System notifications must be sent when background downloads complete.

---

### L19

Status: current

Question: Should the "Play Similar" action be a primary button on AA or in the overflow menu?

Recommended Answer: In the overflow menu initially — keeps main playback controls clean.

Answer: ok

Decision: "Play Similar" must appear as a custom action in the Android Auto overflow menu.

---

### L20

Status: current

Question: When browsing a Playlist or Album on AA and tapping a song, should the full container be shuffled or played in order?

Recommended Answer: Shuffle the entire container (consistent with the "random" identity of the app).

Answer: ok

Decision: Tapping a song in a Playlist or Album on AA must shuffle the full container and start playback from the selected song.

---

### L21

Status: current

Question: When browsing Artists on AA, should all songs or a random subset be shown?

Recommended Answer: All songs by that artist. The "random" aspect applies to playback ordering, not the displayed list.

Answer: All songs

Decision: Artist browsing on AA must fetch and display all songs by that artist.

---

### L22

Status: current

Question: Should the audio_service package be upgraded if needed for AA compatibility?

Recommended Answer: Yes, upgrade to the latest compatible version.

Answer: ok

Decision: Upgrade audio_service (and just_audio_background if needed) to versions that properly support Android Auto browsing.

---

### L23

Status: current

Question: Should the Spec cover online AA functionality and offline together in one Spec?

Recommended Answer: Yes — the Spec covers both online Android Auto (browsing + playback) and offline support (download, storage, AA browse from cache).

Answer: ok

Decision: Single Spec covering both online AA and offline support.

---

### L24

Status: current

Question: How should the storage limit be enforced?

Recommended Answer: Block new downloads when the limit is reached. Show a clear error message with a link to the Downloads page to manage space.

Answer: ok

Decision: When storage limit is reached, block new downloads and display a link to manage space.

---

### L25

Status: current

Question: Should the app download the audio files in their original format from the server, or transcode them to save space?

Recommended Answer: Original format. No transcoding.

Answer: ok

Decision: Downloaded files store the original server format.

---

### L26

Status: current

Question: When the app is offline, should the AA browse tree still be usable?

Recommended Answer: Yes. Cache metadata for all downloaded content so it appears in the AA browse tree even without network.

Answer: ok

Decision: Metadata cache must support fully offline AA browsing for downloaded content.
