---
type: Spec
title: Library Browsing and Playback Mode
---

## Problem

The app can only be driven through commands. The home screen is a `MenuPage` with seven buttons that each start playback immediately (`All Random`, `Random by Playlist`, `Random by Artist`, `Random by Album`, `Random by Favorites`, `Random by Playing`, `Downloads`), and the only browsable lists (Artists, Albums, Playlists) are flat indexes whose rows start a randomized playback on tap. There is no album detail, no artist detail, no playlist detail, no track list anywhere except the play queue, and therefore no way to look at a library the way a music app usually allows.

Two consequences:

- Playback is always random. Tapping an album, an artist or a playlist shakes the whole container; there is no way to listen to an album in track order or to a playlist in its saved order, and no visible control to choose.
- There is no place to act on a track. Adding a song to a playlist is only possible from the queue (long press), because that is the only screen that lists tracks.

Additionally, the three browse pages share a single `searchControllerProvider`, so the Playlists page shows a field labelled "Search artists…" that filters the artists provider.

## Proposed Outcome

A traditional library browsing experience, with sequential or randomized playback as a mode the user controls:

1. A shell with bottom navigation: **Libreria**, **Playlist**, **Downloads**, **Cerca**. The app opens on **Libreria**. [L4][L9]
2. **Libreria** has four tabs: **Artisti**, **Album**, **Preferiti**, **Generi**, each loading from the server and keeping its own instant local filter. [L3][L9]
3. Tapping an album, an artist or a playlist opens a **detail page** with cover, metadata and an ordered track list; container actions (Riproduci, Casuale, Accoda, Scarica, Aggiungi a playlist) live in the detail header. [L9]
4. Tapping a track plays its container starting at that track, in the current **playback mode**; long-pressing a track opens the track actions. [L9]
5. The **playback mode** is `Sequenziale` or `Casuale`. It is persisted, restored at startup, and switchable from the player page, from the detail pages and from Android Auto. [L1][L2][L7]
6. Changing mode while a queue is playing reorders that queue immediately without interrupting playback. [L6]
7. Adding a track to a playlist is possible from every track list, including while browsing, with the same playlist picker (which also allows creating a playlist on the fly). [L10]
8. The playlist detail removes tracks and appends new ones. [L11]
9. A global search covers Artists, Albums and Tracks. [L3]
10. The old random actions remain available as one-shot commands under a **Casuale** entry, and no longer change the persisted mode. [L4][L8]

## User Stories

1. As a listener, I want to browse my library by artist, album, favorites and genre, so that I can find something specific instead of only rolling the dice.
2. As a listener, I want to open an album and see its track list in the album's order, so that I can listen to it as the artist intended.
3. As a listener, I want to open an artist and choose between its albums and all of its tracks.
4. As a listener, I want to open a playlist and see its tracks in the saved order.
5. As a listener, I want to tap a track and have the container play from there, without everything being shuffled.
6. As a listener, I want to switch between sequential and shuffled playback at any time, and have the app remember my choice next time.
7. As a listener, I want to switch that mode from the car screen while I drive, and see the app follow.
8. As a listener, I want to toggle shuffle while music is playing and hear the queue reorder immediately, keeping the current song.
9. As a listener, I want to add the song I am looking at (or listening to) to a playlist without leaving the list I am browsing.
10. As a listener, I want to remove a track from a playlist and create a playlist on the fly from a song.
11. As a listener, I want to search the whole library by artist, album or track.
12. As a listener, I still want the old random commands available when I do want to leave it to chance.

## Requirements

### Playback mode

1. Two modes exist: `Sequenziale` and `Casuale`. They define how a container becomes a queue when playback starts. [L9]
2. The mode is persisted in preferences and restored at startup; when no preference exists the mode is `Sequenziale`. [L1]
3. Starting a container (album, artist, playlist, favorites, genre, search result set) builds the queue as follows:
   - `Sequenziale`: queue = container order, current index = the tapped track.
   - `Casuale`: queue = container order shuffled; when a track was tapped it stays first, otherwise playback starts from a random track. [L12]
