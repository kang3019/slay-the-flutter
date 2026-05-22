# docs/testing.md — 테스트 작성 및 실행 가이드

---

## 테스트 철학

이 프로젝트는 **테스트 주도 개발(TDD)** 을 원칙으로 합니다. 특히 데미지 계산, 상태 이상 적용, 카드 효과 등 게임 로직은 반드시 테스트를 먼저 작성하고 구현합니다.

---

## 테스트 디렉토리 구조

`test/` 는 `lib/`의 Domain·Application 계층을 미러링합니다:

```
test/
├── domain/
│   ├── card_test.dart          # 카드 효과 및 비용 테스트
│   ├── player_test.dart        # 플레이어 HP, 방어도 계산 테스트
│   ├── monster_test.dart       # 몬스터 스탯 공식, 의도 테스트
│   ├── deck_test.dart          # 덱 셔플·드로우 사이클 테스트
│   └── battle_engine_test.dart # 전투 흐름 통합 테스트
└── application/
    ├── battle_provider_test.dart  # 전투 상태 관리 테스트
    └── run_provider_test.dart     # 런 진행·XP 산정 테스트
```

> Presentation(`lib/presentation/`) 계층은 단위 테스트 대상에서 제외합니다. UI 검증은 통합 테스트에서 수행합니다.

---

## 테스트 실행 명령어

```bash
# 전체 테스트
flutter test

# 특정 파일만
flutter test test/domain/battle_engine_test.dart

# 특정 디렉토리
flutter test test/domain/

# 상세 출력
flutter test --reporter=expanded

# 커버리지 측정
flutter test --coverage

# 커버리지 HTML 보고서 생성 (lcov 필요)
genhtml coverage/lcov.info -o coverage/html
start coverage/html/index.html   # Windows
open coverage/html/index.html    # macOS
```

---

## 테스트 작성 예시

### 1. 데미지 계산 단위 테스트 (Domain)

```dart
// test/domain/card_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:slay_the_flutter/domain/entities/card.dart';
import 'package:slay_the_flutter/domain/entities/monster.dart';
import 'package:slay_the_flutter/domain/status_effect.dart';

void main() {
  group('Strike 카드', () {
    test('기본 데미지는 6이어야 한다', () {
      final strike = StrikeCard();
      expect(strike.damage, equals(6));
    });

    test('취약 상태의 몬스터에게 데미지는 1.5배여야 한다', () {
      final monster = Monster(stage: 1)..applyStatus(Status.vulnerable, turns: 2);
      final strike = StrikeCard();

      final actualDamage = strike.calculateDamage(target: monster);

      expect(actualDamage, equals(9)); // 6 * 1.5 = 9
    });

    test('약화 상태의 플레이어가 사용하면 데미지는 0.75배(내림)여야 한다', () {
      final player = Player()..applyStatus(Status.weak, turns: 1);
      final strike = StrikeCard();

      final actualDamage = strike.calculateDamage(source: player);

      expect(actualDamage, equals(4)); // 6 * 0.75 = 4.5 → 내림 = 4
    });
  });
}
```

### 2. 방어도 시스템 테스트 (Domain)

```dart
// test/domain/player_test.dart
void main() {
  group('방어도 시스템', () {
    test('방어도는 데미지를 먼저 흡수해야 한다', () {
      final player = Player(hp: 70)..addBlock(5);

      player.takeDamage(8);

      expect(player.block, equals(0));  // 방어도 5 → 0 (5 흡수)
      expect(player.hp, equals(67));    // 70 - (8 - 5) = 67
    });

    test('방어도는 턴 종료 시 소멸해야 한다', () {
      final player = Player(hp: 70)..addBlock(10);

      player.onTurnEnd();

      expect(player.block, equals(0));
    });
  });
}
```

### 3. 몬스터 스탯 공식 테스트 (Domain)

```dart
// test/domain/monster_test.dart
void main() {
  group('몬스터 스탯 공식', () {
    test('스테이지 1 몬스터 HP는 30이어야 한다', () {
      final monster = Monster(stage: 1);
      expect(monster.maxHp, equals(30)); // 20 + 1*10
    });

    test('스테이지 3 몬스터 공격력은 14여야 한다', () {
      final monster = Monster(stage: 3);
      expect(monster.attackPower, equals(14)); // 8 + 3*2
    });
  });
}
```

### 4. Application 계층 테스트 (Riverpod)

```dart
// test/application/battle_provider_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slay_the_flutter/application/battle_provider.dart';

void main() {
  group('BattleProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('전투 시작 시 플레이어 턴이어야 한다', () {
      final state = container.read(battleProvider);
      expect(state.isPlayerTurn, isTrue);
    });

    test('카드 사용 시 에너지가 차감되어야 한다', () {
      final notifier = container.read(battleProvider.notifier);
      notifier.playCard(CardType.strike); // 비용: 1

      final state = container.read(battleProvider);
      expect(state.energy, equals(2)); // 3 - 1 = 2
    });
  });
}
```

---

## 커버리지 목표

| 계층 | 목표 커버리지 |
|------|-------------|
| `domain/` | **80% 이상** (필수) |
| `application/` | **70% 이상** (권장) |
| `presentation/` | 단위 테스트 제외 |

---

## 주요 테스트 케이스 체크리스트

### Domain 계층

- [ ] Strike: 기본 데미지, 취약 상태 배율, 약화 배율
- [ ] Defend: 방어도 부여
- [ ] Bash: 데미지 + 취약 상태 동시 처리
- [ ] 방어도 흡수 우선순위 (방어도 → HP)
- [ ] 방어도 턴 종료 시 소멸
- [ ] 몬스터 스탯 공식: 스테이지 1~4 검증
- [ ] 덱 셔플: 버림 덱 소진 후 재셔플

### Application 계층

- [ ] 전투 시작 시 초기 상태 (에너지 3, 드로우 5장, 플레이어 턴)
- [ ] 카드 플레이 시 에너지 차감
- [ ] 에너지 부족 시 카드 사용 불가
- [ ] 턴 종료 시 몬스터 턴 전환
- [ ] 몬스터 HP 0 → 승리 상태 전환
- [ ] 플레이어 HP 0 → 패배 상태 전환
- [ ] 런 종료 시 XP 산정 및 누적 저장
