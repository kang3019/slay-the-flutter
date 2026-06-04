import '../status_effect.dart';
import 'player.dart';

/// 몬스터가 다음 턴에 취할 행동 유형 — UI 아이콘·설명에 사용.
enum MonsterIntentType {
  attack,       // 공격
  defend,       // 방어도 획득
  buff,         // 자체 강화 (힘 증가)
  attackDebuff, // 공격 + 플레이어 상태 이상
  sleep,        // 수면 (공격 없음, 방어도 자동 획득)
}

/// 몬스터 한 턴의 행동 명세.
class MonsterTurnAction {
  /// UI에 표시할 행동 유형.
  final MonsterIntentType intentType;

  /// 행동 이름 (UI 표시용).
  final String label;

  /// 타격당 공격 데미지 (공격하지 않으면 0).
  final int attackDamage;

  /// 타격 횟수 — 연속 타격 같은 다중 히트에 사용.
  final int hitCount;

  /// 이번 턴에 자신이 획득할 방어도.
  final int blockGain;

  /// 이번 턴에 자신이 획득할 힘.
  final int strengthGain;

  /// 플레이어에게 부여할 상태 이상 (null이면 없음).
  final StatusEffect? playerDebuff;

  const MonsterTurnAction({
    required this.intentType,
    required this.label,
    this.attackDamage = 0,
    this.hitCount = 1,
    this.blockGain = 0,
    this.strengthGain = 0,
    this.playerDebuff,
  });

  /// 총 공격 데미지 (strength 미적용, hitCount 반영).
  int get totalDamage => attackDamage * hitCount;

  /// 이 행동에 대한 설명 문자열 (UI 팝업에 사용).
  String get description {
    final parts = <String>[];
    if (intentType == MonsterIntentType.sleep) parts.add('이번 턴 행동하지 않는다');
    if (attackDamage > 0) {
      parts.add(hitCount > 1
          ? '$attackDamage × $hitCount = ${totalDamage} 데미지'
          : '$attackDamage 데미지');
    }
    if (blockGain > 0) parts.add('방어도 $blockGain 획득');
    if (strengthGain > 0) parts.add('힘 +$strengthGain (공격력 증가)');
    if (playerDebuff != null) {
      final name = playerDebuff!.type == StatusEffectType.vulnerable ? '취약' : '약화';
      parts.add('플레이어에게 $name ${playerDebuff!.duration}턴 부여');
    }
    return parts.join('\n');
  }
}

/// 몬스터 종류. 각 타입마다 고유 이름·HP·행동 패턴을 가진다.
enum MonsterType {
  /// 하위 호환용 기본 타입 — 매 턴 고정 데미지 공격. 테스트용.
  basic,

  /// 끈적 슬라임 (Stage 1): 힘 충전 후 공격, 시간이 지날수록 강해짐.
  stickySlime,

  /// 고철수집가 (Stage 1): 물기→단련→할퀴기 3턴 순환.
  ironScavenger,

  /// 독파수꾼 (Stage 2): 독기 분출 후 독침+강습 반복.
  venomSentinel,

  /// 석굴 수호자 (Stage 2): 2턴 수면 후 강력 공격 패턴.
  caveGuardian,

  /// 철갑 골렘 (Stage 3 보스): 방어→분쇄→연속타격 순환.
  ironGolem,
}

/// 몬스터 엔티티.
///
/// [MonsterType]으로 이름·HP·행동 패턴이 결정된다.
/// [type]을 지정하지 않으면 [MonsterType.basic]이 사용된다.
///
/// 순수 Dart 클래스 — Flutter·Riverpod 임포트 금지.
class Monster {
  /// SPECS.md: 취약 상태에서 받는 데미지 배율.
  static const double vulnerableMultiplier = 1.5;

  final int stage;
  final MonsterType type;
  final int _maxHp;
  int hp;
  int block;

  /// 이번 전투 동안 축적된 힘. 공격 데미지에 더해진다.
  int strength;

  List<StatusEffect> statusEffects;
  int _turnIndex;
  final List<MonsterTurnAction> _pattern;