4. The title bar toggle (requirement 5) and the player control both show the current mode with the same glyph pair used by the Android Auto action and switch it. [L12]
5. The playback mode has a single control: a toggle in the title bar, visible in the library and in the detail pages, whose icon shows the current mode (shuffle when `Casuale`, list+play when `Sequenziale`, matching the Android Auto action). Detail pages have no separate "Casuale" button: `Riproduci` follows the toggle. [L12]
6. The one-shot random commands (`All Random`, `Random by Playlist`, `Random by Artist`, `Random by Album`, `Random by Favorites`, `Random by Playing`) produce a shuffled queue without changing the persisted mode. [L8]
7. Changing mode while a queue is playing reorders the existing queue immediately:
   - to `Casuale`: the current track keeps its position in the listening order and the remaining tracks are shuffled;
   - to `Sequenziale`: the queue returns to the order the container was started with, positioned on the current track.
   The audio must not stop, restart from zero, or lose its position. [L6]
8. The original order of the current queue is kept in memory while the app runs, so requirement 7 is reversible more than once. For queues that do not come from a container (Play Similar results, a restored session) that order is the order they were queued in. [L6]

### Android Auto

9. The Android Auto browse and playback behaviour follows the current mode instead of always shuffling containers. Tapping a track in the car starts its container according to requirements 3 and 7. [L2]
   - This supersedes Spec `0001-android-auto-offline` requirements 2, 3 and 4, which mandated shuffling the playlist, artist and album containers unconditionally.
10. The media session publishes the current mode as `shuffleMode` (`all` for `Casuale`, `none` for `Sequenziale`) and declares the standard `setShuffleMode` system action. Because Android Auto 17.x does not render the platform shuffle control in its media bar, the mode is also exposed as a custom action whose icon and label describe the next state; it is declared before "Play Similar" so it stays visible in the bar. [L7]
11. A `setShuffleMode` call coming from the car is treated exactly like a mode change in the app: it updates the persisted mode, the app UI and the queue ordering. [L2][L6][L7]
12. The existing "Play Similar" custom action keeps working unchanged.

### Library navigation

13. The app shell has four destinations — Libreria, Playlist, Downloads, Cerca — and opens on Libreria. [L4][L9]
14. Libreria exposes five tabs: Artisti, Album, Brani, Preferiti, Generi. [L12] Artisti and Album are alphabetical with a visible index/scroll affordance; Preferiti groups starred tracks, albums and artists; Generi lists genres. [L9]
15. Each list keeps a local instant filter driven by its own state; a page must never drive another page's filter. [L3]
16. The random commands (`All Random`, `Random by Playing`, `Random by Favorites`) are reachable from a `Casuale` entry in Libreria and no longer from a first-screen button list. [L4]
17. `Cerca` performs a global server search and shows Artists, Albums and Tracks sections; track results support the same track actions. [L3]

### Detail pages and track lists

18. Album detail: cover, title, artist, year, track list in album order, header actions (Riproduci, Casuale, Accoda, Scarica, Aggiungi a playlist).
19. Artist detail: artist header, albums grid, and an "all tracks" entry listing the artist's tracks in album order.
20. Playlist detail: playlist name, cover if available, track list in playlist order, header actions, and per-track removal. [L11]
21. A single `TrackList` widget is used by album detail, artist detail, playlist detail, favorites, genre, search results, queue and downloads, so that behaviour is identical everywhere. [L9]
22. Tap on a track row starts its container according to the current mode (requirement 3).
23. Long press on a track row opens the track actions: Riproduci ora, Riproduci dopo, Accoda, Aggiungi a playlist, Scarica, Testo, plus "Vai all'album" / "Vai all'artista" when the context allows. [L9]
24. "Aggiungi a playlist" from any track list uses the existing playlist picker, including the "create a playlist with this song" path. [L10]
25. Removing a track from a playlist uses `updatePlaylist` with `songIndexToRemove` computed from the position in the playlist order currently displayed; the list refreshes after the removal and the Android Auto caches for that playlist are invalidated. [L11]
26. Playlist track reordering is not supported and must not be offered as an affordance. [L11]

## Technical Decisions

