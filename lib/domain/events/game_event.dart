import 'dart:math';

/// 이벤트 선택지를 골랐을 때 플레이어에게 적용되는 효과.
class EventEffect {
  /// HP 변화량. 양수 = 회복, 음수 = 피해.
  final int hpDelta;

  /// 골드 변화량. 양수 = 획득, 음수 = 손실.
  final int goldDelta;

  /// true면 보상 풀에서 무작위 카드 1장을 덱에 추가한다.
  final bool addRandomCard;

  const EventEffect({
    this.hpDelta = 0,
    this.goldDelta = 0,
    this.addRandomCard = false,
  });
}

/// 이벤트에서 플레이어가 고를 수 있는 선택지 하나.
class EventChoice {
  /// 버튼에 표시되는 짧은 행동 이름.
  final String label;

  /// 선택 시 발생하는 효과를 사람이 읽을 수 있는 형태로 설명.
  final String effectDescription;

  /// 선택 후 결과 화면에 표시되는 서사 묘사.
  final String resultDescription;

  final EventEffect effect;

  const EventChoice({
    required this.label,
    required this.effectDescription,
    required this.resultDescription,
    required this.effect,
  });
}

/// 이벤트 노드(❓)에서 발생하는 텍스트 이벤트.
///
/// 각 이벤트는 배경 설명과 2개의 선택지를 가진다.
/// 선택지마다 이득 또는 손해가 있어 플레이어의 판단이 요구된다.
class GameEvent {
  final String id;
  final String title;
  final String description;
  final List<EventChoice> choices;

  const GameEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.choices,
  });
}

/// 게임에 등록된 모든 이벤트 목록.
///
/// [GameEvents.random]으로 런타임에 무작위 이벤트를 뽑는다.
class GameEvents {
  GameEvents._();

  static const mysteriousPotion = GameEvent(
    id: 'mysterious_potion',
    title: '신비로운 약',
    description: '바닥에 알 수 없는 색의 포션이 떨어져 있다.\n마셔도 괜찮을까?',
    choices: [
      EventChoice(
        label: '마신다',
        effectDescription: 'HP +15 회복',
        resultDescription: '쓴 맛이 나는가 싶더니, 온몸에 따뜻한 기운이 퍼진다.',
        effect: EventEffect(hpDelta: 15),
      ),
      EventChoice(
        label: '집어서 판다',
        effectDescription: '골드 +10 (팔아서 챙긴다)',
        resultDescription: '지나가던 상인에게 팔아넘겼다. 잘 된 거래였기를 바란다.',
        effect: EventEffect(goldDelta: 10),
      ),
    ],
  );

  static const fallenAdventurer = GameEvent(
    id: 'fallen_adventurer',
    title: '쓰러진 모험가',
    description: '피투성이의 모험가가 쓰러져 있다.\n아직 숨이 붙어 있는 것 같다.',
    choices: [
      EventChoice(
        label: '치료해준다',
        effectDescription: '골드 +15 (모험가의 감사 표시)',
        resultDescription: '모험가가 천천히 눈을 뜨며 감사의 뜻으로 주머니를 내민다.',
        effect: EventEffect(goldDelta: 15),
      ),
      EventChoice(
        label: '소지품을 뒤진다',
        effectDescription: '카드 1장 획득',
        resultDescription: '가방 속에서 낡은 기술서 한 권을 발견했다. 모험가는 눈치채지 못했다.',
        effect: EventEffect(addRandomCard: true),
      ),
    ],
  );

  static const devilsDeal = GameEvent(
    id: 'devils_deal',
    title: '악마의 계약',
    description: '어둠 속에서 목소리가 들린다.\n"카드 한 장을 주겠다. 대신 피를 조금 내놓아라."',
    choices: [
      EventChoice(
        label: '계약을 수락한다',
        effectDescription: '카드 1장 획득, HP -8',
        resultDescription: '손바닥을 베는 순간, 어둠 속에서 카드 한 장이 천천히 떠오른다.',
        effect: EventEffect(hpDelta: -8, addRandomCard: true),
      ),
      EventChoice(
        label: '거절한다',
        effectDescription: '아무 일도 없다',
        resultDescription: '목소리는 조용해졌다. 그것이 화가 났는지는 알 수 없다.',
        effect: EventEffect(),
      ),
    ],
  );

  static const abandonedSafe = GameEvent(
    id: 'abandoned_safe',
    title: '버려진 금고',
    description: '먼지 쌓인 금고가 보인다.\n자물쇠가 걸려 있지만 낡아 보인다.',
    choices: [
      EventChoice(
        label: '조심스럽게 연다',
        effectDescription: '골드 +20',
        resultDescription: '녹슨 자물쇠가 풀리며 금화 몇 닢이 쏟아진다.',
        effect: EventEffect(goldDelta: 20),
      ),
      EventChoice(
        label: '세게 부순다',
        effectDescription: '골드 +45, HP -12 (부서진 파편에 맞는다)',
        resultDescription: '금고가 박살나며 금화가 사방으로 튀었다. 파편이 살갗을 긁는다.',
        effect: EventEffect(goldDelta: 45, hpDelta: -12),
      ),
    ],
  );

  static const ancientAltar = GameEvent(
    id: 'ancient_altar',
    title: '고대 제단',
    description: '오래된 제단 앞에 녹슨 동전들이 쌓여 있다.\n누군가의 기도가 남아 있는 것 같다.',
    choices: [
      EventChoice(
        label: '헌금을 챙긴다',
        effectDescription: '골드 +12',
        resultDescription: '동전들을 슬쩍 주머니에 넣었다. 등 뒤가 괜히 서늘하다.',
        effect: EventEffect(goldDelta: 12),
      ),
      EventChoice(
        label: '피를 바친다',
        effectDescription: 'HP -7, 카드 1장 획득',
        resultDescription: '손에서 흘러내린 피가 제단에 스며들더니, 빛나는 무언가가 천천히 떠오른다.',
        effect: EventEffect(hpDelta: -7, addRandomCard: true),
      ),
    ],
  );