  /// 패턴이 끝난 후 다시 시작할 인덱스.
  /// 대부분은 0이지만 [MonsterType.caveGuardian] 같이 수면 구간을 건너뛸 때 사용.
  final int _loopFromIndex;

  Monster({required this.stage, MonsterType? type})
      : type = type ?? MonsterType.basic,
        _maxHp = _computeMaxHp(type ?? MonsterType.basic, stage),
        hp = _computeMaxHp(type ?? MonsterType.basic, stage),
        block = 0,
        strength = 0,
        statusEffects = [],
        _turnIndex = 0,
        _pattern = _buildPattern(type ?? MonsterType.basic, stage),
        _loopFromIndex = _computeLoopFromIndex(type ?? MonsterType.basic);

  // ── Getter ───────────────────────────────────────────────────────────────

  String get name => switch (type) {
        MonsterType.basic         => '몬스터',
        MonsterType.stickySlime   => '끈적 슬라임',
        MonsterType.ironScavenger => '고철수집가',
        MonsterType.venomSentinel => '독파수꾼',
        MonsterType.caveGuardian  => '석굴 수호자',
        MonsterType.ironGolem     => '철갑 골렘',
      };

  int get maxHp => _maxHp;

  /// 현재 의도의 총 공격 데미지 (strength 미적용).
  /// 기본 타입은 stage 공식, 신규 타입은 currentIntent 기준.
  int get attackPower => currentIntent.totalDamage;

  bool get isDead => hp <= 0;

  bool get isVulnerable => statusEffects.any(
        (e) => e.type == StatusEffectType.vulnerable && e.duration > 0,
      );

  bool get isWeak => statusEffects.any(
        (e) => e.type == StatusEffectType.weak && e.duration > 0,
      );

