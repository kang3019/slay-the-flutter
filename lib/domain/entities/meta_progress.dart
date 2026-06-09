import '../map/node_type.dart';

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

  // ── 카드 해금 ──────────────────────────────────────────────────────────────

  /// 레벨·진행도와 무관하게 항상 보상 풀에 등장하는 기본 해금 카드 (7종).
  ///
  /// 신규 플레이어도 전투 보상·이벤트·상점에서 이 카드들을 바로 만날 수 있다.
  static const List<String> baseUnlockedCards = [
    'swiftCut',   // 빠른 이중 공격 — 기초 공격 옵션
    'rageBurst',  // 고데미지 + 복사 — 리스크 있는 화력
    'quickMend',  // 즉시 회복 — 생존 수단
    'regroup',    // 카드 3장 드로우 — 핸드 보충
    'swiftGuard', // 방어 + 드로우 — 범용 방어
    'sharpen',    // 이번 턴 공격 전체 강화 — 시너지 진입
    'fury',       // 힘 +1 영구 — 누적 성장
  ];

  /// 레벨 달성 시 추가로 해금되는 카드 목록.
  ///
  /// - 레벨 1: 스타터 덱 카드 (보상 풀 제외, 시작 덱 추적용)
  /// - 레벨 2~8: 단계별로 강력·복잡한 카드 해금
  static const Map<int, List<String>> levelUnlocks = {
    1: ['strike', 'defend'],                            // 스타터 덱 전용
    2: ['tripleSlash', 'toxicJab', 'comboStrike'],      // 중급 공격·상태이상
    3: ['bash', 'ironWall'],                            // 취약 부여·중방어
    4: ['focus', 'recover', 'indomitable'],             // 카드 강화·회복·힘+방어
    5: ['exploitWeakness', 'weakSlash', 'blockStrike'], // 시너지 특화 카드
    6: ['poisonDart', 'battleCry'],                     // 독·전열 강화
    7: ['crushingBlow', 'bloodRush'],                   // 소모·에너지 기반 피해
    8: ['devilsDeal', 'gamble'],                        // 고위험·고수익 엔드게임
    9: ['limitBreak', 'fiendFire'],                     // 힘 폭발·손패 소멸 피해
    10: ['doubleTap', 'impervious'],                    // 이중 발동·고방어 소멸
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

  // ── 필드 ──────────────────────────────────────────────────────────────────

  final int level;

  /// 누적 XP 총합.
  final int xp;

  /// 현재까지 해금된 카드 타입 문자열 목록 (기본 해금 + 레벨별 해금).
  final List<String> unlockedCardTypes;

  const MetaProgress({
    required this.level,
    required this.xp,
    required this.unlockedCardTypes,
  });

  // ── 팩토리 ────────────────────────────────────────────────────────────────

  /// 게임 최초 시작 상태 — 레벨 1, XP 0, 기본 해금 카드 + 스타터 덱 카드.
  factory MetaProgress.initial() => MetaProgress(
        level: 1,
        xp: 0,
        unlockedCardTypes: computeUnlockedCards(1),
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
  ///
  /// [baseUnlockedCards]는 레벨에 무관하게 항상 포함된다.
  /// [levelUnlocks]는 레벨 1부터 지정 레벨까지 누적해 추가된다.
  static List<String> computeUnlockedCards(int level) {
    final cards = <String>[...baseUnlockedCards];
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

  // ── 직렬화 ────────────────────────────────────────────────────────────────

  /// 세이브 슬롯 저장을 위한 JSON 직렬화.
  Map<String, dynamic> toJson() => {
    'level': level,
    'xp': xp,
    'unlockedCardTypes': unlockedCardTypes,
  };

  /// JSON에서 [MetaProgress]를 복원한다.
  static MetaProgress fromJson(Map<String, dynamic> json) => MetaProgress(
    level: json['level'] as int,
    xp: json['xp'] as int,
    unlockedCardTypes: (json['unlockedCardTypes'] as List).cast<String>(),
  );

  // ── 게터 ──────────────────────────────────────────────────────────────────

  bool get isMaxLevel => level >= xpThresholds.length;

  /// 다음 레벨에 필요한 누적 XP. 최대 레벨이면 현재 XP를 반환한다.
  int get xpForNextLevel => isMaxLevel ? xp : xpThresholds[level];

  /// 다음 레벨까지 남은 XP. 최대 레벨이면 0.
  int get xpToNextLevel => isMaxLevel ? 0 : xpForNextLevel - xp;

  // ── 도메인 로직 ───────────────────────────────────────────────────────────

  /// [amount]만큼 XP를 추가하고, 갱신된 상태와 레벨업 결과를 함께 반환한다.
  (MetaProgress, LevelUpResult) addXp(int amount) {
    final newXp    = xp + amount;
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
