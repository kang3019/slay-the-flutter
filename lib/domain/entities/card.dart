/// 카드가 전투에서 수행하는 효과 분류.
enum CardEffectType { damage, block, buff, heal, draw, blockDraw, strength }

/// SPECS.md 카드 테이블의 각 카드 식별자.
enum CardType {
  strike, bash, swiftCut, defend, ironWall, focus, recover,
  rageBurst, toxicJab, regroup, crushingBlow, fury,
  tripleSlash, quickMend, swiftGuard, exploitWeakness, sharpen,
  weakSlash, blockStrike, bloodRush, devilsDeal,
  battleCry, indomitable, comboStrike, gamble, poisonDart,
}

/// 불변 카드 정의. 비용·효과 분류·수치를 보유한다.
///
/// SwiftCut의 [value]는 타격 1회당 데미지이며 BattleEngine이 2회 적용한다.
/// TripleSlash의 [value]는 타격 1회당 데미지이며 BattleEngine이 3회 적용한다.
/// Focus의 [value](50 또는 75)는 다음 카드에 적용할 퍼센트 보너스를 나타낸다.
/// SwiftGuard의 [value]는 방어도 수치이며 드로우 수(1)는 엔진에 고정된다.
/// [isUpgraded]가 true이면 강화된 카드이며, 이름 뒤에 '+'가 붙는다.
class GameCard {
  final CardType type;
  final String name;
  final int cost;
  final CardEffectType effectType;
  final int value;

  /// 강화 여부. 휴식처에서 강화한 카드에만 true.
  final bool isUpgraded;

