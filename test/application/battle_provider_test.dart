import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slay_the_flutter/application/battle_provider.dart';
import 'package:slay_the_flutter/domain/battle_engine.dart';
import 'package:slay_the_flutter/domain/deck.dart';
import 'package:slay_the_flutter/domain/entities/card.dart';
import 'package:slay_the_flutter/domain/entities/monster.dart';
import 'package:slay_the_flutter/domain/entities/player.dart';

/// 지정 카드 목록과 스테이지로 ProviderContainer를 생성한다.
/// battleEngineFactoryProvider를 오버라이드해 결정론적 덱을 주입한다.
ProviderContainer _makeContainer({
  int stage = 1,
  List<GameCard>? cards,
}) {
  return ProviderContainer(
    overrides: [
      battleEngineFactoryProvider.overrideWith(
        (ref) => (s) {
          final engine = BattleEngine(
            player: Player(),
            monster: Monster(stage: s),
            deck: Deck(
              initialCards: cards ?? List.filled(10, Cards.strike),
            ),
          );
          engine.startPlayerTurn();
          return engine;
        },
      ),
    ],
  );
}

void main() {
  group('BattleNotifier 초기 상태', () {
    late ProviderContainer container;

    setUp(() => container = _makeContainer());
    tearDown(() => container.dispose());

    test('플레이어 HP는 70이다', () {
      expect(container.read(battleProvider).playerHp, equals(70));
    });

    test('플레이어 최대 HP는 70이다', () {
      expect(container.read(battleProvider).playerMaxHp, equals(70));
    });

    test('에너지는 3이다', () {
      expect(container.read(battleProvider).energy, equals(3));
    });

    test('최대 에너지는 3이다', () {
      expect(container.read(battleProvider).maxEnergy, equals(3));
    });

    test('패에 5장이 있다', () {
      expect(container.read(battleProvider).hand.length, equals(5));
    });

    test('전투는 진행 중이고 결과는 없다', () {
      final state = container.read(battleProvider);
      expect(state.isBattleOver, isFalse);
      expect(state.result, isNull);
    });

    test('스테이지 1 몬스터 HP는 30이다', () {
      expect(container.read(battleProvider).monsterHp, equals(30));
    });

    test('스테이지 1 몬스터 최대 HP는 30이다', () {
      expect(container.read(battleProvider).monsterMaxHp, equals(30));
    });
  });

  group('playCard — 상태 갱신', () {
    late ProviderContainer container;

    setUp(
      () => container = _makeContainer(cards: List.filled(10, Cards.strike)),
    );
    tearDown(() => container.dispose());

    test('카드 사용 후 패가 1장 줄어든다', () {
      container.read(battleProvider.notifier).playCard(Cards.strike);
      expect(container.read(battleProvider).hand.length, equals(4));
    });

    test('Strike 사용 시 에너지가 1 감소한다', () {
      container.read(battleProvider.notifier).playCard(Cards.strike);
      expect(container.read(battleProvider).energy, equals(2));
    });

    test('Strike 사용 시 몬스터 HP가 6 감소한다', () {
      container.read(battleProvider.notifier).playCard(Cards.strike);
      expect(container.read(battleProvider).monsterHp, equals(24));
    });

    test('에너지가 부족하면 상태가 변하지 않는다', () {
      final notifier = container.read(battleProvider.notifier);
      notifier.playCard(Cards.strike); // energy 2
      notifier.playCard(Cards.strike); // energy 1
      notifier.playCard(Cards.strike); // energy 0

      final before = container.read(battleProvider);
      notifier.playCard(Cards.strike); // energy 0 < cost 1 → 실패

      final after = container.read(battleProvider);
      expect(after.energy, equals(before.energy));
      expect(after.hand.length, equals(before.hand.length));
    });
  });

  group('endTurn — 몬스터 행동 및 다음 턴 시작', () {
    late ProviderContainer container;

    setUp(
      () => container = _makeContainer(cards: List.filled(10, Cards.strike)),
    );
    tearDown(() => container.dispose());

    test('턴 종료 후 에너지가 3으로 충전된다', () {
      container.read(battleProvider.notifier).playCard(Cards.strike);
      container.read(battleProvider.notifier).endTurn();
      expect(container.read(battleProvider).energy, equals(3));
    });

    test('턴 종료 후 패에 5장이 있다', () {
      container.read(battleProvider.notifier).endTurn();
      expect(container.read(battleProvider).hand.length, equals(5));
    });

    test('턴 종료 시 몬스터가 플레이어를 공격한다 (스테이지 1: 10 데미지)', () {
      container.read(battleProvider.notifier).endTurn();
      expect(container.read(battleProvider).playerHp, equals(60));
    });

    test('방어도가 있으면 몬스터 공격을 흡수하고 턴 종료 후 소멸한다', () {
      final c = _makeContainer(cards: List.filled(10, Cards.defend));
      addTearDown(c.dispose);

      c.read(battleProvider.notifier).playCard(Cards.defend); // 방어도 5
      c.read(battleProvider.notifier).endTurn(); // 몬스터 10 공격 → 5 흡수 → HP 65, 방어도 소멸

      expect(c.read(battleProvider).playerHp, equals(65));
      expect(c.read(battleProvider).playerBlock, equals(0));
    });
  });

  group('전투 승패 — isBattleOver 상태 반영', () {
    test('몬스터 HP가 0이 되면 playerWon으로 전투 종료', () {
      final container = ProviderContainer(
        overrides: [
          battleEngineFactoryProvider.overrideWith(
            (ref) => (_) {
              final monster = Monster(stage: 1)..takeDamage(24); // HP 30→6
              final engine = BattleEngine(
                player: Player(),
                monster: monster,
                deck: Deck(initialCards: [Cards.strike]),
              );
              engine.startPlayerTurn();
              return engine;
            },
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(battleProvider.notifier).playCard(Cards.strike); // 6 데미지 → HP 0

      expect(container.read(battleProvider).isBattleOver, isTrue);
      expect(container.read(battleProvider).result, equals(BattleResult.playerWon));
    });

    test('플레이어 HP가 0이 되면 playerLost로 전투 종료', () {
      final container = ProviderContainer(
        overrides: [
          battleEngineFactoryProvider.overrideWith(
            (ref) => (_) {
              final engine = BattleEngine(
                player: Player(hp: 5),
                monster: Monster(stage: 1), // 공격력 10 > HP 5
                deck: Deck(initialCards: []),
              );
              engine.startPlayerTurn();
              return engine;
            },
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(battleProvider.notifier).endTurn(); // 몬스터 10 공격 → HP 0

      expect(container.read(battleProvider).isBattleOver, isTrue);
      expect(container.read(battleProvider).result, equals(BattleResult.playerLost));
    });

    test('전투 종료 후 endTurn을 다시 호출해도 상태가 변하지 않는다', () {
      final container = ProviderContainer(
        overrides: [
          battleEngineFactoryProvider.overrideWith(
            (ref) => (_) {
              final engine = BattleEngine(
                player: Player(hp: 5),
                monster: Monster(stage: 1),
                deck: Deck(initialCards: []),
              );
              engine.startPlayerTurn();
              return engine;
            },
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(battleProvider.notifier).endTurn(); // 전투 종료
      final stateAfterEnd = container.read(battleProvider);

      container.read(battleProvider.notifier).endTurn(); // 재호출 — 무시되어야 함
      expect(container.read(battleProvider).playerHp, equals(stateAfterEnd.playerHp));
    });
  });

  group('startBattle — 새 전투 시작', () {
    late ProviderContainer container;

    setUp(() => container = _makeContainer());
    tearDown(() => container.dispose());

    test('startBattle 호출 시 플레이어 상태가 초기화된다', () {
      final notifier = container.read(battleProvider.notifier);
      notifier.playCard(Cards.strike); // 상태 변경
      notifier.startBattle(1);

      expect(container.read(battleProvider).playerHp, equals(70));
      expect(container.read(battleProvider).energy, equals(3));
      expect(container.read(battleProvider).hand.length, equals(5));
      expect(container.read(battleProvider).isBattleOver, isFalse);
    });

    test('스테이지 2로 시작하면 몬스터 HP가 40이다', () {
      container.read(battleProvider.notifier).startBattle(2);
      expect(container.read(battleProvider).monsterHp, equals(40));
    });

    test('스테이지 3으로 시작하면 몬스터 HP가 50이다', () {
      container.read(battleProvider.notifier).startBattle(3);
      expect(container.read(battleProvider).monsterHp, equals(50));
    });
  });
}
