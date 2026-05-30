# 07-architecture-overview.md — 아키텍처 개요

**버전**: 1.0 | **생성일**: 2026-05-22 (AI Agent 자동 생성)

---

## 한 눈에 보는 아키텍처

```
┌─────────────────────────────────────────────────────────┐
│  Presentation (lib/presentation/)                        │
│  ─ Flutter 위젯만 존재                                    │
│  ─ 상태 읽기: ref.watch(provider)                        │
│  ─ 이벤트 전달: ref.read(provider.notifier).method()     │
└────────────────────┬────────────────────────────────────┘
                     │ ref.watch / notifier 호출
┌────────────────────▼────────────────────────────────────┐
│  Application (lib/application/)                          │
│  ─ Riverpod Notifier / AsyncNotifier                     │
│  ─ 상태 소유 및 비즈니스 명령 처리                        │
│  ─ Domain 서비스 호출 후 상태 emit                       │
└──────┬─────────────────────────────┬────────────────────┘
       │ 호출                         │ 호출
┌──────▼──────────┐        ┌─────────▼──────────────────┐
│  Domain         │        │  Data (lib/data/)           │
│  (lib/domain/)  │        │  ─ SharedPreferences 래퍼   │
│  ─ 순수 Dart    │        │  ─ JSON 직렬화/역직렬화      │
│  ─ Flutter 없음 │        │  ─ Application만 호출 가능  │
│  ─ 게임 규칙    │        └────────────────────────────┘
└─────────────────┘
```

**임포트 규칙 (절대 위반 금지)**

| 계층 | 임포트 가능 | 임포트 불가 |
|------|------------|------------|
| Presentation | Application | Domain, Data 직접 |
| Application | Domain, Data | Presentation |
| Domain | 없음 (순수 Dart) | Application, Presentation, Data |
| Data | Domain (엔티티만) | Application, Presentation |

---

## 계층별 상세

### Presentation 계층

역할: 화면을 그리고 사용자 입력을 Application으로 전달한다.

```
lib/presentation/
├── app_router.dart               # RunPhase에 따라 화면 교체
├── battle/
│   ├── battle_screen.dart        # 전투 메인 화면
│   ├── battle_constants.dart     # 전투 화면 상수
│   └── widgets/
│       ├── card_widget.dart      # 개별 카드 UI
│       ├── hand_widget.dart      # 손패 전체 UI
│       └── monster_widget.dart   # 몬스터 + 의도 아이콘
├── map/
│   ├── map_screen.dart           # 던전 맵 화면
│   ├── map_constants.dart        # 맵 화면 상수
│   └── widgets/
│       └── map_painter.dart      # CustomPainter DAG 렌더링
├── reward/
│   ├── reward_screen.dart        # 카드 보상 선택 화면
│   └── reward_constants.dart     # 보상 화면 상수
├── shared/
│   └── hp_bar_widget.dart        # HP/블록 바 (공용)
└── meta/                         # [미구현] 레벨·해금 화면 (예정)
    └── meta_screen.dart
```

**규칙**
- `Widget.build()` 안에 조건 로직 3줄 초과 시 별도 위젯으로 분리
- 하드코딩 문자열 금지 → `lib/presentation/constants/strings.dart` 사용
- `BuildContext`를 Application 계층으로 넘기지 않는다

---

### Application 계층

역할: 사용자 명령을 받아 Domain을 호출하고 새 상태를 emit한다.

```
lib/application/
├── battle_provider.dart          # BattleNotifier — 전투 상태 관리
├── run_provider.dart             # RunNotifier — 맵 이동·보상·런 관리
└── meta_progress_provider.dart   # MetaProgressNotifier — XP·레벨·해금
```

**BattleNotifier 공개 API**

```dart
class BattleNotifier extends Notifier<BattleState> {
  void startBattle(int stage);   // 새 전투 시작 (RunProvider가 호출)
  void playCard(GameCard card);  // 카드 사용
  void endTurn();                // 턴 종료 → 몬스터 행동 → 다음 턴
}
```

**RunNotifier 공개 API**

```dart
class RunNotifier extends Notifier<RunState> {
  void moveToNode(String nodeId);                          // 맵 이동
  void startReward({required int remainingHp,              // 일반 승리 → 보상 화면
                    required int goldEarned});
  void selectRewardCard(GameCard card);                    // 카드 선택 → 맵 복귀
  void skipReward();                                       // 보상 건너뛰기
  void exitBattleToMap({required int remainingHp,          // 보스 승리·패배 → 맵
                        required int goldEarned});
  void startNewRun();                                      // 런 초기화
}
```

---

### Domain 계층

역할: Flutter 의존 없이 순수 게임 규칙만 구현한다. 테스트 가능성의 핵심.

```
lib/domain/
├── entities/
│   ├── card.dart            # GameCard, CardType, CardEffectType
│   ├── player.dart          # Player 상태
│   ├── monster.dart         # Monster 상태 + 스탯 공식
│   └── meta_progress.dart   # MetaProgress — XP·레벨·해금 목록
├── map/
│   ├── map_generator.dart   # Act 1 맵 생성 (5층 12노드)
│   ├── map_node.dart        # MapNode 데이터 클래스
│   └── node_type.dart       # NodeType 열거형
├── battle_engine.dart       # 데미지 계산, 카드 효과, 턴 로직
├── deck.dart                # 드로우, 셔플, 버림 덱
└── status_effect.dart       # 취약/약화 열거형 + 배율 상수
```

**절대 금지**
```dart
// ❌ Domain에서 Flutter/Riverpod 임포트 금지
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
```

---

### Data 계층

역할: 로컬 저장소 읽기/쓰기를 캡슐화한다.

```
lib/data/
└── local_storage.dart       # SharedPreferences 래퍼
```

```dart
abstract class LocalStorage {
  Future<int> loadXp();
  Future<void> saveXp(int xp);
  Future<List<String>> loadUnlockedCards();
  Future<void> saveUnlockedCards(List<String> ids);
  Future<void> saveRunState(RunState state);
  Future<RunState?> loadRunState();
}
```

---

## 상태 흐름 예시 — "카드 사용"

```
1. [Presentation] 사용자가 카드를 드래그 → 드롭
2. [Presentation] ref.read(battleProvider.notifier).playCard(card)
3. [Application]  BattleNotifier.playCard(card):
     a. BattleEngine.calculateDamage(card, state.player, state.monster)
     b. state = state.copyWith(monster: updatedMonster, player: updatedPlayer)
     c. emit(state)
4. [Presentation] ref.watch(battleProvider) 변경 감지 → 화면 리빌드
```

---

## 테스트 전략 (계층별)

| 계층 | 테스트 종류 | 도구 |
|------|------------|------|
| Domain | 단위 테스트 (순수 Dart) | `flutter_test` |
| Application | Provider 테스트 | `ProviderContainer` |
| Data | 통합 테스트 (SharedPreferences 스텁) | `shared_preferences` fake |
| Presentation | 위젯 테스트 (smoke test 수준) | `flutter_test` |

---

## ADR 연결

| 결정 | ADR |
|------|-----|
| Flutter 선택 이유 | [ADR-0001](../docs/decisions/ADR-0001-mobile-platform.md) |
| Layered Architecture 채택 이유 | [ADR-0002](../docs/decisions/ADR-0002-architecture-mvvm.md) |
| Riverpod 선택 이유 | [ADR-0003](../docs/decisions/ADR-0003-state-management-riverpod.md) |
| SharedPreferences 선택 이유 | [ADR-0004](../docs/decisions/ADR-0004-persistence-local.md) |