  const GameCard({
    required this.type,
    required this.name,
    required this.cost,
    required this.effectType,
    required this.value,
    this.isUpgraded = false,
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

  /// 강타 강화: 9 데미지.
  static const strikeUpgraded = GameCard(
    type: CardType.strike,
    name: '강타+',
    cost: 1,
    effectType: CardEffectType.damage,
    value: 9,
    isUpgraded: true,
  );

  static const bash = GameCard(
    type: CardType.bash,
    name: '맹타',
    cost: 2,
    effectType: CardEffectType.damage,
    value: 8,
  );

  /// 맹타 강화: 11 데미지 + 취약 2턴.
  static const bashUpgraded = GameCard(
    type: CardType.bash,
    name: '맹타+',
    cost: 2,
    effectType: CardEffectType.damage,
    value: 11,
    isUpgraded: true,
  );

  /// 타격당 4 데미지 × 2회. BattleEngine이 value를 두 번 적용한다.
  static const swiftCut = GameCard(
    type: CardType.swiftCut,
    name: '연격',
    cost: 1,
    effectType: CardEffectType.damage,
    value: 4,
  );

  /// 연격 강화: 6×2 데미지.
  static const swiftCutUpgraded = GameCard(
    type: CardType.swiftCut,
    name: '연격+',
    cost: 1,
    effectType: CardEffectType.damage,
    value: 6,
    isUpgraded: true,
  );

  static const defend = GameCard(
    type: CardType.defend,
    name: '방어',
    cost: 1,
    effectType: CardEffectType.block,
    value: 5,
  );

  /// 방어 강화: 방어도 8.
  static const defendUpgraded = GameCard(
    type: CardType.defend,
    name: '방어+',
    cost: 1,
    effectType: CardEffectType.block,
    value: 8,
    isUpgraded: true,
  );

  static const ironWall = GameCard(
    type: CardType.ironWall,
    name: '철벽',
    cost: 2,
    effectType: CardEffectType.block,
    value: 10,
  );

  /// 철벽 강화: 비용 1, 방어도 10.
  static const ironWallUpgraded = GameCard(
    type: CardType.ironWall,
    name: '철벽+',
    cost: 1,
    effectType: CardEffectType.block,
    value: 10,
    isUpgraded: true,
  );

  /// 다음 카드 효과 +50%. [value] = 50 (퍼센트).
  static const focus = GameCard(
    type: CardType.focus,
    name: '집중',
    cost: 0,
    effectType: CardEffectType.buff,
    value: 50,
  );

  /// 집중 강화: 다음 카드 효과 +75%.
  static const focusUpgraded = GameCard(
    type: CardType.focus,
    name: '집중+',
    cost: 0,
    effectType: CardEffectType.buff,
    value: 75,
    isUpgraded: true,
  );

  static const recover = GameCard(
    type: CardType.recover,
    name: '회복',
    cost: 2,
    effectType: CardEffectType.heal,
    value: 8,
  );

  /// 회복 강화: 비용 1, HP +8.
  static const recoverUpgraded = GameCard(
    type: CardType.recover,
    name: '회복+',
    cost: 1,
    effectType: CardEffectType.heal,
    value: 8,
    isUpgraded: true,
  );

  /// 5 데미지. 사용 후 버리는 더미에 복사본을 추가한다.
  static const rageBurst = GameCard(
    type: CardType.rageBurst,
    name: '광분',
    cost: 0,
    effectType: CardEffectType.damage,
    value: 5,
  );

  /// 광분 강화: 8 데미지 + 복사.
  static const rageBurstUpgraded = GameCard(
    type: CardType.rageBurst,
    name: '광분+',
    cost: 0,
    effectType: CardEffectType.damage,
    value: 8,
    isUpgraded: true,
  );

  /// 5 데미지 + 적에게 취약 2턴 부여.
  static const toxicJab = GameCard(
    type: CardType.toxicJab,
    name: '독침',
    cost: 1,
    effectType: CardEffectType.damage,
    value: 5,
  );

  /// 독침 강화: 7 데미지 + 취약 3턴.
  static const toxicJabUpgraded = GameCard(
    type: CardType.toxicJab,
    name: '독침+',
    cost: 1,
    effectType: CardEffectType.damage,
    value: 7,
    isUpgraded: true,
  );

  /// 카드 2장 드로우.
  static const regroup = GameCard(
    type: CardType.regroup,
    name: '결집',
    cost: 1,
    effectType: CardEffectType.draw,
    value: 2,
  );

  /// 결집 강화: 드로우 3.
  static const regroupUpgraded = GameCard(
    type: CardType.regroup,
    name: '결집+',
    cost: 1,
    effectType: CardEffectType.draw,
    value: 3,
    isUpgraded: true,
  );

  /// 20 데미지. 사용 후 소멸(버리는 더미로 가지 않는다).
  static const crushingBlow = GameCard(
    type: CardType.crushingBlow,
    name: '파괴의 일격',
    cost: 2,
    effectType: CardEffectType.damage,
    value: 20,
  );

  /// 파괴의 일격 강화: 25 데미지, 소멸.
  static const crushingBlowUpgraded = GameCard(
    type: CardType.crushingBlow,
    name: '파괴의 일격+',
    cost: 2,
    effectType: CardEffectType.damage,
    value: 25,
    isUpgraded: true,
  );

  /// 이번 전투 힘 +[value]. 데미지 카드의 공격력에 지속 합산된다.
  static const fury = GameCard(
    type: CardType.fury,
    name: '분노',
    cost: 1,
    effectType: CardEffectType.strength,
    value: 2,
  );

  /// 분노 강화: 힘 +3.
  static const furyUpgraded = GameCard(
    type: CardType.fury,
    name: '분노+',
    cost: 1,
    effectType: CardEffectType.strength,
    value: 3,
    isUpgraded: true,
  );

  /// 타격당 3 데미지 × 3회. BattleEngine이 value를 세 번 적용한다.
  static const tripleSlash = GameCard(
    type: CardType.tripleSlash,
    name: '세 번 베기',
    cost: 1,
    effectType: CardEffectType.damage,
    value: 3,
  );

  /// 세 번 베기 강화: 4×3 데미지.
  static const tripleSlashUpgraded = GameCard(
    type: CardType.tripleSlash,
    name: '세 번 베기+',
    cost: 1,
    effectType: CardEffectType.damage,
    value: 4,
    isUpgraded: true,
  );

  /// HP 5 회복. 사용 후 소멸.
  static const quickMend = GameCard(
    type: CardType.quickMend,
    name: '응급처치',
    cost: 0,
    effectType: CardEffectType.heal,
    value: 5,
  );

  /// 응급처치 강화: HP +8, 소멸.
  static const quickMendUpgraded = GameCard(
    type: CardType.quickMend,
    name: '응급처치+',
    cost: 0,
    effectType: CardEffectType.heal,
    value: 8,
    isUpgraded: true,
  );

  /// 방어도 6 획득 + 카드 1장 드로우. [value]는 방어도 수치.
  static const swiftGuard = GameCard(
    type: CardType.swiftGuard,
    name: '날렵한 방어',
    cost: 1,
    effectType: CardEffectType.blockDraw,
    value: 6,
  );

  /// 날렵한 방어 강화: 방어도 9 + 드로우 1.
  static const swiftGuardUpgraded = GameCard(
    type: CardType.swiftGuard,
    name: '날렵한 방어+',
    cost: 1,
    effectType: CardEffectType.blockDraw,
    value: 9,
    isUpgraded: true,
  );

  /// 9 데미지. 적이 취약 상태이면 6 추가 데미지.
  static const exploitWeakness = GameCard(
    type: CardType.exploitWeakness,
    name: '취약 틈새',
    cost: 1,
    effectType: CardEffectType.damage,
    value: 9,
  );

  /// 취약 틈새 강화: 9 데미지. 취약 시 +9 추가 데미지.
  static const exploitWeaknessUpgraded = GameCard(
    type: CardType.exploitWeakness,
    name: '취약 틈새+',
    cost: 1,
    effectType: CardEffectType.damage,
    value: 9,
    isUpgraded: true,
  );

  /// 이번 턴 공격 카드 전부 +[value] 데미지. Focus처럼 buff 타입이라 Focus의 영향을 받지 않는다.
  static const sharpen = GameCard(
    type: CardType.sharpen,
    name: '무기 연마',
    cost: 0,
    effectType: CardEffectType.buff,
    value: 4,
  );

  /// 무기 연마 강화: 공격 +6.
  static const sharpenUpgraded = GameCard(
    type: CardType.sharpen,
    name: '무기 연마+',
    cost: 0,
    effectType: CardEffectType.buff,
    value: 6,
    isUpgraded: true,
  );

  /// [value] 데미지 + 적에게 약화 2턴 부여.
  static const weakSlash = GameCard(
    type: CardType.weakSlash,
    name: '약화 강타',
    cost: 2,
    effectType: CardEffectType.damage,
    value: 12,
  );

  /// 약화 강타 강화: 12 데미지 + 약화 3턴.
  static const weakSlashUpgraded = GameCard(
    type: CardType.weakSlash,
    name: '약화 강타+',
    cost: 2,
    effectType: CardEffectType.damage,
    value: 12,
    isUpgraded: true,
  );

  /// 현재 플레이어 방어도만큼 데미지. [value]는 사용하지 않으며 엔진이 player.block으로 계산한다.
  static const blockStrike = GameCard(
    type: CardType.blockStrike,
    name: '방어도 공격',
    cost: 1,
    effectType: CardEffectType.damage,
    value: 0,
  );

  /// 방어도 공격 강화: 방어도 × 1.5 데미지.
  static const blockStrikeUpgraded = GameCard(
    type: CardType.blockStrike,
    name: '방어도 공격+',
    cost: 1,
    effectType: CardEffectType.damage,
    value: 0,
    isUpgraded: true,
  );

  /// X 비용(cost == -1). X × [value] 데미지. 플레이 시 남은 에너지 전부를 X로 사용한다.
  static const bloodRush = GameCard(
    type: CardType.bloodRush,
    name: '혈기',
    cost: -1,
    effectType: CardEffectType.damage,
    value: 6,
  );

  /// 혈기 강화: X × 8 데미지.
  static const bloodRushUpgraded = GameCard(
    type: CardType.bloodRush,
    name: '혈기+',
    cost: -1,
    effectType: CardEffectType.damage,
    value: 8,
    isUpgraded: true,
  );

  /// HP -[value], 카드 3장 드로우.
  static const devilsDeal = GameCard(
    type: CardType.devilsDeal,
    name: '악마의 거래',
    cost: 0,
    effectType: CardEffectType.draw,
    value: 6,
  );

  /// 악마의 거래 강화: HP -4, 드로우 3.
  static const devilsDealUpgraded = GameCard(
    type: CardType.devilsDeal,
    name: '악마의 거래+',
    cost: 0,
    effectType: CardEffectType.draw,
    value: 4,
    isUpgraded: true,
  );

  /// 카드 2장 드로우 + 힘 +1, 소멸.
  static const battleCry = GameCard(
    type: CardType.battleCry,
    name: '전투 함성',
    cost: 1,
    effectType: CardEffectType.draw,
    value: 2,
  );

  /// 전투 함성 강화: 드로우 2 + 힘 +2, 소멸.
  static const battleCryUpgraded = GameCard(
    type: CardType.battleCry,
    name: '전투 함성+',
    cost: 1,
    effectType: CardEffectType.draw,
    value: 2,
    isUpgraded: true,
  );

  /// 방어도 [value] 획득. 힘이 있으면 힘만큼 추가 방어도.
  static const indomitable = GameCard(
    type: CardType.indomitable,
    name: '불굴',
    cost: 0,
    effectType: CardEffectType.block,
    value: 3,
  );

  /// 불굴 강화: 방어도 5 + 힘.
  static const indomitableUpgraded = GameCard(
    type: CardType.indomitable,
    name: '불굴+',
    cost: 0,
    effectType: CardEffectType.block,
    value: 5,
    isUpgraded: true,
  );

  /// 손패의 공격 카드 수 × [value] 데미지.
  static const comboStrike = GameCard(
    type: CardType.comboStrike,
    name: '연속 강타',
    cost: 1,
    effectType: CardEffectType.damage,
    value: 4,
  );

  /// 연속 강타 강화: 공격패 수 × 5 데미지.
  static const comboStrikeUpgraded = GameCard(
    type: CardType.comboStrike,
    name: '연속 강타+',
    cost: 1,
    effectType: CardEffectType.damage,
    value: 5,
    isUpgraded: true,
  );

  /// HP -[value], 에너지 +2.
  static const gamble = GameCard(
    type: CardType.gamble,
    name: '승부수',
    cost: 0,
    effectType: CardEffectType.buff,
    value: 4,
  );

  /// 승부수 강화: HP -2, 에너지 +2.
  static const gambleUpgraded = GameCard(
    type: CardType.gamble,
    name: '승부수+',
    cost: 0,
    effectType: CardEffectType.buff,
    value: 2,
    isUpgraded: true,
  );

  /// [value] 데미지 + 적에게 독 3스택 부여.
  static const poisonDart = GameCard(
    type: CardType.poisonDart,
    name: '독화살',
    cost: 1,
    effectType: CardEffectType.damage,
    value: 4,
  );

  /// 독화살 강화: 6 데미지 + 독 5스택.
  static const poisonDartUpgraded = GameCard(
    type: CardType.poisonDart,
    name: '독화살+',
    cost: 1,
    effectType: CardEffectType.damage,
    value: 6,
    isUpgraded: true,
  );

  /// [card]의 강화 버전을 반환한다.
  ///
  /// 이미 강화된 카드([isUpgraded] == true)이면 원본을 그대로 반환한다.
  static GameCard upgrade(GameCard card) {
    if (card.isUpgraded) return card;
    return switch (card.type) {
      CardType.strike          => strikeUpgraded,
      CardType.bash            => bashUpgraded,
      CardType.swiftCut        => swiftCutUpgraded,
      CardType.defend          => defendUpgraded,
      CardType.ironWall        => ironWallUpgraded,
      CardType.focus           => focusUpgraded,
      CardType.recover         => recoverUpgraded,
      CardType.rageBurst       => rageBurstUpgraded,
      CardType.toxicJab        => toxicJabUpgraded,
      CardType.regroup         => regroupUpgraded,
      CardType.crushingBlow    => crushingBlowUpgraded,
      CardType.fury            => furyUpgraded,
      CardType.tripleSlash     => tripleSlashUpgraded,
      CardType.quickMend       => quickMendUpgraded,
      CardType.swiftGuard      => swiftGuardUpgraded,
      CardType.exploitWeakness => exploitWeaknessUpgraded,
      CardType.sharpen         => sharpenUpgraded,
      CardType.weakSlash       => weakSlashUpgraded,
      CardType.blockStrike     => blockStrikeUpgraded,
      CardType.bloodRush       => bloodRushUpgraded,
      CardType.devilsDeal      => devilsDealUpgraded,
      CardType.battleCry       => battleCryUpgraded,
      CardType.indomitable     => indomitableUpgraded,
      CardType.comboStrike     => comboStrikeUpgraded,
      CardType.gamble          => gambleUpgraded,
      CardType.poisonDart      => poisonDartUpgraded,
    };
  }
}
