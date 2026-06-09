import 'dart:math';

import 'entities/card.dart';
import 'entities/monster.dart';
import 'entities/player.dart';
import 'map/node_type.dart';
import 'entities/relic.dart';
import 'deck.dart';
import 'status_effect.dart';

/// 전투 최종 결과.
enum BattleResult { playerWon, playerLost }

/// 턴 흐름과 카드 효과 적용을 담당하는 핵심 게임 규칙 엔진.
///
/// 순수 Dart 클래스 — Flutter·Riverpod 임포트 금지.
///
/// 턴 순서: startPlayerTurn → playCard(s) → endPlayerTurn → (반복)
/// endPlayerTurn 내부 순서: 패 버림 → 턴 종료 유물 체크 → 몬스터 행동 → monster.endTurn →
///   player.endTurn(블록 소멸) — 블록이 몬스터 공격을 막을 수 있도록 보장.
class BattleEngine {
  /// SPECS.md: 턴당 에너지.
  static const int energyPerTurn = 3;

  /// SPECS.md: 턴당 드로우 수.
  static const int drawPerTurn = 5;

  final Player player;
  final Monster monster;
  final Deck deck;

  /// 현재 전투에 적용 중인 유물 목록.
  final List<Relic> relics;

  int energy;
  bool isBattleOver;
  BattleResult? result;
  bool _focusActive;

  /// 활성화된 집중([CardType.focus]) 카드의 보너스 퍼센트 (50 또는 75).
  /// [_focusActive]가 true일 때만 유효하다.
  int _focusBonus;

  // ── 유물 상태 추적 플래그 ─────────────────────────────────────────────────

  /// 아직 첫 번째 턴이 시작되지 않았으면 true. [extraEnergyOnFirstTurn] 적용에 사용.
  bool _isFirstTurn;

  /// 이번 전투에서 사용한 공격 카드 수. [firstAttackBonus], [secondAttackBonus] 판정에 사용.
  int _attackCountThisCombat;

  /// 이번 전투에서 아직 블록 카드를 사용하지 않았으면 true. [firstBlockBonus] 적용에 사용.
  bool _hasBlockedThisCombat;

  /// 도마뱀 꼬리([nearDeathSave])가 아직 발동 가능하면 true.
  bool _lizardTailAvailable;

  /// 전투 시작 시 추가 드로우할 카드 수. [extraDrawOnCombatStart], [blockAndExtraDrawOnCombatStart] 합산.
  final int _combatStartExtraDraw;

  /// 무기 연마([CardType.sharpen])로 이번 턴 공격 카드에 더해지는 추가 데미지.
  int _sharpenBonus;

  /// 폭격 태세([CardType.doubleTap])로 남은 추가 발동 횟수.
  int _doubleTapCount;

  /// 직전 [endPlayerTurn]에서 발동된 턴 종료 유물 메시지.
  /// [endPlayerTurn] 시작 시 초기화, [_applyTurnEndRelics]에서 채워진다.
  final List<String> lastRelicTriggers = [];

  BattleEngine({
    required this.player,
    required this.monster,
    required this.deck,
    this.relics = const [],
  })  : energy = 0,
        isBattleOver = false,
        result = null,
        _focusActive = false,
        _focusBonus = 0,
        _isFirstTurn = true,
        _attackCountThisCombat = 0,
        _hasBlockedThisCombat = false,
        _lizardTailAvailable = false,
        _sharpenBonus = 0,
        _doubleTapCount = 0,
        _combatStartExtraDraw = relics.fold<int>(0, (sum, r) {
          if (r.effect == RelicEffect.extraDrawOnCombatStart) return sum + r.value;
          if (r.effect == RelicEffect.blockAndExtraDrawOnCombatStart) return sum + 1;
          return sum;
        }) {
    _lizardTailAvailable =
        relics.any((r) => r.effect == RelicEffect.nearDeathSave);
    _applyCombatStartRelics();
  }

