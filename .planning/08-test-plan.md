# 08-test-plan.md — 테스트 계획서

**버전**: 1.0 | **생성일**: 2026-05-22 (AI Agent 자동 생성)

---

## 커버리지 목표

| 범위 | 목표 | 비고 |
|------|------|------|
| `lib/domain/` | ≥ 80% | 필수 (AGENTS.md 요구사항) |
| `lib/application/` | ≥ 70% | 권장 |
| `lib/presentation/` | smoke test | 위젯 렌더링 오류 없음 수준 |
| `lib/data/` | ≥ 60% | fake SharedPreferences 사용 |

---

## 테스트 디렉토리 구조

```
test/
├── domain/
│   ├── battle_engine_test.dart   # BattleEngine 핵심 로직
│   ├── deck_test.dart            # 드로우/셔플/버림 덱
│   ├── card_test.dart            # Card 데이터 검증
│   ├── monster_test.dart         # Monster 스탯 공식
│   ├── player_test.dart          # Player 상태 변이
│   ├── status_effect_test.dart   # 취약/약화 배율
│   └── xp_system_test.dart       # XP 산정/레벨업
├── application/
│   ├── battle_provider_test.dart
│   ├── run_provider_test.dart
│   └── meta_provider_test.dart
└── data/
    └── local_storage_test.dart
```

---

## Domain 테스트 케이스

### BattleEngine — 데미지 계산

```dart
group('BattleEngine.calculateDamage', () {
  test('일반 데미지: 배율 없음', () {
    expect(BattleEngine.calculateDamage(6, weak: false, vulnerable: false), 6);
  });

  test('약화 적용: floor(6 × 0.75) = 4', () {
    expect(BattleEngine.calculateDamage(6, weak: true, vulnerable: false), 4);
  });

  test('취약 적용: floor(6 × 1.5) = 9', () {
    expect(BattleEngine.calculateDamage(6, weak: false, vulnerable: true), 9);
  });

  test('약화+취약 동시: floor(floor(6×0.75)×1.5) = floor(4×1.5) = 6', () {
    expect(BattleEngine.calculateDamage(6, weak: true, vulnerable: true), 6);
  });

  test('데미지 0: 최솟값 0 보장', () {
    expect(BattleEngine.calculateDamage(0, weak: true, vulnerable: false), 0);
  });
});
```

### BattleEngine — 방어도 적용

```dart
group('BattleEngine.applyDamage', () {
  test('방어도가 데미지 전부 흡수', () {
    final player = Player(currentHp: 70, block: 10);
    BattleEngine.applyDamage(player, 8);
    expect(player.block, 2);
    expect(player.currentHp, 70);
  });

  test('데미지가 방어도 초과 — 초과분이 HP 감소', () {
    final player = Player(currentHp: 70, block: 5);
    BattleEngine.applyDamage(player, 8);
    expect(player.block, 0);
    expect(player.currentHp, 67);
  });

  test('HP가 0 미만으로 내려가지 않음', () {
    final player = Player(currentHp: 3, block: 0);
    BattleEngine.applyDamage(player, 100);
    expect(player.currentHp, 0);
  });

  test('방어도 0일 때 전부 HP에 적용', () {
    final player = Player(currentHp: 70, block: 0);
    BattleEngine.applyDamage(player, 6);
    expect(player.currentHp, 64);
  });
});
```

### BattleEngine — 카드 사용

```dart
group('BattleEngine.playCard', () {
  test('Strike: 에너지 1 소모, 몬스터에 6 데미지', () {
    final state = makeBattleState(energy: 3, monsterHp: 30);
    final next = BattleEngine.playCard(strikeCard, state);
    expect(next.player.energy, 2);
    expect(next.monster.hp, 24);
  });

  test('Defend: 에너지 1 소모, 플레이어 방어도 +5', () {
    final state = makeBattleState(energy: 3, playerBlock: 0);
    final next = BattleEngine.playCard(defendCard, state);
    expect(next.player.energy, 2);
    expect(next.player.block, 5);
  });

  test('에너지 부족 시 카드 사용 불가', () {
    final state = makeBattleState(energy: 0);
    expect(() => BattleEngine.playCard(strikeCard, state),
           throwsAssertionError);
  });

  test('Bash: 데미지 8 + 몬스터 취약 2턴', () {
    final state = makeBattleState(energy: 3, monsterHp: 30);
    final next = BattleEngine.playCard(bashCard, state);
    expect(next.monster.hp, 22);
    expect(next.monster.vulnerableTurns, 2);
  });
});
```

### BattleEngine — 턴 종료

```dart
group('BattleEngine.endPlayerTurn', () {
  test('플레이어 방어도 0으로 초기화', () {
    final state = makeBattleState(playerBlock: 8);
    final next = BattleEngine.endPlayerTurn(state);
    expect(next.player.block, 0);
  });

  test('에너지 3으로 초기화', () {
    final state = makeBattleState(energy: 0);
    final next = BattleEngine.endPlayerTurn(state);
    expect(next.player.energy, 3);
  });

  test('손패 전부 버림 덱으로 이동 후 5장 드로우', () {
    final state = makeBattleState(handSize: 3, deckSize: 10);
    final next = BattleEngine.endPlayerTurn(state);
    expect(next.hand.length, 5);
  });

  test('상태이상 턴 수 1 감소', () {
    final state = makeBattleState(playerWeakTurns: 2);
    final next = BattleEngine.endPlayerTurn(state);
    expect(next.player.weakTurns, 1);
  });

  test('상태이상 0 미만으로 내려가지 않음', () {
    final state = makeBattleState(playerWeakTurns: 0);
    final next = BattleEngine.endPlayerTurn(state);
    expect(next.player.weakTurns, 0);
  });
});
```

