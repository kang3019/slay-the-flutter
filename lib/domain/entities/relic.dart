/// 유물이 전투에서 발동하는 효과 종류.
/// 각 값은 발동 시점과 적용 내용을 함께 의미한다.
enum RelicEffect {
  /// 전투 시작 시 플레이어 방어도 +value.
  blockOnCombatStart,

  /// 전투 시작 시 플레이어 HP +value 회복.
  healOnCombatStart,

  /// 전투 시작 시 카드 +value 장 추가 드로우.
  extraDrawOnCombatStart,

  /// 전투 시작 시 적에게 취약(Vulnerable) value턴 부여.
  vulnerableEnemyOnCombatStart,

  /// 전투 시작 시 적에게 약화(Weak) value턴 부여.
  weakEnemyOnCombatStart,

  /// 첫 번째 턴에만 에너지 +value.
  extraEnergyOnFirstTurn,

  /// 턴 종료 시 방어도가 0이면 방어도 +value.
  blockIfNoneOnTurnEnd,

  /// 보스 전투(stage 3) 시작 시 HP +value 회복.
  healOnBossCombatStart,

  /// 전투 중 사망 시 HP를 value로 되살린다 (1회).
  nearDeathSave,

  /// 매 전투 첫 번째 공격 카드에 +value 데미지.
  firstAttackBonus,

  /// 매 전투 두 번째 공격 카드에 +value 데미지.
  secondAttackBonus,

  /// 매 플레이어 턴 시작 시 HP +value 회복.
  healOnTurnStart,

  /// 플레이어 턴 종료 시 남은 에너지 1당 방어도 +value.
  blockPerRemainingEnergy,

  /// 매 전투 첫 번째 블록 카드에 +value 방어도 추가.
  firstBlockBonus,

  /// 전투 시작 시 방어도 +value, 카드 1장 추가 드로우.
  blockAndExtraDrawOnCombatStart,

  /// 전투 시작 시 적에게 취약 value턴 + 약화 value턴 동시 부여.
  vulnerableAndWeakOnCombatStart,

  /// 전투 시작 시 플레이어 힘 +value.
  strengthOnCombatStart,

  /// 보스 전투(stage 3) 시작 시 플레이어 힘 +value.
  strengthOnBossCombatStart,

  /// 전투 시작 시 HP가 최대 HP의 50% 이하면 에너지 +value.
  extraEnergyOnLowHP,

  /// 전투 시작 시 집중 카드를 손패에 value장 추가한다.
  addFocusCardOnCombatStart,
}

/// 런 내내 패시브 효과를 제공하는 유물.
///
/// 불변 데이터 클래스 — 모든 필드가 final.
class Relic {
  final String id;
  final String name;
  final String description;
  final RelicEffect effect;

  /// 효과에 적용되는 수치. 의미는 [RelicEffect] 값에 따라 결정된다.
  final int value;

