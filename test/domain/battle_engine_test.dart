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

  group('새 카드 효과', () {
    test('광분: 5 데미지 + 버리는 더미에 복사본 추가', () {
      final monster = Monster(stage: 1); // HP 30
      final engine = _makeEngine(cards: [Cards.rageBurst], monster: monster);
      engine.playCard(Cards.rageBurst);
      expect(monster.hp, equals(25));
      // 플레이한 원본 + 복사본 = 2장
      expect(engine.deck.discardPile.where((c) => c == Cards.rageBurst).length, equals(2));
    });

    test('독침: 5 데미지 + 적에게 취약 2턴', () {
      final monster = Monster(stage: 1); // HP 30
      final engine = _makeEngine(cards: [Cards.toxicJab], monster: monster);
      engine.playCard(Cards.toxicJab);
      expect(monster.hp, equals(25));
      expect(monster.isVulnerable, isTrue);
    });

    test('결집: 카드 2장 드로우', () {
      final cards = [...List.filled(7, Cards.strike), Cards.regroup];
      final engine = _makeEngine(cards: cards);
      // startPlayerTurn: 5장 패, 나머지 드로우 파일에
      final handBefore = engine.deck.hand.length; // 5
      engine.playCard(Cards.regroup); // 패에서 제거 후 2장 드로우 → 5 - 1 + 2 = 6
      expect(engine.deck.hand.length, equals(handBefore - 1 + 2));
    });

    test('파괴의 일격: 20 데미지 + 소멸(버리는 더미에 없음)', () {
      final monster = Monster(stage: 1); // HP 30
      final engine = _makeEngine(cards: [Cards.crushingBlow], monster: monster);
      engine.playCard(Cards.crushingBlow);
      expect(monster.hp, equals(10));
      expect(engine.deck.discardPile, isEmpty);
      expect(engine.deck.exhaustPile.length, equals(1));
    });

    test('분노: 힘 +2 후 공격 카드 데미지 증가', () {
      final monster = Monster(stage: 1); // HP 30
      final player = Player();
      final engine = _makeEngine(cards: [Cards.fury, Cards.strike], player: player, monster: monster);
      engine.playCard(Cards.fury);
      expect(player.strength, equals(2));
      engine.playCard(Cards.strike); // 6 + 2 = 8 데미지
      expect(monster.hp, equals(22));
    });

    test('세 번 베기: 3 데미지 × 3회 = 합계 9', () {
      final monster = Monster(stage: 1); // HP 30
      final engine = _makeEngine(cards: [Cards.tripleSlash], monster: monster);
      engine.playCard(Cards.tripleSlash);
      expect(monster.hp, equals(21));
    });

    test('응급처치: HP 5 회복 + 소멸', () {
      final player = Player(hp: 50);
      final engine = _makeEngine(cards: [Cards.quickMend], player: player);
      engine.playCard(Cards.quickMend);
      expect(player.hp, equals(55));
      expect(engine.deck.discardPile, isEmpty);
      expect(engine.deck.exhaustPile.length, equals(1));
    });

    test('날렵한 방어: 방어도 6 + 카드 1장 드로우', () {
      final player = Player();
      final cards = [...List.filled(6, Cards.strike), Cards.swiftGuard];
      final engine = _makeEngine(cards: cards, player: player);
      final handBefore = engine.deck.hand.length; // 5
      engine.playCard(Cards.swiftGuard); // 패 -1 + 드로우 +1 = 5
      expect(player.block, equals(6));
      expect(engine.deck.hand.length, equals(handBefore - 1 + 1));
    });

    test('취약 틈새: 일반 상태 9 데미지', () {
      final monster = Monster(stage: 1); // HP 30
      final engine = _makeEngine(cards: [Cards.exploitWeakness], monster: monster);
      engine.playCard(Cards.exploitWeakness);
      expect(monster.hp, equals(21));
    });

    test('취약 틈새: 적이 취약 상태면 (9+6)=15 → 몬스터 1.5배 적용 = 22 데미지', () {
      final monster = Monster(stage: 1)
        ..applyStatusEffect(const StatusEffect(type: StatusEffectType.vulnerable, duration: 2));
      final engine = _makeEngine(cards: [Cards.exploitWeakness], monster: monster);
      engine.playCard(Cards.exploitWeakness);
      expect(monster.hp, equals(8)); // 30 - floor(15 × 1.5) = 30 - 22
    });

    test('약화 강타: 12 데미지 + 적 약화 2턴', () {
      final monster = Monster(stage: 1); // HP 30
      final engine = _makeEngine(cards: [Cards.weakSlash], monster: monster);
      engine.playCard(Cards.weakSlash);
      expect(monster.hp, equals(18)); // 30 - 12
      expect(monster.isWeak, isTrue);
    });

    test('방어도 공격: 방어도만큼 데미지', () {
      final monster = Monster(stage: 1); // HP 30
      final player = Player();
      final engine = _makeEngine(cards: [Cards.blockStrike], player: player, monster: monster);
      player.gainBlock(8);
      engine.playCard(Cards.blockStrike);
      expect(monster.hp, equals(22)); // 30 - 8
    });

    test('방어도 공격: 방어도 0이면 데미지 0', () {
      final monster = Monster(stage: 1); // HP 30
      final engine = _makeEngine(cards: [Cards.blockStrike], monster: monster);
      engine.playCard(Cards.blockStrike);
      expect(monster.hp, equals(30));
    });

    test('혈기: 에너지 3이면 X=3, 18 데미지 후 에너지 소진', () {
      final monster = Monster(stage: 1); // HP 30
      final engine = _makeEngine(cards: [Cards.bloodRush], monster: monster);
      engine.playCard(Cards.bloodRush); // X=3, 3×6=18
      expect(monster.hp, equals(12));
      expect(engine.energy, equals(0));
    });

    test('혈기: 에너지 0이면 사용 불가', () {
      final engine = _makeEngine(cards: [Cards.bloodRush]);
      engine.energy = 0;
      expect(engine.playCard(Cards.bloodRush), isFalse);
    });

    test('혈기: 에너지 1이면 X=1, 6 데미지', () {
      final monster = Monster(stage: 1); // HP 30
      final engine = _makeEngine(cards: [Cards.bloodRush], monster: monster);
      engine.energy = 1;
      engine.playCard(Cards.bloodRush); // X=1, 1×6=6
      expect(monster.hp, equals(24));
    });

    test('악마의 거래: HP -6, 카드 3장 드로우', () {
      final player = Player(hp: 50);
      final cards = [...List.filled(10, Cards.strike), Cards.devilsDeal];
      final engine = _makeEngine(cards: cards, player: player);
      final handBefore = engine.deck.hand.length;
      engine.playCard(Cards.devilsDeal);
      expect(player.hp, equals(44));
      expect(engine.deck.hand.length, equals(handBefore - 1 + 3));
    });

    test('전투 함성: 드로우 2 + 힘 +1, 소멸', () {
      final player = Player();
      final cards = [...List.filled(9, Cards.strike), Cards.battleCry];
      final engine = _makeEngine(cards: cards, player: player);
      final handBefore = engine.deck.hand.length;
      engine.playCard(Cards.battleCry);
      expect(player.strength, equals(1));
      expect(engine.deck.hand.length, equals(handBefore - 1 + 2));
      expect(engine.deck.exhaustPile.length, equals(1));
    });

    test('불굴: 방어도 3 획득', () {
      final player = Player();
      final engine = _makeEngine(cards: [Cards.indomitable], player: player);
      engine.playCard(Cards.indomitable);
      expect(player.block, equals(3));
    });

    test('불굴: 힘이 2이면 방어도 5 획득', () {
      final player = Player(strength: 2);
      final engine = _makeEngine(cards: [Cards.indomitable], player: player);
      engine.playCard(Cards.indomitable);
      expect(player.block, equals(5)); // 3 + 2
    });

    test('연속 강타: 손패의 공격 카드 수 × 4 데미지', () {
      final monster = Monster(stage: 1); // HP 30
      // 손패: [defend, strike, strike, comboStrike] → comboStrike 사용 후 공격패 2장 → 2×4=8
      final cards = [Cards.defend, Cards.strike, Cards.strike, Cards.comboStrike];
      final engine = _makeEngine(cards: cards, monster: monster);
      engine.playCard(Cards.comboStrike);
      expect(monster.hp, equals(22)); // 30 - 8
    });

    test('연속 강타: 공격 카드 없으면 데미지 0', () {
      final monster = Monster(stage: 1); // HP 30
      final cards = [Cards.defend, Cards.defend, Cards.comboStrike];
      final engine = _makeEngine(cards: cards, monster: monster);
      engine.playCard(Cards.comboStrike);
      expect(monster.hp, equals(30));
    });

    test('승부수: HP -4, 에너지 +2', () {
      final player = Player(hp: 50);
      final engine = _makeEngine(cards: [Cards.gamble], player: player);
      engine.playCard(Cards.gamble);
      expect(player.hp, equals(46));
      expect(engine.energy, equals(5)); // 3 + 2
    });

    test('무기 연마: 이번 턴 공격 카드 전부 +4 데미지', () {
      final monster = Monster(stage: 1); // HP 30
      final engine = _makeEngine(
        cards: [Cards.sharpen, Cards.strike, Cards.strike],
        monster: monster,
      );
      engine.playCard(Cards.sharpen);
      engine.playCard(Cards.strike); // 6 + 4 = 10
      engine.playCard(Cards.strike); // 6 + 4 = 10
      expect(monster.hp, equals(10)); // 30 - 10 - 10
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
