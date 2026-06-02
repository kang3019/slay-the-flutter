import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:slay_the_flutter/domain/events/game_event.dart';

void main() {
  group('GameEvents', () {
    test('all 풀에 4개 이벤트가 등록되어 있다', () {
      expect(GameEvents.all.length, equals(4));
    });

    test('모든 이벤트는 고유한 id를 가진다', () {
      final ids = GameEvents.all.map((e) => e.id).toList();
      expect(ids.toSet().length, equals(ids.length));
    });

    test('모든 이벤트는 정확히 2개의 선택지를 가진다', () {
      for (final event in GameEvents.all) {
        expect(event.choices.length, equals(2),
            reason: '${event.id} 이벤트의 선택지 수가 2개가 아님');
      }
    });
  });

  group('EventEffect', () {
    test('기본값은 모두 0이고 addRandomCard는 false이다', () {
      const effect = EventEffect();
      expect(effect.hpDelta, equals(0));
      expect(effect.goldDelta, equals(0));
      expect(effect.addRandomCard, isFalse);
    });
  });

  group('GameEvents.random', () {
    test('반환된 이벤트는 all 풀에 속한다', () {
      final event = GameEvents.random();
      expect(GameEvents.all, contains(event));
    });

    test('동일한 seed로 호출하면 동일한 이벤트를 반환한다', () {
      final a = GameEvents.random(Random(42));
      final b = GameEvents.random(Random(42));
      expect(a.id, equals(b.id));
    });
  });

  group('이벤트별 효과 검증', () {
    test('신비로운 약 — 선택 A: HP +15', () {
      final choice = GameEvents.mysteriousPotion.choices[0];
      expect(choice.effect.hpDelta, equals(15));
      expect(choice.effect.goldDelta, equals(0));
    });

    test('신비로운 약 — 선택 B: 골드 +10', () {
      final choice = GameEvents.mysteriousPotion.choices[1];
      expect(choice.effect.goldDelta, equals(10));
      expect(choice.effect.hpDelta, equals(0));
    });

    test('악마의 계약 — 계약 수락: 카드 획득 + HP -8', () {
      final choice = GameEvents.devilsDeal.choices[0];
      expect(choice.effect.addRandomCard, isTrue);
      expect(choice.effect.hpDelta, equals(-8));
    });

    test('악마의 계약 — 거절: 아무 효과 없음', () {
      final choice = GameEvents.devilsDeal.choices[1];
      expect(choice.effect.hpDelta, equals(0));
      expect(choice.effect.goldDelta, equals(0));
      expect(choice.effect.addRandomCard, isFalse);
    });

    test('버려진 금고 — 세게 부순다: 골드 +45 HP -12', () {
      final choice = GameEvents.abandonedSafe.choices[1];
      expect(choice.effect.goldDelta, equals(45));
      expect(choice.effect.hpDelta, equals(-12));
    });
  });
}
