import 'package:flutter_test/flutter_test.dart';
import 'package:slay_the_flutter/domain/entities/monster.dart';
import 'package:slay_the_flutter/domain/entities/player.dart';
import 'package:slay_the_flutter/domain/status_effect.dart';

void main() {
  group('Monster 스탯 공식 — HP = 16 + (stage × 8)', () {
    test('스테이지 1: HP = 24', () {
      final monster = Monster(stage: 1);
      expect(monster.hp, equals(24));
    });

    test('스테이지 2: HP = 32', () {
      final monster = Monster(stage: 2);
      expect(monster.hp, equals(32));
    });

    test('스테이지 3: HP = 40', () {
      final monster = Monster(stage: 3);
      expect(monster.hp, equals(40));
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
      final monster = Monster(stage: 1); // HP 24
      monster.takeDamage(10);
      expect(monster.hp, equals(14));
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
      final monster = Monster(stage: 1); // HP 24
      monster.gainBlock(5);
      monster.takeDamage(3);

      expect(monster.hp, equals(24));
      expect(monster.block, equals(2));
    });

    test('데미지가 방어도를 초과하면 초과분만 체력에서 감소한다', () {
      final monster = Monster(stage: 1);
      monster.gainBlock(5);
      monster.takeDamage(8);

      expect(monster.block, equals(0));
      expect(monster.hp, equals(21)); // 24 - (8 - 5)
    });

    test('턴 종료 시 방어도가 0으로 초기화된다', () {
      final monster = Monster(stage: 1);
      monster.gainBlock(10);
      monster.endTurn();

      expect(monster.block, equals(0));
    });
  });

  group('Monster 기본 인텐트 시스템 (basic 타입)', () {
    test('스테이지 1 초기 인텐트 타입은 attack이다', () {
      expect(Monster(stage: 1).currentIntent.intentType, MonsterIntentType.attack);
    });

    test('스테이지 1 기본 공격 데미지는 10이다', () {
      expect(Monster(stage: 1).currentIntent.attackDamage, equals(10));
    });

    test('executeAction 후 패턴이 순환한다', () {
      final m = Monster(stage: 1);
      final p = Player();
      m.executeAction(p); // basic 패턴은 1개 → 다시 index 0으로
      expect(m.currentIntent.intentType, MonsterIntentType.attack);
    });
  });

  group('Monster 상태 이상 — Vulnerable', () {
    test('Vulnerable 상태에서 받는 데미지가 1.5배가 된다', () {
      final monster = Monster(stage: 1); // HP 24
      monster.applyStatusEffect(
        const StatusEffect(type: StatusEffectType.vulnerable, duration: 2),
      );
      monster.takeDamage(10); // floor(10 × 1.5) = 15

      expect(monster.hp, equals(9)); // 24 - 15
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

  // ── 새 몬스터 타입 행동 패턴 ──────────────────────────────────────────────

  group('끈적 슬라임 (stickySlime) — 힘 충전 후 공격 순환', () {
    late Monster m;
    late Player p;

    setUp(() {
      m = Monster(stage: 1, type: MonsterType.stickySlime);
      p = Player();
    });

    test('초기 HP = 35', () => expect(m.maxHp, equals(35)));

    test('1턴: 분비 — 힘 +3, 플레이어 피해 없음', () {
      m.executeAction(p);
      expect(m.strength, equals(3));
      expect(p.hp, equals(Player.maxHp));
    });

    test('2턴: 점착 공격 — 힘(3) 포함 10 데미지', () {
      m.executeAction(p); // 1턴: 분비
      m.executeAction(p); // 2턴: 공격
      expect(p.hp, equals(Player.maxHp - 10)); // 7 + 3(strength)
    });

    test('4턴: 두 번째 분비로 힘 6 누적', () {
      for (var i = 0; i < 4; i++) m.executeAction(p);
      expect(m.strength, equals(6));
    });

    test('1턴 의도 타입: buff', () {
      expect(m.currentIntent.intentType, equals(MonsterIntentType.buff));
    });
  });

  group('고철수집가 (ironScavenger) — 물기→단련→할퀴기 순환', () {
    late Monster m;
    late Player p;

    setUp(() {
      m = Monster(stage: 1, type: MonsterType.ironScavenger);
      p = Player();
    });

    test('초기 HP = 32', () => expect(m.maxHp, equals(32)));

    test('1턴: 물기 — 11 데미지', () {
      m.executeAction(p);
      expect(p.hp, equals(Player.maxHp - 11));
    });

    test('2턴: 단련 — 힘+2, 방어도+5, 공격 없음', () {
      m.executeAction(p); // 물기
      final hpBefore = p.hp;
      m.executeAction(p); // 단련
      expect(m.strength, equals(2));
      expect(m.block, equals(5));
      expect(p.hp, equals(hpBefore));
    });

    test('3턴: 할퀴기 — 7+strength 데미지 + 방어도 3 획득', () {
      m.executeAction(p); // 물기
      m.executeAction(p); // 단련 (strength=2, block=5)
      m.endTurn();        // 방어도 소멸 (새 턴)
      m.executeAction(p); // 할퀴기
      expect(p.hp, equals(Player.maxHp - 11 - 9)); // 7+2(strength)
      expect(m.block, equals(3));
    });

    test('4턴: 다시 물기 (순환)', () {
      for (var i = 0; i < 3; i++) {
        m.executeAction(p);
        m.endTurn();
      }
      expect(m.currentIntent.label, equals('물기'));
    });
  });

  group('독파수꾼 (venomSentinel) — 취약 부여 후 독침+강습 반복', () {
    late Monster m;
    late Player p;

    setUp(() {
      m = Monster(stage: 2, type: MonsterType.venomSentinel);
      p = Player();
    });

    test('초기 HP = 48', () => expect(m.maxHp, equals(48)));

    test('1턴: 독기 분출 — 4 데미지 + 플레이어 취약 2턴', () {
      m.executeAction(p);
      expect(p.hp, equals(Player.maxHp - 4));
      expect(p.isVulnerable, isTrue);
    });

    test('2턴: 독침 — 취약 상태 플레이어에게 floor(7×1.5)=10 데미지', () {
      m.executeAction(p); // 독기 분출 → 플레이어 취약(2)
      m.executeAction(p); // 독침 → 플레이어 취약 상태라 10 데미지
      expect(p.hp, equals(Player.maxHp - 4 - 10)); // 70-4-10=56
      expect(p.isVulnerable, isTrue);
    });

    test('3턴: 강습 — 취약 상태 플레이어에게 floor(12×1.5)=18 데미지', () {
      m.executeAction(p); // 독기 분출
      m.executeAction(p); // 독침
      m.executeAction(p); // 강습
      expect(p.hp, equals(Player.maxHp - 4 - 10 - 18)); // 70-4-10-18=38
    });

    test('4턴: 독침으로 돌아옴 (독기 분출 반복 없음)', () {
      for (var i = 0; i < 3; i++) m.executeAction(p);
      expect(m.currentIntent.label, equals('독침'));
    });
  });

  group('석굴 수호자 (caveGuardian) — 수면 후 강력 공격', () {
    late Monster m;
    late Player p;

    setUp(() {
      m = Monster(stage: 2, type: MonsterType.caveGuardian);
      p = Player();
    });

    test('초기 HP = 64', () => expect(m.maxHp, equals(64)));

    test('1턴: 수면 — 방어도 +5, 공격 없음', () {
      m.executeAction(p);
      expect(m.block, equals(5));
      expect(p.hp, equals(Player.maxHp));
    });

    test('2턴: 수면 — 방어도 추가 +5', () {
      m.executeAction(p); // 1턴
      m.endTurn();        // 방어도 소멸
      m.executeAction(p); // 2턴
      expect(m.block, equals(5));
      expect(p.hp, equals(Player.maxHp));
    });

    test('3턴: 깨어남 — 강타 15 데미지', () {
      for (var i = 0; i < 2; i++) {
        m.executeAction(p);
        m.endTurn();
      }
      m.executeAction(p); // 3턴: 강타
      expect(p.hp, equals(Player.maxHp - 15));
    });

    test('5턴: 기력 흡수 — 10 데미지 + 플레이어 약화 2턴', () {
      for (var i = 0; i < 4; i++) {
        m.executeAction(p);
        m.endTurn();
      }
      m.executeAction(p); // 5턴: 기력 흡수
      expect(p.isWeak, isTrue);
    });

    test('6턴: 수면 없이 강타로 순환', () {
      for (var i = 0; i < 5; i++) {
        m.executeAction(p);
        m.endTurn();
      }
      expect(m.currentIntent.label, equals('강타'));
    });

    test('1턴 의도 타입: sleep', () {
      expect(m.currentIntent.intentType, equals(MonsterIntentType.sleep));
    });
  });

  group('철갑 골렘 (ironGolem) — 방어→분쇄→연속타격 순환 (보스)', () {
    late Monster m;
    late Player p;

    setUp(() {
      m = Monster(stage: 3, type: MonsterType.ironGolem);
      p = Player();
    });

    test('초기 HP = 96', () => expect(m.maxHp, equals(96)));

    test('1턴: 장갑 강화 — 방어도 10 획득, 공격 없음', () {
      m.executeAction(p);
      expect(m.block, equals(10));
      expect(p.hp, equals(Player.maxHp));
    });

    test('2턴: 분쇄 강타 — 18 데미지', () {
      m.executeAction(p); // 장갑 강화
      m.executeAction(p); // 분쇄 강타
      expect(p.hp, equals(Player.maxHp - 18));
    });

    test('3턴: 연속 타격 — 5 × 3 = 15 데미지', () {
      m.executeAction(p); // 장갑 강화
      m.executeAction(p); // 분쇄 강타
      m.executeAction(p); // 연속 타격
      expect(p.hp, equals(Player.maxHp - 18 - 15));
    });

    test('연속 타격은 방어도를 히트마다 따로 통과한다', () {
      p.gainBlock(10);
      m.executeAction(p); // 장갑 강화 (공격 없음)
      m.executeAction(p); // 분쇄 강타 (18 > block 10) → hp=62, block=0
      p.gainBlock(10);    // 다시 방어도 부여
      // 연속 타격 5×3: hit1→block(5), hit2→block(0), hit3→hp(-5) → 총 HP -5
      m.executeAction(p);
      expect(p.hp, equals(57)); // 62 - 5
    });

    test('4턴: 다시 장갑 강화로 순환', () {
      for (var i = 0; i < 3; i++) m.executeAction(p);
      expect(m.currentIntent.intentType, equals(MonsterIntentType.defend));
    });
  });
}
