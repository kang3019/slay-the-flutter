# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

@AGENTS.md

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
flutter test test/domain/card_test.dart           # single file
flutter test test/domain/                         # directory
flutter test --reporter=expanded                  # verbose output
flutter test --coverage                           # generate coverage/lcov.info

# Clean rebuild
flutter clean && flutter pub get
```

## Architecture

4-Layer Layered Architecture + Riverpod — see `AGENTS.md` for the enforced layer rules, dependency direction, and provider conventions. Directory layout:

```
lib/
├── presentation/  # Widgets only — reads state, dispatches events to Application
├── application/   # Riverpod Notifier/AsyncNotifier providers (_provider.dart suffix)
├── domain/        # Pure Dart — game rules only, no Flutter/Riverpod imports
└── data/          # SharedPreferences wrapper — read/write only
```

## Test Structure

`test/` mirrors the Domain, Application, and Data layers of `lib/`:

```
test/
├── domain/
│   ├── card_test.dart
│   ├── player_test.dart
│   ├── monster_test.dart
│   ├── deck_test.dart
│   ├── battle_engine_test.dart
│   ├── event_test.dart
│   ├── map_generator_test.dart
│   ├── relic_test.dart
│   ├── meta_progress_test.dart
│   ├── gold_rewards_test.dart
│   └── save_slot_test.dart
├── application/
│   ├── battle_provider_test.dart
│   ├── run_provider_test.dart
│   ├── meta_progress_provider_test.dart
│   └── save_slot_provider_test.dart
├── data/
│   └── local_storage_test.dart
└── widget_test.dart
```

Application layer tests use `ProviderContainer` directly — no widget tree needed:

```dart
setUp(() => container = ProviderContainer());
tearDown(() => container.dispose());
```

Coverage targets: `domain/` ≥ 80% (required), `application/` ≥ 70% (recommended).

## TDD Requirement

For all game logic (damage calculation, status effects, card effects, deck mechanics): **write the test first, then implement**. This is non-negotiable per `AGENTS.md`.

## Key Game Formulas (SPECS.md)

```
Monster HP         = 16 + (stage × 8)   → stage 1: 24 / 2: 32 / 3: 40
Monster attack     = 8 + (stage × 2)    → stage 1: 10 / 2: 12 / 3: 14
Stage mapping      = floor 0-1 → stage 1, floor 2-3 → stage 2, floor 4+ → stage 3
Vulnerable damage  = base × 1.5   (received damage multiplier)
Weak damage        = base × 0.75  (dealt damage multiplier, floor the result)
Block              = absorbs damage before HP, resets to 0 on turn end
Energy per turn    = 3  |  Draw per turn = 5
Gold reward        = (floor + 1) + 10~14  (monster) / + 20~25 (elite) / 0 (boss)
Relic reward       = elite victory → 1 relic (auto) / boss victory → 1 relic (auto)
```

## Planning Docs

| File | Contents |
|------|----------|
| `.planning/00-vision.md` | Game vision and phase roadmap |
| `.planning/01-requirements.md` | MoSCoW feature requirements |
| `docs/wbs.json` | WBS task data (edit to update progress) |
| `.planning/04-schedule.md` | WBS update guide and weekly review checklist |
| `SPECS.md` | Complete game rules, card stats, map structure |
| `docs/index.html` | Gantt chart viewer (requires local HTTP server) |
