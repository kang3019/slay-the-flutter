import 'entities/card.dart';
import 'entities/monster.dart';
import 'entities/player.dart';
import 'deck.dart';
import 'status_effect.dart';

/// 전투 최종 결과.
enum BattleResult { playerWon, playerLost }

/// 턴 흐름과 카드 효과 적용을 담당하는 핵심 게임 규칙 엔진.
///
/// 순수 Dart 클래스 — Flutter·Riverpod 임포트 금지.
///
/// 턴 순서: startPlayerTurn → playCard(s) → endPlayerTurn → (반복)
/// endPlayerTurn 내부 순서: 패 버림 → 몬스터 행동 → monster.endTurn →
///   player.endTurn(블록 소멸) — 블록이 몬스터 공격을 막을 수 있도록 보장.
class BattleEngine {
  /// SPECS.md: 턴당 에너지.
  static const int energyPerTurn = 3;

  /// SPECS.md: 턴당 드로우 수.
  static const int drawPerTurn = 5;

  final Player player;
  final Monster monster;
  final Deck deck;

  int energy;
  bool isBattleOver;
  BattleResult? result;
  bool _focusActive;

  BattleEngine({
    required this.player,
    required this.monster,
    required this.deck,
  })  : energy = 0,
        isBattleOver = false,
        result = null,
        _focusActive = false;

  /// 기본 덱(강타 5 + 방어 5)으로 새 전투를 시작한다.
  factory BattleEngine.start({required int stage}) {
    final engine = BattleEngine(
      player: Player(),
      monster: Monster(stage: stage),
      deck: Deck(initialCards: _starterCards()),
    );
    engine.deck.shuffle();
    engine.startPlayerTurn();
    return engine;
  }

  /// 플레이어 턴 시작: 에너지 충전 및 [drawPerTurn]장 드로우.
  void startPlayerTurn() {
    energy = energyPerTurn;
    deck.draw(drawPerTurn);
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
  /// 패 버림 → 몬스터 행동(블록 활성) → monster.endTurn → player.endTurn(블록 소멸).
  void endPlayerTurn() {
    deck.discardHand();

    if (!isBattleOver) {
      _runMonsterTurn();
      monster.endTurn();
      _checkBattleOver();
    }

    player.endTurn();
  }

  void _applyCardEffect(GameCard card) {
    var value = card.value;

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
    player.takeDamage(monster.attackPower);
  }

  void _checkBattleOver() {
    if (monster.isDead) {
      isBattleOver = true;
      result = BattleResult.playerWon;
    } else if (player.isDead) {
      isBattleOver = true;
      result = BattleResult.playerLost;
    }
  }

  static List<GameCard> _starterCards() => [
        ...List.filled(5, Cards.strike),
        ...List.filled(5, Cards.defend),
      ];
}
