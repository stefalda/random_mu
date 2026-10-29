---
type: Work Item
title: Download engine hardening and tests
parent: ../spec.md
---

## What to build

Fix the queue engine defects and give the offline system the test coverage the Spec requires.

Defects to fix in `lib/services/download_service.dart`:

- `_processQueue` picks work with `_queue.firstWhere(..., orElse: () => _queue.first)`, which can
  re-select an item that is already active instead of advancing FIFO, and `_isRunning` is cleared
  before the launched work completes.
- Retry backoff is `5s * attempt` (5s, 10s, 15s) instead of the specified 5s, 15s, 45s, and the
  attempt counter leaks across songs of the same item.
- No pre-check of the next item's size against the storage limit; the limit is only noticed after a
  song finishes.
- Files are written directly with the final name, so an interrupted write can leave a partial file.
- 16 `unawaited_futures` analyzer findings.

Required implementation:

- Introduce Test Seams: injectable `http.Client`, injectable storage directory resolver, injectable
  retry delays, and overridable `fetchSongsFor(item)` / `fetchSongBytes(song)`.
- Download each song to `<songId>.<suffix>.part`, then rename on success; delete the `.part` file on
  failure or when the item fails.
- Extract the pure queue decisions (next queued item, concurrency, limit blocking, retry delay) so
  they can be unit tested without I/O.

Tests:

- Unit: FIFO ordering, max 2 concurrent, retry-then-success, failure after 3 attempts with
  exponential backoff, partial file removed, storage limit blocking, queue persisted and restored
  across restarts (in-progress items return to `queued`).
- Unit: `DownloadItem`/`StorageInfo` JSON round-trip and formatting.
- Widget: `DownloadsPage` renders queue statuses, storage card and limit message.
- Full suite must pass and `flutter analyze` must be clean for the touched files.

## Required context

- `lib/services/download_models.dart` — `DownloadItem`, `DownloadStatus`, `StorageInfo`.
- `lib/services/download_service.dart` — current queue implementation.
- `lib/pages/downloads_page.dart` — page under widget test; it resolves `DownloadService` through a
  provider that can be overridden.
- Tests can seed persistence with `SharedPreferences.setMockInitialValues`; `path_provider` must not
  be hit in unit tests (use the injected directory resolver with a temp directory).

## Acceptance criteria

- [ ] FIFO order and the 2-concurrent cap are covered by passing tests.
- [ ] Retry backoff is 5s, 15s, 45s; a fourth failure marks the item failed with the error message.
- [ ] A failed song leaves no `.part` or final file behind.
- [ ] The storage limit is checked before starting an item and between songs.
- [ ] Queue state survives a restart and in-progress items come back as `queued`.
- [ ] `flutter analyze` reports no `unawaited_futures` in `download_service.dart`.
- [ ] `flutter test` passes.

## Covers

- Requirements: 19, 20, 21, 22, 23, 27, 28, 29, 30, 31
- Interview Ledger: L6, L7, L15, L16, L17, L24

## Blocked by

03-browse-download-controls.md