  /// 지정 덱으로 새 전투를 시작한다. [cards]가 비어있으면 기본 덱을 사용한다.
  ///
  /// [monsterType]을 지정하지 않으면 [stage]에 맞는 타입을 무작위로 선택한다.
  factory BattleEngine.start({
    required int stage,
    List<Relic> relics = const [],
    List<GameCard> cards = const [],
    int? playerHp,
    MonsterType? monsterType,
  }) {
    final type = monsterType ?? _randomMonsterType(stage);
    final engine = BattleEngine(
      player: Player(hp: playerHp ?? Player.maxHp),
      monster: Monster(stage: stage, type: type),
      deck: Deck(initialCards: cards.isEmpty ? _starterCards() : List.of(cards)),
      relics: relics,
    );
    engine.deck.shuffle();
    engine.startPlayerTurn();
    return engine;
  }

  /// [NodeType]과 스테이지를 기반으로 적절한 [MonsterType]을 반환한다.
  ///
  /// - boss  → 항상 ironGolem
  /// - elite → 현재 스테이지보다 강한 몬스터 풀 (ironGolem 제외)
  /// - 그 외 → 스테이지에 맞는 일반 몬스터 풀 (ironGolem 제외)
  static MonsterType monsterTypeFor(
    NodeType nodeType,
    int stage, {
    Random? random,
  }) {
    if (nodeType == NodeType.boss) return MonsterType.ironGolem;
    final rng = random ?? Random();
    if (nodeType == NodeType.elite) return _eliteMonsterType(stage, rng);
    return _normalMonsterType(stage, rng);
  }

  /// 엘리트 노드 몬스터: 스테이지 무관하게 독파수꾼 또는 석굴 수호자.
  static MonsterType _eliteMonsterType(int stage, Random rng) =>
      rng.nextBool() ? MonsterType.venomSentinel : MonsterType.caveGuardian;

  /// 일반 노드 몬스터: 스테이지 무관하게 끈적 슬라임 또는 고철수집가.
  static MonsterType _normalMonsterType(int stage, Random rng) =>
      rng.nextBool() ? MonsterType.stickySlime : MonsterType.ironScavenger;

  /// 스테이지에 맞는 몬스터 타입을 무작위로 반환한다.
  static MonsterType _randomMonsterType(int stage) =>
      _normalMonsterType(stage, Random());

  /// 플레이어 턴 시작: 에너지 충전, [drawPerTurn]장 드로우.
  ///
  /// 첫 번째 턴에는 [extraEnergyOnFirstTurn], [extraEnergyOnLowHP], [addFocusCardOnCombatStart] 유물이 추가 적용된다.
  /// [healOnTurnStart] 유물은 매 턴 적용된다.
  void startPlayerTurn() {
    energy = energyPerTurn;
    _sharpenBonus = 0;
    _doubleTapCount = 0;

    for (final relic in relics) {
      if (relic.effect == RelicEffect.healOnTurnStart) {
        player.heal(relic.value);
      }
    }

    // 독 피해: 블록을 무시하고 stack 수치만큼 직접 HP 감소.
    final playerPoison = player.poisonStacks;
    if (playerPoison > 0) {
      player.hp = (player.hp - playerPoison).clamp(0, Player.maxHp);
      _checkBattleOver();
      if (isBattleOver) return;
    }

    if (_isFirstTurn) {
      for (final relic in relics) {
        if (relic.effect == RelicEffect.extraEnergyOnFirstTurn) {
          energy += relic.value;
        }
        if (relic.effect == RelicEffect.extraEnergyOnLowHP &&
            player.hp <= (Player.maxHp * 0.5).floor()) {
          energy += relic.value;
        }
        if (relic.effect == RelicEffect.addFocusCardOnCombatStart) {
          for (var i = 0; i < relic.value; i++) {
            deck.addToHand(Cards.focus);
          }
        }
      }
      deck.draw(drawPerTurn + _combatStartExtraDraw);
      _isFirstTurn = false;
    } else {
      deck.draw(drawPerTurn);
    }
  }

