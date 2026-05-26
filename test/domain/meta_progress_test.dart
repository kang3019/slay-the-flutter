import 'package:flutter_test/flutter_test.dart';
import 'package:slay_the_flutter/domain/entities/meta_progress.dart';

void main() {
  group('MetaProgress.computeLevel — SPECS.md XP 임계치', () {
    test('XP 0 → 레벨 1', () => expect(MetaProgress.computeLevel(0), equals(1)));
    test('XP 99 → 레벨 1', () => expect(MetaProgress.computeLevel(99), equals(1)));
    test('XP 100 → 레벨 2', () => expect(MetaProgress.computeLevel(100), equals(2)));
    test('XP 249 → 레벨 2', () => expect(MetaProgress.computeLevel(249), equals(2)));
    test('XP 250 → 레벨 3', () => expect(MetaProgress.computeLevel(250), equals(3)));
    test('XP 449 → 레벨 3', () => expect(MetaProgress.computeLevel(449), equals(3)));
    test('XP 450 → 레벨 4', () => expect(MetaProgress.computeLevel(450), equals(4)));
    test('XP 1000 → 레벨 4 (최대 레벨 유지)', () {
      expect(MetaProgress.computeLevel(1000), equals(4));
    });
  });

  group('MetaProgress.computeUnlockedCards', () {
    test('레벨 1: strike, defend (2종)', () {
      final cards = MetaProgress.computeUnlockedCards(1);
      expect(cards, containsAll(['strike', 'defend']));
      expect(cards.length, equals(2));
    });

    test('레벨 2: strike, defend, bash, swiftCut (4종)', () {
      final cards = MetaProgress.computeUnlockedCards(2);
      expect(cards, containsAll(['strike', 'defend', 'bash', 'swiftCut']));
      expect(cards.length, equals(4));
    });

    test('레벨 3: ironWall, focus 추가 해금 (6종)', () {
      final cards = MetaProgress.computeUnlockedCards(3);
      expect(
        cards,
        containsAll(['strike', 'defend', 'bash', 'swiftCut', 'ironWall', 'focus']),
      );
      expect(cards.length, equals(6));
    });

    test('레벨 4: recover 추가 해금 (7종)', () {
      final cards = MetaProgress.computeUnlockedCards(4);
      expect(cards, contains('recover'));
      expect(cards.length, equals(7));
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

    test('최대 레벨에서 isMaxLevel = true, xpToNextLevel = 0', () {
      const p = MetaProgress(
        level: 4,
        xp: 450,
        unlockedCardTypes: ['strike', 'defend', 'bash', 'swiftCut', 'ironWall', 'focus', 'recover'],
      );
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
    test('레벨 1 → 2: bash, swiftCut 신규 해금', () {
      final p = MetaProgress.initial();
      final (updated, result) = p.addXp(100);

      expect(updated.level, equals(2));
      expect(result.didLevelUp, isTrue);
      expect(result.previousLevel, equals(1));
      expect(result.newLevel, equals(2));
      expect(result.newlyUnlockedCards, containsAll(['bash', 'swiftCut']));
      expect(result.newlyUnlockedCards.length, equals(2));
    });

    test('레벨 2 → 3: ironWall, focus 신규 해금', () {
      const p = MetaProgress(
        level: 2,
        xp: 200,
        unlockedCardTypes: ['strike', 'defend', 'bash', 'swiftCut'],
      );
      final (updated, result) = p.addXp(50); // 200 + 50 = 250

      expect(updated.level, equals(3));
      expect(result.didLevelUp, isTrue);
      expect(result.newlyUnlockedCards, containsAll(['ironWall', 'focus']));
    });

    test('XP가 여러 레벨을 한 번에 초과 → 올바른 레벨·신규 해금 반환', () {
      final p = MetaProgress.initial();
      final (updated, result) = p.addXp(250); // 레벨 1 → 3

      expect(updated.level, equals(3));
      expect(result.didLevelUp, isTrue);
      expect(result.newlyUnlockedCards,
          containsAll(['bash', 'swiftCut', 'ironWall', 'focus']));
      expect(result.newlyUnlockedCards.length, equals(4));
    });

    test('최대 레벨에서 XP 추가 → 레벨 변동 없음', () {
      const p = MetaProgress(
        level: 4,
        xp: 450,
        unlockedCardTypes: [
          'strike', 'defend', 'bash', 'swiftCut', 'ironWall', 'focus', 'recover'
        ],
      );
      final (updated, result) = p.addXp(500);

      expect(updated.level, equals(4));
      expect(result.didLevelUp, isFalse);
      expect(result.newlyUnlockedCards, isEmpty);
    });

    test('addXp 후 unlockedCardTypes에 이전 카드도 포함된다', () {
      final p = MetaProgress.initial();
      final (updated, _) = p.addXp(100);

      expect(updated.unlockedCardTypes, containsAll(['strike', 'defend', 'bash', 'swiftCut']));
    });
  });
}
