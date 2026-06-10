import 'package:flutter/material.dart';

import '../../domain/entities/card.dart';
import '../../domain/entities/meta_progress.dart';
import '../../domain/map/node_type.dart';

/// 전투 화면 문자열 상수.
abstract final class BattleStrings {
  static const appTitle          = 'Slay the Flutter';
  static const stageLabel        = '스테이지';
  static const endTurn           = '턴 종료';
  static const nextAttack        = '다음 공격';
  static const intentAttack      = '공격';
  static const intentHeavyAttack = '강공격';
  static const intentBlock       = '방어';
  static const runClear          = '런 클리어!';
  static const defeat            = '패배...';
  static const restart           = '새 런 시작';
  static const returnToMap       = '맵으로 이동';
  static const peekMap           = '지도 보기';
  static const vulnerable            = '취약';
  static const vulnerableDescription = '받는 피해가 50% 증가한다. (×1.5)';
  static const weak                  = '약화';
  static const weakDescription       = '주는 피해가 25% 감소한다. (×0.75)';
  static const poison                = '독';
  static const poisonDescription     = '매 턴 시작 시 스택 수치만큼 피해를 입는다. (블록 무시)\n턴마다 스택이 1 감소한다.';
  static const emptyHand         = '패에 카드가 없습니다';
  static const hp                = 'HP';
  static const block             = '방어도';
  static const energy            = '에너지';

  /// 카드 효과 설명 문자열.
  static String cardEffect(GameCard card) => switch (card.type) {
        CardType.strike          => '${card.value} 데미지',
        CardType.bash            => '${card.value} 데미지 + 취약 2턴',
        CardType.swiftCut        => '${card.value}×2 데미지',
        CardType.defend          => '방어도 ${card.value}',
        CardType.ironWall        => '방어도 ${card.value}',
        CardType.focus           => '다음 카드 효과 +${card.value}%',
        CardType.recover         => 'HP +${card.value}',
        CardType.rageBurst       => '${card.value} 데미지, 사용 후 복사본이 버리는 더미에 추가됨',
        CardType.toxicJab        => '${card.value} 데미지 + 취약 ${card.isUpgraded ? 3 : 2}턴',
        CardType.regroup         => '카드 ${card.value}장 드로우',
        CardType.crushingBlow    => '${card.value} 데미지 (이번 전투에서 소멸)',
        CardType.fury            => '힘 +${card.value} (지속)',
        CardType.tripleSlash     => '${card.value}×3 데미지',
        CardType.quickMend       => 'HP +${card.value} (이번 전투에서 소멸)',
        CardType.swiftGuard      => '방어도 ${card.value} + 드로우 1',
        CardType.exploitWeakness => '${card.value} 데미지 (취약 시 +${card.isUpgraded ? 9 : 6})',
        CardType.sharpen         => '이번 턴 공격 카드 전부 +${card.value} 데미지',
        CardType.weakSlash       => '${card.value} 데미지 + 약화 ${card.isUpgraded ? 3 : 2}턴',
        CardType.blockStrike     => card.isUpgraded ? '방어도×1.5 데미지' : '방어도만큼 데미지',
        CardType.bloodRush       => '남은 에너지(X)×${card.value} 데미지',
        CardType.devilsDeal      => 'HP -${card.value}, 카드 3장 드로우',
        CardType.battleCry       => '드로우 2 + 힘 +${card.isUpgraded ? 2 : 1} (이번 전투에서 소멸)',
        CardType.indomitable     => '방어도 ${card.value} (+ 힘)',
        CardType.comboStrike     => '손패 공격 카드 수 × ${card.value} 데미지',
        CardType.gamble          => 'HP -${card.value}, 에너지 +2',
        CardType.poisonDart      => '${card.value} 데미지 + 독 ${card.isUpgraded ? 5 : 3}스택',
        CardType.limitBreak      => card.isUpgraded ? '힘 2배 (소멸)' : '힘 2배',
        CardType.impervious      => '방어도 ${card.value} (소멸)',
        CardType.doubleTap       => '다음 공격 카드 ${card.value}장 2번 발동',
        CardType.fiendFire       => '손패 전체 버림, 카드당 ${card.value} 데미지 (소멸)',
      };
}

/// 전투 결과 XP 표시 유틸리티 — 도메인 상수([MetaProgress])를 UI에 연결한다.
abstract final class BattleXpRewards {
  /// 노드 타입·승패에 따른 획득 XP. [MetaProgress.xpForBattle]로 위임.
  static int xpFor(NodeType nodeType, {required bool isVictory}) =>
      MetaProgress.xpForBattle(nodeType, isVictory: isVictory);

  static String xpGainedLabel(int xp) => '+$xp XP';

  static String xpLostLabel(int xp) => '+$xp XP (패배 보정)';
}

