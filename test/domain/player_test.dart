import 'package:flutter_test/flutter_test.dart';
import 'package:slay_the_flutter/domain/entities/player.dart';
import 'package:slay_the_flutter/domain/status_effect.dart';

void main() {
  late Player player;

  setUp(() {
    player = Player();
  });

  group('Player 초기 상태', () {
    test('체력은 70으로 시작한다', () {
      expect(player.hp, equals(70));
    });

    test('방어도는 0으로 시작한다', () {
      expect(player.block, equals(0));
    });

    test('초기 상태에서 isDead는 false', () {
      expect(player.isDead, isFalse);
    });
  });

  group('데미지 처리', () {
    test('플레이어가 데미지를 입으면 체력이 감소한다', () {
      player.takeDamage(10);
      expect(player.hp, equals(60));
    });

    test('체력은 0 아래로 내려가지 않는다', () {
      player.takeDamage(200);
      expect(player.hp, equals(0));
    });

    test('체력이 0이면 isDead는 true', () {
      player.takeDamage(200);
      expect(player.isDead, isTrue);
    });
  });

  group('방어도(Block) 처리', () {
    test('방어도가 있으면 데미지가 방어도에 먼저 흡수된다', () {
      player.gainBlock(5);
      player.takeDamage(3);

      expect(player.hp, equals(70)); // 방어도가 전부 흡수
      expect(player.block, equals(2)); // 잔여 방어도 = 5 - 3
    });

    test('데미지가 방어도를 초과하면 초과분만 체력에서 감소한다', () {
      player.gainBlock(5);
      player.takeDamage(8);

      expect(player.block, equals(0));
      expect(player.hp, equals(67)); // 8 - 5 = 3 데미지
    });

    test('방어도가 데미지와 정확히 같으면 체력 손실 없음', () {
      player.gainBlock(10);
      player.takeDamage(10);

      expect(player.block, equals(0));
      expect(player.hp, equals(70));
    });

    test('턴 종료 시 방어도가 0으로 초기화된다', () {
      player.gainBlock(10);
      player.endTurn();

      expect(player.block, equals(0));
    });
  });

  group('상태 이상 — Vulnerable', () {
    test('Vulnerable 상태에서 받는 데미지가 1.5배가 된다', () {
      player.applyStatusEffect(
        const StatusEffect(type: StatusEffectType.vulnerable, duration: 1),
      );
      player.takeDamage(10); // 10 × 1.5 = 15

      expect(player.hp, equals(55));
    });

    test('Vulnerable은 턴 종료 후 duration이 감소한다', () {
      player.applyStatusEffect(
        const StatusEffect(type: StatusEffectType.vulnerable, duration: 2),
      );
      player.endTurn();

      expect(player.isVulnerable, isTrue); // duration 1 남음
    });

    test('Vulnerable은 duration 만료 후 해제된다', () {
      player.applyStatusEffect(
        const StatusEffect(type: StatusEffectType.vulnerable, duration: 1),
      );
      player.endTurn(); // duration 0 → 제거

      player.takeDamage(10); // 배율 없이 10 데미지
      expect(player.hp, equals(60));
    });

    test('동일 상태 이상을 중복 적용하면 duration이 누적된다', () {
      player.applyStatusEffect(
        const StatusEffect(type: StatusEffectType.vulnerable, duration: 2),
      );
      player.applyStatusEffect(
        const StatusEffect(type: StatusEffectType.vulnerable, duration: 1),
      );

      expect(
        player.statusEffects
            .firstWhere((e) => e.type == StatusEffectType.vulnerable)
            .duration,
        equals(3),
      );
    });
  });

  group('상태 이상 — Weak', () {
    test('Weak 상태에서는 isWeak가 true', () {
      player.applyStatusEffect(
        const StatusEffect(type: StatusEffectType.weak, duration: 2),
      );
      expect(player.isWeak, isTrue);
    });

    test('Weak은 턴 종료 후 duration이 감소한다', () {
      player.applyStatusEffect(
        const StatusEffect(type: StatusEffectType.weak, duration: 1),
      );
      player.endTurn();

      expect(player.isWeak, isFalse);
    });
  });
}
