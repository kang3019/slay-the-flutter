import 'package:flutter_test/flutter_test.dart';
import 'package:slay_the_flutter/domain/entities/card.dart';
import 'package:slay_the_flutter/domain/entities/player.dart';

void main() {
  group('GameCard 상수 — SPECS.md 카드 테이블 검증', () {
    test('Strike: 비용 1, 데미지 6', () {
      expect(Cards.strike.cost, equals(1));
      expect(Cards.strike.value, equals(6));
      expect(Cards.strike.effectType, equals(CardEffectType.damage));
    });

    test('Bash: 비용 2, 데미지 8', () {
      expect(Cards.bash.cost, equals(2));
      expect(Cards.bash.value, equals(8));
      expect(Cards.bash.effectType, equals(CardEffectType.damage));
    });

    test('SwiftCut: 비용 1, 타격당 데미지 4 (2회)', () {
      expect(Cards.swiftCut.cost, equals(1));
      expect(Cards.swiftCut.value, equals(4));
      expect(Cards.swiftCut.effectType, equals(CardEffectType.damage));
    });

    test('Defend: 비용 1, 방어도 5', () {
      expect(Cards.defend.cost, equals(1));
      expect(Cards.defend.value, equals(5));
      expect(Cards.defend.effectType, equals(CardEffectType.block));
    });

    test('Iron Wall: 비용 2, 방어도 10', () {
      expect(Cards.ironWall.cost, equals(2));
      expect(Cards.ironWall.value, equals(10));
      expect(Cards.ironWall.effectType, equals(CardEffectType.block));
    });

    test('Focus: 비용 0, 버프 타입', () {
      expect(Cards.focus.cost, equals(0));
      expect(Cards.focus.effectType, equals(CardEffectType.buff));
    });

    test('Recover: 비용 2, 회복 8', () {
      expect(Cards.recover.cost, equals(2));
      expect(Cards.recover.value, equals(8));
      expect(Cards.recover.effectType, equals(CardEffectType.heal));
    });
  });

  group('데미지 배율 상수 — SPECS.md 공식 검증', () {
    test('Vulnerable 배율은 1.5', () {
      expect(Player.vulnerableMultiplier, equals(1.5));
    });

    test('Weak 배율은 0.75', () {
      expect(Player.weakMultiplier, equals(0.75));
    });

    test('Weak 데미지는 floor 적용: floor(7 × 0.75) = 5', () {
      const base = 7;
      final result = (base * Player.weakMultiplier).floor();
      expect(result, equals(5));
    });

    test('Weak 데미지는 floor 적용: floor(10 × 0.75) = 7', () {
      const base = 10;
      final result = (base * Player.weakMultiplier).floor();
      expect(result, equals(7));
    });
  });
}
