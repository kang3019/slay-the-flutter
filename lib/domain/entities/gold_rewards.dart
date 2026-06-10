import 'dart:math';

import '../map/node_type.dart';

/// 전투 승리 시 골드 보상 계산.
///
/// 순수 Dart 클래스 — Flutter·Riverpod import 절대 금지.
abstract final class GoldRewards {
  /// 일반 몬스터 처치 시 보너스 골드 최소값.
  static const int monsterBonusMin = 10;

  /// 일반 몬스터 처치 시 보너스 골드 최대값 (포함).
  static const int monsterBonusMax = 14;

  /// 엘리트 처치 시 보너스 골드 최소값.
  static const int eliteBonusMin = 20;

  /// 엘리트 처치 시 보너스 골드 최대값 (포함).
  static const int eliteBonusMax = 25;

  /// [nodeType]·[floor]에 따른 전투 승리 골드 보상.
  ///
  /// - 일반 몬스터: 층수(floor + 1) + (10~14 무작위)
  /// - 엘리트: 층수(floor + 1) + (20~25 무작위)
  /// - 보스·기타: 0 (별도 골드 보상 없음)
  static int forVictory(NodeType nodeType, int floor, Random random) {
    final floorNumber = floor + 1;
    return switch (nodeType) {
      NodeType.monster => floorNumber +
          monsterBonusMin +
          random.nextInt(monsterBonusMax - monsterBonusMin + 1),
      NodeType.elite => floorNumber +
          eliteBonusMin +
          random.nextInt(eliteBonusMax - eliteBonusMin + 1),
      _ => 0,
    };
  }
}
