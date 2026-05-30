# 06-tech-spec.md — 기술 명세서

**버전**: 1.0 | **생성일**: 2026-05-22 (AI Agent 자동 생성)

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

### 2-1. Card

```dart
class Card {
  final String id;          // 'strike', 'defend', 'bash' …
  final String name;        // 표시 이름
  final CardType type;      // attack | defense | special
  final int cost;           // 에너지 비용 (0~3)
  final int value;          // 데미지 또는 방어도 수치
  final StatusEffect? effect; // 부가 상태이상 (nullable)
  final int? effectDuration;  // 상태이상 지속 턴
}

enum CardType { attack, defense, special }
```

### 2-2. StatusEffect

```dart
enum StatusEffect { vulnerable, weak }

// 배율 상수
const double kVulnerableMultiplier = 1.5;
const double kWeakMultiplier       = 0.75;
```

### 2-3. Player

```dart
class Player {
  final int maxHp;          // 고정 70
  int currentHp;
  int block;                // 턴 종료 시 0으로 초기화
  int energy;               // 턴 시작 시 3으로 초기화
  int weakTurns;
  int vulnerableTurns;
  int xp;
  int level;
  List<String> unlockedCardIds;
}
```

### 2-4. Monster

```dart
class Monster {
  final String id;
  final String name;
  final int stage;          // 1~4 (4 = 보스)
  late int hp;              // 20 + (stage × 10)
  late int attack;          // 8  + (stage × 2)
  int block;
  MonsterIntent nextIntent; // attack | defend
  int weakTurns;
  int vulnerableTurns;
}

enum MonsterIntent { attack, defend }

// 스탯 공식
// hp     = 20 + (stage * 10)
// attack = 8  + (stage * 2)
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

enum BattleResult { playerWon, monsterWon }
```

### 2-6. RunState / RunPhase

```dart
/// 현재 런의 화면 단계.
enum RunPhase { map, battle, reward }

class RunState {
  final RunPhase phase;          // 현재 화면 단계
  final int floor;               // 현재 층 (-1 = 미시작)
  final int playerHp;
  final int gold;
  final List<GameCard> deck;     // 이번 런에서 보유한 카드
  final List<MapNode> mapNodes;  // Act 1 전체 노드
  final String? currentNodeId;   // 현재 위치 노드 ID
  final List<String> visitedNodeIds;
  final bool isRunOver;
  final List<GameCard> rewardCards; // reward 단계에서만 채워짐

  // 파생값: floor → stage (0·1→1, 2·3→2, 4+→3)
  int get currentStage;
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
  assert player.energy >= card.cost
  player.energy -= card.cost

  switch card.type:
    attack:
      dmg = calcDamage(card.value, player.weakTurns > 0,
                                   monster.vulnerableTurns > 0)
      applyDamage(monster, dmg)
    defense:
      player.block += card.value
    special:
      applySpecialEffect(card, player, monster)

  if card.effect != null:
    applyStatusEffect(card.effect, card.effectDuration, monster)

  hand.remove(card)
  discardPile.add(card)
```

### 3-3. 턴 종료

```
endPlayerTurn(player, hand, discardPile):
  player.block  = 0          // 방어도 소멸
  player.energy = 3          // 에너지 초기화
  player.weakTurns      = max(0, player.weakTurns - 1)
  player.vulnerableTurns= max(0, player.vulnerableTurns - 1)
  discardPile.addAll(hand)
  hand.clear()
  drawCards(5)               // 5장 드로우

drawCards(n):
  while hand.length < n:
    if deck.isEmpty:
      deck = shuffle(discardPile)
      discardPile.clear()
    hand.add(deck.removeLast())
```

### 3-4. 몬스터 턴

```
executeMonsterTurn(monster, player):
  if monster.nextIntent == attack:
    dmg = calcDamage(monster.attack,
                     monster.weakTurns > 0,
                     player.vulnerableTurns > 0)
    applyDamage(player, dmg)
  else:
    monster.block += floor(monster.attack × 0.8)

  monster.block  = 0
  monster.weakTurns       = max(0, monster.weakTurns - 1)
  monster.vulnerableTurns = max(0, monster.vulnerableTurns - 1)
  monster.nextIntent = randomIntent()
```

---

## 4. XP / 레벨 명세

### XP 획득 테이블

| 이벤트 | XP |
|--------|----|
| 일반 몬스터 처치 | +10 |
| 스테이지 클리어 | +30 |
| 런 클리어 (보스 처치) | +100 |

### 레벨업 임계치

| 레벨 | 누적 XP | 해금 |
|------|---------|------|
| 1 | 0 | Strike, Defend |
| 2 | 100 | Bash, Swift Cut |
| 3 | 250 | Iron Wall, Focus |
| 4 | 450 | Recover, 유물 1종 |
| 5+ | +200 per level | 추가 카드/유물 |

```dart
int calcLevel(int totalXp) {
  const thresholds = [0, 100, 250, 450];
  int level = 1;
  for (final t in thresholds) {
    if (totalXp >= t) level++;
  }
  return level - 1; // 1-based
}
```

---

## 5. 로컬 저장소 스키마

`SharedPreferences` 키 목록:

| 키 | 타입 | 설명 |
|----|------|------|
| `player_xp` | int | 누적 XP |
| `player_level` | int | 현재 레벨 |
| `unlocked_cards` | String (JSON) | `["bash","swift_cut",…]` |
| `unlocked_relics` | String (JSON) | `["relic_01",…]` |
| `run_state` | String (JSON) | 진행 중인 런 스냅샷 (nullable) |

---

## 6. Provider 목록

| Provider | 타입 | 파일 | 책임 |
|----------|------|------|------|
| `battleProvider` | `Notifier<BattleState>` | `battle_provider.dart` | 카드 사용, 턴 종료, 승패 판정 |
| `runProvider` | `Notifier<RunState>` | `run_provider.dart` | 맵 이동, 보상 단계 전환, 런 리셋 |
| `metaProgressProvider` | `Notifier<MetaProgress>` | `meta_progress_provider.dart` | XP 적립, 레벨업, 해금 목록 관리 |

> **참고**: 덱 관리(`draw`, `shuffle`, `discard`)는 `BattleState` 안에서 처리되며 별도 Provider가 없다.

---

## 7. 에러 처리 정책

| 상황 | 처리 방법 |
|------|-----------|
| 에너지 부족 시 카드 사용 시도 | assert 또는 early return, UI에서 사전 차단 |
| SharedPreferences 로드 실패 | 기본값(XP=0, level=1)으로 초기화 |
| JSON 파싱 오류 | 저장 데이터 초기화 후 로깅 |
| 덱이 비었을 때 드로우 | 버림 덱을 셔플하여 재사용, 버림 덱도 비면 드로우 스킵 |
