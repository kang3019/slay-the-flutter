import '../status_effect.dart';
import 'monster_intent.dart';

/// 몬스터 엔티티. 스테이지 번호로 스탯이 결정된다.
///
/// 순수 Dart 클래스 — Flutter·Riverpod 임포트 금지.
class Monster {
  /// SPECS.md: 취약 상태에서 받는 데미지 배율.
  static const double vulnerableMultiplier = 1.5;

  /// 강공격 데미지 배율 (attackPower × 1.8, floor).
  static const double heavyAttackMultiplier = 1.8;

  final int stage;
  int hp;
  int block;
  List<StatusEffect> statusEffects;

  final List<MonsterIntent> _pattern;
  int _patternIndex;

  /// SPECS.md 공식: HP = 20 + (stage × 10), 공격력 = 8 + (stage × 2).
  Monster({required this.stage})
      : hp = 20 + (stage * 10),
        block = 0,
        statusEffects = [],
        _pattern = _buildPattern(stage),
        _patternIndex = 0;

  int get maxHp => 20 + (stage * 10);
  int get attackPower => 8 + (stage * 2);

  bool get isDead => hp <= 0;

  bool get isVulnerable => statusEffects.any(
        (e) => e.type == StatusEffectType.vulnerable && e.duration > 0,
      );

  bool get isWeak => statusEffects.any(
        (e) => e.type == StatusEffectType.weak && e.duration > 0,
      );

  /// 다음 턴에 실행할 행동 의도. UI에서 플레이어에게 예고를 표시하는 데 사용된다.
  MonsterIntent get currentIntent => _pattern[_patternIndex];

  /// 행동 패턴의 다음 인덱스로 이동한다. 끝에 도달하면 처음으로 순환한다.
  void advanceIntent() {
    _patternIndex = (_patternIndex + 1) % _pattern.length;
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

  void gainBlock(int amount) {
    block += amount;
  }

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

  /// 스테이지별 행동 패턴을 생성한다. 패턴은 끝에 도달하면 처음부터 순환된다.
  ///
  /// - Stage 1: attack → attack → gainBlock
  /// - Stage 2: attack → heavyAttack → gainBlock
  /// - Stage 3+: heavyAttack → attack → gainBlock → attack
  static List<MonsterIntent> _buildPattern(int stage) {
    final atk = 8 + stage * 2;
    final heavy = (atk * heavyAttackMultiplier).floor();
    final def = 5 + stage * 3;

    return switch (stage) {
      1 => [
          MonsterIntent(type: MonsterIntentType.attack, value: atk),
          MonsterIntent(type: MonsterIntentType.attack, value: atk),
          MonsterIntent(type: MonsterIntentType.gainBlock, value: def),
        ],
      2 => [
          MonsterIntent(type: MonsterIntentType.attack, value: atk),
          MonsterIntent(type: MonsterIntentType.heavyAttack, value: heavy),
          MonsterIntent(type: MonsterIntentType.gainBlock, value: def),
        ],
      _ => [
          MonsterIntent(type: MonsterIntentType.heavyAttack, value: heavy),
          MonsterIntent(type: MonsterIntentType.attack, value: atk),
          MonsterIntent(type: MonsterIntentType.gainBlock, value: def),
          MonsterIntent(type: MonsterIntentType.attack, value: atk),
        ],
    };
  }
}
