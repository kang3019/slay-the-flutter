import 'entities/card.dart';
import 'entities/monster.dart';
import 'entities/player.dart';
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

  BattleEngine({
    required this.player,
    required this.monster,
    required this.deck,
    this.relics = const [],
  })  : energy = 0,
        isBattleOver = false,
        result = null,
        _focusActive = false,
        _isFirstTurn = true,
        _attackCountThisCombat = 0,
        _hasBlockedThisCombat = false,
        _lizardTailAvailable = false,
        _sharpenBonus = 0,
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
  factory BattleEngine.start({
    required int stage,
    List<Relic> relics = const [],
    List<GameCard> cards = const [],
    int? playerHp,
  }) {
    final engine = BattleEngine(
      player: Player(hp: playerHp ?? Player.maxHp),
      monster: Monster(stage: stage),
      deck: Deck(initialCards: cards.isEmpty ? _starterCards() : List.of(cards)),
      relics: relics,
    );
    engine.deck.shuffle();
    engine.startPlayerTurn();
    return engine;
  }

  /// 플레이어 턴 시작: 에너지 충전, [drawPerTurn]장 드로우.
  ///
  /// 첫 번째 턴에는 [extraEnergyOnFirstTurn], [extraEnergyOnLowHP], [addFocusCardOnCombatStart] 유물이 추가 적용된다.
  /// [healOnTurnStart] 유물은 매 턴 적용된다.
  void startPlayerTurn() {
    energy = energyPerTurn;
    _sharpenBonus = 0;

    for (final relic in relics) {
      if (relic.effect == RelicEffect.healOnTurnStart) {
        player.heal(relic.value);
      }
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
    _checkBattleOver();
    return true;
  }

  /// 플레이어 턴 종료.
  /// 패 버림 → 턴 종료 유물 → 몬스터 행동(블록 활성) → monster.endTurn →
  ///   player.endTurn(블록 소멸).
  void endPlayerTurn() {
    deck.discardHand();
    _applyTurnEndRelics();

    if (!isBattleOver) {
      _runMonsterTurn();
      monster.endTurn();
      _checkBattleOver();
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
          if (player.block == 0) player.gainBlock(relic.value);
        case RelicEffect.blockPerRemainingEnergy:
          if (energy > 0) player.gainBlock(energy * relic.value);
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

    // Focus: 다음 비-버프·비-드로우 카드의 효과값을 +50% 증가시킨다.
    if (_focusActive &&
        card.effectType != CardEffectType.buff &&
        card.effectType != CardEffectType.draw) {
      value = (value * 1.5).floor();
      _focusActive = false;
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
      case CardType.recover:
        player.heal(value);
      case CardType.rageBurst:
        monster.takeDamage(_weakAdjusted(value));
        deck.addToDiscard(card);
      case CardType.toxicJab:
        monster.takeDamage(_weakAdjusted(value));
        monster.applyStatusEffect(
          const StatusEffect(type: StatusEffectType.vulnerable, duration: 2),
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
        final bonus = monster.isVulnerable ? 6 : 0;
        monster.takeDamage(_weakAdjusted(value + bonus));
      case CardType.sharpen:
        _sharpenBonus += value;
      case CardType.weakSlash:
        monster.takeDamage(_weakAdjusted(value));
        monster.applyStatusEffect(
          const StatusEffect(type: StatusEffectType.weak, duration: 2),
        );
      case CardType.blockStrike:
        monster.takeDamage(_weakAdjusted(player.block));
      case CardType.bloodRush:
        monster.takeDamage(_weakAdjusted(xValue * card.value));
      case CardType.devilsDeal:
        player.hp = (player.hp - card.value).clamp(0, Player.maxHp);
        if (!player.isDead) deck.draw(3);
      case CardType.battleCry:
        deck.draw(2);
        player.strength += 1;
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
    }
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
    player.takeDamage(monster.attackPower);
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
