# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Slay the Flutter** is a Flutter deckbuilding roguelike card game (Android/iOS). Each run starts with a 10-card default deck and progresses through stages 1→2→3→Boss. Cards, relics, and mechanics unlock permanently via an XP/level system. See `SPECS.md` for full game rules and `AGENTS.md` for mandatory coding principles.

## Commands

```bash
# Dependencies
flutter pub get

# Run (debug)
flutter run
flutter run -d <device-id>

# Lint — must pass with 0 warnings before every commit
flutter analyze

# Format
dart format lib/ test/

# Tests
flutter test                                      # all tests
flutter test test/models/card_test.dart           # single file
flutter test test/models/                         # directory
flutter test --reporter=expanded                  # verbose output
flutter test --coverage                           # generate coverage/lcov.info

# Clean rebuild
flutter clean && flutter pub get
```

## Architecture

MVVM with Riverpod. The three layers have strict import rules enforced by `AGENTS.md`:

```
lib/
├── models/        # Pure Dart — data structures + business logic only
│                  # No Flutter, no Riverpod imports allowed here
├── viewmodels/    # Riverpod Notifier/AsyncNotifier providers
│                  # Files named with _provider.dart suffix
│                  # Never imports views/
└── views/         # Widgets only — reads state, dispatches events to ViewModel
                   # No business logic; >3 lines of conditional logic → extract
```

**Provider pattern**: Use `Notifier` / `AsyncNotifier` (not deprecated `StateNotifier`). `ref.watch` is only valid inside `build()` or Widget tree. `BuildContext` must never be passed into a ViewModel.

## Test Structure

`test/` mirrors `lib/`:

```
test/
├── models/
│   ├── card_test.dart
│   ├── character_test.dart
│   ├── monster_test.dart
│   ├── quest_test.dart
│   └── battle_engine_test.dart
└── viewmodels/
    ├── battle_viewmodel_test.dart
    └── quest_viewmodel_test.dart
```

ViewModel tests use `ProviderContainer` directly — no widget tree needed:

```dart
setUp(() => container = ProviderContainer());
tearDown(() => container.dispose());
```

Coverage targets: `models/` ≥ 80% (required), `viewmodels/` ≥ 70% (recommended).

## TDD Requirement

For all game logic (damage calculation, status effects, card effects, deck mechanics): **write the test first, then implement**. This is non-negotiable per `AGENTS.md`.

## Key Game Formulas (SPECS.md)

```
Monster HP         = 20 + (stage × 10)
Monster attack     = 8 + (stage × 2)
Vulnerable damage  = base × 1.5   (received damage multiplier)
Weak damage        = base × 0.75  (dealt damage multiplier, floor the result)
Block              = absorbs damage before HP, resets to 0 on turn end
Energy per turn    = 3  |  Draw per turn = 5
```

## Code Conventions (AGENTS.md)

- All `public` classes, methods, and fields require `///` dartdoc comments explaining *why*, not what.
- Magic numbers must be extracted to named `const` values.
- TODO format: `// TODO(kang3019): description`
- Files over 300 lines should be split.
- Remove all `print()` statements before committing.
- Hardcoded strings must not live inside view logic — use a separate constants file.

## Planning Docs

| File | Contents |
|------|----------|
| `.planning/00-vision.md` | Game vision and phase roadmap |
| `.planning/01-requirements.md` | MoSCoW feature requirements |
| `.planning/02-wbs.json` | WBS task data (edit to update progress) |
| `.planning/04-schedule.md` | WBS update guide and weekly review checklist |
| `SPECS.md` | Complete game rules, card stats, map structure |
| `docs/index.html` | Gantt chart viewer (requires local HTTP server) |