  /// 패에서 [card]를 사용한다.
  /// 전투 종료·에너지 부족·패에 없는 카드인 경우 false 반환.
  /// X 비용 카드(cost == -1)는 남은 에너지 전부를 X로 사용하며 에너지 > 0이어야 한다.
  bool playCard(GameCard card) {
    if (isBattleOver) return false;
    if (!deck.hand.contains(card)) return false;

    int xValue = 0;
    if (card.cost == -1) {
      if (energy == 0) return false;
      xValue = energy;
      energy = 0;
    } else {
      if (energy < card.cost) return false;
      energy -= card.cost;
    }

    deck.playCard(card);
    _applyCardEffect(card, xValue: xValue);

    // 폭격 태세: 공격 카드는 데미지만 한 번 더 적용한다.
    if (_doubleTapCount > 0 && card.effectType == CardEffectType.damage) {
      _doubleTapCount--;
      monster.takeDamage(_computeRawDamage(card, xValue: xValue));
    }

    _checkBattleOver();
    return true;
  }

  /// 플레이어 턴 종료.
  /// 패 버림 → 턴 종료 유물 → 몬스터 행동(블록 활성) → monster.endTurn →
  ///   player.endTurn(블록 소멸).
  void endPlayerTurn() {
    lastRelicTriggers.clear();
    deck.discardHand();
    _applyTurnEndRelics();

    if (!isBattleOver) {
      monster.endTurn();   // 독 피해 + 방어도·상태이상 정리
      _checkBattleOver();  // 독으로 몬스터 사망 여부 확인
      if (!isBattleOver) {
        _runMonsterTurn();   // 몬스터 행동 (새 방어도·공격 적용)
        _checkBattleOver();
      }
    }

    player.endTurn();
  }

  // ── 유물 적용 ─────────────────────────────────────────────────────────────

  /// 전투 시작 시 발동하는 유물 효과를 적용한다.
  ///
  /// [extraDrawOnCombatStart], [blockAndExtraDrawOnCombatStart]는 [startPlayerTurn]에서 처리.
  /// [extraEnergyOnFirstTurn], [extraEnergyOnLowHP], [addFocusCardOnCombatStart]도 [startPlayerTurn]에서 처리.
  void _applyCombatStartRelics() {
    for (final relic in relics) {
      switch (relic.effect) {
        case RelicEffect.blockOnCombatStart:
          player.gainBlock(relic.value);
        case RelicEffect.blockAndExtraDrawOnCombatStart:
          player.gainBlock(relic.value);
        case RelicEffect.healOnCombatStart:
          player.heal(relic.value);
        case RelicEffect.vulnerableEnemyOnCombatStart:
          monster.applyStatusEffect(
            StatusEffect(type: StatusEffectType.vulnerable, duration: relic.value),
          );
        case RelicEffect.weakEnemyOnCombatStart:
          monster.applyStatusEffect(
            StatusEffect(type: StatusEffectType.weak, duration: relic.value),
          );
        case RelicEffect.vulnerableAndWeakOnCombatStart:
          monster.applyStatusEffect(
            StatusEffect(type: StatusEffectType.vulnerable, duration: relic.value),
          );
          monster.applyStatusEffect(
            StatusEffect(type: StatusEffectType.weak, duration: relic.value),
          );
        case RelicEffect.healOnBossCombatStart:
          if (monster.stage >= 3) player.heal(relic.value);
        case RelicEffect.strengthOnCombatStart:
          player.strength += relic.value;
        case RelicEffect.strengthOnBossCombatStart:
          if (monster.stage >= 3) player.strength += relic.value;
        default:
          break;
      }
    }
  }

  /// 턴 종료 시 발동하는 유물 효과를 적용한다.
  void _applyTurnEndRelics() {
    for (final relic in relics) {
      switch (relic.effect) {
        case RelicEffect.blockIfNoneOnTurnEnd:
          if (player.block == 0) {
            player.gainBlock(relic.value);
            lastRelicTriggers.add('${relic.name} +${relic.value} 방어도');
          }
        case RelicEffect.blockPerRemainingEnergy:
          if (energy > 0) {
            final gained = energy * relic.value;
            player.gainBlock(gained);
            lastRelicTriggers.add('${relic.name} +$gained 방어도');
          }
        default:
          break;
      }
    }
  }

