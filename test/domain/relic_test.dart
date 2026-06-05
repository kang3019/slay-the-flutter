import 'package:flutter_test/flutter_test.dart';
import 'package:slay_the_flutter/domain/battle_engine.dart';
import 'package:slay_the_flutter/domain/deck.dart';
import 'package:slay_the_flutter/domain/entities/card.dart';
import 'package:slay_the_flutter/domain/entities/monster.dart';
import 'package:slay_the_flutter/domain/entities/player.dart';
import 'package:slay_the_flutter/domain/entities/relic.dart';

/// 지정 카드·유물·HP로 엔진을 만들고 첫 턴을 시작한다.
BattleEngine _makeEngine({
  List<GameCard>? cards,
  List<Relic> relics = const [],
  int stage = 1,
  int playerHp = Player.maxHp,
}) {
  final engine = BattleEngine(
    player: Player(hp: playerHp),
    monster: Monster(stage: stage),
    deck: Deck(initialCards: cards ?? List.filled(10, Cards.strike)),
    relics: relics,
  );
  engine.startPlayerTurn();
  return engine;
}

void main() {
  group('GameRelics 목록', () {
    test('20개 유물이 등록되어 있다', () {
      expect(GameRelics.all.length, equals(20));
    });

    test('모든 유물은 고유한 id를 가진다', () {
      final ids = GameRelics.all.map((r) => r.id).toList();
      expect(ids.toSet().length, equals(ids.length));
    });
  });

  group('방패 부적 — blockOnCombatStart', () {
    test('전투 시작 시 방어도 6을 얻는다', () {
      final engine = _makeEngine(relics: [GameRelics.shieldAmulet]);
      expect(engine.player.block, equals(6));
    });
  });

  group('피의 유리병 — healOnCombatStart', () {
    test('전투 시작 시 HP 2를 회복한다', () {
      final engine = _makeEngine(
        relics: [GameRelics.bloodVial],
        playerHp: 50,
      );
      expect(engine.player.hp, equals(52));
    });

    test('HP가 최대치를 초과하지 않는다', () {
      final engine = _makeEngine(relics: [GameRelics.bloodVial]);
      expect(engine.player.hp, equals(Player.maxHp));
    });
  });

  group('준비의 낭 — extraDrawOnCombatStart', () {
    test('전투 시작 시 카드를 6장(기본 5+1) 드로우한다', () {
      final engine = _makeEngine(relics: [GameRelics.preparationPouch]);
      expect(engine.deck.hand.length, equals(6));
    });
  });

  group('독 구슬 — vulnerableEnemyOnCombatStart', () {
    test('전투 시작 시 적이 취약 상태가 된다', () {
      final engine = _makeEngine(relics: [GameRelics.toxicMarble]);
      expect(engine.monster.isVulnerable, isTrue);
    });
  });

  group('약화 독약 — weakEnemyOnCombatStart', () {
    test('전투 시작 시 적이 약화 상태가 된다', () {
      final engine = _makeEngine(relics: [GameRelics.weaknessPoison]);
      expect(engine.monster.isWeak, isTrue);
    });
  });

  group('등불 — extraEnergyOnFirstTurn', () {
    test('첫 번째 턴에 에너지가 4이다 (기본 3+1)', () {
      final engine = _makeEngine(relics: [GameRelics.lantern]);
      expect(engine.energy, equals(4));
    });

    test('두 번째 턴부터는 에너지가 3으로 돌아온다', () {
      final engine = _makeEngine(relics: [GameRelics.lantern]);
      engine.endPlayerTurn();
      engine.startPlayerTurn();
      expect(engine.energy, equals(3));
    });
  });

  group('황금 방패 — blockIfNoneOnTurnEnd', () {
    test('턴 종료 시 방어도 0이면 방어도 4를 얻는다', () {
      // 방어도 없이 턴 종료 → 황금 방패 발동
      // 주의: endPlayerTurn 내부에서 방어도 부여 후 몬스터가 공격하므로
      // 몬스터 HP를 확인하는 대신 피해 흡수 여부를 간접 확인한다.
      final engine = BattleEngine(
        player: Player(hp: Player.maxHp),
        monster: Monster(stage: 1), // 공격력 10
        deck: Deck(initialCards: List.filled(10, Cards.strike)),
        relics: [GameRelics.goldenShield],
      );
      engine.startPlayerTurn();

      // 방어도 0인 상태로 턴 종료 → 황금 방패로 방어도 4 획득 → 몬스터 공격 10 흡수 → 피해 6
      engine.endPlayerTurn();
      expect(engine.player.hp, equals(Player.maxHp - (10 - 4)));
    });

    test('방어도가 있으면 황금 방패가 발동하지 않는다', () {
      final engine = _makeEngine(
        relics: [GameRelics.goldenShield],
        cards: List.filled(10, Cards.defend),
      );
      engine.playCard(Cards.defend); // 방어도 5 획득
      engine.endPlayerTurn();
      // 방어도 5가 있었으므로 황금 방패 미발동 → 몬스터 공격 10에서 5 흡수 → 피해 5
      expect(engine.player.hp, equals(Player.maxHp - 5));
    });
  });

  group('보스의 망토 — healOnBossCombatStart', () {
    test('보스 전투(stage 3)에서 HP 15를 회복한다', () {
      final engine = _makeEngine(
        relics: [GameRelics.bossCloak],
        stage: 3,
        playerHp: 40,
      );
      expect(engine.player.hp, equals(55));
    });

    test('일반 전투(stage 1)에서는 발동하지 않는다', () {
      final engine = _makeEngine(
        relics: [GameRelics.bossCloak],
        stage: 1,
        playerHp: 40,
      );
      expect(engine.player.hp, equals(40));
    });
  });

  group('도마뱀 꼬리 — nearDeathSave', () {
    test('HP 0이 되는 피해를 받으면 HP 1로 생존한다', () {
      // 체력 1짜리 플레이어가 큰 피해를 받아도 살아남는다
      final engine = BattleEngine(
        player: Player(hp: 1),
        monster: Monster(stage: 3), // 강한 몬스터
        deck: Deck(initialCards: List.filled(10, Cards.defend)),
        relics: [GameRelics.lizardTail],
      );
      engine.startPlayerTurn();
      engine.endPlayerTurn(); // 몬스터 공격 → 사망 위기 → 도마뱀 꼬리 발동
      expect(engine.player.hp, equals(1));
      expect(engine.isBattleOver, isFalse);
    });

    test('2번 사망 위기에서는 두 번째에 실제로 사망한다', () {
      final engine = BattleEngine(
        player: Player(hp: 1),
        monster: Monster(stage: 3),
        deck: Deck(initialCards: List.filled(10, Cards.defend)),
        relics: [GameRelics.lizardTail],
      );
      engine.startPlayerTurn();
      engine.endPlayerTurn(); // 첫 번째 → 꼬리 발동, HP 1
      engine.startPlayerTurn();
      engine.endPlayerTurn(); // 두 번째 → 꼬리 없음, 사망
      expect(engine.isBattleOver, isTrue);
      expect(engine.result, equals(BattleResult.playerLost));
    });
  });

  group('첫 타격의 도끼 — firstAttackBonus', () {
    test('첫 번째 공격 카드가 4 추가 데미지를 준다', () {
      final engine = _makeEngine(relics: [GameRelics.warAxe]);
      final hpBefore = engine.monster.hp;
      engine.playCard(Cards.strike); // 6 + 4 = 10 데미지
      expect(engine.monster.hp, equals(hpBefore - 10));
    });

    test('두 번째 공격 카드는 추가 데미지 없이 기본 데미지만 준다', () {
      final engine = _makeEngine(relics: [GameRelics.warAxe]);
      engine.playCard(Cards.strike); // 첫 공격: 10 데미지
      final hpAfterFirst = engine.monster.hp;
      engine.playCard(Cards.strike); // 두 번째: 6 데미지만
      expect(engine.monster.hp, equals(hpAfterFirst - 6));
    });
  });

  group('전사의 낙인 — secondAttackBonus', () {
    test('두 번째 공격 카드가 5 추가 데미지를 준다', () {
      final engine = _makeEngine(relics: [GameRelics.warriorsCrest]);
      final hpAfterFirst = engine.monster.hp - 6; // 첫 공격: 보너스 없음
      engine.playCard(Cards.strike);
      expect(engine.monster.hp, equals(hpAfterFirst));
      final hpAfterSecond = hpAfterFirst - 11; // 두 번째: 6 + 5
      engine.playCard(Cards.strike);
      expect(engine.monster.hp, equals(hpAfterSecond));
    });

    test('첫 번째 공격에는 보너스가 없다', () {
      final engine = _makeEngine(relics: [GameRelics.warriorsCrest]);
      final hpBefore = engine.monster.hp;
      engine.playCard(Cards.strike);
      expect(engine.monster.hp, equals(hpBefore - 6));
    });
  });

  group('재생의 문신 — healOnTurnStart', () {
    test('매 턴 시작 시 HP +1 회복', () {
      final engine = _makeEngine(relics: [GameRelics.regenTattoo], playerHp: 50);
      expect(engine.player.hp, equals(51)); // 첫 턴 시작 시 +1
    });

    test('두 번째 턴 시작에도 HP +1', () {
      final engine = _makeEngine(relics: [GameRelics.regenTattoo], playerHp: 50);
      engine.endPlayerTurn(); // 몬스터 공격 -10
      engine.startPlayerTurn(); // +1
      expect(engine.player.hp, equals(42)); // 51 - 10 + 1
    });
  });

  group('냉각 보석 — blockPerRemainingEnergy', () {
    test('턴 종료 시 남은 에너지 1당 방어도 +2', () {
      final engine = _makeEngine(
        relics: [GameRelics.frostCrystal],
        cards: List.filled(10, Cards.strike),
      );
      engine.playCard(Cards.strike); // 에너지 3 → 2 남음
      // 턴 종료: 방어도 4 획득 후 몬스터 공격 10 → 10 - 4 = 6 피해
      engine.endPlayerTurn();
      expect(engine.player.hp, equals(Player.maxHp - 6));
    });

    test('에너지를 모두 소비하면 방어도 보너스 없음', () {
      final engine = _makeEngine(
        relics: [GameRelics.frostCrystal],
        cards: [Cards.ironWall, Cards.strike],
      );
      engine.playCard(Cards.ironWall); // 에너지 3 → 1
      engine.playCard(Cards.strike);  // 에너지 1 → 0
      // 냉각 보석 발동 안 됨, 방어도 10만 존재 → 몬스터 10 흡수, HP 그대로
      engine.endPlayerTurn();
      expect(engine.player.hp, equals(Player.maxHp));
    });
  });

  group('수호의 팔찌 — blockAndExtraDrawOnCombatStart', () {
    test('전투 시작 시 방어도 3 + 카드 1장 추가 드로우', () {
      final engine = _makeEngine(relics: [GameRelics.guardianBangle]);
      expect(engine.player.block, equals(3));
      expect(engine.deck.hand.length, equals(6)); // 기본 5 + 1
    });
  });

  group('위기의 부적 — extraEnergyOnLowHP', () {
    test('HP 50% 이하면 전투 시작 시 에너지 +1', () {
      final engine = _makeEngine(
        relics: [GameRelics.crisisTalisman],
        playerHp: 35, // 35/70 = 50%
      );
      expect(engine.energy, equals(4));
    });

    test('HP 50% 초과면 에너지 보너스 없음', () {
      final engine = _makeEngine(
        relics: [GameRelics.crisisTalisman],
        playerHp: 36,
      );
      expect(engine.energy, equals(3));
    });
  });

  group('독화살촉 — vulnerableAndWeakOnCombatStart', () {
    test('전투 시작 시 적에게 취약 2턴 + 약화 2턴 동시 부여', () {
      final engine = _makeEngine(relics: [GameRelics.venomBolt]);
      expect(engine.monster.isVulnerable, isTrue);
      expect(engine.monster.isWeak, isTrue);
    });
  });

  group('분노의 인장 — strengthOnCombatStart', () {
    test('전투 시작 시 힘 +1, 공격 데미지 증가', () {
      final engine = _makeEngine(relics: [GameRelics.rageSeal]);
      expect(engine.player.strength, equals(1));
      final hpBefore = engine.monster.hp;
      engine.playCard(Cards.strike); // 6 + 1 = 7 데미지
      expect(engine.monster.hp, equals(hpBefore - 7));
    });
  });

  group('피 묻은 장갑 — firstBlockBonus', () {
    test('첫 번째 블록 카드에 +5 방어도', () {
      final engine = _makeEngine(
        relics: [GameRelics.bloodstainedGloves],
        cards: List.filled(10, Cards.defend),
      );
      engine.playCard(Cards.defend); // 첫 번째: 5 + 5 = 10
      expect(engine.player.block, equals(10));
    });

    test('두 번째 블록 카드부터는 보너스 없음', () {
      final engine = _makeEngine(
        relics: [GameRelics.bloodstainedGloves],
        cards: List.filled(10, Cards.defend),
      );
      engine.playCard(Cards.defend); // 첫 번째: 10
      engine.playCard(Cards.defend); // 두 번째: 5 (보너스 없음)
      expect(engine.player.block, equals(15));
    });
  });

  group('집중의 렌즈 — addFocusCardOnCombatStart', () {
    test('전투 시작 시 손패에 집중 카드 1장 추가', () {
      final engine = _makeEngine(relics: [GameRelics.focusLens]);
      expect(engine.deck.hand.length, equals(6)); // 5 + 1 focus
      expect(engine.deck.hand.contains(Cards.focus), isTrue);
    });
  });

  group('격투사의 띠 — strengthOnBossCombatStart', () {
    test('보스 전투(stage 3)에서 힘 +2', () {
      final engine = _makeEngine(relics: [GameRelics.fightersBand], stage: 3);
      expect(engine.player.strength, equals(2));
    });

    test('일반 전투(stage 1)에서는 힘 보너스 없음', () {
      final engine = _makeEngine(relics: [GameRelics.fightersBand], stage: 1);
      expect(engine.player.strength, equals(0));
    });
  });

  group('유물 중복 적용', () {
    test('방패 부적 + 피의 유리병이 동시에 적용된다', () {
      final engine = _makeEngine(
        relics: [GameRelics.shieldAmulet, GameRelics.bloodVial],
        playerHp: 60,
      );
      expect(engine.player.block, equals(6));
      expect(engine.player.hp, equals(62));
    });
  });
}
