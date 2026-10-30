# Random Muu(sic)

<img src="./assets/icon_round_purple.png" alt="App Icon" width="200" height="200">

Random Muu is a Flutter music player for Subsonic-compatible servers. It browses
your library the traditional way — artists, albums, favorites, genres, playlists,
search — and plays it **sequentially or shuffled**, a mode you choose and the app
remembers. When you do want to leave it to chance, the one-shot random commands
are one tap away:

- **All Random**
- **Random by Playing**
- **Random by Favorites**

It also works while driving: **Android Auto** support with a browsable library,
and an **offline mode** where playlists, albums, artists and favorites can be
downloaded and played without a network connection.

Currently, the app has been tested on **Web** and **Android** platforms, with
**Navidrome** as the Subsonic-compatible server.

[Icon](https://thenounproject.com/icon/cow-7450755/) by
[Made x Made](https://thenounproject.com/creator/christian933/)

The app should be considered a POC, I've scaffolded the code using different
LLMs (ChatGPT and Claude), to check how they perform but some code could be
optimized.

## Features

- **Library browsing**: bottom navigation with Libreria (Artists, Albums,
  Favorites, Genres), Playlist, Downloads and Cerca; album, artist and playlist
  detail pages with ordered track lists.
- **Playback mode**: sequential or shuffled, persisted across restarts, switchable
  from the player and from Android Auto; changing it reorders the live queue
  without interrupting playback.
- **Track actions**: long press any track to play it now, play it next, queue it,
  add it to a playlist, or read its lyrics.
- **Random Music Selection**: one-shot random commands for when you want to roll
  the dice.
- **Subsonic API Integration**: Fully integrates with the Subsonic API
  (Navidrome supported).
- **Playlists on the server**: create, rename and delete playlists, add tracks
  while browsing and remove them from the playlist detail — all written through
  to Navidrome.
- **Favorites**: star/unstar any track (every list) and any album from its detail
  page; the change is written to the server.
- **Android Auto**: browse Playlists, Artists, Albums, Favorites, Songs and
  Downloads on the car screen, with now-playing metadata, artwork, a mode toggle,
  "Play Similar" and search (also offline, over the downloads).
- **Offline downloads**: download playlists, albums, artists or all favorites and
  keep listening with no connection.
- **Local-first playback**: downloaded songs are played from the phone, only the
  missing ones are streamed.
- **Lyrics**: synced lyrics when the server provides them, with the current line
  highlighted and followed.
- **Works offline**: when the server is unreachable the library degrades to what
  is downloaded, with a banner and a retry, and playback uses the local files.
- **English and Italian**: all UI text is localized, following the device
  language.
- **Cross-Platform**: Currently tested on Web and Android.

## Web

This is the usable web version:

[Web version](https://stefalda.github.io/random_mu/)

while the android apks can be downloaded from the
[Releases](https://github.com/stefalda/random_mu/releases) section.

On the web everything works except the Android-only parts: **offline downloads**
(the Downloads tab explains it) and **Android Auto**. Playback uses the browser's
audio stack and publishes the Media Session, so the browser's own media controls
work too. The server must allow CORS for the app's origin (Navidrome does).

## Setup and Installation

### Prerequisites

1. Flutter 3.x or later installed on your machine.
2. A running **Navidrome** instance or any compatible Subsonic server (I guess).
3. Access to your Subsonic server credentials (username and password).
4. For Android builds: Android SDK 36+ with the JDK bundled with Android Studio
   (the project uses Gradle 9 / AGP 9 / Java 17 bytecode).

### Clone the Repository

```bash
git clone https://github.com/stefalda/random-mu.git
cd random-mu
```

### Install Dependencies

Ensure you have the Flutter environment set up. Install the required
dependencies by running:

```bash
flutter pub get
```

### Run the Application

For **Web**:

```bash
flutter run -d chrome
```

For **Android**:

```bash
flutter run -d android
```

### Checks

```bash
flutter analyze                                     # must stay clean
flutter test                                        # unit + widget tests
flutter build apk --debug                           # Android build
```

## Features and Usage

- **Libreria**: browse Artists (alphabetical), Albums, Favorites (tracks, albums,
  artists) and Genres; every list has its own instant filter.
- **Album / Artist / Playlist**: cover, metadata and the track list in the
  container's own order, with `Riproduci`, `Casuale`, `Accoda`, `Scarica`.
- **Playback mode**: the shuffle toggle in the player switches between
  `Sequenziale` and `Casuale`; the choice is remembered and applies to the queue
  that is already playing.
- **Track actions** (long press in any list): Riproduci ora, Riproduci dopo,
  Accoda, Aggiungi a playlist, Testo.
- **Playlist**: create a playlist from the Playlists page, rename or delete it
  from the row menu, add tracks while browsing and remove them from the playlist
  detail.
- **Cerca**: global search over Artists, Albums and Tracks (`search3`).
- **Casuale** (shuffle button in the Libreria app bar): the one-shot commands
  `All Random`, `Random by Playing` and `Random by Favorites`. They never change
  the persisted playback mode.
- **Downloads**: download content for offline playback, see below.

## Android Auto

The car UI is served by `audio_service`, which implements Android's
`MediaBrowserService`; the browse tree is defined in Dart
(`lib/client/audio_player_handler.dart`) and needs no native media browser code.

Root categories:

```
Root
├── Playlists  → songs of the playlist
├── Artists    → all songs by the artist
├── Albums     → tracks of the album
├── Favorites  → starred songs + songs of starred albums
├── Songs      → the library's songs (first 500, server order)
└── Downloads  → the downloaded songs, playable offline
```

With six categories Android Auto groups the last ones under **More**.

Behaviour:

- Tapping a song inside a playlist, album or artist starts its container from the
  song you tapped **according to the current playback mode**: in `Sequenziale` the
  container plays in order, in `Casuale` it is shuffled. The browse lists always
  show the container order.
- The playback mode is published as the session `shuffleMode` and can be switched
  from the car with the mode action next to "Play Similar".
- The media bar exposes the **mode toggle** (sequential / shuffled) and
  **Play Similar** ("Random by Playing"), which replaces the queue with similar
  songs and starts from the current one.
- Now playing shows title, artist, album, artwork and progress; play/pause,
  skip and seek use the `MediaSession` managed by `audio_service`.
- Browsing works **offline** for content that was downloaded: metadata and
  artwork are cached (see below), the **Downloads** node always works without a
  connection, and playback falls back to the local files.
- The **search** affordance (magnifier) is enabled by declaring
  `android.media.browse.SEARCH_SUPPORTED` in the browser root extras
  (`AudioServiceConfig.androidBrowsableRootExtras`); when the server is
  unreachable the search runs over the downloads instead.
- The queue is reachable from the chip in the top-right of the now playing screen
  (labelled **"Metti in coda"** in Italian Android Auto).
- Playback state reports loading/buffering and the buffered position, so the car
  shows the right spinner and progress bar.
- The in-memory browse tree expires after 5 minutes: a playlist added on the
  server shows up in the car without restarting the app.

## Offline Downloads

Everything is managed by `DownloadService`
(`lib/services/download_service.dart`) and surfaced in three places: a download
icon on the library pages, a **Downloads** page, and system notifications.

### What you can download

- a **playlist** (download icon on the Playlists page),
- an **album** (download icon on the Albums page),
- an **artist**, meaning all songs by that artist (Artists page),
- **all favorites** (the cloud icon in the Downloads page app bar).

### Queue behaviour

- Items are processed **FIFO**, at most **2 at a time**.
- Each song is fetched in its **original format** (no transcoding) and written to
  the app's private storage: `getApplicationDocumentsDirectory()/offline_music/`.
- Downloads run to a `<songId>.<ext>.part` file that is renamed only on success,
  so an interrupted download never leaves a corrupt song behind. `.part` leftovers
  from a crash are removed at startup.
- A failing song is retried **3 times with backoff (5s, 15s, 45s)**; after that
  the item is marked *failed* with the error and can be retried by tapping the
  red icon (library page) or the refresh button (Downloads page).
- Progress is persisted after every song, so closing the app keeps the queue and
  its progress. In-progress items return to the queue on the next start.
- **Pause / resume**: the pause button in the Downloads page or in the
  foreground notification stops the item in flight (it goes back to the queue
  with its partial progress). Resuming continues from the next missing song:
  files already on disk are never downloaded twice.
- Deleting an item (library checkmark or Downloads page) removes its files and
  its metadata; deleting while it downloads cancels the in-flight work.

### Storage limit

A user-configurable limit (default **unlimited** in code, configurable from the
storage card on the Downloads page: 1, 2, 5, 10, 20, 50 GB or unlimited).

- The size of an item is estimated from the Subsonic song sizes **before**
  starting it: if it does not fit, the item stays queued and the app shows
  "Storage limit reached. Free up space in Downloads to continue." with a
  shortcut to the Downloads page.
- During a download the limit is checked after every song.
- The storage card shows `Used: X / Limit: Y` and a progress bar.

### Background downloads

Downloads keep running when the app goes to the background thanks to a native
foreground service (`android/app/src/main/kotlin/com/babisoft/random_mu/OfflineDownloadService.kt`),
started and stopped by `DownloadForegroundService`
(`lib/services/download_foreground_service.dart`) over a `MethodChannel`
(`com.babisoft.randommu/downloads`).

- The service is a `dataSync` foreground service with its own notification
  channel: it shows the current item and `completed/total downloads complete`.
- It has a **Pause** action that pauses the queue in the app.
- It starts only while the queue has work and the app is in the foreground
  (Android 12+ forbids starting a foreground service from the background), and it
  stops as soon as the queue drains.
- The queue itself lives in the Dart isolate: the service exists to keep the
  process alive, not to run HTTP work in a second isolate.
- On iOS/web/desktop no service is created; downloads follow the app lifecycle.

### Artwork

- Cover art is downloaded together with the songs, **once per cover id** (covers
  are shared between songs, albums and playlists), into
  `offline_music/covers/<base64(coverId)>.img`.
- `resolveArtUri()` (`lib/services/offline_source.dart`) prefers the cached file
  and falls back to the server URL, so the phone player, the queue list, the
  notification and the Android Auto now-playing screen all show covers while
  offline. `ArtworkImage` (`lib/pages/artwork_image.dart`) picks the right loader
  (`Image.file` vs `Image.network`).
- Deleting a download garbage-collects the artwork no remaining item references;
  "Clear All" removes the whole `covers` folder. Cached covers count towards the
  storage usage.

### Notifications

- One notification per completed item ("Playlist 'Chill' downloaded"), collapsed
  into a summary ("3 downloads completed") when several finish within 3 seconds.
- Failures are reported immediately with the error message.
- The Android 13+ notification permission is requested **when the first download
  starts** (`permission_handler`); if denied, downloads keep working silently.

### Offline playback (local-first)

`PlayerService._enqueueSongs` resolves every song through
`resolveSongUri()` (`lib/services/offline_source.dart`):

1. if a downloaded file exists for the song → play it from disk (`file://`),
2. otherwise → stream it from the server as usual.

The same happens for the artwork (`resolveArtUri`), so the now-playing screen and
the car keep showing covers with no connection.

The choice is transparent and identical on the phone and on Android Auto, so a
partially downloaded library simply plays the songs it has, without prompts. The
lookup uses in-memory indexes of the offline folder (`songId → file`,
`coverId → file`), rebuilt whenever storage is scanned, so a large queue does not
hit SharedPreferences for every song and a missing metadata record cannot hide an
existing file.

## Architecture Notes

| Concern | Where |
| --- | --- |
| Subsonic API client | `lib/client/subsonic_client.dart` |
| Playback + queue | `lib/services/player_service.dart` |
| Android Auto browse tree + media session | `lib/client/audio_player_handler.dart` |
| Offline browse metadata cache | `lib/services/browse_cache.dart` |
| Local file/artwork resolution | `lib/services/offline_source.dart` |
| Download queue, retries, storage limit | `lib/services/download_service.dart` |
| Download foreground service bridge | `lib/services/download_foreground_service.dart` |
| Download notifications | `lib/services/notification_service.dart` |
| Runtime permissions | `lib/services/permissions.dart` |
| Downloads UI | `lib/pages/downloads_page.dart`, `lib/pages/download_button.dart` |
| Artwork widget (file vs network) | `lib/pages/artwork_image.dart` |

The offline browse cache is primed when an item finishes downloading: the
container node (e.g. `playlist-<id>`, with the cached artwork of its first song)
and its entry inside the category node are stored, so the Android Auto tree can
be built with no network. Deleting a download removes those nodes again.

Android Auto needs no custom native code: `audio_service` provides the
`MediaBrowserService` (`AudioService` in the manifest, declared with
`foregroundServiceType="mediaPlayback"` and the `android.media.browse.MediaBrowserService`
intent filter), `res/xml/automotive_app_desc.xml` declares `<uses name="media"/>`,
`MainActivity` extends `AudioServiceActivity`, and the tree itself is Dart code in
`audio_player_handler.dart`. The commented-out `androidx.car.app:app-automotive`
dependency is only needed by apps that ship their own Android Automotive OS
templates UI, which a media app does not.

## Releasing

Releases are built and published **from this machine**: the GitHub Actions
workflow (`.github/workflows/android_build.yml`) is now manual-only
(`workflow_dispatch`), because the APK that gets published is the one verified on
a device and the CI pins an older Flutter. Creating a tag or a release no longer
triggers a second build:

```bash
# 1. bump the version in pubspec.yaml (e.g. version: 0.0.24+3)
flutter analyze && flutter test
flutter build apk --release

# 2. name the artifact like the existing releases
cp build/app/outputs/flutter-apk/app-release.apk \
   build/app/outputs/flutter-apk/RandomMuu-v.0.0.24-android.apk

# 3. publish: gh creates the tag through the API, so the workflow does NOT run
gh release create v.0.0.24 \
   build/app/outputs/flutter-apk/RandomMuu-v.0.0.24-android.apk \
   --title "v.0.0.24" --notes-file CHANGELOG.md
```

`gh` is already authenticated on this machine (`gh auth status`). Both CI
workflows (Android and web) are now **manual-only**, so creating a tag or a
release never builds a second, unverified artifact.

The web version is published the same way, by pushing the build to `gh-pages`
(GitHub's own Pages deployment runs, our workflow does not):

```bash
flutter build web --release --base-href="/random_mu/"
git worktree add /tmp/ghp origin/gh-pages
cd /tmp/ghp && git rm -rq . && cp -R <repo>/build/web/. . \
  && git add -A && git commit -m "Deploy web build" && git push origin gh-pages
```

Verify the deployment by comparing the served bundle with the local one:
`curl -s https://stefalda.github.io/random_mu/main.dart.js | shasum -a 256`.

The release build needs `android/app/key.properties` (git-ignored) and the
keystore it points to; both already exist locally.

Two release-only pitfalls that are easy to reintroduce:

- resources referenced only by name from Dart (the Android Auto action icons) are
  removed by the shrinker unless listed in `android/app/src/main/res/raw/keep.xml`;
- the media notification needs a **monochrome** small icon: `mipmap/ic_launcher`
  is an adaptive icon and Android 14+ rejects it, crashing the media service.

## Development Notes

Workflow specs, interview ledgers and work items live in `ai_specs/`.

## Supported Platforms

- Web (Tested)
- Android (Tested)

## Contributing

If you'd like to contribute to the project, feel free to fork the repository and
submit a pull request. Please ensure that your code follows the existing coding
style and includes relevant tests if applicable.

## License

This project is licensed under the MIT License – see the [LICENSE](LICENSE) file
for details.