  const Relic({
    required this.id,
    required this.name,
    required this.description,
    required this.effect,
    required this.value,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Relic && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// 게임에 등록된 모든 유물 목록.
class GameRelics {
  GameRelics._();

  /// 전투 시작 시 방어도 +6.
  static const shieldAmulet = Relic(
    id: 'shield_amulet',
    name: '방패 부적',
    description: '전투 시작 시 방어도 6 획득.',
    effect: RelicEffect.blockOnCombatStart,
    value: 6,
  );

  /// 전투 시작 시 HP +2 회복.
  static const bloodVial = Relic(
    id: 'blood_vial',
    name: '피의 유리병',
    description: '전투 시작 시 HP 2 회복.',
    effect: RelicEffect.healOnCombatStart,
    value: 2,
  );

  /// 전투 시작 시 카드 1장 추가 드로우.
  static const preparationPouch = Relic(
    id: 'preparation_pouch',
    name: '준비의 낭',
    description: '전투 시작 시 카드 1장을 추가로 드로우한다.',
    effect: RelicEffect.extraDrawOnCombatStart,
    value: 1,
  );

  /// 전투 시작 시 적에게 취약(1턴) 부여.
  static const toxicMarble = Relic(
    id: 'toxic_marble',
    name: '독 구슬',
    description: '전투 시작 시 적에게 취약 1턴을 부여한다.',
    effect: RelicEffect.vulnerableEnemyOnCombatStart,
    value: 1,
  );

  /// 전투 시작 시 적에게 약화(1턴) 부여.
  static const weaknessPoison = Relic(
    id: 'weakness_poison',
    name: '약화 독약',
    description: '전투 시작 시 적에게 약화 1턴을 부여한다.',
    effect: RelicEffect.weakEnemyOnCombatStart,
    value: 1,
  );

  /// 첫 번째 턴에만 에너지 +1.
  static const lantern = Relic(
    id: 'lantern',
    name: '등불',
    description: '매 전투 첫 번째 턴에 에너지 1을 추가로 얻는다.',
    effect: RelicEffect.extraEnergyOnFirstTurn,
    value: 1,
  );

  /// 턴 종료 시 방어도 0이면 방어도 +4.
  static const goldenShield = Relic(
    id: 'golden_shield',
    name: '황금 방패',
    description: '턴 종료 시 방어도가 0이면 방어도 4를 획득한다.',
    effect: RelicEffect.blockIfNoneOnTurnEnd,
    value: 4,
  );

  /// 보스 전투 시작 시 HP +15.
  static const bossCloak = Relic(
    id: 'boss_cloak',
    name: '보스의 망토',
    description: '보스 전투 시작 시 HP 15를 회복한다.',
    effect: RelicEffect.healOnBossCombatStart,
    value: 15,
  );

  /// 사망 시 HP 1로 생존 (1회).
  static const lizardTail = Relic(
    id: 'lizard_tail',
    name: '도마뱀 꼬리',
    description: '전투 중 처음 사망할 때 HP 1로 되살아난다.',
    effect: RelicEffect.nearDeathSave,
    value: 1,
  );

  /// 첫 번째 공격 카드 데미지 +4.
  static const warAxe = Relic(
    id: 'war_axe',
    name: '첫 타격의 도끼',
    description: '매 전투 첫 번째 공격 카드가 4 추가 데미지를 준다.',
    effect: RelicEffect.firstAttackBonus,
    value: 4,
  );

  /// 두 번째 공격 카드 데미지 +5.
  static const warriorsCrest = Relic(
    id: 'warriors_crest',
    name: '전사의 낙인',
    description: '매 전투 두 번째 공격 카드가 5 추가 데미지를 준다.',
    effect: RelicEffect.secondAttackBonus,
    value: 5,
  );

  /// 매 플레이어 턴 시작 시 HP +1 회복.
  static const regenTattoo = Relic(
    id: 'regen_tattoo',
    name: '재생의 문신',
    description: '매 플레이어 턴 시작 시 HP 1을 회복한다.',
    effect: RelicEffect.healOnTurnStart,
    value: 1,
  );

  /// 턴 종료 시 남은 에너지 1당 방어도 +2.
  static const frostCrystal = Relic(
    id: 'frost_crystal',
    name: '냉각 보석',
    description: '턴 종료 시 남은 에너지 1당 방어도 2를 획득한다.',
    effect: RelicEffect.blockPerRemainingEnergy,
    value: 2,
  );

  /// 첫 번째 블록 카드에 +5 방어도.
  static const bloodstainedGloves = Relic(
    id: 'bloodstained_gloves',
    name: '피 묻은 장갑',
    description: '매 전투 첫 번째 블록 카드가 5 추가 방어도를 제공한다.',
    effect: RelicEffect.firstBlockBonus,
    value: 5,
  );

  /// 전투 시작 시 방어도 3 + 카드 1장 추가 드로우.
  static const guardianBangle = Relic(
    id: 'guardian_bangle',
    name: '수호의 팔찌',
    description: '전투 시작 시 방어도 3을 획득하고 카드 1장을 추가로 드로우한다.',
    effect: RelicEffect.blockAndExtraDrawOnCombatStart,
    value: 3,
  );

  /// 전투 시작 시 적에게 취약 2턴 + 약화 2턴 동시 부여.
  static const venomBolt = Relic(
    id: 'venom_bolt',
    name: '독화살촉',
    description: '전투 시작 시 적에게 취약 2턴과 약화 2턴을 부여한다.',
    effect: RelicEffect.vulnerableAndWeakOnCombatStart,
    value: 2,
  );

  /// 전투 시작 시 힘 +1.
  static const rageSeal = Relic(
    id: 'rage_seal',
    name: '분노의 인장',
    description: '매 전투 시작 시 힘 1을 획득한다.',
    effect: RelicEffect.strengthOnCombatStart,
    value: 1,
  );

  /// 보스 전투 시작 시 힘 +2.
  static const fightersBand = Relic(
    id: 'fighters_band',
    name: '격투사의 띠',
    description: '보스 전투 시작 시 힘 2를 획득한다.',
    effect: RelicEffect.strengthOnBossCombatStart,
    value: 2,
  );

  /// 전투 시작 시 HP가 최대 HP의 50% 이하면 에너지 +1.
  static const crisisTalisman = Relic(
    id: 'crisis_talisman',
    name: '위기의 부적',
    description: '전투 시작 시 HP가 최대치의 50% 이하이면 에너지 1을 추가로 얻는다.',
    effect: RelicEffect.extraEnergyOnLowHP,
    value: 1,
  );

  /// 전투 시작 시 집중 카드 1장을 손패에 추가.
  static const focusLens = Relic(
    id: 'focus_lens',
    name: '집중의 렌즈',
    description: '전투 시작 시 집중 카드 1장이 손패에 추가된다.',
    effect: RelicEffect.addFocusCardOnCombatStart,
    value: 1,
  );

  static const List<Relic> all = [
    shieldAmulet,
    bloodVial,
    preparationPouch,
    toxicMarble,
    weaknessPoison,
    lantern,
    goldenShield,
    bossCloak,
    lizardTail,
    warAxe,
    warriorsCrest,
    regenTattoo,
    frostCrystal,
    bloodstainedGloves,
    guardianBangle,
    venomBolt,
    rageSeal,
    fightersBand,
    crisisTalisman,
    focusLens,
  ];
}
