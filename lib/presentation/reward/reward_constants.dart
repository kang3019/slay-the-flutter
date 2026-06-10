import 'package:flutter/material.dart';

import '../../domain/entities/card.dart';

/// 보상 화면 문자열 상수.
abstract final class RewardStrings {
  static const victoryTitle = '전투 승리!';
  static const subtitle    = '카드 1장을 덱에 추가하세요';
  static const skipButton  = '건너뛰기';
  static const claimButton = '획득하기';
  static const claimedLabel = '획득 완료';

  /// 골드 보상 표시 문자열.
  static String goldLabel(int gold) => '+$gold 골드';

  /// 카드 효과 설명.
  static String cardEffect(GameCard card) => switch (card.type) {
        CardType.strike         => '${card.value} 데미지',
        CardType.bash           => '${card.value} 데미지 + 취약 2턴',
        CardType.swiftCut       => '${card.value}×2 데미지',
        CardType.defend         => '방어도 ${card.value}',
        CardType.ironWall       => '방어도 ${card.value}',
        CardType.focus          => '다음 카드 효과 +${card.value}%',
        CardType.recover        => 'HP +${card.value}',
        CardType.rageBurst      => '${card.value} 데미지, 사용 후 복사본이 버리는 더미에 추가됨',
        CardType.toxicJab       => '${card.value} 데미지 + 취약 ${card.isUpgraded ? 3 : 2}턴',
        CardType.regroup        => '카드 ${card.value}장 드로우',
        CardType.crushingBlow   => '${card.value} 데미지 (이번 전투에서 소멸)',
        CardType.fury           => '힘 +${card.value} (지속)',
        CardType.tripleSlash    => '${card.value}×3 데미지',
        CardType.quickMend      => 'HP +${card.value} (이번 전투에서 소멸)',
        CardType.swiftGuard     => '방어도 ${card.value} + 드로우 1',
        CardType.exploitWeakness=> '${card.value} 데미지 (취약 시 +${card.isUpgraded ? 9 : 6})',
        CardType.sharpen        => '이번 턴 공격 카드 전부 +${card.value} 데미지',
        CardType.weakSlash      => '${card.value} 데미지 + 약화 ${card.isUpgraded ? 3 : 2}턴',
        CardType.blockStrike    => card.isUpgraded ? '방어도×1.5 데미지' : '방어도만큼 데미지',
        CardType.bloodRush      => '남은 에너지(X)×${card.value} 데미지',
        CardType.devilsDeal     => 'HP -${card.value}, 카드 3장 드로우',
        CardType.battleCry      => '드로우 2 + 힘 +${card.isUpgraded ? 2 : 1} (이번 전투에서 소멸)',
        CardType.indomitable    => '방어도 ${card.value} (+ 힘)',
        CardType.comboStrike    => '손패 공격 카드 수 × ${card.value} 데미지',
        CardType.gamble         => 'HP -${card.value}, 에너지 +2',
        CardType.poisonDart     => '${card.value} 데미지 + 독 ${card.isUpgraded ? 5 : 3}스택',
        CardType.limitBreak     => card.isUpgraded ? '힘 2배 (소멸)' : '힘 2배',
        CardType.impervious     => '방어도 ${card.value} (소멸)',
        CardType.doubleTap      => '다음 공격 카드 ${card.value}장 2번 발동',
        CardType.fiendFire      => '손패 전체 버림, 카드당 ${card.value} 데미지 (소멸)',
      };
}

/// 보상 화면 색상 상수.
abstract final class RewardColors {
  static const surface    = Color(0xFF16213E);
  static const cardBorder = Color(0xFFFFD700);

  // ── 팝업형 레이아웃 (RunEndScreen과 톤 통일) ────────────────────────────
  static const popupBackground = Color(0xFF1A1510);
  static const popupBorder     = Color(0xFFB8860B);
  static const gold            = Color(0xFFFFD700);
  static const claimedAccent   = Color(0xFF66BB6A);

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