- `PlaybackMode` is owned by `PlayerService` and persisted through `PreferenceService` (single source of truth). Both the app UI and the `AudioPlayerHandler` read and write it through the service. [L1][L2]
- `PlayerService` keeps the current queue's original order in memory (`_queueSongs`) alongside the `AudioPlayer` sequence, so `setMode` can reshuffle or restore without re-fetching the container. [L6]
- Container playback funnels through one entry point (`playContainer(songs, startAt)`) that applies the mode; `playSongsStartingAt` and the random commands are thin wrappers, so no playback path bypasses the mode. [L8][L9]
- `AudioPlayerHandler` publishes `shuffleMode` in `PlaybackState`, adds `MediaAction.setShuffleMode` to `systemActions`, and implements `setShuffleMode` by delegating to `PlayerService.setMode`. Android Auto therefore uses the platform control. [L7]
- Library data comes from existing client calls: `getArtists`, `getAlbum` + `getSongsByAlbum`, `getArtist` + `getSongsByAlbum`, `getStarred`, `getGenres` + `getSongsByGenre`, `getPlaylist` + `getPlaylistSongs`, `search3`. `getAlbumList2` paginates the Album tab. [L9]
- Large lists are loaded page by page: albums via `getAlbumList2` (60 per page, server sorted) and songs via `search3` with an empty query (200 per page), triggered by scrolling with a deduplication guard; the Artist index stays a single `getArtists` call because the API does not paginate it, and the Android Auto browse tree still loads complete lists because the car does not paginate node children. [L13]
- Riverpod: one `AsyncNotifier` per library surface (artists, albums with pagination, favorites, genres, search) with its own filter state, replacing the shared `searchControllerProvider`. [L3]
- The playlist picker, playlist name dialog and the playlist mutations from Spec `0002`'s predecessor work (`createPlaylist`, `renamePlaylist`, `deletePlaylist`, `addSongsToPlaylist`) are reused as-is; the detail page adds `removeSongsFromPlaylist(indexes)`. [L10][L11]

## Testing Strategy

Unit tests (no network, fake `SubsonicClient`):

- Mode persistence: default `Sequenziale` when the preference is absent, restored value when present.
- `playContainer` with `Sequenziale` keeps container order and the tapped index; with `Casuale` keeps the tapped track first and shuffles the rest.
- `setMode` reorder: current track stays current, position preserved in both directions, and two consecutive toggles return to the original order.
- Random commands do not mutate the persisted mode.
- Playlist removal computes indexes from the displayed order and invalidates the AA caches.

Widget tests:

- `TrackList` long press opens the action sheet with the expected entries for each context (album vs queue vs playlist).
- Playlist detail removes a row and refreshes.
- Library tabs keep independent filters (regression for the shared controller bug).

Manual device checks (Poco F1, Navidrome):

- Album, artist and playlist details render ordered track lists; tap starts from the tapped track in the current mode.
- Toggle shuffle while playing: audio keeps playing, queue reorders, current track unchanged; toggle back restores order.
- Restart app: mode restored.
- Android Auto (Desktop Head Unit): gesture shuffle control present, reflects app mode, and changing it from the car reorders the queue and updates the app; browse containers follow the mode.

## Out of Scope

- Multi-select of tracks for bulk operations. [L5]
- Reordering tracks inside a playlist (not supported by the Subsonic API). [L11]
- Gapless playback, crossfade, and per-genre smart queues.
- Offline caching of library pages beyond what the download feature already produces.
- Lyrics changes: the lyrics page added with the playlist work is reused from the track actions unchanged.

## Open Questions

- Should the Library tabs use an alphabetical index ribbon (fast scroller) on the right edge, or a simple scroll list?
- Should `Preferiti` show starred albums as navigable cards or as a flat list of their tracks?
- When the queue was produced by `Play Similar`, is "Sequenziale" meaningful for the user, or should the toggle be hidden in that case?

## Follow-Ups

- Multi-select bulk add to playlist (deferred from L5).
- Save the current queue as a playlist (natural next step now that playlist creation exists).
- Consider pagination and pull-to-refresh polish for very large libraries.

## Notes

- The app is called "Random Muu" and its identity is random playback; `Sequenziale` becomes the first-run default for browsing predictability, while the random identity lives in the `Casuale` entry and the shuffle toggle. [L1]
- Two defects observed in the current code and fixed as part of this work: the shared `searchControllerProvider` across browse pages, and the `Header` widget overflowing in narrow AppBars.
- Android Auto caches browse nodes in memory (5 minute TTL) and in preferences; playlist mutations already invalidate them, and the new detail pages must do the same for track removals.
