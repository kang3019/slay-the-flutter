# 06-tech-spec.md — 기술 명세서

**버전**: 2.0 | **생성일**: 2026-05-22 | **최종 수정**: 2026-06-11

---

## 1. 기술 스택

| 역할 | 기술 | 버전 기준 |
|------|------|-----------|
| 프레임워크 | Flutter | ≥ 3.19 |
| 언어 | Dart | ≥ 3.3 |
| 상태 관리 | flutter_riverpod | ≥ 2.5 |
| 로컬 저장소 | shared_preferences | ≥ 2.2 |
| 테스트 | flutter_test (내장) | — |
| 목(Mock) | mockito | ≥ 5.4 |
| 빌드 자동화 | GitHub Actions | — |

---

## 2. 도메인 모델 명세

### 2-1. GameCard

```dart
/// 카드가 전투에서 수행하는 효과 분류.
enum CardEffectType { damage, block, buff, heal, draw, blockDraw, strength }

/// 카드 식별자 — SPECS.md에 정의된 31종.
enum CardType {
  strike, bash, swiftCut, defend, ironWall, focus, recover,
  rageBurst, toxicJab, regroup, crushingBlow, fury,
  tripleSlash, quickMend, swiftGuard, exploitWeakness, sharpen,
  weakSlash, blockStrike, bloodRush, devilsDeal,
  battleCry, indomitable, comboStrike, gamble, poisonDart,
  limitBreak, impervious, doubleTap, fiendFire,
}

/// 불변 카드 정의. 비용·효과 분류·수치를 보유한다.
class GameCard {
  final CardType type;
  final String name;          // 표시 이름
  final int cost;             // 에너지 비용 (0~3, -1 = X비용)
  final CardEffectType effectType;
  final int value;            // 데미지 또는 방어도 수치
  final bool isUpgraded;      // 휴식처 강화 여부
}

// 카드 인스턴스: Cards.strike, Cards.defend, Cards.bash …
// 강화 인스턴스: Cards.strikeUpgraded, Cards.defendUpgraded …
// 강화 헬퍼: Cards.upgrade(GameCard card) → GameCard
```

### 2-2. StatusEffect

```dart
/// 상태 이상 종류.
enum StatusEffectType { vulnerable, weak, poison }

/// 남은 지속 턴을 가진 단일 상태 이상.
class StatusEffect {
  final StatusEffectType type;
  final int duration; // vulnerable·weak: 남은 턴 수 / poison: 스택 수
}

// 배율 상수 (Player·Monster 클래스에 선언)
static const double vulnerableMultiplier = 1.5;  // 받는 데미지 ×1.5
static const double weakMultiplier       = 0.75; // 주는 데미지 ×0.75 (floor)
// Poison: 턴 시작 시 스택 수만큼 HP 감소 (방어도 무시), 매 턴 스택 1 감소
```

### 2-3. Player

```dart
class Player {
  static const int maxHp = 70;

  int hp;
  int block;       // 턴 종료 시 0으로 초기화
  int strength;    // 전투 내 공격력 보너스 (전투 종료 시 자동 초기화)
  List<StatusEffect> statusEffects; // Vulnerable·Weak·Poison 포함
}
```

> `energy`(에너지)는 `BattleEngine`이 관리.
> `xp` / `level` / `unlockedCardTypes`는 `MetaProgress` 클래스에서 관리 — Player와 별개.

### 2-4. Monster

```dart
/// 몬스터 한 턴의 행동 명세 — UI 의도 아이콘 및 실행에 사용.
enum MonsterIntentType { attack, defend, buff, attackDebuff, sleep }

class MonsterTurnAction {
  final MonsterIntentType intentType;
  final int attackDamage; // 타격당 데미지 (없으면 0)
  final int hitCount;     // 타격 횟수
  final int blockGain;
  final int strengthGain;
  final StatusEffect? playerDebuff; // 플레이어에게 부여할 상태 이상
}

/// 몬스터 종류 (6종).
enum MonsterType { basic, stickySlime, ironScavenger, venomSentinel, caveGuardian, ironGolem }

class Monster {
  final int stage;
  final MonsterType type;
  int hp;
  int block;
  int strength;
  List<StatusEffect> statusEffects;
  // currentIntent: MonsterTurnAction — 패턴 인덱스로 자동 결정

  bool get isVulnerable; // statusEffects에서 계산
  bool get isWeak;
  int get poisonStacks;
}

// 스탯 공식 (MonsterType.basic 전용 — 테스트 전용 타입)
// hp     = 16 + (stage * 8)   → stage 1: 24 / 2: 32 / 3: 40
// attack = 8  + (stage * 2)   → stage 1: 10 / 2: 12 / 3: 14
// 네임드 몬스터(슬라임·고철수집가·독파수꾼·석굴수호자·철갑골렘)는 고정 HP 사용
```

