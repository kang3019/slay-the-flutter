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

  group('새 카드 상수 검증', () {
    test('광분: 비용 0, 데미지 5', () {
      expect(Cards.rageBurst.cost, equals(0));
      expect(Cards.rageBurst.value, equals(5));
      expect(Cards.rageBurst.effectType, equals(CardEffectType.damage));
    });

    test('독침: 비용 1, 데미지 5', () {
      expect(Cards.toxicJab.cost, equals(1));
      expect(Cards.toxicJab.value, equals(5));
      expect(Cards.toxicJab.effectType, equals(CardEffectType.damage));
    });

    test('결집: 비용 1, 드로우 2', () {
      expect(Cards.regroup.cost, equals(1));
      expect(Cards.regroup.value, equals(2));
      expect(Cards.regroup.effectType, equals(CardEffectType.draw));
    });

    test('파괴의 일격: 비용 2, 데미지 20', () {
      expect(Cards.crushingBlow.cost, equals(2));
      expect(Cards.crushingBlow.value, equals(20));
      expect(Cards.crushingBlow.effectType, equals(CardEffectType.damage));
    });

    test('분노: 비용 1, 힘 2', () {
      expect(Cards.fury.cost, equals(1));
      expect(Cards.fury.value, equals(2));
      expect(Cards.fury.effectType, equals(CardEffectType.strength));
    });

    test('세 번 베기: 비용 1, 타격당 데미지 3', () {
      expect(Cards.tripleSlash.cost, equals(1));
      expect(Cards.tripleSlash.value, equals(3));
      expect(Cards.tripleSlash.effectType, equals(CardEffectType.damage));
    });

    test('응급처치: 비용 0, 회복 5', () {
      expect(Cards.quickMend.cost, equals(0));
      expect(Cards.quickMend.value, equals(5));
      expect(Cards.quickMend.effectType, equals(CardEffectType.heal));
    });

    test('날렵한 방어: 비용 1, 방어도 6', () {
      expect(Cards.swiftGuard.cost, equals(1));
      expect(Cards.swiftGuard.value, equals(6));
      expect(Cards.swiftGuard.effectType, equals(CardEffectType.blockDraw));
    });

    test('취약 틈새: 비용 1, 데미지 9', () {
      expect(Cards.exploitWeakness.cost, equals(1));
      expect(Cards.exploitWeakness.value, equals(9));
      expect(Cards.exploitWeakness.effectType, equals(CardEffectType.damage));
    });

    test('무기 연마: 비용 0, 버프 타입', () {
      expect(Cards.sharpen.cost, equals(0));
      expect(Cards.sharpen.effectType, equals(CardEffectType.buff));
    });

    test('약화 강타: 비용 2, 데미지 12', () {
      expect(Cards.weakSlash.cost, equals(2));
      expect(Cards.weakSlash.value, equals(12));
      expect(Cards.weakSlash.effectType, equals(CardEffectType.damage));
    });

    test('방어도 공격: 비용 1, 데미지 타입', () {
      expect(Cards.blockStrike.cost, equals(1));
      expect(Cards.blockStrike.effectType, equals(CardEffectType.damage));
    });

    test('혈기: X 비용(-1), 데미지 타입, 타격당 6', () {
      expect(Cards.bloodRush.cost, equals(-1));
      expect(Cards.bloodRush.value, equals(6));
      expect(Cards.bloodRush.effectType, equals(CardEffectType.damage));
    });

    test('악마의 거래: 비용 0, HP 비용 6', () {
      expect(Cards.devilsDeal.cost, equals(0));
      expect(Cards.devilsDeal.value, equals(6));
      expect(Cards.devilsDeal.effectType, equals(CardEffectType.draw));
    });

    test('전투 함성: 비용 1, 드로우 타입', () {
      expect(Cards.battleCry.cost, equals(1));
      expect(Cards.battleCry.effectType, equals(CardEffectType.draw));
    });

    test('불굴: 비용 0, 방어도 3', () {
      expect(Cards.indomitable.cost, equals(0));
      expect(Cards.indomitable.value, equals(3));
      expect(Cards.indomitable.effectType, equals(CardEffectType.block));
    });

    test('연속 강타: 비용 1, 타격당 4', () {
      expect(Cards.comboStrike.cost, equals(1));
      expect(Cards.comboStrike.value, equals(4));
      expect(Cards.comboStrike.effectType, equals(CardEffectType.damage));
    });

    test('승부수: 비용 0, HP 비용 4', () {
      expect(Cards.gamble.cost, equals(0));
      expect(Cards.gamble.value, equals(4));
      expect(Cards.gamble.effectType, equals(CardEffectType.buff));
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
