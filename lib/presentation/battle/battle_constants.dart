import 'package:flutter/material.dart';

import '../../domain/entities/card.dart';

/// 전투 화면 문자열 상수.
abstract final class BattleStrings {
  static const appTitle = 'Slay the Flutter';
  static const stageLabel = '스테이지';
  static const endTurn = '턴 종료';
  static const nextAttack = '다음 공격';
  static const victory = '승리!';
  static const defeat = '패배...';
  static const restart = '다시 시작';
  static const vulnerable = '취약';
  static const weak = '약화';
  static const emptyHand = '패에 카드가 없습니다';

  /// 카드 효과 설명 문자열.
  static String cardEffect(GameCard card) => switch (card.type) {
        CardType.strike => '${card.value} 데미지',
        CardType.bash => '${card.value} 데미지 + 취약 2턴',
        CardType.swiftCut => '${card.value}×2 데미지',
        CardType.defend => '방어도 ${card.value}',
        CardType.ironWall => '방어도 ${card.value}',
        CardType.focus => '다음 카드 효과 +50%',
        CardType.recover => 'HP +${card.value}',
      };
}

/// SPECS.md: 전투 승리 시 지급되는 XP 보상.
abstract final class BattleXpRewards {
  static const int stageClear = 30;
  static const int runClear = 100;

  /// 스테이지 3(보스)는 런 클리어로 100 XP, 나머지는 30 XP.
  static int xpForStage(int stage) =>
      stage == 3 ? runClear : stageClear;

  static String xpGainedLabel(int xp) => '+$xp XP';
}

/// 전투 화면 색상 상수.
abstract final class BattleColors {
  static const background = Color(0xFF1A1A2E);
  static const surface = Color(0xFF16213E);

  /// 카드 효과 타입별 강조 색상.
  static Color forCard(CardEffectType type) => switch (type) {
        CardEffectType.damage => const Color(0xFFEF5350),
        CardEffectType.block => const Color(0xFF42A5F5),
        CardEffectType.heal => const Color(0xFF66BB6A),
        CardEffectType.buff => const Color(0xFFFFCA28),
      };
}