### 2-5. BattleState

```dart
class BattleState {
  final int stage;           // 1~3
  final int playerHp;
  final int playerMaxHp;
  final int playerBlock;
  final int energy;
  final int maxEnergy;       // 고정 3
  final int monsterHp;
  final int monsterMaxHp;
  final int monsterAttackPower;
  final bool monsterIsVulnerable;
  final List<GameCard> hand;
  final bool isBattleOver;
  final BattleResult? result;
}

enum BattleResult { playerWon, playerLost }
```

### 2-6. RunState / RunPhase

```dart
/// 현재 런이 어느 화면에 있는지를 나타내는 단계 값 (8종).
enum RunPhase {
  map,      // 지도 화면
  battle,   // 전투 화면
  reward,   // 카드 보상 선택
  event,    // 텍스트 이벤트
  treasure, // 유물 보관소
  rest,     // 휴식처
  shop,     // 상점
  runEnd,   // 런 종료 결과
}

class RunState {
  final RunPhase phase;
  final int floor;                    // 현재 층 (-1 = 미시작)
  final int playerHp;
  final int gold;
  final List<GameCard> deck;
  final List<MapNode> mapNodes;
  final String? currentNodeId;
  final List<String> visitedNodeIds;
  final bool isRunOver;
  final List<GameCard> rewardCards;   // reward 단계에서만 채워짐
  final List<Relic> relics;           // 보유 유물 목록
  final GameEvent? currentEvent;      // event 단계에서만 non-null
  final Relic? currentTreasureRelic;  // treasure 단계에서만 non-null
  final int pendingGoldReward;        // 미수령 골드 (reward 화면 클릭 전)
  final bool goldClaimed;
  final Relic? pendingRelicReward;    // 엘리트/보스 처치 시 자동 지급된 유물
  final int xpGainedThisRun;
  final List<String> newlyUnlockedCardsThisRun;
  // 상점 관련 필드 생략 (shopCards, shopCardPrices 등)

  // 파생값
  int get currentStage;  // floor 0·1→1, 2·3→2, 4+→3
  MapNode? get currentNode;
}
```

---

## 3. BattleEngine 명세

### 3-1. 데미지 계산

```
calcDamage(base, attackerWeak, defenderVulnerable):
  dmg = base
  if attackerWeak:    dmg = floor(dmg × 0.75)
  if defenderVulnerable: dmg = floor(dmg × 1.5)
  return dmg

applyDamage(target, damage):
  absorbed = min(target.block, damage)
  target.block -= absorbed
  target.hp   -= (damage - absorbed)
  target.hp    = max(0, target.hp)
```

### 3-2. 카드 사용 흐름

```
playCard(card, player, monster):
  assert energy >= card.cost
  energy -= card.cost

  switch card.effectType:
    damage:
      dmg = calcDamage(card.value + player.strength,
                       player.isWeak, monster.isVulnerable)
      applyDamage(monster, dmg)
    block:
      player.gainBlock(card.value)
    heal:
      player.heal(card.value)
    buff / strength / draw / …:
      applySpecialEffect(card, player, monster)

  hand.remove(card)
  discardPile.add(card)   // Exhaust 카드는 discardPile 대신 소멸
```

### 3-3. 턴 종료

```
endPlayerTurn(player, hand, discardPile):
  discardPile.addAll(hand)
  hand.clear()
  applyTurnEndRelics()       // 유물 턴 종료 효과 (턴 종료 유물)
  monster.executeAction(player)  // 몬스터 행동 실행
  monster.endTurn()          // 몬스터 블록 소멸·상태이상 duration 감소
  player.endTurn()           // 플레이어 블록 소멸·상태이상 duration 감소
  // player.endTurn() 내부:
  //   block = 0
  //   statusEffects = statusEffects.map(e → duration-1).where(duration>0)

startPlayerTurn():
  energy = energyPerTurn     // 3 (유물로 증가 가능)
  drawCards(drawPerTurn)     // 기본 5장

drawCards(n):
  while hand.length < n:
    if deck.isEmpty:
      deck = shuffle(discardPile)
      discardPile.clear()
    hand.add(deck.removeLast())
```

### 3-4. 몬스터 턴

