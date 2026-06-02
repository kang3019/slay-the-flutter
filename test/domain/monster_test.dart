import 'package:flutter_test/flutter_test.dart';
import 'package:slay_the_flutter/domain/entities/monster.dart';
import 'package:slay_the_flutter/domain/entities/monster_intent.dart';
import 'package:slay_the_flutter/domain/status_effect.dart';

void main() {
  group('Monster 스탯 공식 — SPECS.md: HP = 20 + (stage × 10)', () {
    test('스테이지 1: HP = 30', () {
      final monster = Monster(stage: 1);
      expect(monster.hp, equals(30));
    });

    test('스테이지 2: HP = 40', () {
      final monster = Monster(stage: 2);
      expect(monster.hp, equals(40));
    });

    test('스테이지 3: HP = 50', () {
      final monster = Monster(stage: 3);
      expect(monster.hp, equals(50));
    });
  });

  group('Monster 스탯 공식 — SPECS.md: 공격력 = 8 + (stage × 2)', () {
    test('스테이지 1: 공격력 = 10', () {
      final monster = Monster(stage: 1);
      expect(monster.attackPower, equals(10));
    });

    test('스테이지 2: 공격력 = 12', () {
      final monster = Monster(stage: 2);
      expect(monster.attackPower, equals(12));
    });

    test('스테이지 3: 공격력 = 14', () {
      final monster = Monster(stage: 3);
      expect(monster.attackPower, equals(14));
    });
  });

  group('Monster 데미지 처리', () {
    test('몬스터가 데미지를 입으면 체력이 감소한다', () {
      final monster = Monster(stage: 1); // HP 30
      monster.takeDamage(10);
      expect(monster.hp, equals(20));
    });

    test('체력은 0 아래로 내려가지 않는다', () {
      final monster = Monster(stage: 1);
      monster.takeDamage(100);
      expect(monster.hp, equals(0));
    });

    test('체력이 0이면 isDead는 true', () {
      final monster = Monster(stage: 1);
      monster.takeDamage(100);
      expect(monster.isDead, isTrue);
    });

    test('초기 상태에서 isDead는 false', () {
      final monster = Monster(stage: 1);
      expect(monster.isDead, isFalse);
    });
  });

  group('Monster 방어도(Block) 처리', () {
    test('방어도가 있으면 데미지가 방어도에 먼저 흡수된다', () {
      final monster = Monster(stage: 1); // HP 30
      monster.gainBlock(5);
      monster.takeDamage(3);

      expect(monster.hp, equals(30));
      expect(monster.block, equals(2));
    });

    test('데미지가 방어도를 초과하면 초과분만 체력에서 감소한다', () {
      final monster = Monster(stage: 1);
      monster.gainBlock(5);
      monster.takeDamage(8);

      expect(monster.block, equals(0));
      expect(monster.hp, equals(27)); // 30 - (8 - 5)
    });

    test('턴 종료 시 방어도가 0으로 초기화된다', () {
      final monster = Monster(stage: 1);
      monster.gainBlock(10);
      monster.endTurn();

      expect(monster.block, equals(0));
    });
  });

  group('Monster 인텐트 시스템', () {
    test('스테이지 1 초기 인텐트는 attack이다', () {
      expect(Monster(stage: 1).currentIntent.type, MonsterIntentType.attack);
    });

    test('스테이지 1 attack 인텐트 value는 공격력(10)과 같다', () {
      final m = Monster(stage: 1);
      expect(m.currentIntent.value, equals(10));
    });

    test('advanceIntent로 스테이지 1 패턴 [attack, attack, gainBlock]을 순환한다', () {
      final m = Monster(stage: 1);
      expect(m.currentIntent.type, MonsterIntentType.attack);   // index 0
      m.advanceIntent();
      expect(m.currentIntent.type, MonsterIntentType.attack);   // index 1
      m.advanceIntent();
      expect(m.currentIntent.type, MonsterIntentType.gainBlock); // index 2
      m.advanceIntent();
      expect(m.currentIntent.type, MonsterIntentType.attack);   // index 0 (wrap)
    });

    test('스테이지 2 패턴은 heavyAttack 인텐트를 포함한다', () {
      final m = Monster(stage: 2);
      m.advanceIntent(); // index 1 = heavyAttack
      expect(m.currentIntent.type, MonsterIntentType.heavyAttack);
    });

    test('스테이지 2 heavyAttack value는 일반 attack보다 크다', () {
      final m = Monster(stage: 2);
      final attackValue = m.currentIntent.value; // index 0 = attack
      m.advanceIntent(); // index 1 = heavyAttack
      expect(m.currentIntent.value, greaterThan(attackValue));
    });

    test('스테이지 3(보스) 초기 인텐트는 heavyAttack이다', () {
      expect(Monster(stage: 3).currentIntent.type, MonsterIntentType.heavyAttack);
    });

    test('gainBlock 인텐트 value는 양수이다', () {
      final m = Monster(stage: 1);
      // pattern: [attack, attack, gainBlock]
      m.advanceIntent();
      m.advanceIntent();
      expect(m.currentIntent.type, MonsterIntentType.gainBlock);
      expect(m.currentIntent.value, greaterThan(0));
    });
  });

  group('Monster 상태 이상 — Vulnerable', () {
    test('Vulnerable 상태에서 받는 데미지가 1.5배가 된다', () {
      final monster = Monster(stage: 1); // HP 30
      monster.applyStatusEffect(
        const StatusEffect(type: StatusEffectType.vulnerable, duration: 2),
      );
      monster.takeDamage(10); // floor(10 × 1.5) = 15

      expect(monster.hp, equals(15)); // 30 - 15
    });

    test('Vulnerable은 턴 종료 후 duration이 감소한다', () {
      final monster = Monster(stage: 1);
      monster.applyStatusEffect(
        const StatusEffect(type: StatusEffectType.vulnerable, duration: 1),
      );
      monster.endTurn();

      expect(monster.isVulnerable, isFalse);
    });
  });
}
