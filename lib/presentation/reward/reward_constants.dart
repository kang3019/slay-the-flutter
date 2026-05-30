import 'package:flutter/material.dart';

import '../../domain/entities/card.dart';

/// 보상 화면 문자열 상수.
abstract final class RewardStrings {
  static const title      = '보상 카드 선택';
  static const subtitle   = '카드 1장을 덱에 추가하세요';
  static const skipButton = '건너뛰기';

  /// 카드 효과 설명.
  static String cardEffect(GameCard card) => switch (card.type) {
        CardType.strike   => '${card.value} 데미지',
        CardType.bash     => '${card.value} 데미지 + 취약 2턴',
        CardType.swiftCut => '${card.value}×2 데미지',
        CardType.defend   => '방어도 ${card.value}',
        CardType.ironWall => '방어도 ${card.value}',
        CardType.focus    => '다음 카드 효과 +50%',
        CardType.recover  => 'HP +${card.value}',
      };
}

/// 보상 화면 색상 상수.
abstract final class RewardColors {
  static const background = Color(0xFF1A1A2E);
  static const surface    = Color(0xFF16213E);
  static const cardBorder = Color(0xFFFFD700);

  /// 카드 효과 타입별 강조 색상.
  static Color forEffectType(CardEffectType type) => switch (type) {
        CardEffectType.damage => const Color(0xFFEF5350),
        CardEffectType.block  => const Color(0xFF42A5F5),
        CardEffectType.heal   => const Color(0xFF66BB6A),
        CardEffectType.buff   => const Color(0xFFFFCA28),
      };
}