  void _applyCardEffect(GameCard card, {int xValue = 0}) {
    var value = card.value;

    if (card.effectType == CardEffectType.damage) {
      value += player.strength;
      value += _sharpenBonus;

      _attackCountThisCombat++;
      for (final relic in relics) {
        if (relic.effect == RelicEffect.firstAttackBonus && _attackCountThisCombat == 1) {
          value += relic.value;
        }
        if (relic.effect == RelicEffect.secondAttackBonus && _attackCountThisCombat == 2) {
          value += relic.value;
        }
      }
    }

    // Focus: 다음 비-버프·비-드로우 카드의 효과값을 증가시킨다.
    // 기본 집중 +50%, 강화 집중 +75% — _focusBonus(50 또는 75)로 배율을 결정한다.
    if (_focusActive &&
        card.effectType != CardEffectType.buff &&
        card.effectType != CardEffectType.draw) {
      value = (value * (1.0 + _focusBonus / 100)).floor();
      _focusActive = false;
      _focusBonus = 0;
    }

    switch (card.type) {
      case CardType.strike:
        monster.takeDamage(_weakAdjusted(value));
      case CardType.bash:
        monster.takeDamage(_weakAdjusted(value));
        monster.applyStatusEffect(
          const StatusEffect(type: StatusEffectType.vulnerable, duration: 2),
        );
      case CardType.swiftCut:
        final dmg = _weakAdjusted(value);
        monster.takeDamage(dmg);
        monster.takeDamage(dmg);
      case CardType.defend:
      case CardType.ironWall:
        player.gainBlock(_applyFirstBlockBonus(value));
      case CardType.focus:
        _focusActive = true;
        // card.value = 50(기본) 또는 75(강화+). 플레이 시 보너스 퍼센트를 저장한다.
        _focusBonus = card.value;
      case CardType.recover:
        player.heal(value);
      case CardType.rageBurst:
        monster.takeDamage(_weakAdjusted(value));
        deck.addToDiscard(card);
      case CardType.toxicJab:
        monster.takeDamage(_weakAdjusted(value));
        // 강화 시 취약 3턴, 기본 2턴.
        monster.applyStatusEffect(
          StatusEffect(type: StatusEffectType.vulnerable, duration: card.isUpgraded ? 3 : 2),
        );
      case CardType.regroup:
        deck.draw(value);
      case CardType.crushingBlow:
        monster.takeDamage(_weakAdjusted(value));
        deck.exhaustLastPlayed();
      case CardType.fury:
        player.strength += value;
      case CardType.tripleSlash:
        final dmg = _weakAdjusted(value);
        monster.takeDamage(dmg);
        monster.takeDamage(dmg);
        monster.takeDamage(dmg);
      case CardType.quickMend:
        player.heal(value);
        deck.exhaustLastPlayed();
      case CardType.swiftGuard:
        player.gainBlock(_applyFirstBlockBonus(value));
        deck.draw(1);
      case CardType.exploitWeakness:
        // 강화 시 취약 보너스 +9, 기본 +6.
        final bonus = monster.isVulnerable ? (card.isUpgraded ? 9 : 6) : 0;
        monster.takeDamage(_weakAdjusted(value + bonus));
      case CardType.sharpen:
        _sharpenBonus += value;
      case CardType.weakSlash:
        monster.takeDamage(_weakAdjusted(value));
        // 강화 시 약화 3턴, 기본 2턴.
        monster.applyStatusEffect(
          StatusEffect(type: StatusEffectType.weak, duration: card.isUpgraded ? 3 : 2),
        );
      case CardType.blockStrike:
        // 강화 시 방어도 × 1.5 데미지, 기본 방어도 수치 그대로.
        final blockDmg = card.isUpgraded
            ? (player.block * 1.5).floor()
            : player.block;
        monster.takeDamage(_weakAdjusted(blockDmg));
      case CardType.bloodRush:
        monster.takeDamage(_weakAdjusted(xValue * card.value));
      case CardType.devilsDeal:
        player.hp = (player.hp - card.value).clamp(0, Player.maxHp);
        if (!player.isDead) deck.draw(3);
      case CardType.battleCry:
        deck.draw(2);
        // 강화 시 힘 +2, 기본 힘 +1.
        player.strength += card.isUpgraded ? 2 : 1;
        deck.exhaustLastPlayed();
      case CardType.indomitable:
        final blockAmt = card.value + (player.strength > 0 ? player.strength : 0);
        player.gainBlock(_applyFirstBlockBonus(blockAmt));
      case CardType.comboStrike:
        final attackCount = deck.hand
            .where((c) => c.effectType == CardEffectType.damage)
            .length;
        monster.takeDamage(_weakAdjusted(attackCount * card.value));
      case CardType.gamble:
        player.hp = (player.hp - card.value).clamp(0, Player.maxHp);
        if (!player.isDead) energy += 2;
      case CardType.poisonDart:
        monster.takeDamage(_weakAdjusted(value));
        // 강화 시 독 5스택, 기본 3스택.
        monster.applyStatusEffect(
          StatusEffect(type: StatusEffectType.poison, duration: card.isUpgraded ? 5 : 3),
        );
      case CardType.limitBreak:
        player.strength *= 2;
        if (card.isUpgraded) deck.exhaustLastPlayed();
      case CardType.impervious:
        player.gainBlock(_applyFirstBlockBonus(value));
        deck.exhaustLastPlayed();
      case CardType.doubleTap:
        _doubleTapCount += card.value;
      case CardType.fiendFire:
        final handCount = deck.hand.length;
        deck.discardHand();
        monster.takeDamage(_weakAdjusted(handCount * value));
        deck.exhaustLastPlayed();
    }
  }

