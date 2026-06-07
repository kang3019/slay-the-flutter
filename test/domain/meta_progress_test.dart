import 'package:flutter_test/flutter_test.dart';
import 'package:slay_the_flutter/domain/entities/meta_progress.dart';
import 'package:slay_the_flutter/domain/map/node_type.dart';

void main() {
  group('MetaProgress.computeLevel — 10레벨 XP 임계치', () {
    test('XP 0 → 레벨 1',    () => expect(MetaProgress.computeLevel(0),    equals(1)));
    test('XP 99 → 레벨 1',   () => expect(MetaProgress.computeLevel(99),   equals(1)));
    test('XP 100 → 레벨 2',  () => expect(MetaProgress.computeLevel(100),  equals(2)));
    test('XP 249 → 레벨 2',  () => expect(MetaProgress.computeLevel(249),  equals(2)));
    test('XP 250 → 레벨 3',  () => expect(MetaProgress.computeLevel(250),  equals(3)));
    test('XP 449 → 레벨 3',  () => expect(MetaProgress.computeLevel(449),  equals(3)));
    test('XP 450 → 레벨 4',  () => expect(MetaProgress.computeLevel(450),  equals(4)));
    test('XP 699 → 레벨 4',  () => expect(MetaProgress.computeLevel(699),  equals(4)));
    test('XP 700 → 레벨 5',  () => expect(MetaProgress.computeLevel(700),  equals(5)));
    test('XP 999 → 레벨 5',  () => expect(MetaProgress.computeLevel(999),  equals(5)));
    test('XP 1000 → 레벨 6', () => expect(MetaProgress.computeLevel(1000), equals(6)));
    test('XP 1349 → 레벨 6', () => expect(MetaProgress.computeLevel(1349), equals(6)));
    test('XP 1350 → 레벨 7', () => expect(MetaProgress.computeLevel(1350), equals(7)));
    test('XP 1750 → 레벨 8', () => expect(MetaProgress.computeLevel(1750), equals(8)));
    test('XP 2200 → 레벨 9', () => expect(MetaProgress.computeLevel(2200), equals(9)));
    test('XP 2700 → 레벨 10', () => expect(MetaProgress.computeLevel(2700), equals(10)));
    test('XP 9999 → 레벨 10 (최대 레벨 유지)', () {
      expect(MetaProgress.computeLevel(9999), equals(10));
    });
  });

  group('MetaProgress.computeUnlockedCards', () {
    test('레벨 1: strike, defend (2종)', () {
      final cards = MetaProgress.computeUnlockedCards(1);
      expect(cards, containsAll(['strike', 'defend']));
      expect(cards.length, equals(2));
    });

    test('레벨 2: rageBurst, quickMend 추가 해금 (4종)', () {
      final cards = MetaProgress.computeUnlockedCards(2);
      expect(cards, containsAll(['strike', 'defend', 'rageBurst', 'quickMend']));
      expect(cards.length, equals(4));
    });

    test('레벨 3: swiftCut, regroup 추가 해금 (6종)', () {
      final cards = MetaProgress.computeUnlockedCards(3);
      expect(cards, containsAll(['swiftCut', 'regroup']));
      expect(cards.length, equals(6));
    });

    test('레벨 5: swiftGuard, comboStrike, sharpen 추가 해금 (11종)', () {
      final cards = MetaProgress.computeUnlockedCards(5);
      expect(cards, containsAll(['swiftGuard', 'comboStrike', 'sharpen']));
      expect(cards.length, equals(11));
    });

    test('레벨 6: bash, ironWall 추가 해금 (13종)', () {
      final cards = MetaProgress.computeUnlockedCards(6);
      expect(cards, containsAll(['bash', 'ironWall']));
      expect(cards.length, equals(13));
    });

    test('레벨 10: 전체 26종 해금', () {
      final cards = MetaProgress.computeUnlockedCards(10);
      expect(cards, containsAll(['devilsDeal', 'gamble']));
      expect(cards.length, equals(26));
    });
  });

  group('MetaProgress.initial', () {
    test('레벨 1, XP 0으로 초기화', () {
      final p = MetaProgress.initial();
      expect(p.level, equals(1));
      expect(p.xp, equals(0));
    });

    test('초기 해금 카드: strike, defend', () {
      final p = MetaProgress.initial();
      expect(p.unlockedCardTypes, containsAll(['strike', 'defend']));
      expect(p.unlockedCardTypes.length, equals(2));
    });

    test('초기 상태에서 isMaxLevel = false', () {
      expect(MetaProgress.initial().isMaxLevel, isFalse);
    });
  });

  group('MetaProgress XP 게이지', () {
    test('레벨 1에서 다음 레벨까지 필요 XP = 100', () {
      final p = MetaProgress.initial();
      expect(p.xpForNextLevel, equals(100));
      expect(p.xpToNextLevel, equals(100));
    });

    test('레벨 1, XP 70이면 xpToNextLevel = 30', () {
      const p = MetaProgress(level: 1, xp: 70, unlockedCardTypes: ['strike', 'defend']);
      expect(p.xpToNextLevel, equals(30));
    });

    test('레벨 10(최대)에서 isMaxLevel = true, xpToNextLevel = 0', () {
      final cards = MetaProgress.computeUnlockedCards(10);
      final p = MetaProgress(level: 10, xp: 2700, unlockedCardTypes: cards);
      expect(p.isMaxLevel, isTrue);
      expect(p.xpToNextLevel, equals(0));
    });
  });

  group('MetaProgress.addXp — 레벨업 없음', () {
    test('XP 50 추가 → 레벨 그대로, XP 누적', () {
      final p = MetaProgress.initial();
      final (updated, result) = p.addXp(50);
      expect(updated.xp, equals(50));
      expect(updated.level, equals(1));
      expect(result.didLevelUp, isFalse);
      expect(result.newlyUnlockedCards, isEmpty);
    });

    test('XP 추가 후 원본 객체는 변경되지 않는다 (불변성)', () {
      final p = MetaProgress.initial();
      p.addXp(50);
      expect(p.xp, equals(0));
    });
  });

  group('MetaProgress.addXp — 레벨업', () {
    test('레벨 1 → 2: rageBurst, quickMend 신규 해금', () {
      final p = MetaProgress.initial();
      final (updated, result) = p.addXp(100);

      expect(updated.level, equals(2));
      expect(result.didLevelUp, isTrue);
      expect(result.previousLevel, equals(1));
      expect(result.newLevel, equals(2));
      expect(result.newlyUnlockedCards, containsAll(['rageBurst', 'quickMend']));
      expect(result.newlyUnlockedCards.length, equals(2));
    });

    test('레벨 2 → 3: swiftCut, regroup 신규 해금', () {
      const p = MetaProgress(
        level: 2,
        xp: 200,
        unlockedCardTypes: ['strike', 'defend', 'rageBurst', 'quickMend'],
      );
      final (updated, result) = p.addXp(50); // 200 + 50 = 250

      expect(updated.level, equals(3));
      expect(result.didLevelUp, isTrue);
      expect(result.newlyUnlockedCards, containsAll(['swiftCut', 'regroup']));
    });

    test('XP가 여러 레벨을 한 번에 초과 → 올바른 레벨·신규 해금 반환', () {
      final p = MetaProgress.initial();
      final (updated, result) = p.addXp(250); // 레벨 1 → 3

      expect(updated.level, equals(3));
      expect(result.didLevelUp, isTrue);
      expect(result.newlyUnlockedCards,
          containsAll(['rageBurst', 'quickMend', 'swiftCut', 'regroup']));
      expect(result.newlyUnlockedCards.length, equals(4));
    });

    test('최대 레벨(10)에서 XP 추가 → 레벨 변동 없음', () {
      final cards = MetaProgress.computeUnlockedCards(10);
      final p = MetaProgress(level: 10, xp: 2700, unlockedCardTypes: cards);
      final (updated, result) = p.addXp(500);

      expect(updated.level, equals(10));
      expect(result.didLevelUp, isFalse);
      expect(result.newlyUnlockedCards, isEmpty);
    });

    test('addXp 후 unlockedCardTypes에 이전 카드도 포함된다', () {
      final p = MetaProgress.initial();
      final (updated, _) = p.addXp(100);

      expect(updated.unlockedCardTypes,
          containsAll(['strike', 'defend', 'rageBurst', 'quickMend']));
    });
  });

  group('MetaProgress.xpForBattle — 노드 타입·승패별 XP', () {
    test('몬스터 승리: monsterWinXp', () {
      expect(
        MetaProgress.xpForBattle(NodeType.monster, isVictory: true),
        equals(MetaProgress.monsterWinXp),
      );
    });

    test('몬스터 패배: monsterLoseXp', () {
      expect(
        MetaProgress.xpForBattle(NodeType.monster, isVictory: false),
        equals(MetaProgress.monsterLoseXp),
      );
    });

    test('엘리트 승리: eliteWinXp', () {
      expect(
        MetaProgress.xpForBattle(NodeType.elite, isVictory: true),
        equals(MetaProgress.eliteWinXp),
      );
    });

    test('엘리트 패배: eliteLoseXp', () {
      expect(
        MetaProgress.xpForBattle(NodeType.elite, isVictory: false),
        equals(MetaProgress.eliteLoseXp),
      );
    });

    test('보스 승리: bossWinXp', () {
      expect(
        MetaProgress.xpForBattle(NodeType.boss, isVictory: true),
        equals(MetaProgress.bossWinXp),
      );
    });

    test('보스 패배: bossLoseXp', () {
      expect(
        MetaProgress.xpForBattle(NodeType.boss, isVictory: false),
        equals(MetaProgress.bossLoseXp),
      );
    });

    test('패배 XP는 승리 XP보다 항상 작다', () {
      expect(MetaProgress.monsterLoseXp, lessThan(MetaProgress.monsterWinXp));
      expect(MetaProgress.eliteLoseXp,   lessThan(MetaProgress.eliteWinXp));
      expect(MetaProgress.bossLoseXp,    lessThan(MetaProgress.bossWinXp));
    });

    test('엘리트 XP > 몬스터 XP', () {
      expect(MetaProgress.eliteWinXp, greaterThan(MetaProgress.monsterWinXp));
    });

    test('보스 XP > 엘리트 XP', () {
      expect(MetaProgress.bossWinXp, greaterThan(MetaProgress.eliteWinXp));
    });
  });

  group('MetaProgress.rewardPoolForLevel — 레벨업 보상 풀', () {
    test('레벨 2~5는 tier1RewardPool 반환', () {
      for (final level in [2, 3, 4, 5]) {
        expect(
          MetaProgress.rewardPoolForLevel(level),
          same(MetaProgress.tier1RewardPool),
        );
      }
    });

    test('레벨 6~8은 tier2RewardPool 반환', () {
      for (final level in [6, 7, 8]) {
        expect(
          MetaProgress.rewardPoolForLevel(level),
          same(MetaProgress.tier2RewardPool),
        );
      }
    });

    test('레벨 9~10은 tier3RewardPool 반환', () {
      for (final level in [9, 10]) {
        expect(
          MetaProgress.rewardPoolForLevel(level),
          same(MetaProgress.tier3RewardPool),
        );
      }
    });

    test('tier1Pool은 비어있지 않다', () {
      expect(MetaProgress.tier1RewardPool, isNotEmpty);
    });

    test('tier3Pool은 tier1Pool보다 카드 수가 적다 (희귀 카드)', () {
      expect(
        MetaProgress.tier3RewardPool.length,
        lessThan(MetaProgress.tier1RewardPool.length),
      );
    });
  });
}
