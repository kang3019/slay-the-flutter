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

  final EventEffect effect;

  const EventChoice({
    required this.label,
    required this.effectDescription,
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
        effect: EventEffect(hpDelta: 15),
      ),
      EventChoice(
        label: '그냥 지나친다',
        effectDescription: '골드 +10 (팔아서 챙긴다)',
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
        effectDescription: 'HP +10 회복',
        effect: EventEffect(hpDelta: 10),
      ),
      EventChoice(
        label: '소지품을 뒤진다',
        effectDescription: '골드 +25',
        effect: EventEffect(goldDelta: 25),
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
        effect: EventEffect(hpDelta: -8, addRandomCard: true),
      ),
      EventChoice(
        label: '거절한다',
        effectDescription: '아무 일도 없다',
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
        effect: EventEffect(goldDelta: 20),
      ),
      EventChoice(
        label: '세게 부순다',
        effectDescription: '골드 +45, HP -12 (부서진 파편에 맞는다)',
        effect: EventEffect(goldDelta: 45, hpDelta: -12),
      ),
    ],
  );

  static const List<GameEvent> all = [
    mysteriousPotion,
    fallenAdventurer,
    devilsDeal,
    abandonedSafe,
  ];

  /// [all] 풀에서 무작위 이벤트 하나를 반환한다.
  static GameEvent random([Random? rng]) {
    final r = rng ?? Random();
    return all[r.nextInt(all.length)];
  }
}
