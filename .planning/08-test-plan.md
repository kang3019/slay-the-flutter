# 08-test-plan.md — 테스트 계획서

**버전**: 2.0 | **생성일**: 2026-05-22 | **최종 수정**: 2026-06-11

---

## 커버리지 목표

| 범위 | 목표 | 비고 |
|------|------|------|
| `lib/domain/` | ≥ 80% | 필수 (AGENTS.md 요구사항) |
| `lib/application/` | ≥ 70% | 권장 |
| `lib/presentation/` | smoke test | 위젯 렌더링 오류 없음 수준 |
| `lib/data/` | ≥ 60% | fake SharedPreferences 사용 |

---

## 테스트 현황 (2026-06-11 기준)

| 항목 | 수치 |
|------|------|
| 전체 테스트 수 | **446개** |
| 통과 | **446 / 446** |
| `flutter analyze` 경고 | **0건** |

---

## 테스트 디렉토리 구조

```
test/
├── domain/
│   ├── battle_engine_test.dart   # BattleEngine 카드 플레이·턴 종료·상태이상·유물 효과
│   ├── deck_test.dart            # Deck 드로우·셔플·버림 덱·Exhaust
│   ├── card_test.dart            # GameCard 정의 및 Cards.byTypeName 조회
│   ├── monster_test.dart         # Monster 스탯 공식·데미지 처리·상태이상·패턴 행동
│   ├── player_test.dart          # Player 데미지·회복·블록·StatusEffect 관리
│   ├── event_test.dart           # GameEvent 선택지·보상 유형 검증
│   ├── map_generator_test.dart   # MapGenerator DAG 구조·노드 분포 검증
│   ├── relic_test.dart           # Relic 유물 효과 20종 BattleEngine 통합 검증
│   ├── meta_progress_test.dart   # MetaProgress.computeLevel·computeUnlockedCards·addXp
│   ├── gold_rewards_test.dart    # GoldRewards.forVictory 골드 범위 검증
│   └── save_slot_test.dart       # SaveSlot JSON 직렬화·왕복 복원
├── application/
│   ├── battle_provider_test.dart         # BattleNotifier 상태 갱신·승패 판정
│   ├── run_provider_test.dart            # RunNotifier 스테이지 전환·보상·런 종료
│   ├── meta_progress_provider_test.dart  # MetaProgressNotifier XP 적립·레벨업·저장
│   └── save_slot_provider_test.dart      # SaveSlotNotifier 슬롯 저장·로드·삭제
├── data/
│   └── local_storage_test.dart   # LocalStorage SharedPreferences 읽기/쓰기
└── widget_test.dart              # IntroScreen smoke test
```

---

## Domain 테스트 케이스

### BattleEngine

**엔진 생성 패턴**
```dart
BattleEngine _makeEngine({required List<GameCard> cards, Player? player, Monster? monster}) {
  final engine = BattleEngine(
    player: player ?? Player(),
    monster: monster ?? Monster(stage: 1),
    deck: Deck(initialCards: cards),
  );
  engine.startPlayerTurn();
  return engine;
}
```

**주요 검증 항목**
```dart
// 카드 플레이 — 에너지 및 효과
engine.playCard(Cards.strike);              // bool 반환 (성공 여부)
expect(engine.energy, equals(2));           // 에너지 1 소모
expect(monster.hp, equals(18));            // Strike: 6 데미지 (24 - 6 = 18)
expect(monster.isVulnerable, isTrue);      // Bash: 취약 부여 확인

// 턴 종료
engine.endPlayerTurn();
expect(engine.deck.hand, isEmpty);          // 손패 전부 버림 덱 이동
expect(player.hp, equals(60));             // 몬스터 공격 10 (stage 1) 반영
expect(player.block, equals(0));           // player.endTurn() 후 블록 소멸

// 승리 판정
expect(engine.isBattleOver, isTrue);
expect(engine.result, equals(BattleResult.playerWon));
```

---

### Monster

```dart
// 스탯 공식 (MonsterType.basic)
Monster(stage: 1)  → hp: 24, attackPower: 10
Monster(stage: 2)  → hp: 32, attackPower: 12
Monster(stage: 3)  → hp: 40, attackPower: 14

// 생성자: Monster(stage: n) 또는 Monster(stage: n, type: MonsterType.stickySlime)
// 네임드 몬스터는 고정 HP 사용 (IronGolem: 96 등)

monster.takeDamage(10);
expect(monster.hp, equals(14));
expect(monster.isVulnerable, isTrue);  // Bash 효과 확인
```

