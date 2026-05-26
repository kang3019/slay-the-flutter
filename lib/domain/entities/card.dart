/// 카드가 전투에서 수행하는 효과 분류.
enum CardEffectType { damage, block, buff, heal }

/// SPECS.md 카드 테이블의 각 카드 식별자.
enum CardType { strike, bash, swiftCut, defend, ironWall, focus, recover }

/// 불변 카드 정의. 비용·효과 분류·수치를 보유한다.
///
/// SwiftCut의 [value]는 타격 1회당 데미지이며 BattleEngine이 2회 적용한다.
/// Focus의 [value](50)는 다음 카드에 적용할 퍼센트 보너스를 나타낸다.
class GameCard {
  final CardType type;
  final String name;
  final int cost;
  final CardEffectType effectType;
  final int value;

  const GameCard({
    required this.type,
    required this.name,
    required this.cost,
    required this.effectType,
    required this.value,
  });
}

/// SPECS.md에 정의된 카드 인스턴스 모음.
class Cards {
  Cards._();

  static const strike = GameCard(
    type: CardType.strike,
    name: '강타',
    cost: 1,
    effectType: CardEffectType.damage,
    value: 6,
  );

  static const bash = GameCard(
    type: CardType.bash,
    name: '맹타',
    cost: 2,
    effectType: CardEffectType.damage,
    value: 8,
  );

  /// 타격당 4 데미지 × 2회. BattleEngine이 value를 두 번 적용한다.
  static const swiftCut = GameCard(
    type: CardType.swiftCut,
    name: '연격',
    cost: 1,
    effectType: CardEffectType.damage,
    value: 4,
  );

  static const defend = GameCard(
    type: CardType.defend,
    name: '방어',
    cost: 1,
    effectType: CardEffectType.block,
    value: 5,
  );

  static const ironWall = GameCard(
    type: CardType.ironWall,
    name: '철벽',
    cost: 2,
    effectType: CardEffectType.block,
    value: 10,
  );

  /// 다음 카드 효과 +50%. [value] = 50 (퍼센트).
  static const focus = GameCard(
    type: CardType.focus,
    name: '집중',
    cost: 0,
    effectType: CardEffectType.buff,
    value: 50,
  );

  static const recover = GameCard(
    type: CardType.recover,
    name: '회복',
    cost: 2,
    effectType: CardEffectType.heal,
    value: 8,
  );
}
