import 'package:flutter_test/flutter_test.dart';
import 'package:slay_the_flutter/domain/battle_engine.dart';
import 'package:slay_the_flutter/domain/deck.dart';
import 'package:slay_the_flutter/domain/entities/card.dart';
import 'package:slay_the_flutter/domain/entities/monster.dart';
import 'package:slay_the_flutter/domain/entities/player.dart';
import 'package:slay_the_flutter/domain/status_effect.dart';

/// 지정 카드 목록으로 엔진을 생성하고 첫 턴을 시작한다.
BattleEngine _makeEngine({
  required List<GameCard> cards,
  Player? player,
  Monster? monster,
}) {
  final engine = BattleEngine(
    player: player ?? Player(),
    monster: monster ?? Monster(stage: 1),
    deck: Deck(initialCards: cards),
  );
  engine.startPlayerTurn();
  return engine;
}

void main() {
  group('플레이어 턴 시작 (startPlayerTurn)', () {
    test('에너지가 3으로 충전된다', () {
      final engine = _makeEngine(cards: []);
      expect(engine.energy, equals(3));
    });

    test('뽑는 더미에서 5장을 패로 가져온다', () {
      final engine = _makeEngine(cards: List.filled(10, Cards.strike));
      expect(engine.deck.hand.length, equals(5));
    });

    test('초기 전투는 종료 상태가 아니다', () {
      final engine = _makeEngine(cards: []);
      expect(engine.isBattleOver, isFalse);
      expect(engine.result, isNull);
    });
  });

  group('카드 플레이 — 에너지 및 유효성', () {
    test('에너지가 충분하면 카드 플레이에 성공한다', () {
      final engine = _makeEngine(cards: [Cards.strike]);
      expect(engine.playCard(Cards.strike), isTrue);
    });

    test('카드 플레이 후 에너지가 비용만큼 감소한다', () {
      final engine = _makeEngine(cards: [Cards.strike]); // 비용 1
      engine.playCard(Cards.strike);
      expect(engine.energy, equals(2));
    });

    test('에너지가 부족하면 카드 플레이에 실패한다', () {
      // ironWall 비용 2 — 에너지를 먼저 소진하고 시도
      final engine = _makeEngine(cards: [Cards.strike, Cards.ironWall]);
      engine.playCard(Cards.strike); // 에너지 2 남음
      engine.playCard(Cards.strike); // ... Cards.strike가 하나뿐이라 실패
      // 에너지를 직접 소진
      engine.energy = 1;
      expect(engine.playCard(Cards.ironWall), isFalse); // 비용 2 > 에너지 1
    });

    test('패에 없는 카드는 플레이에 실패한다', () {
      final engine = _makeEngine(cards: [Cards.defend]);
      expect(engine.playCard(Cards.strike), isFalse);
    });

    test('전투 종료 후 카드 플레이는 실패한다', () {
      final monster = Monster(stage: 1)..takeDamage(25); // HP = 5
      final engine = _makeEngine(cards: [Cards.strike, Cards.strike], monster: monster);
      engine.playCard(Cards.strike); // 6 데미지 → 몬스터 사망, 전투 종료
      expect(engine.playCard(Cards.strike), isFalse);
    });
  });

  group('카드 효과', () {
    test('Strike: 몬스터에게 6 데미지를 준다', () {
      final monster = Monster(stage: 1); // HP 30
      final engine = _makeEngine(cards: [Cards.strike], monster: monster);
      engine.playCard(Cards.strike);
      expect(monster.hp, equals(24));
    });

    test('Defend: 플레이어에게 방어도 5를 부여한다', () {
      final player = Player();
      final engine = _makeEngine(cards: [Cards.defend], player: player);
      engine.playCard(Cards.defend);
      expect(player.block, equals(5));
    });

    test('Iron Wall: 플레이어에게 방어도 10을 부여한다', () {
      final player = Player();
      final engine = _makeEngine(cards: [Cards.ironWall], player: player);
      engine.playCard(Cards.ironWall);
      expect(player.block, equals(10));
    });

    test('Bash: 몬스터에게 8 데미지 + Vulnerable 2턴을 부여한다', () {
      final monster = Monster(stage: 1); // HP 30
      final engine = _makeEngine(cards: [Cards.bash], monster: monster);
      engine.playCard(Cards.bash);
      expect(monster.hp, equals(22)); // 30 - 8
      expect(monster.isVulnerable, isTrue);
    });

    test('SwiftCut: 몬스터에게 4 데미지 × 2회 (합계 8)를 준다', () {
      final monster = Monster(stage: 1); // HP 30
      final engine = _makeEngine(cards: [Cards.swiftCut], monster: monster);
      engine.playCard(Cards.swiftCut);
      expect(monster.hp, equals(22)); // 30 - 4 - 4
    });

    test('Recover: 플레이어 HP를 8 회복한다', () {
      final player = Player(hp: 50);
      final engine = _makeEngine(cards: [Cards.recover], player: player);
      engine.playCard(Cards.recover);
      expect(player.hp, equals(58));
    });

    test('Recover: 최대 HP를 초과하지 않는다', () {
      final player = Player(hp: 68);
      final engine = _makeEngine(cards: [Cards.recover], player: player);
      engine.playCard(Cards.recover);
      expect(player.hp, equals(Player.maxHp));
    });

    test('Focus: 다음 카드 데미지를 +50% 증가시킨다', () {
      final monster = Monster(stage: 1); // HP 30
      final engine = _makeEngine(
        cards: [Cards.focus, Cards.strike],
        monster: monster,
      );
      engine.playCard(Cards.focus);
      engine.playCard(Cards.strike); // floor(6 × 1.5) = 9 데미지
      expect(monster.hp, equals(21)); // 30 - 9
    });

    test('Focus: 버프 카드에는 적용되지 않는다', () {
      final monster = Monster(stage: 1);
      final engine = _makeEngine(
        cards: [Cards.focus, Cards.focus, Cards.strike],
        monster: monster,
      );
      engine.playCard(Cards.focus);
      engine.playCard(Cards.focus); // 버프 카드 → Focus 소비 안 됨
      engine.playCard(Cards.strike); // Focus 여전히 활성 → 9 데미지
      expect(monster.hp, equals(21));
    });
  });

  group('턴 종료 (endPlayerTurn)', () {
    test('패가 전부 버리는 더미로 이동한다', () {
      final engine = _makeEngine(cards: List.filled(5, Cards.strike));
      engine.endPlayerTurn();
      expect(engine.deck.hand, isEmpty);
      expect(engine.deck.discardPile.isNotEmpty, isTrue);
    });

    test('몬스터가 플레이어를 공격한다 (스테이지 1: 공격력 10)', () {
      final player = Player();
      final engine = _makeEngine(cards: [], player: player);
      engine.endPlayerTurn();
      expect(player.hp, equals(60)); // 70 - 10
    });

    test('블록이 몬스터 공격을 흡수한다 (endPlayerTurn 시 블록 활성)', () {
      final player = Player();
      final engine = _makeEngine(cards: [Cards.defend], player: player);
      engine.playCard(Cards.defend); // 방어도 5 획득
      engine.endPlayerTurn(); // 몬스터 공격 10 → 5 흡수 → 5 HP 손실
      expect(player.hp, equals(65)); // 70 - (10 - 5)
    });

    test('플레이어 방어도는 몬스터 행동 이후 소멸한다', () {
      final player = Player();
      final engine = _makeEngine(cards: [Cards.ironWall], player: player);
      engine.playCard(Cards.ironWall); // 방어도 10 획득
      engine.endPlayerTurn(); // 몬스터 공격 10 → 방어도가 전부 흡수, 이후 소멸
      expect(player.hp, equals(70)); // HP 손실 없음
      expect(player.block, equals(0)); // 방어도 소멸
    });
  });

  group('전투 승패 판정', () {
    test('몬스터 HP가 0이 되면 플레이어 승리', () {
      final monster = Monster(stage: 1)..takeDamage(25); // HP = 5
      final engine = _makeEngine(cards: [Cards.strike], monster: monster);
      engine.playCard(Cards.strike); // 6 데미지 → 몬스터 사망
      expect(engine.isBattleOver, isTrue);
      expect(engine.result, equals(BattleResult.playerWon));
    });

    test('플레이어 HP가 0이 되면 패배', () {
      final player = Player(hp: 5);
      final engine = _makeEngine(
        cards: [],
        player: player,
        monster: Monster(stage: 1), // 공격력 10
      );
      engine.endPlayerTurn(); // 몬스터 10 공격 → HP 0
      expect(engine.isBattleOver, isTrue);
      expect(engine.result, equals(BattleResult.playerLost));
    });
  });

  group('Weak 상태 이상 — 딜 감소', () {
    test('Weak 상태에서 Strike 데미지가 floor(6 × 0.75) = 4로 감소한다', () {
      final player = Player();
      player.applyStatusEffect(
        const StatusEffect(type: StatusEffectType.weak, duration: 2),
      );
      final monster = Monster(stage: 1); // HP 30
      final engine = _makeEngine(
        cards: [Cards.strike],
        player: player,
        monster: monster,
      );
      engine.playCard(Cards.strike); // floor(6 × 0.75) = 4
      expect(monster.hp, equals(26)); // 30 - 4
    });
  });
}