/// SPECS.md §6: 전투 승리 시 지급되는 골드 보상.
abstract final class BattleGoldRewards {
  static const int minGold = 15;
  static const int maxGold = 30;

  static int forStage(int stage) => switch (stage) {
        1 => minGold,
        2 => 25,
        _ => 0,
      };

  static String goldLabel(int gold) => '+$gold 골드';
}

/// 전투 화면 에셋 경로 상수.
abstract final class BattleAssets {
  static const background        = 'assets/images/battle_bg.png';
  /// 일반·엘리트 전투 배경 MP4 — 무한 루프 재생용.
  static const backgroundVideo   = 'assets/images/battle_bg.mp4';
  static const ironGolemBg       = 'assets/images/backgrounds/iron_golem_bg.jpg';
}

/// 플레이어 캐릭터 이미지 경로 상수.
abstract final class PlayerAssets {
  static const idle   = 'assets/images/player_idle.png';
  static const attack = 'assets/images/player_attack.png';
}

/// 몬스터 이미지 경로 상수.
abstract final class MonsterAssets {
  static const stickySlime   = 'assets/images/monsters/sticky_slime.png';
  static const ironScavenger = 'assets/images/monsters/iron_scavenger.png';
  static const venomSentinel = 'assets/images/monsters/venom_sentinel.png';
  static const caveGuardian  = 'assets/images/monsters/cave_guardian.png';
  static const ironGolem     = 'assets/images/monsters/iron_golem.png';

  /// [MonsterType] 이름을 받아 대응하는 에셋 경로를 반환한다. basic은 null.
  static String? forTypeName(String typeName) => switch (typeName) {
        'stickySlime'   => stickySlime,
        'ironScavenger' => ironScavenger,
        'venomSentinel' => venomSentinel,
        'caveGuardian'  => caveGuardian,
        'ironGolem'     => ironGolem,
        _               => null,
      };
}

/// 전투 화면 색상 상수.
///
/// 횃불의 금/주황과 돌 회색으로 구성된 다크 판타지 팔레트.
abstract final class BattleColors {
  // ── 배경 ──────────────────────────────────────────────────────────────
  /// 배경 이미지 위에 씌우는 반투명 어두운 오버레이 (가독성 확보).
  static const backgroundOverlay = Color(0x4D000000); // 30% 검정

  // ── 패널 ──────────────────────────────────────────────────────────────
  /// 몬스터·플레이어 패널의 반투명 배경. 배경 이미지가 살짝 비치도록 한다.
  static const panelBg     = Color(0xCC0D0A07); // 80% 다크 브라운
  static const panelBorder = Color(0xFF3D3020); // 어두운 금색 테두리

  // ── 포인트 컬러: 횃불 ─────────────────────────────────────────────────
  static const torchGold   = Color(0xFFF59E0B); // 횃불 금색
  static const torchOrange = Color(0xFFD97706); // 횃불 주황

  // ── 포인트 컬러: 돌 ───────────────────────────────────────────────────
  static const dungeonStone = Color(0xFF78909C); // 던전 돌 회색

  // ── HP 바 ─────────────────────────────────────────────────────────────
  static const playerHpBar  = Color(0xFF4CAF50); // 플레이어 HP (녹색)
  static const monsterHpBar = Color(0xFFEF5350); // 몬스터 HP (빨강)

  // ── 레거시 (다른 화면과의 호환) ─────────────────────────────────────
  static const background = Color(0xFF1A1A2E);
  static const surface    = Color(0xFF16213E);

  /// 카드 효과 타입별 강조 색상.
  static Color forCard(CardEffectType type) => switch (type) {
        CardEffectType.damage    => const Color(0xFFEF5350),
        CardEffectType.block     => const Color(0xFF42A5F5),
        CardEffectType.heal      => const Color(0xFF66BB6A),
        CardEffectType.buff      => const Color(0xFFFFCA28),
        CardEffectType.draw      => const Color(0xFFAB47BC),
        CardEffectType.blockDraw => const Color(0xFF29B6F6),
        CardEffectType.strength  => const Color(0xFFFF7043),
      };

  /// 카드 테두리에 쓰이는 어두운 변형 색상.
  static Color borderForCard(CardEffectType type) => switch (type) {
        CardEffectType.damage    => const Color(0xFFC62828),
        CardEffectType.block     => const Color(0xFF1565C0),
        CardEffectType.heal      => const Color(0xFF2E7D32),
        CardEffectType.buff      => const Color(0xFFF9A825),
        CardEffectType.draw      => const Color(0xFF7B1FA2),
        CardEffectType.blockDraw => const Color(0xFF0277BD),
        CardEffectType.strength  => const Color(0xFFE64A19),
      };
}
