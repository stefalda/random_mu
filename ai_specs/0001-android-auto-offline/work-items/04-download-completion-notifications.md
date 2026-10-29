---
type: Work Item
title: Notification when a download completes
parent: ../spec.md
---

## What to build

Post a system notification when an offline download finishes.

- Add `flutter_local_notifications` (already resolvable from the local pub cache) and a small
  `NotificationService` wrapper with its own channel (separate from the audio playback channel).
- Show one notification per completed item ("Playlist 'X' downloaded") and a summary when several
  items complete close together ("3 downloads downloaded").
- Show a notification for failed items too, so a background failure is visible.
- Request the Android 13+ `POST_NOTIFICATIONS` permission once, without blocking the UI.
- Keep it optional at runtime: if permission is denied or the plugin is unavailable, downloads must
  keep working silently.

## Required context

- `android/app/src/main/AndroidManifest.xml` already declares `POST_NOTIFICATIONS`.
- `flutter_local_notifications` 22.x requires Android core library desugaring; add
  `coreLibraryDesugaringEnabled = true` and the `desugar_jdk_libs` dependency to
  `android/app/build.gradle`.
- `DownloadService` marks an item `completed`/`failed` in `_processItem`; that is the single place
  to emit notifications.
- The audio `AudioService` channel id is `com.ryanheise.bg_demo.channel.audio`; use a different id
  (e.g. `random_mu_downloads`).

## Acceptance criteria

- [x] Completing a download posts a notification naming the item.
- [x] Several completions within a short window produce a summary notification instead of one per
      item.
- [x] A failed download posts a failure notification with the item name.
- [x] Downloading still works when notifications are denied/unavailable.
- [x] Desugaring is configured so the Android release build compiles.
- [x] `NotificationService` formatting logic is unit tested.

## Covers

- User Stories: 11
- Requirements: 26
- Interview Ledger: L18

## Blocked by

None - ready to start

## Notes

Verified on device: completing the "00.info" download posted "Playlist '00.info' downloaded" on the
`random_mu_downloads` channel. The permission is requested lazily on the first download through
`permission_handler`, so a denied permission never blocks downloads.
