import '../map/node_type.dart';
import 'card.dart';

/// 런 종료 후 영구 유지되는 메타 진행 상태.
///
/// 순수 Dart 클래스 — Flutter·Riverpod import 절대 금지.
class MetaProgress {
  // ── XP 임계치 ──────────────────────────────────────────────────────────────

  /// SPECS.md: 각 레벨에 진입하는 데 필요한 누적 XP 임계치 (레벨 1~10).
  /// index i = 레벨 (i+1)에 진입하는 데 필요한 총 XP.
  static const List<int> xpThresholds = [
    0,     // 레벨 1
    100,   // 레벨 2
    250,   // 레벨 3
    450,   // 레벨 4
    700,   // 레벨 5
    1000,  // 레벨 6
    1350,  // 레벨 7
    1750,  // 레벨 8
    2200,  // 레벨 9
    2700,  // 레벨 10
  ];

  // ── 레벨별 카드 해금 ──────────────────────────────────────────────────────

  /// SPECS.md: 레벨 달성 시 런 보상 풀에 추가되는 카드 타입 문자열 목록.
  /// 티어 구조: T1(1~5), T2(6~8), T3(9~10).
  static const Map<int, List<String>> levelUnlocks = {
    1:  ['strike', 'defend'],
    2:  ['rageBurst', 'quickMend'],
    3:  ['swiftCut', 'regroup'],
    4:  ['tripleSlash', 'toxicJab'],
    5:  ['swiftGuard', 'comboStrike', 'sharpen'],
    6:  ['bash', 'ironWall'],
    7:  ['focus', 'recover', 'indomitable'],
    8:  ['fury', 'exploitWeakness', 'blockStrike', 'weakSlash', 'poisonDart'],
    9:  ['crushingBlow', 'bloodRush', 'battleCry'],
    10: ['devilsDeal', 'gamble'],
  };

  // ── 전투 XP 상수 ──────────────────────────────────────────────────────────

  /// 일반 몬스터 처치 XP (승리).
  static const int monsterWinXp  = 10;

  /// 엘리트 처치 XP (승리).
  static const int eliteWinXp    = 25;

  /// 보스 처치 XP — 런 클리어 (승리).
  static const int bossWinXp     = 100;

  /// 일반 몬스터 전투 XP (패배). 승리의 30% 수준.
  static const int monsterLoseXp = 3;

  /// 엘리트 전투 XP (패배).
  static const int eliteLoseXp   = 8;

  /// 보스 전투 XP (패배).
  static const int bossLoseXp    = 20;

  // ── 레벨업 보상 카드 풀 ───────────────────────────────────────────────────

  /// Tier 1 레벨업 보상 풀 — 레벨 2~5 달성 시 제공.
  /// 저비용 안정형 카드로 구성.
  static const List<GameCard> tier1RewardPool = [
    Cards.rageBurst, Cards.quickMend, Cards.swiftCut, Cards.regroup,
    Cards.tripleSlash, Cards.toxicJab, Cards.swiftGuard,
    Cards.comboStrike, Cards.sharpen, Cards.indomitable,
  ];

  /// Tier 2 레벨업 보상 풀 — 레벨 6~8 달성 시 제공.
  /// 전략적 중간급 카드로 구성.
  static const List<GameCard> tier2RewardPool = [
    Cards.bash, Cards.ironWall, Cards.focus, Cards.recover, Cards.fury,
    Cards.exploitWeakness, Cards.blockStrike, Cards.weakSlash, Cards.poisonDart,
  ];

  /// Tier 3 레벨업 보상 풀 — 레벨 9~10 달성 시 제공.
  /// 고위험·고수익 카드로 구성.
  static const List<GameCard> tier3RewardPool = [
    Cards.crushingBlow, Cards.bloodRush, Cards.battleCry,
    Cards.devilsDeal, Cards.gamble,
  ];

  // ── 필드 ──────────────────────────────────────────────────────────────────

