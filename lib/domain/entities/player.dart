import '../status_effect.dart';

/// 플레이어 엔티티. 체력·방어도·상태 이상을 관리한다.
///
/// 순수 Dart 클래스 — Flutter·Riverpod 임포트 금지.
class Player {
  static const int maxHp = 70;

  /// SPECS.md: 취약 상태에서 받는 데미지 배율.
  static const double vulnerableMultiplier = 1.5;

  /// SPECS.md: 약화 상태에서 주는 데미지 배율 (floor 적용).
  static const double weakMultiplier = 0.75;

  int hp;
  int block;

  /// 이번 전투 내 모든 데미지 카드의 공격력에 더해지는 힘 수치.
  /// 전투가 끝나면 새 BattleEngine이 생성되므로 자동 초기화된다.
  int strength;

  List<StatusEffect> statusEffects;

  Player({
    this.hp = maxHp,
    this.block = 0,
    this.strength = 0,
    List<StatusEffect>? statusEffects,
  }) : statusEffects = statusEffects ?? [];

  bool get isDead => hp <= 0;

  bool get isVulnerable => statusEffects.any(
        (e) => e.type == StatusEffectType.vulnerable && e.duration > 0,
      );

  bool get isWeak => statusEffects.any(
        (e) => e.type == StatusEffectType.weak && e.duration > 0,
      );

  /// 현재 독 스택 수. 0이면 독 없음.
  int get poisonStacks {
    for (final e in statusEffects) {
      if (e.type == StatusEffectType.poison) return e.duration;
    }
    return 0;
  }

  /// 방어도를 먼저 차감한 뒤 나머지를 체력에서 감소시킨다.
  /// Vulnerable 상태이면 rawDamage × 1.5를 적용한 뒤 처리한다.
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

  void heal(int amount) {
    hp = (hp + amount).clamp(0, maxHp);
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
}
