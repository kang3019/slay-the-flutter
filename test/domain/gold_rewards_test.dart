import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:slay_the_flutter/domain/entities/gold_rewards.dart';
import 'package:slay_the_flutter/domain/map/node_type.dart';

void main() {
  group('GoldRewards.forVictory', () {
    final random = Random();

    test('일반 몬스터: floor 0(1층) → 층수(1) + 10~14 = 11~15', () {
      for (var i = 0; i < 200; i++) {
        final gold = GoldRewards.forVictory(NodeType.monster, 0, random);
        expect(gold, inInclusiveRange(11, 15));
      }
    });

    test('일반 몬스터: floor 3(4층) → 층수(4) + 10~14 = 14~18', () {
      for (var i = 0; i < 200; i++) {
        final gold = GoldRewards.forVictory(NodeType.monster, 3, random);
        expect(gold, inInclusiveRange(14, 18));
      }
    });

    test('엘리트: floor 1(2층) → 층수(2) + 20~25 = 22~27', () {
      for (var i = 0; i < 200; i++) {
        final gold = GoldRewards.forVictory(NodeType.elite, 1, random);
        expect(gold, inInclusiveRange(22, 27));
      }
    });

    test('보스는 골드 보상이 없다 (0)', () {
      expect(GoldRewards.forVictory(NodeType.boss, 4, random), 0);
    });

    test('전투가 아닌 노드 타입은 골드 보상이 없다 (0)', () {
      expect(GoldRewards.forVictory(NodeType.rest, 0, random), 0);
      expect(GoldRewards.forVictory(NodeType.shop, 0, random), 0);
      expect(GoldRewards.forVictory(NodeType.treasure, 0, random), 0);
      expect(GoldRewards.forVictory(NodeType.event, 0, random), 0);
    });
  });
}