  /// 폭격 태세의 추가 발동에 사용되는 순수 데미지 계산. side-effect 없음.
  int _computeRawDamage(GameCard card, {int xValue = 0}) {
    return switch (card.type) {
      CardType.blockStrike => _weakAdjusted(
          card.isUpgraded ? (player.block * 1.5).floor() : player.block,
        ),
      CardType.bloodRush   => _weakAdjusted(xValue * card.value),
      CardType.comboStrike => _weakAdjusted(
          deck.hand.where((c) => c.effectType == CardEffectType.damage).length *
              card.value,
        ),
      CardType.fiendFire   => _weakAdjusted(deck.hand.length * card.value),
      _                    => _weakAdjusted(
          card.value + player.strength + _sharpenBonus,
        ),
    };
  }

  /// 첫 번째 블록 카드 사용 시 [firstBlockBonus] 유물 보너스를 반영한 값을 반환한다.
  int _applyFirstBlockBonus(int value) {
    if (!_hasBlockedThisCombat) {
      for (final relic in relics) {
        if (relic.effect == RelicEffect.firstBlockBonus) value += relic.value;
      }
      _hasBlockedThisCombat = true;
    }
    return value;
  }

  /// SPECS.md: Weak 상태이면 데미지에 0.75 배율을 floor 적용한다.
  int _weakAdjusted(int value) =>
      player.isWeak ? (value * Player.weakMultiplier).floor() : value;

  void _runMonsterTurn() {
    monster.executeAction(player);
  }

  void _checkBattleOver() {
    if (monster.isDead) {
      isBattleOver = true;
      result = BattleResult.playerWon;
    } else if (player.isDead) {
      // nearDeathSave(도마뱀 꼬리): 최초 사망 시 HP 1로 되살린다.
      if (_lizardTailAvailable) {
        _lizardTailAvailable = false;
        player.hp = 1;
      } else {
        isBattleOver = true;
        result = BattleResult.playerLost;
      }
    }
  }

  static List<GameCard> _starterCards() => [
        ...List.filled(5, Cards.strike),
        ...List.filled(5, Cards.defend),
      ];
}