```
monster.executeAction(player):
  action = monster.currentIntent  // 패턴 인덱스로 결정
  if action.attackDamage > 0:
    dmg = (action.attackDamage + monster.strength) × hitCount
    // player.takeDamage() 내부에서 player.isVulnerable 배율 적용
    player.takeDamage(dmg / hitCount) × hitCount  // 히트마다 개별 적용
  if action.blockGain > 0:   monster.gainBlock(action.blockGain)
  if action.strengthGain > 0: monster.strength += action.strengthGain
  if action.playerDebuff != null: player.applyStatusEffect(action.playerDebuff)
  _turnIndex++  // 다음 패턴으로 진행

monster.endTurn():
  block = 0
  statusEffects = statusEffects.map(e → duration-1).where(duration>0)
```

---

## 4. XP / 레벨 명세

### XP 획득 테이블

| 이벤트 | XP |
|--------|----|
| 일반 몬스터 처치 (승리) | +10 |
| 엘리트 처치 (승리) | +25 |
| 보스 처치 — 런 클리어 (승리) | +100 |
| 일반 몬스터 전투 (패배) | +3 |
| 엘리트 전투 (패배) | +8 |
| 보스 전투 (패배) | +20 |

### 레벨업 임계치

| 레벨 | 누적 XP | 해금 카드 |
|------|---------|----------|
| 1 | 0 | strike, defend (스타터 덱) |
| 2 | 100 | tripleSlash, toxicJab, comboStrike |
| 3 | 250 | bash, ironWall |
| 4 | 450 | focus, recover, indomitable |
| 5 | 700 | exploitWeakness, weakSlash, blockStrike |
| 6 | 1000 | poisonDart, battleCry |
| 7 | 1350 | crushingBlow, bloodRush |
| 8 | 1750 | devilsDeal, gamble |
| 9 | 2200 | limitBreak, fiendFire |
| 10 | 2700 | doubleTap, impervious |

> 기본 해금 카드 7종 (swiftCut·rageBurst·quickMend·regroup·swiftGuard·sharpen·fury)은 레벨과 무관하게 항상 보상 풀에 포함된다.

```dart
// MetaProgress.computeLevel() — lib/domain/entities/meta_progress.dart
static int computeLevel(int xp) {
  for (int i = xpThresholds.length - 1; i >= 0; i--) {
    if (xp >= xpThresholds[i]) return i + 1;
  }
  return 1;
}
```

---

## 5. 로컬 저장소 스키마

`SharedPreferences` 키 목록:

| 키 | 타입 | 설명 |
|----|------|------|
| `meta_xp` | int | 누적 XP |
| `meta_level` | int | 현재 레벨 |
| `meta_unlocked_cards` | String (JSON) | `["bash","swiftCut",…]` |
| `save_slot_1` | String (JSON) | 세이브 슬롯 1 (RunState 스냅샷, nullable) |
| `save_slot_2` | String (JSON) | 세이브 슬롯 2 (RunState 스냅샷, nullable) |
| `save_slot_3` | String (JSON) | 세이브 슬롯 3 (RunState 스냅샷, nullable) |

---

## 6. Provider 목록

| Provider | 타입 | 파일 | 책임 |
|----------|------|------|------|
| `battleProvider` | `Notifier<BattleState>` | `battle_provider.dart` | 카드 사용, 턴 종료, 승패 판정 |
| `runProvider` | `Notifier<RunState>` | `run_provider.dart` | 맵 이동, 보상 단계 전환, 런 리셋 (8 RunPhase) |
| `metaProgressProvider` | `Notifier<MetaProgress>` | `meta_progress_provider.dart` | XP 적립, 레벨업, 해금 목록 관리 |
| `saveSlotProvider` | `Notifier<List<SaveSlot?>>` | `save_slot_provider.dart` | 3슬롯 저장·로드·삭제 |

> **참고**: 덱 관리(`draw`, `shuffle`, `discard`)는 `BattleState` 안에서 처리되며 별도 Provider가 없다.

---

## 7. 에러 처리 정책

| 상황 | 처리 방법 |
|------|-----------|
| 에너지 부족 시 카드 사용 시도 | assert 또는 early return, UI에서 사전 차단 |
| SharedPreferences 로드 실패 | 기본값(XP=0, level=1)으로 초기화 |
| JSON 파싱 오류 | 저장 데이터 초기화 후 로깅 |
| 덱이 비었을 때 드로우 | 버림 덱을 셔플하여 재사용, 버림 덱도 비면 드로우 스킵 |
