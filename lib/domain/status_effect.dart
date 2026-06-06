/// 전투 중 유닛에게 적용되는 상태 이상의 종류.
enum StatusEffectType { vulnerable, weak, poison }

/// 남은 지속 턴을 가진 단일 상태 이상.
class StatusEffect {
  final StatusEffectType type;
  final int duration;

  const StatusEffect({required this.type, required this.duration});

  StatusEffect withDuration(int newDuration) =>
      StatusEffect(type: type, duration: newDuration);
}
