import 'package:flutter/material.dart';

import '../../domain/entities/card.dart';

/// 전투 화면 문자열 상수.
abstract final class BattleStrings {
  static const appTitle    = 'Slay the Flutter';
  static const stageLabel  = '스테이지';
  static const endTurn     = '턴 종료';
  static const nextAttack  = '다음 공격';
  static const victory     = '승리!';
  static const runClear    = '런 클리어! 🎉';
  static const defeat      = '패배...';
  static const restart     = '새 런 시작';
  static const selectReward = '보상 카드 선택 →';
  static const returnToMap  = '맵으로 이동 →';
  static const vulnerable  = '취약';
  static const weak        = '약화';
  static const emptyHand   = '패에 카드가 없습니다';

  /// 카드 효과 설명 문자열.
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

/// SPECS.md: 전투 승리 시 지급되는 XP 보상.
abstract final class BattleXpRewards {
  static const int stageClear = 30;
  static const int runClear = 100;

  /// 스테이지 3(보스)는 런 클리어로 100 XP, 나머지는 30 XP.
  static int xpForStage(int stage) =>
      stage == 3 ? runClear : stageClear;

  static String xpGainedLabel(int xp) => '+$xp XP';
}

/// SPECS.md §6: 전투 승리 시 지급되는 골드 보상.
///
/// 일반 몬스터 처치 보상: 15~30 골드. 보스는 별도 보상 없음(런 클리어).
abstract final class BattleGoldRewards {
  /// 일반 몬스터 처치 최소 골드.
  static const int minGold = 15;

  /// 일반 몬스터 처치 최대 골드.
  static const int maxGold = 30;

  /// 스테이지별 고정 골드 보상.
  ///
  /// 추후 Random 보상으로 교체할 수 있도록 단일 진입점을 제공한다.
  static int forStage(int stage) => switch (stage) {
        1 => minGold,
        2 => 25,
        _ => 0, // 보스(스테이지 3)는 골드 대신 런 클리어
      };

  static String goldLabel(int gold) => '+$gold 골드';
}

/// 전투 화면 색상 상수.
abstract final class BattleColors {
  static const background = Color(0xFF1A1A2E);
  static const surface = Color(0xFF16213E);

  /// 카드 효과 타입별 강조 색상.
  static Color forCard(CardEffectType type) => switch (type) {
        CardEffectType.damage   => const Color(0xFFEF5350),
        CardEffectType.block    => const Color(0xFF42A5F5),
        CardEffectType.heal     => const Color(0xFF66BB6A),
        CardEffectType.buff     => const Color(0xFFFFCA28),
        CardEffectType.draw     => const Color(0xFFAB47BC),
        CardEffectType.blockDraw=> const Color(0xFF29B6F6),
        CardEffectType.strength => const Color(0xFFFF7043),
      };
}
