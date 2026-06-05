import 'package:flutter/material.dart';

import '../../domain/entities/card.dart';

/// 보상 화면 문자열 상수.
abstract final class RewardStrings {
  static const title      = '보상 카드 선택';
  static const subtitle   = '카드 1장을 덱에 추가하세요';
  static const skipButton = '건너뛰기';

  /// 카드 효과 설명.
  static String cardEffect(GameCard card) => switch (card.type) {
        CardType.strike         => '${card.value} 데미지',
        CardType.bash           => '${card.value} 데미지 + 취약 2턴',
        CardType.swiftCut       => '${card.value}×2 데미지',
        CardType.defend         => '방어도 ${card.value}',
        CardType.ironWall       => '방어도 ${card.value}',
        CardType.focus          => '다음 카드 효과 +50%',
        CardType.recover        => 'HP +${card.value}',
        CardType.rageBurst      => '${card.value} 데미지 (복사본 생성)',
        CardType.toxicJab       => '${card.value} 데미지 + 취약 2턴',
        CardType.regroup        => '카드 ${card.value}장 드로우',
        CardType.crushingBlow   => '${card.value} 데미지 (소멸)',
        CardType.fury           => '힘 +${card.value} (지속)',
        CardType.tripleSlash    => '${card.value}×3 데미지',
        CardType.quickMend      => 'HP +${card.value} (소멸)',
        CardType.swiftGuard     => '방어도 ${card.value} + 드로우 1',
        CardType.exploitWeakness=> '${card.value} 데미지 (취약 시 +6)',
        CardType.sharpen        => '이번 턴 공격 +${card.value}',
        CardType.weakSlash      => '${card.value} 데미지 + 약화 2턴',
        CardType.blockStrike    => '방어도만큼 데미지',
        CardType.bloodRush      => 'X×${card.value} 데미지',
        CardType.devilsDeal     => 'HP -${card.value}, 카드 3장 드로우',
        CardType.battleCry      => '드로우 2 + 힘 +1 (소멸)',
        CardType.indomitable    => '방어도 ${card.value} (+ 힘)',
        CardType.comboStrike    => '공격패 수 × ${card.value} 데미지',
        CardType.gamble         => 'HP -${card.value}, 에너지 +2',
      };
}

/// 보상 화면 색상 상수.
abstract final class RewardColors {
  static const background = Color(0xFF1A1A2E);
  static const surface    = Color(0xFF16213E);
  static const cardBorder = Color(0xFFFFD700);

  /// 카드 효과 타입별 강조 색상.
  static Color forEffectType(CardEffectType type) => switch (type) {
        CardEffectType.damage   => const Color(0xFFEF5350),
        CardEffectType.block    => const Color(0xFF42A5F5),
        CardEffectType.heal     => const Color(0xFF66BB6A),
        CardEffectType.buff     => const Color(0xFFFFCA28),
        CardEffectType.draw     => const Color(0xFFAB47BC),
        CardEffectType.blockDraw=> const Color(0xFF29B6F6),
        CardEffectType.strength => const Color(0xFFFF7043),
      };
}
