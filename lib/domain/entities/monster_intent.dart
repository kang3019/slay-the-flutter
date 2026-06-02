/// 몬스터가 다음 턴에 실행할 행동 유형.
///
/// 순수 Dart 클래스 — Flutter·Riverpod 임포트 금지.
enum MonsterIntentType {
  /// 일반 공격 — 정해진 데미지를 플레이어에게 가한다.
  attack,

  /// 강공격 — 일반 공격보다 높은 데미지를 가한다.
  heavyAttack,

  /// 방어 — 자신에게 방어도를 부여한다.
  gainBlock,
}

/// 몬스터의 단일 행동 의도. 타입과 효과 수치를 보유하는 불변 값 객체.
///
/// 순수 Dart 클래스 — Flutter·Riverpod 임포트 금지.
class MonsterIntent {
  /// 행동 유형.
  final MonsterIntentType type;

  /// 효과 수치. 공격 유형은 데미지량, gainBlock은 방어도량.
  final int value;

  const MonsterIntent({required this.type, required this.value});
}
