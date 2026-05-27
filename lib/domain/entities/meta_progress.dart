/// 런 종료 후 영구 유지되는 메타 진행 상태.
///
/// 순수 Dart 클래스 — Flutter·Riverpod 임포트 금지.
class MetaProgress {
  /// SPECS.md: 각 레벨에 도달하기 위한 누적 XP 임계치.
  /// index i = 레벨 (i+1)에 진입하는 데 필요한 총 XP.
  static const List<int> xpThresholds = [0, 100, 250, 450];

  /// SPECS.md: 각 레벨 달성 시 새로 해금되는 카드 타입 목록.
  static const Map<int, List<String>> levelUnlocks = {
    1: ['strike', 'defend'],
    2: ['bash', 'swiftCut'],
    3: ['ironWall', 'focus'],
    4: ['recover'],
  };

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

  /// 게임 최초 시작 상태 — 레벨 1, XP 0, 기본 카드 2종 해금.
  factory MetaProgress.initial() => const MetaProgress(
        level: 1,
        xp: 0,
        unlockedCardTypes: ['strike', 'defend'],
      );

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

  bool get isMaxLevel => level >= xpThresholds.length;

  /// 다음 레벨에 필요한 누적 XP. 최대 레벨이면 현재 XP를 반환한다.
  int get xpForNextLevel => isMaxLevel ? xp : xpThresholds[level];

  /// 다음 레벨까지 남은 XP. 최대 레벨이면 0.
  int get xpToNextLevel => isMaxLevel ? 0 : xpForNextLevel - xp;

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
