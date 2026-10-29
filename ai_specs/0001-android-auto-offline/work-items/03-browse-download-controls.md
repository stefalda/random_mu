---
type: Work Item
title: Download controls on the browse pages
parent: ../spec.md
---

## What to build

Let the user start, monitor and remove offline downloads from the library pages.

- Add a shared `DownloadButton` widget showing the queue state of one library item: not downloaded
  (`Icons.cloud_download_outlined`), queued (progress indicator), downloading (progress with
  percentage), completed (`Icons.check_circle`), failed (`Icons.error_outline`).
- Tapping the idle icon enqueues the item (`enqueuePlaylist` / `enqueueAlbum` / `enqueueArtist`).
- Tapping the completed icon asks for confirmation and then deletes the download and its files.
- Tapping the failed icon offers a retry (`retryItem`).
- When the storage limit is reached, block the enqueue and show the message
  "Storage limit reached. Free up space in Downloads to continue." with an action that opens the
  Downloads page.
- Wire the button into `PlaylistsList`, `AlbumsList` and `ArtistList` list tiles.
- Add a "Download All Favorites" action, placed on the Downloads page (the phone app has no
  Favorites browse page; only the "Random by Favorites" menu action), calling `enqueueFavorites()`
  and reflecting the favorites item state.

## Required context

- `lib/services/download_service.dart` — `DownloadService` is a `ChangeNotifier` registered with
  `InjectX` in `lib/main.dart`; queue items expose `type`, `sourceId`, `status`, `progress`.
- `lib/pages/downloads_page.dart` currently declares `downloadServiceProvider` inline; move the
  provider to `lib/providers/download_provider.dart` so browse pages can share it.
- `DownloadService` is a `ChangeNotifier`, so widgets must rebuild on `notifyListeners()`
  (e.g. `ListenableBuilder`).
- `SubsonicModels`: `Playlist.id/name`, `Album.id/name`, `Artist.id/name`.

## Acceptance criteria

- [x] Playlists, Artists and Albums rows show the download state icon and update live.
- [x] Tapping the idle icon enqueues exactly one download item for that library item.
- [x] Tapping the completed icon requires confirmation before deleting the download.
- [x] Tapping the failed icon retries the item.
- [x] With the storage limit reached, the tap shows the limit message and a working action that opens
      the Downloads page; nothing is enqueued.
- [x] The Downloads page offers "Download All Favorites" and shows its state.
- [x] Widget tests cover the icon states and the limit-reached message.

## Covers

- User Stories: 7, 8, 9
- Requirements: 16, 17, 18
- Interview Ledger: L8, L13, L24

## Blocked by

None - ready to start

## Notes

Verified on device: the playlist rows show idle (`cloud_download_outlined`), progress and the teal
`check_circle` states, the tap enqueues, the checkmark asks for confirmation before deleting, and
the storage card shows "Used: 49 MB / Limit: Unlimited". Widget tests cover every state plus the
limit-reached message.
