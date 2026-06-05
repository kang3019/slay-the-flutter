/// 카드가 전투에서 수행하는 효과 분류.
enum CardEffectType { damage, block, buff, heal, draw, blockDraw, strength }

/// SPECS.md 카드 테이블의 각 카드 식별자.
enum CardType {
  strike, bash, swiftCut, defend, ironWall, focus, recover,
  rageBurst, toxicJab, regroup, crushingBlow, fury,
  tripleSlash, quickMend, swiftGuard, exploitWeakness, sharpen,
  weakSlash, blockStrike, bloodRush, devilsDeal,
  battleCry, indomitable, comboStrike, gamble,
}

/// 불변 카드 정의. 비용·효과 분류·수치를 보유한다.
///
/// SwiftCut의 [value]는 타격 1회당 데미지이며 BattleEngine이 2회 적용한다.
/// TripleSlash의 [value]는 타격 1회당 데미지이며 BattleEngine이 3회 적용한다.
/// Focus의 [value](50)는 다음 카드에 적용할 퍼센트 보너스를 나타낸다.
/// SwiftGuard의 [value]는 방어도 수치이며 드로우 수(1)는 엔진에 고정된다.
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

  /// 5 데미지. 사용 후 버리는 더미에 복사본을 추가한다.
  static const rageBurst = GameCard(
    type: CardType.rageBurst,
    name: '광분',
    cost: 0,
    effectType: CardEffectType.damage,
    value: 5,
  );

  /// 5 데미지 + 적에게 취약 2턴 부여.
  static const toxicJab = GameCard(
    type: CardType.toxicJab,
    name: '독침',
    cost: 1,
    effectType: CardEffectType.damage,
    value: 5,
  );

  /// 카드 2장 드로우.
  static const regroup = GameCard(
    type: CardType.regroup,
    name: '결집',
    cost: 1,
    effectType: CardEffectType.draw,
    value: 2,
  );

  /// 20 데미지. 사용 후 소멸(버리는 더미로 가지 않는다).
  static const crushingBlow = GameCard(
    type: CardType.crushingBlow,
    name: '파괴의 일격',
    cost: 2,
    effectType: CardEffectType.damage,
    value: 20,
  );

  /// 이번 전투 힘 +[value]. 데미지 카드의 공격력에 지속 합산된다.
  static const fury = GameCard(
    type: CardType.fury,
    name: '분노',
    cost: 1,
    effectType: CardEffectType.strength,
    value: 2,
  );

  /// 타격당 3 데미지 × 3회. BattleEngine이 value를 세 번 적용한다.
  static const tripleSlash = GameCard(
    type: CardType.tripleSlash,
    name: '세 번 베기',
    cost: 1,
    effectType: CardEffectType.damage,
    value: 3,
  );

  /// HP 5 회복. 사용 후 소멸.
  static const quickMend = GameCard(
    type: CardType.quickMend,
    name: '응급처치',
    cost: 0,
    effectType: CardEffectType.heal,
    value: 5,
  );

  /// 방어도 6 획득 + 카드 1장 드로우. [value]는 방어도 수치.
  static const swiftGuard = GameCard(
    type: CardType.swiftGuard,
    name: '날렵한 방어',
    cost: 1,
    effectType: CardEffectType.blockDraw,
    value: 6,
  );

  /// 9 데미지. 적이 취약 상태이면 6 추가 데미지.
  static const exploitWeakness = GameCard(
    type: CardType.exploitWeakness,
    name: '취약 틈새',
    cost: 1,
    effectType: CardEffectType.damage,
    value: 9,
  );

  /// 이번 턴 공격 카드 전부 +[value] 데미지. Focus처럼 buff 타입이라 Focus의 영향을 받지 않는다.
  static const sharpen = GameCard(
    type: CardType.sharpen,
    name: '무기 연마',
    cost: 0,
    effectType: CardEffectType.buff,
    value: 4,
  );

  /// [value] 데미지 + 적에게 약화 2턴 부여.
  static const weakSlash = GameCard(
    type: CardType.weakSlash,
    name: '약화 강타',
    cost: 2,
    effectType: CardEffectType.damage,
    value: 12,
  );

  /// 현재 플레이어 방어도만큼 데미지. [value]는 사용하지 않으며 엔진이 player.block으로 계산한다.
  static const blockStrike = GameCard(
    type: CardType.blockStrike,
    name: '방어도 공격',
    cost: 1,
    effectType: CardEffectType.damage,
    value: 0,
  );

  /// X 비용(cost == -1). X × [value] 데미지. 플레이 시 남은 에너지 전부를 X로 사용한다.
  static const bloodRush = GameCard(
    type: CardType.bloodRush,
    name: '혈기',
    cost: -1,
    effectType: CardEffectType.damage,
    value: 6,
  );

  /// HP -[value], 카드 3장 드로우.
  static const devilsDeal = GameCard(
    type: CardType.devilsDeal,
    name: '악마의 거래',
    cost: 0,
    effectType: CardEffectType.draw,
    value: 6,
  );

  /// 카드 2장 드로우 + 힘 +1, 소멸.
  static const battleCry = GameCard(
    type: CardType.battleCry,
    name: '전투 함성',
    cost: 1,
    effectType: CardEffectType.draw,
    value: 2,
  );

  /// 방어도 [value] 획득. 힘이 있으면 힘만큼 추가 방어도.
  static const indomitable = GameCard(
    type: CardType.indomitable,
    name: '불굴',
    cost: 0,
    effectType: CardEffectType.block,
    value: 3,
  );

  /// 손패의 공격 카드 수 × [value] 데미지.
  static const comboStrike = GameCard(
    type: CardType.comboStrike,
    name: '연속 강타',
    cost: 1,
    effectType: CardEffectType.damage,
    value: 4,
  );

  /// HP -[value], 에너지 +2.
  static const gamble = GameCard(
    type: CardType.gamble,
    name: '승부수',
    cost: 0,
    effectType: CardEffectType.buff,
    value: 4,
  );
}