### Deck — 드로우/셔플

```dart
group('Deck', () {
  test('drawCards(5): 덱에서 5장 드로우', () {
    final deck = Deck(cards: List.generate(10, (_) => strikeCard));
    final hand = deck.drawCards(5);
    expect(hand.length, 5);
    expect(deck.remaining, 5);
  });

  test('덱 소진 시 버림 덱 셔플 후 드로우', () {
    final deck = Deck(cards: [strikeCard],
                      discardPile: List.generate(9, (_) => defendCard));
    deck.drawCards(5);
    expect(deck.remaining + deck.discardCount, 5);
  });

  test('덱+버림덱 합산보다 많이 드로우 요청 시 가능한 수만큼 드로우', () {
    final deck = Deck(cards: [strikeCard, defendCard]);
    final hand = deck.drawCards(5);
    expect(hand.length, 2);
  });
});
```

### Monster — 스탯 공식

```dart
group('Monster 스탯 공식', () {
  test('스테이지 1: HP=30, 공격=10', () {
    final m = Monster.fromStage(1);
    expect(m.hp, 30);
    expect(m.attack, 10);
  });

  test('스테이지 2: HP=40, 공격=12', () {
    final m = Monster.fromStage(2);
    expect(m.hp, 40);
    expect(m.attack, 12);
  });

  test('스테이지 3: HP=50, 공격=14', () {
    final m = Monster.fromStage(3);
    expect(m.hp, 50);
    expect(m.attack, 14);
  });

  test('보스(스테이지 4): HP=80, 공격=22', () {
    final m = Monster.fromStage(4);
    expect(m.hp, 80);
    expect(m.attack, 22);
  });
});
```

### XpSystem

```dart
group('XpSystem', () {
  test('레벨 1: XP=0', () {
    expect(XpSystem.calcLevel(0), 1);
  });

  test('레벨 2: XP=100 도달 시', () {
    expect(XpSystem.calcLevel(100), 2);
  });

  test('레벨 2: XP=249 (임계치 미달)', () {
    expect(XpSystem.calcLevel(249), 2);
  });

  test('레벨 3: XP=250', () {
    expect(XpSystem.calcLevel(250), 3);
  });

  test('런 클리어 XP: 100', () {
    expect(XpSystem.runClearXp, 100);
  });

  test('스테이지 클리어 XP: 30', () {
    expect(XpSystem.stageClearXp, 30);
  });

  test('몬스터 처치 XP: 10', () {
    expect(XpSystem.monsterKillXp, 10);
  });
});
```

---

## Application 테스트 케이스

### BattleProvider

```dart
group('BattleNotifier', () {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('playCard: 상태가 올바르게 갱신됨', () {
    container.read(battleProvider.notifier).startBattle(Monster.fromStage(1));
    container.read(battleProvider.notifier).playCard(strikeCard);
    final state = container.read(battleProvider);
    expect(state.monster.hp, lessThan(30));
    expect(state.player.energy, 2);
  });

  test('endTurn: 몬스터 턴 실행 후 플레이어 턴으로 복귀', () {
    container.read(battleProvider.notifier).startBattle(Monster.fromStage(1));
    container.read(battleProvider.notifier).endTurn();
    final state = container.read(battleProvider);
    expect(state.phase, BattlePhase.playerTurn);
    expect(state.player.energy, 3);
    expect(state.hand.length, 5);
  });

  test('몬스터 HP 0 → isOver=true, playerWon=true', () {
    // 몬스터 HP를 1로 설정 후 Strike 사용
    final state = container.read(battleProvider);
    expect(state.isOver, isTrue);
    expect(state.playerWon, isTrue);
  });
});
```

### MetaProvider

```dart
group('MetaNotifier', () {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('addXp: XP 누적 저장', () async {
    await container.read(metaProvider.notifier).addXp(50);
    final state = await container.read(metaProvider.future);
    expect(state.xp, 50);
  });

  test('addXp: 임계치 초과 시 레벨업', () async {
    await container.read(metaProvider.notifier).addXp(100);
    final state = await container.read(metaProvider.future);
    expect(state.level, 2);
  });

  test('레벨업 시 해금 카드 목록 갱신', () async {
    await container.read(metaProvider.notifier).addXp(100);
    final state = await container.read(metaProvider.future);
    expect(state.unlockedCardIds, contains('bash'));
  });
});
```

---

## 실행 명령어

```bash
# 전체 테스트 실행
flutter test

# 커버리지 포함
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

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
- flutter test      # 모든 테스트 GREEN
- 커버리지 리포트   # domain/ ≥ 80%
```