  final int level;

  /// 누적 XP 총합.
  final int xp;

  /// 현재까지 해금된 카드 타입 문자열 목록.
  final List<String> unlockedCardTypes;

  const MetaProgress({
    required this.level,
    required this.xp,
    required this.unlockedCardTypes,
  });

  // ── 팩토리 ────────────────────────────────────────────────────────────────

  /// 게임 최초 시작 상태 — 레벨 1, XP 0, 기본 카드 2종 해금.
  factory MetaProgress.initial() => const MetaProgress(
        level: 1,
        xp: 0,
        unlockedCardTypes: ['strike', 'defend'],
      );

  // ── static 계산 메서드 ────────────────────────────────────────────────────

  /// 누적 XP에서 현재 레벨을 계산한다.
  static int computeLevel(int xp) {
    for (int i = xpThresholds.length - 1; i >= 0; i--) {
      if (xp >= xpThresholds[i]) return i + 1;
    }
    return 1;
  }

  /// 지정 레벨까지 해금된 모든 카드 타입을 반환한다.
  static List<String> computeUnlockedCards(int level) {
    final cards = <String>[];
    for (int l = 1; l <= level && levelUnlocks.containsKey(l); l++) {
      cards.addAll(levelUnlocks[l]!);
    }
    return cards;
  }

  /// 노드 유형과 승패에 따라 획득할 XP를 반환한다.
  static int xpForBattle(NodeType nodeType, {required bool isVictory}) =>
      switch (nodeType) {
        NodeType.monster => isVictory ? monsterWinXp  : monsterLoseXp,
        NodeType.elite   => isVictory ? eliteWinXp    : eliteLoseXp,
        NodeType.boss    => isVictory ? bossWinXp     : bossLoseXp,
        _                => 0,
      };

  /// 해당 레벨 달성 시 제공할 보상 카드 풀을 반환한다.
  static List<GameCard> rewardPoolForLevel(int level) {
    if (level <= 5) return tier1RewardPool;
    if (level <= 8) return tier2RewardPool;
    return tier3RewardPool;
  }

  // ── 게터 ──────────────────────────────────────────────────────────────────

  bool get isMaxLevel => level >= xpThresholds.length;

  /// 다음 레벨에 필요한 누적 XP. 최대 레벨이면 현재 XP를 반환한다.
  int get xpForNextLevel => isMaxLevel ? xp : xpThresholds[level];

  /// 다음 레벨까지 남은 XP. 최대 레벨이면 0.
  int get xpToNextLevel => isMaxLevel ? 0 : xpForNextLevel - xp;

  // ── 도메인 로직 ───────────────────────────────────────────────────────────

  /// [amount]만큼 XP를 추가하고, 갱신된 상태와 레벨업 결과를 함께 반환한다.
  (MetaProgress, LevelUpResult) addXp(int amount) {
    final newXp = xp + amount;
    final newLevel = computeLevel(newXp);
    final newCards = computeUnlockedCards(newLevel);
    final newlyUnlocked =
        newCards.where((c) => !unlockedCardTypes.contains(c)).toList();

    return (
      MetaProgress(level: newLevel, xp: newXp, unlockedCardTypes: newCards),
      LevelUpResult(
        didLevelUp: newLevel > level,
        previousLevel: level,
        newLevel: newLevel,
        newlyUnlockedCards: newlyUnlocked,
      ),
    );
  }
}

// ── 값 객체 ───────────────────────────────────────────────────────────────────

/// XP 추가 후 레벨업 여부와 신규 해금 카드를 담는 값 객체.
class LevelUpResult {
  final bool didLevelUp;
  final int previousLevel;
  final int newLevel;
  final List<String> newlyUnlockedCards;

  const LevelUpResult({
    required this.didLevelUp,
    required this.previousLevel,
    required this.newLevel,
    required this.newlyUnlockedCards,
  });
}
