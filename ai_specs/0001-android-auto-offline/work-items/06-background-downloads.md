---
type: Work Item
title: Downloads continue while the app is backgrounded
parent: ../spec.md
---

## What to build

Keep the download queue processing when the user leaves the app.

- Add `flutter_background_service` and start a foreground service while the queue has active work,
  stopping it when the queue drains, so Android does not kill the app process mid-download.
- Downloads keep running in the main isolate (queue state, `DownloadService`, Riverpod providers stay
  where they are); the foreground service exists to keep the process alive and to show progress.
- Update the persistent notification with overall progress (items done / total, current item name)
  and a cancel action that pauses the queue.
- Do not start the service when nothing is queued, and never leave it running after the queue drains.
- Handle platform limits: no service on iOS/web/desktop (downloads stay in the app lifecycle).

This Work Item is the only one with platform risk (foreground service types on Android 14+). If the
plugin cannot be integrated without breaking the build, report it and leave the queue behaviour
unchanged rather than shipping a broken service.

## Required context

- `lib/services/download_service.dart` — queue processing entry points (`_processQueue`,
  notification of completion) are where the service is started/stopped.
- `android/app/build.gradle` — `targetSdk = 35`; a foreground service needs
  `android:foregroundServiceType="dataSync"` and the `FOREGROUND_SERVICE_DATA_SYNC` permission.
- `android/app/src/main/AndroidManifest.xml` already declares `FOREGROUND_SERVICE`,
  `FOREGROUND_SERVICE_MEDIA_PLAYBACK` and `WAKE_LOCK`; the audio `AudioService` already owns a media
  playback foreground service, so the download service must be a separate, separately-typed service.
- `lib/main.dart` initialises `AudioService` and `InjectX`; the background service entry point needs
  the stored connection details to build its own `SubsonicClient` if a second isolate is used.

## Acceptance criteria

- [ ] Queued downloads keep progressing while the app is backgrounded or the screen is off.
- [ ] The foreground notification shows overall progress and can pause the queue.
- [ ] The service starts only when work is queued and stops when the queue drains.
- [ ] No service is started on iOS/web/desktop.
- [ ] The Android build still compiles and `flutter analyze` is clean.
- [ ] Manual verification steps are recorded in the Work Item notes.

## Covers

- User Stories: 11, 12
- Requirements: 11, 21
- Interview Ledger: L7

## Blocked by

04-download-completion-notifications.md, 05-download-engine-hardening.md
