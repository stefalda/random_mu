---
type: Work Item
title: Star songs and albums from the app
parent: ../spec.md
---

## What to build

- A favourite toggle per track row (in the shared `TrackList`, so it works in
  album, artist, playlist, genre, search, favorites and queue views) and one for
  the album in its detail header.
- Both call the Subsonic `star`/`unstar` endpoints and update the server; the
  icon flips optimistically and reverts with a snackbar when the call fails.
- The star state comes from the models (`Song.starred`, `Album.starred`).
- After a change, the favorites tab reloads and the Android Auto `Favorites`
  browse node is invalidated.

## Required context

- Navidrome rejects `star?songId=…` with "Required id parameter is missing": the
  generic `id` parameter must always be sent (verified against Navidrome 0.64.2).
- `BrowseCache` and `AudioPlayerHandler.clearBrowseCache()` already exist for the
  Android Auto tree; favorites are the `favorites` node.
- `starredProvider` (FutureProvider) backs the favorites tab.

## Acceptance criteria

- [x] A track can be starred and unstarred from any list; the server reflects it.
- [x] An album can be starred and unstarred from its detail header.
- [x] The icon reflects the server state and reverts if the call fails.
- [x] The favorites tab shows a newly starred song and drops an unstarred one.
- [x] The Android Auto favorites node is invalidated after a change.

## Covers

- User Stories: 9, 10
- Requirements: 24, 25
- Interview Ledger: L10

## Blocked by

None - ready to start

## Notes

Verified on the Poco against Navidrome: starring a track took the starred songs
from 33 to 34 and the song appeared in Preferiti; unstarring returned to 33 and
the row icon went back to the outline; the album header toggled the album's
`starred` timestamp. Test data was reverted afterwards.