  static const lostMerchant = GameEvent(
    id: 'lost_merchant',
    title: '길 잃은 상인',
    description: '짐을 잔뜩 진 상인이 갈림길에서 헤매고 있다.\n목적지를 찾지 못해 발을 동동 구르는 중이다.',
    choices: [
      EventChoice(
        label: '길을 안내해준다',
        effectDescription: '골드 +20 (상인의 사례금)',
        resultDescription: '상인은 고마운 표정으로 사례금을 건네며 서둘러 길을 떠난다.',
        effect: EventEffect(goldDelta: 20),
      ),
      EventChoice(
        label: '짐을 빼앗는다',
        effectDescription: '카드 1장 획득, HP -8 (상인이 저항한다)',
        resultDescription: '저항하는 상인과 실랑이 끝에 짐 꾸러미 하나를 빼앗았다. 긁힌 자국이 쓰리다.',
        effect: EventEffect(addRandomCard: true, hpDelta: -8),
      ),
    ],
  );

  static const ancientWell = GameEvent(
    id: 'ancient_well',
    title: '오래된 우물',
    description: '이끼 낀 돌 우물에서 맑은 물소리가 들린다.\n소원을 들어준다는 전설이 전해지는 곳이다.',
    choices: [
      EventChoice(
        label: '물을 마신다',
        effectDescription: 'HP +12',
        resultDescription: '차갑고 맑은 물이 목을 타고 내려간다. 기운이 조금 되살아난다.',
        effect: EventEffect(hpDelta: 12),
      ),
      EventChoice(
        label: '동전을 던지며 소원을 빈다',
        effectDescription: '골드 -15, HP +25',
        resultDescription: '동전이 물속으로 가라앉는 순간, 온몸을 감싸는 따스한 빛이 느껴진다.',
        effect: EventEffect(goldDelta: -15, hpDelta: 25),
      ),
    ],
  );

  static const cursedTreasure = GameEvent(
    id: 'cursed_treasure',
    title: '저주받은 보물',
    description: '화려한 보물 상자가 덩그러니 놓여 있다.\n주변 공기가 묘하게 차갑고, 불길한 기운이 감돈다.',
    choices: [
      EventChoice(
        label: '손에 넣는다',
        effectDescription: '골드 +35, 카드 1장 획득, HP -15 (저주에 감염된다)',
        resultDescription: '상자를 여는 순간 차가운 기운이 몸속으로 파고든다. 그래도... 값진 물건들이다.',
        effect: EventEffect(goldDelta: 35, addRandomCard: true, hpDelta: -15),
      ),
      EventChoice(
        label: '그냥 지나친다',
        effectDescription: '아무 일도 없다',
        resultDescription: '불길한 기운을 뒤로하고 발걸음을 옮긴다. 현명한 선택이었을 것이다.',
        effect: EventEffect(),
      ),
    ],
  );

  static const suspiciousLetter = GameEvent(
    id: 'suspicious_letter',
    title: '수상한 편지',
    description: '바닥에 봉인된 편지 한 통이 떨어져 있다.\n수신인 이름이 적혀 있지만 알 수 없는 인물이다.',
    choices: [
      EventChoice(
        label: '편지를 뜯어 읽는다',
        effectDescription: '카드 1장 획득 (비법이 적혀 있었다)',
        resultDescription: '편지에는 낯선 언어로 빼곡히 적힌 전투 비법이 담겨 있었다.',
        effect: EventEffect(addRandomCard: true),
      ),
      EventChoice(
        label: '심부름꾼에게 전달한다',
        effectDescription: '골드 +15 (수신인이 보상을 건넨다)',
        resultDescription: '수신인은 편지를 받아 들고 안도하며 감사의 골드를 쥐여준다.',
        effect: EventEffect(goldDelta: 15),
      ),
    ],
  );

  static const collapsingBridge = GameEvent(
    id: 'collapsing_bridge',
    title: '무너지는 다리',
    description: '낡은 다리가 금방이라도 무너질 것 같다.\n건너편으로 가는 방법을 골라야 한다.',
    choices: [
      EventChoice(
        label: '통행료를 내고 뱃사공을 부른다',
        effectDescription: '골드 -10, HP +10 (배 위에서 잠시 쉰다)',
        resultDescription: '낡은 배 위에서 잠시 눈을 붙였다. 강바람이 쌓인 피로를 씻어준다.',
        effect: EventEffect(goldDelta: -10, hpDelta: 10),
      ),
      EventChoice(
        label: '위험을 무릅쓰고 뛰어간다',
        effectDescription: 'HP -10, 카드 1장 획득 (건너편에서 뭔가를 줍는다)',
        resultDescription: '다리가 삐걱거리며 무너지는 와중에 겨우 건넜다. 건너편 바닥에서 뭔가를 주웠다.',
        effect: EventEffect(hpDelta: -10, addRandomCard: true),
      ),
    ],
  );

  static const List<GameEvent> all = [
    mysteriousPotion,
    fallenAdventurer,
    devilsDeal,
    abandonedSafe,
    ancientAltar,
    lostMerchant,
    ancientWell,
    cursedTreasure,
    suspiciousLetter,
    collapsingBridge,
  ];

  /// [all] 풀에서 무작위 이벤트 하나를 반환한다.
  static GameEvent random([Random? rng]) {
    final r = rng ?? Random();
    return all[r.nextInt(all.length)];
  }
}
