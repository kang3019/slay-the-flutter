import 'entities/card.dart';
import 'entities/monster.dart';
import 'entities/monster_intent.dart';
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
/// endPlayerTurn 내부 순서: 패 버림 → 황금 방패 체크 → 몬스터 행동 → monster.endTurn →
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

  /// 이번 전투에서 아직 공격 카드를 사용하지 않았으면 true. [firstAttackBonus] 적용에 사용.
  bool _hasAttackedThisCombat;

  /// 도마뱀 꼬리([nearDeathSave])가 아직 발동 가능하면 true.
  bool _lizardTailAvailable;

  /// 전투 시작 시 추가 드로우할 카드 수. [extraDrawOnCombatStart] 유물들의 합산.
  final int _combatStartExtraDraw;

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
        _hasAttackedThisCombat = false,
        _lizardTailAvailable = false,
        _combatStartExtraDraw = relics
            .where((r) => r.effect == RelicEffect.extraDrawOnCombatStart)
            .fold(0, (sum, r) => sum + r.value) {
    _lizardTailAvailable =
        relics.any((r) => r.effect == RelicEffect.nearDeathSave);
    _applyCombatStartRelics();
  }

  /// 기본 덱(강타 5 + 방어 5)으로 새 전투를 시작한다.
  factory BattleEngine.start({
    required int stage,
    List<Relic> relics = const [],
  }) {
    final engine = BattleEngine(
      player: Player(),
      monster: Monster(stage: stage),
      deck: Deck(initialCards: _starterCards()),
      relics: relics,
    );
    engine.deck.shuffle();
    engine.startPlayerTurn();
    return engine;
  }

  /// 플레이어 턴 시작: 에너지 충전, [drawPerTurn]장 드로우.
  ///
  /// 첫 번째 턴에는 [extraEnergyOnFirstTurn] 유물과 [extraDrawOnCombatStart] 추가 드로우가 적용된다.
  void startPlayerTurn() {
    energy = energyPerTurn;

    if (_isFirstTurn) {
      for (final relic in relics) {
        if (relic.effect == RelicEffect.extraEnergyOnFirstTurn) {
          energy += relic.value;
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
  bool playCard(GameCard card) {
    if (isBattleOver) return false;
    if (energy < card.cost) return false;
    if (!deck.hand.contains(card)) return false;

    energy -= card.cost;
    deck.playCard(card);
    _applyCardEffect(card);
    _checkBattleOver();
    return true;
  }

  /// 플레이어 턴 종료.
  /// 패 버림 → 황금 방패 체크 → 몬스터 행동(블록 활성) → monster.endTurn →
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
  /// [extraDrawOnCombatStart]는 [startPlayerTurn]에서 처리하므로 여기서 제외.
  void _applyCombatStartRelics() {
    for (final relic in relics) {
      switch (relic.effect) {
        case RelicEffect.blockOnCombatStart:
          player.gainBlock(relic.value);
        case RelicEffect.healOnCombatStart:
          player.heal(relic.value);
        case RelicEffect.vulnerableEnemyOnCombatStart:
          monster.applyStatusEffect(
            StatusEffect(
              type: StatusEffectType.vulnerable,
              duration: relic.value,
            ),
          );
        case RelicEffect.weakEnemyOnCombatStart:
          monster.applyStatusEffect(
            StatusEffect(
              type: StatusEffectType.weak,
              duration: relic.value,
            ),
          );
        case RelicEffect.healOnBossCombatStart:
          if (monster.stage >= 3) player.heal(relic.value);
        default:
          break;
      }
    }
  }

  /// 턴 종료 시 발동하는 유물 효과를 적용한다.
  void _applyTurnEndRelics() {
    if (player.block == 0) {
      for (final relic in relics) {
        if (relic.effect == RelicEffect.blockIfNoneOnTurnEnd) {
          player.gainBlock(relic.value);
        }
      }
    }
  }

  void _applyCardEffect(GameCard card) {
    var value = card.value;

    // firstAttackBonus: 이번 전투 첫 번째 공격 카드에 추가 데미지.
    if (!_hasAttackedThisCombat && card.effectType == CardEffectType.damage) {
      for (final relic in relics) {
        if (relic.effect == RelicEffect.firstAttackBonus) {
          value += relic.value;
        }
      }
    }
    if (card.effectType == CardEffectType.damage) {
      _hasAttackedThisCombat = true;
    }

    // Focus는 다음 비-버프 카드의 효과값을 +50% 증가시킨다.
    if (_focusActive && card.effectType != CardEffectType.buff) {
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
        player.gainBlock(value);
      case CardType.focus:
        _focusActive = true;
      case CardType.recover:
        player.heal(value);
    }
  }

  /// SPECS.md: Weak 상태이면 데미지에 0.75 배율을 floor 적용한다.
  int _weakAdjusted(int value) =>
      player.isWeak ? (value * Player.weakMultiplier).floor() : value;

  void _runMonsterTurn() {
    final intent = monster.currentIntent;
    switch (intent.type) {
      case MonsterIntentType.attack:
      case MonsterIntentType.heavyAttack:
        player.takeDamage(intent.value);
      case MonsterIntentType.gainBlock:
        monster.gainBlock(intent.value);
    }
    monster.advanceIntent();
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