---

### Player

```dart
// 생성자: Player() 기본값 hp=70 / Player(hp: 50)
player.takeDamage(8);   // 블록 우선 흡수 후 HP 감소
player.gainBlock(5);
player.heal(10);        // maxHp(70) 초과 불가
player.endTurn();       // block=0, statusEffects duration 1 감소 후 만료 제거
```

---

### MetaProgress

```dart
// computeLevel — 10레벨 임계치
MetaProgress.computeLevel(0)    → 1
MetaProgress.computeLevel(100)  → 2
MetaProgress.computeLevel(249)  → 2
MetaProgress.computeLevel(250)  → 3
MetaProgress.computeLevel(2700) → 10
MetaProgress.computeLevel(9999) → 10  // 최대 레벨 유지

// computeUnlockedCards
MetaProgress.computeUnlockedCards(1)  → 9종 (기본 7 + 스타터 2)
MetaProgress.computeUnlockedCards(3)  → 14종
MetaProgress.computeUnlockedCards(10) → 31종 (전체 해금)

// addXp — (MetaProgress, LevelUpResult) 반환
final (newMeta, result) = meta.addXp(100);
expect(result.didLevelUp, isTrue);
expect(result.newlyUnlockedCards, isNotEmpty);
```

---

### GoldRewards

```dart
// GoldRewards.forVictory(NodeType, floor, Random)
// monster: (floor + 1) + 10~14
// elite:   (floor + 1) + 20~25
// boss:    0

final gold = GoldRewards.forVictory(NodeType.monster, 0, Random());
expect(gold, inInclusiveRange(11, 15));   // floor 0: 1 + 10~14

final bossGold = GoldRewards.forVictory(NodeType.boss, 5, Random());
expect(bossGold, equals(0));
```

---

## Application 테스트 케이스

### BattleNotifier

**컨테이너 생성 패턴** — `battleEngineFactoryProvider`를 오버라이드해 결정론적 덱 주입
```dart
ProviderContainer _makeContainer({List<GameCard>? cards}) {
  return ProviderContainer(
    overrides: [
      battleEngineFactoryProvider.overrideWith(
        (ref) => (s, relics, _, __, ___) {
          final engine = BattleEngine(
            player: Player(),
            monster: Monster(stage: s),
            deck: Deck(initialCards: cards ?? List.filled(10, Cards.strike)),
            relics: relics,
          );
          engine.startPlayerTurn();
          return engine;
        },
      ),
    ],
  );
}
```

**주요 검증 항목**
```dart
container.read(battleProvider).playerHp      // 70
container.read(battleProvider).energy        // 3
container.read(battleProvider).hand.length   // 5

container.read(battleProvider.notifier).playCard(Cards.strike);
expect(container.read(battleProvider).energy, equals(2));

container.read(battleProvider.notifier).endTurn();
// 승패 판정
expect(container.read(battleProvider).isBattleOver, isTrue);
expect(container.read(battleProvider).result, equals(BattleResult.playerWon));
```

---

### MetaProgressNotifier

**컨테이너 생성 패턴** — `localStorageProvider`를 fake SharedPreferences로 오버라이드
```dart
setUp(() async {
  SharedPreferences.setMockInitialValues({});
  prefs = await SharedPreferences.getInstance();
  container = ProviderContainer(
    overrides: [localStorageProvider.overrideWithValue(LocalStorage(prefs))],
  );
});
```

**주요 검증 항목**
```dart
// 초기 상태
container.read(metaProgressProvider).level          // 1
container.read(metaProgressProvider).xp             // 0
container.read(metaProgressProvider).unlockedCardTypes  // ['strike','defend',...]

// XP 적립 및 레벨업
container.read(metaProgressProvider.notifier).addXp(100);
expect(container.read(metaProgressProvider).level, equals(2));

// SharedPreferences 영속 저장 확인
await prefs.setInt('meta_level', 3);
await prefs.setInt('meta_xp', 300);
// 새 컨테이너 생성 후 저장 값 복원 검증
```

---

## 실행 명령어

```bash
# 전체 테스트 실행
flutter test

# 커버리지 포함
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# 특정 파일만
flutter test test/domain/battle_engine_test.dart

# 상세 출력
flutter test --reporter=expanded

# 도메인만
flutter test test/domain/
```

---

## CI 통과 기준

```yaml
# .github/workflows에서 자동 검증
- flutter analyze   # 경고 0건
- flutter test      # 446개 전체 GREEN
- 커버리지 리포트   # domain/ ≥ 80%
```
