---
type: Work Item
title: Degrade to the downloaded library when the server is unreachable
parent: ../spec.md
---

## What to build

- A local catalogue built from the download metadata (`download_queue`,
  `download_metadata_<item>`, `song_<id>`): downloaded songs plus the containers
  they belong to.
- Library tabs fall back to it when the server call fails: Songs shows the
  downloaded songs, Albums and Artists list the downloaded containers, each
  opening a page that plays them from local files.
- A banner states that the server is unreachable and offers Retry, which
  re-runs the network request.
- Requests time out (15 s) so an unreachable server fails fast instead of
  spinning.

## Required context

- `DownloadService` already stores the song metadata and resolves local paths, and
  `PlayerService._enqueueSongs` plays downloaded files first.
- The Downloads page lives in an `IndexedStack` built at startup, so it must
  listen to the service to show a restored queue.

## Acceptance criteria

- [x] With no network, Songs lists the downloaded songs and Albums/Artists list the downloaded containers.
- [x] Tapping a downloaded container opens its tracks and plays them from local files.
- [x] The banner explains the fallback and Retry restores the online lists.
- [x] A dead server fails within the request timeout instead of hanging.
- [x] The Downloads page shows the restored queue (MTV Unplugged included) and the real used space.

## Covers

- User Stories: 9, 10
- Requirements: 27
- Interview Ledger: L10

## Blocked by

None - ready to start

## Notes

Verified on the Poco in airplane mode: Songs showed the downloaded tracks with
the banner, Albums listed 00.info / 52nd Street / MTV Unplugged, opening MTV
Unplugged played "You Learn" from `offline_music/*.mp3` (12 local sources), and
Retry brought the online album list back. The Downloads page now reports 2.2 GB
used and all four items; before the fix it showed "No downloads yet" because it
never rebuilt after the service restored its queue.

Known issue found while testing: `restoreSongs` logs an unhandled
"Source error" from `setAudioSources` on startup in airplane mode; the track then
plays correctly after tapping, so it is a restore-time race worth a separate look.
