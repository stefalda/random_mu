---
type: Work Item
title: Remove the command menu and the shared search state
parent: ../spec.md
---

## What to build

- Delete `MenuPage` and the pages/providers that are no longer reachable.
- Consolidate the `Casuale` entry: no duplicated random commands.
- Remove the shared `searchControllerProvider` usages and the mislabelled search fields.
- Update `README.md` to describe the new navigation and the playback mode.

## Required context

- `lib/pages/menu_page.dart` hosts the seven buttons; `lib/main.dart` exposes
  `searchControllerProvider`, `menu` navigation and the providers.
- `README.md` documents Android Auto, offline downloads and local-first playback.

## Acceptance criteria

- [ ] No reference to `MenuPage` or `searchControllerProvider` remains.
- [ ] All random commands are reachable only from the `Casuale` entry (and the player).
- [ ] `flutter analyze` and `flutter test` are clean.
- [ ] README describes the four destinations, the details and the playback mode.

## Covers

- Requirements: 15, 16
- Interview Ledger: L3, L4

## Blocked by

3, 4, 5, 6, 7
