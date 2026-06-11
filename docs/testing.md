# docs/testing.md — 테스트 작성 및 실행 가이드

> **현재 상태**: `flutter test` → **446/446 전부 통과** | `flutter analyze` → **경고 0건**

---

## 테스트 철학

이 프로젝트는 **TDD(테스트 주도 개발)** 를 원칙으로 한다.
Domain 계층(게임 규칙)은 Flutter 없이 순수 Dart로 작성되어 있어,
`ProviderContainer` 하나만으로 Application 계층까지 위젯 트리 없이 테스트한다.

---

## 테스트 디렉토리 구조

`test/`는 `lib/`의 Domain·Application·Data 계층을 미러링한다.

```
test/
├── domain/
│   ├── card_test.dart             # 카드 30종 상수 검증 (비용·효과·강화)
│   ├── player_test.dart           # HP·방어도·상태이상 (Vulnerable·Weak)
│   ├── monster_test.dart          # 5종 몬스터 행동 패턴 전수 검증
│   ├── deck_test.dart             # 드로우·셔플·소멸(Exhaust) 사이클
│   ├── battle_engine_test.dart    # 전투 흐름 통합 (에너지·카드 효과·유물)
│   ├── event_test.dart            # 이벤트 10종 선택지 효과 검증
│   ├── map_generator_test.dart    # DAG 맵 생성 5대 제약 전수 검증
│   ├── relic_test.dart            # 유물 20종 패시브 효과
│   ├── gold_rewards_test.dart      # 골드 보상 공식 검증 (일반·엘리트·보스)
│   ├── meta_progress_test.dart    # XP 누적·레벨업·카드 해금
│   └── save_slot_test.dart        # SaveSlot JSON 직렬화 왕복 검증
├── application/
│   ├── battle_provider_test.dart  # BattleNotifier 상태 전환
│   ├── run_provider_test.dart     # RunNotifier 맵 이동·보상·런 종료
│   ├── meta_progress_provider_test.dart  # XP 저장·레벨업 알림
│   └── save_slot_provider_test.dart      # 슬롯 저장·로드·삭제
├── data/
│   └── local_storage_test.dart    # SharedPreferences 키-값 입출력
└── widget_test.dart               # 앱 스모크 테스트
```

---

## 테스트 실행 명령어

```bash
# 전체 테스트 (446개)
flutter test

# 상세 출력 — 각 test() 이름 표시
flutter test --reporter=expanded

# 특정 파일만
flutter test test/domain/battle_engine_test.dart

# 특정 디렉토리
flutter test test/domain/

# 커버리지 측정
flutter test --coverage

# 커버리지 HTML 보고서 (lcov 필요)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html    # macOS
start coverage/html/index.html   # Windows
```

---

## Application 계층 테스트 패턴

```dart
// test/application/meta_progress_provider_test.dart
late ProviderContainer container;
late SharedPreferences prefs;

setUp(() async {
  SharedPreferences.setMockInitialValues({});
  prefs = await SharedPreferences.getInstance();
  container = ProviderContainer(
    overrides: [
      localStorageProvider.overrideWithValue(LocalStorage(prefs)),
    ],
  );
});

tearDown(() => container.dispose());

test('XP 적립 시 레벨이 오른다', () {
  container.read(metaProgressProvider.notifier).addXp(100);

  expect(container.read(metaProgressProvider).level, equals(2));
});
```

- `ProviderContainer`를 매 `setUp`마다 새로 생성해 테스트 간 상태를 완전히 격리한다.
- `BuildContext`·MediaQuery·Widget 트리가 전혀 없어도 테스트 가능하다.

---

## Domain 계층 테스트 패턴

```dart
// test/domain/monster_test.dart
group('철갑 골렘 (보스)', () {
  late Monster boss;
  setUp(() => boss = Monster(type: MonsterType.ironGolem, stage: 3));

  test('첫 행동은 장갑 강화(방어도+10)이어야 한다', () {
    final player = Player();
    boss.executeAction(player);
    expect(boss.block, equals(10));
  });
});
```

- Domain 엔티티는 순수 Dart이므로 `flutter_test` 없이도 `dart test`로 실행 가능하다.

---

## 커버리지 목표

| 계층 | 목표 | 이유 |
|------|------|------|
| `domain/` | **≥ 80%** (필수) | 게임 규칙의 정확성이 전체 품질의 핵심 |
| `application/` | **≥ 70%** (권장) | Provider 상태 전환 시나리오 검증 |
| `presentation/` | 단위 테스트 제외 | UI 검증은 통합 테스트 범위 |

---

## 주요 테스트 케이스 체크리스트

### Domain 계층

- [x] Strike: 기본 데미지 6, 취약 배율 ×1.5, 약화 배율 ×0.75 (floor)
- [x] Defend: 방어도 5 부여
- [x] Bash: 데미지 8 + 취약 2턴 동시 처리
- [x] 방어도 흡수 우선순위 (방어도 → HP)
- [x] 방어도 턴 종료 시 소멸
- [x] 몬스터 5종 행동 패턴 전수 검증
- [x] 덱 셔플: 버림 덱 소진 후 자동 재셔플
- [x] 소멸(Exhaust): 재활용 더미에 포함되지 않음
- [x] DAG 맵 생성 5대 제약 (고정층·교차·도달성·최소콘텐츠·연속금지)
- [x] XP 누적 → 레벨업 → 카드 해금 체인

### Application 계층

- [x] 전투 시작 시 초기 상태 (에너지 3, 드로우 5장)
- [x] 카드 플레이 시 에너지 차감
- [x] 에너지 부족 시 카드 사용 불가 (false 반환)
- [x] 턴 종료 → 몬스터 행동 자동 발동 → 다음 턴 자동 시작
- [x] 몬스터 HP 0 → isBattleOver = true, result = playerWon
- [x] 플레이어 HP 0 → isBattleOver = true, result = playerLost
- [x] 런 종료 시 XP 정산 및 LocalStorage 영속 저장