  /// 이번 턴에 취할 행동. UI의 의도 표시에 사용된다.
  MonsterTurnAction get currentIntent {
    if (_turnIndex < _pattern.length) return _pattern[_turnIndex];
    final loopLength = _pattern.length - _loopFromIndex;
    return _pattern[_loopFromIndex + (_turnIndex - _loopFromIndex) % loopLength];
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  /// 현재 의도를 실행하고 다음 턴으로 진행한다.
  ///
  /// 순서: 공격(힘 포함, 히트마다 별도 적용) → 방어도 획득 → 힘 증가 → 플레이어 상태 이상 부여.
  void executeAction(Player player) {
    final action = currentIntent;

    if (action.attackDamage > 0) {
      final dmg = action.attackDamage + strength;
      for (var i = 0; i < action.hitCount; i++) {
        player.takeDamage(dmg);
      }
    }

    if (action.blockGain > 0) gainBlock(action.blockGain);
    if (action.strengthGain > 0) strength += action.strengthGain;
    if (action.playerDebuff != null) player.applyStatusEffect(action.playerDebuff!);

    _turnIndex++;
  }

  /// 방어도를 먼저 차감한 뒤 나머지를 체력에서 감소시킨다.
  /// Vulnerable 상태이면 rawDamage × 1.5(floor)를 적용한다.
  void takeDamage(int rawDamage) {
    final damage =
        isVulnerable ? (rawDamage * vulnerableMultiplier).floor() : rawDamage;

    final absorbed = block < damage ? block : damage;
    block -= absorbed;
    hp = (hp - (damage - absorbed)).clamp(0, maxHp);
  }

  void gainBlock(int amount) => block += amount;

  /// 동일 타입이 이미 있으면 duration을 누적한다.
  void applyStatusEffect(StatusEffect effect) {
    final idx = statusEffects.indexWhere((e) => e.type == effect.type);
    if (idx >= 0) {
      statusEffects[idx] =
          statusEffects[idx].withDuration(statusEffects[idx].duration + effect.duration);
    } else {
      statusEffects.add(effect);
    }
  }

  /// 턴 종료: 방어도 소멸, 상태 이상 duration 1 감소 후 만료된 것 제거.
  void endTurn() {
    block = 0;
    statusEffects = statusEffects
        .map((e) => e.withDuration(e.duration - 1))
        .where((e) => e.duration > 0)
        .toList();
  }

  // ── Static helpers ────────────────────────────────────────────────────────

  static int _computeMaxHp(MonsterType type, int stage) => switch (type) {
        MonsterType.basic         => 20 + (stage * 10),
        MonsterType.stickySlime   => 44,
        MonsterType.ironScavenger => 40,
        MonsterType.venomSentinel => 80,
        MonsterType.caveGuardian  => 110,
        MonsterType.ironGolem     => 220,
      };

  /// 패턴 종료 후 루프를 시작할 인덱스.
  /// [MonsterType.venomSentinel]: 첫 번째 독기 분출(0) 건너뜀.
  /// [MonsterType.caveGuardian]: 수면 구간(0,1) 건너뜀.
  static int _computeLoopFromIndex(MonsterType type) => switch (type) {
        MonsterType.venomSentinel => 1,
        MonsterType.caveGuardian  => 2,
        _                         => 0,
      };

  static List<MonsterTurnAction> _buildPattern(MonsterType type, int stage) =>
      switch (type) {
        MonsterType.basic => [
          MonsterTurnAction(
            intentType: MonsterIntentType.attack,
            label: '공격',
            attackDamage: 8 + stage * 2,
          ),
        ],
        MonsterType.stickySlime => const [
          MonsterTurnAction(
            intentType: MonsterIntentType.buff,
            label: '분비',
            strengthGain: 3,
          ),
          MonsterTurnAction(
            intentType: MonsterIntentType.attack,
            label: '점착 공격',
            attackDamage: 7,
          ),
          MonsterTurnAction(
            intentType: MonsterIntentType.attack,
            label: '점착 공격',
            attackDamage: 7,
          ),
        ],
        MonsterType.ironScavenger => const [
          MonsterTurnAction(
            intentType: MonsterIntentType.attack,
            label: '물기',
            attackDamage: 11,
          ),
          MonsterTurnAction(
            intentType: MonsterIntentType.buff,
            label: '단련',
            blockGain: 5,
            strengthGain: 2,
          ),
          MonsterTurnAction(
            intentType: MonsterIntentType.attack,
            label: '할퀴기',
            attackDamage: 7,
            blockGain: 3,
          ),
        ],
        MonsterType.venomSentinel => const [
          MonsterTurnAction(
            intentType: MonsterIntentType.attackDebuff,
            label: '독기 분출',
            attackDamage: 5,
            playerDebuff: StatusEffect(type: StatusEffectType.vulnerable, duration: 2),
          ),
          MonsterTurnAction(
            intentType: MonsterIntentType.attackDebuff,
            label: '독침',
            attackDamage: 8,
            playerDebuff: StatusEffect(type: StatusEffectType.vulnerable, duration: 1),
          ),
          MonsterTurnAction(
            intentType: MonsterIntentType.attack,
            label: '강습',
            attackDamage: 16,
          ),
        ],
        MonsterType.caveGuardian => const [
          MonsterTurnAction(
            intentType: MonsterIntentType.sleep,
            label: '수면',
            blockGain: 8,
          ),
          MonsterTurnAction(
            intentType: MonsterIntentType.sleep,
            label: '수면',
            blockGain: 8,
          ),
          MonsterTurnAction(
            intentType: MonsterIntentType.attack,
            label: '강타',
            attackDamage: 18,
          ),
          MonsterTurnAction(
            intentType: MonsterIntentType.attack,
            label: '강타',
            attackDamage: 18,
          ),
          MonsterTurnAction(
            intentType: MonsterIntentType.attackDebuff,
            label: '기력 흡수',
            attackDamage: 10,
            playerDebuff: StatusEffect(type: StatusEffectType.weak, duration: 2),
          ),
        ],
        MonsterType.ironGolem => const [
          MonsterTurnAction(
            intentType: MonsterIntentType.defend,
            label: '장갑 강화',
            blockGain: 18,
          ),
          MonsterTurnAction(
            intentType: MonsterIntentType.attack,
            label: '분쇄 강타',
            attackDamage: 30,
          ),
          MonsterTurnAction(
            intentType: MonsterIntentType.attack,
            label: '연속 타격',
            attackDamage: 6,
            hitCount: 4,
          ),
        ],
      };
}
