import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/card.dart';
import '../domain/entities/player.dart';
import '../domain/entities/relic.dart';
import '../domain/events/game_event.dart';
import '../domain/map/map_generator.dart';
import '../domain/map/map_node.dart';
import '../domain/map/node_type.dart';
import 'meta_progress_provider.dart';

// ──────────────────────────────────────────────────────────────────────────
// RunPhase — 런 진행 단계
// ──────────────────────────────────────────────────────────────────────────

/// 현재 런이 어느 화면에 있는지를 나타내는 단계 값.
///
/// [AppRouter]가 이 값을 감시해 [MapScreen]·[BattleScreen]·[RewardScreen]을 교체한다.
enum RunPhase {
  /// 지도 화면 — 다음 노드를 선택하는 단계.
  map,

  /// 전투 화면 — 몬스터·엘리트·보스와 전투 중인 단계.
  battle,

  /// 보상 선택 화면 — 전투 승리 후 카드 3장 중 1장을 덱에 추가하는 단계.
  reward,

  /// 이벤트 화면 — 텍스트 이벤트 선택지를 고르는 단계.
  event,

  /// 유물 보관소 화면 — 유물 1개를 획득하거나 건너뛰는 단계.
  treasure,

  /// 휴식처 화면 — HP 회복 또는 카드 강화를 선택하는 단계.
  rest,

  /// 상점 화면 — 골드로 카드 구매·제거·유물 구매를 하는 단계.
  shop,

  /// 런 종료 화면 — 보스 처치 또는 플레이어 사망 후 결과를 보여주는 단계.
  runEnd,
}

// ──────────────────────────────────────────────────────────────────────────
// RunState — 런 전체 상태 스냅샷
// ──────────────────────────────────────────────────────────────────────────

/// 런(한 번의 게임 시도) 전체 상태 스냅샷.
///
/// 전투 사이 맵 화면에서 보존되며, 런 종료 또는 새 런 시작 시 초기화된다.
/// 불변 값 타입 — 상태 변경은 항상 [copyWith]로 새 인스턴스를 반환한다.
class RunState {
  /// 현재 런의 진행 단계. [AppRouter]가 표시할 화면을 결정한다.
  final RunPhase phase;

  /// 현재 층(floor). -1 = 아직 시작하지 않음(맵에서 시작 노드 선택 전).
  final int floor;

  /// 현재 런의 플레이어 HP. 전투 결과가 반영된 값이 유지된다.
  final int playerHp;

  /// 현재 런에서 보유한 골드.
  final int gold;

  /// 현재 런의 덱 카드 목록. 보상으로 카드를 추가·제거하면 갱신된다.
  final List<GameCard> deck;

  /// Act 1 맵의 전체 노드 목록.
  final List<MapNode> mapNodes;

  /// 현재 위치한 노드 ID.
  /// null = 맵에서 시작 노드를 아직 선택하지 않은 상태.
  final String? currentNodeId;

  /// 이번 런에서 방문한 노드 ID 목록.
  final List<String> visitedNodeIds;

  /// 런이 끝났으면 true. 보스 처치 또는 플레이어 사망 시 true가 된다.
  final bool isRunOver;

  /// 보상 화면에서 제시할 카드 3장. [RunPhase.reward]일 때만 채워지며,
  /// 다른 단계에서는 빈 리스트.
  final List<GameCard> rewardCards;

  /// 현재 런에서 보유 중인 유물 목록.
  final List<Relic> relics;

  /// 현재 진행 중인 이벤트. [RunPhase.event]일 때만 non-null이며,
  /// 선택지를 고르면 null로 초기화된다.
  final GameEvent? currentEvent;

  /// 유물 보관소에서 제시할 유물. [RunPhase.treasure]일 때만 non-null이며,
  /// 획득하거나 건너뛰면 null로 초기화된다.
  final Relic? currentTreasureRelic;

  /// 상점에서 판매 중인 카드 목록. [RunPhase.shop]일 때만 채워진다.
  final List<GameCard> shopCards;

  /// 상점 카드 가격 목록. [shopCards]와 1:1 대응.
  final List<int> shopCardPrices;

  /// 상점 카드 구매 여부. [shopCards]와 1:1 대응.
  final List<bool> shopCardSold;

  /// 상점에서 판매 중인 유물 목록. [RunPhase.shop]일 때만 채워진다.
  final List<Relic> shopRelics;

  /// 상점 유물 가격 목록. [shopRelics]와 1:1 대응.
  final List<int> shopRelicPrices;

  /// 상점 유물 구매 여부. [shopRelics]와 1:1 대응.
  final List<bool> shopRelicSold;

  /// 이번 상점 방문에서 카드 제거 서비스를 이미 사용했으면 true.
  final bool shopCardRemovalDone;

  /// 보상 화면에서 아직 획득하지 않은 골드. [RunPhase.reward]일 때만 0보다 크다.
  final int pendingGoldReward;

  /// 보상 화면에서 [pendingGoldReward]를 클릭해 획득했으면 true.
  final bool goldClaimed;

  /// 이번 런에서 누적 획득한 XP. [RunEndScreen]에 표시된다.
  final int xpGainedThisRun;

  /// 이번 런 동안 레벨업으로 신규 해금된 카드 타입명 목록 (중복 없음).
  /// [RunEndScreen]에 표시된다.
  final List<String> newlyUnlockedCardsThisRun;

  const RunState({
    required this.phase,
    required this.floor,
    required this.playerHp,
    required this.gold,
    required this.deck,
    required this.mapNodes,
    required this.currentNodeId,
    required this.visitedNodeIds,
    required this.isRunOver,
    required this.rewardCards,
    this.relics = const [],
    this.currentEvent,
    this.currentTreasureRelic,
    this.shopCards = const [],
    this.shopCardPrices = const [],
    this.shopCardSold = const [],
    this.shopRelics = const [],
    this.shopRelicPrices = const [],
    this.shopRelicSold = const [],
    this.shopCardRemovalDone = false,
    this.pendingGoldReward = 0,
    this.goldClaimed = false,
    this.xpGainedThisRun = 0,
    this.newlyUnlockedCardsThisRun = const [],
  });

  // ── 직렬화 ────────────────────────────────────────────────────────────

  /// 세이브 슬롯 저장을 위한 JSON 직렬화.
  Map<String, dynamic> toJson() => {
    'phase': phase.name,
    'floor': floor,
    'playerHp': playerHp,
    'gold': gold,
    'deck': deck.map(_cardToJson).toList(),
    'mapNodes': mapNodes.map(_nodeToJson).toList(),
    'currentNodeId': currentNodeId,
    'visitedNodeIds': visitedNodeIds,
    'isRunOver': isRunOver,
    'rewardCards': rewardCards.map(_cardToJson).toList(),
    'relics': relics.map((r) => r.id).toList(),
    'currentEvent': currentEvent?.id,
    'currentTreasureRelic': currentTreasureRelic?.id,
    'shopCards': shopCards.map(_cardToJson).toList(),
    'shopCardPrices': shopCardPrices,
    'shopCardSold': shopCardSold,
    'shopRelics': shopRelics.map((r) => r.id).toList(),
    'shopRelicPrices': shopRelicPrices,
    'shopRelicSold': shopRelicSold,
    'shopCardRemovalDone': shopCardRemovalDone,
    'pendingGoldReward': pendingGoldReward,
    'goldClaimed': goldClaimed,
    'xpGainedThisRun': xpGainedThisRun,
    'newlyUnlockedCardsThisRun': newlyUnlockedCardsThisRun,
  };

  static Map<String, dynamic> _cardToJson(GameCard c) => {
    'type': c.type.name,
    'isUpgraded': c.isUpgraded,
  };

  static Map<String, dynamic> _nodeToJson(MapNode n) => {
    'id': n.id,
    'type': n.type.name,
    'floor': n.floor,
    'connectedNodeIds': n.connectedNodeIds,
  };

  /// 세이브 슬롯 로드를 위한 JSON 역직렬화.
  static RunState fromJson(Map<String, dynamic> json) {
    GameCard cardFromJson(Map<String, dynamic> j) {
      final type       = CardType.values.byName(j['type'] as String);
      final isUpgraded = j['isUpgraded'] as bool? ?? false;
      final base       = _cardForType(type);
      return isUpgraded ? Cards.upgrade(base) : base;
    }

    MapNode nodeFromJson(Map<String, dynamic> j) => MapNode(
      id: j['id'] as String,
      type: NodeType.values.byName(j['type'] as String),
      floor: j['floor'] as int,
      connectedNodeIds: List<String>.from(j['connectedNodeIds'] as List),
    );

    final relicIds = List<String>.from(json['relics'] as List? ?? []);
    final relics   = relicIds
        .map((id) {
          try { return GameRelics.all.firstWhere((r) => r.id == id); }
          catch (_) { return null; }
        })
        .whereType<Relic>()
        .toList();

    final eventId = json['currentEvent'] as String?;
    GameEvent? event;
    if (eventId != null) {
      try { event = GameEvents.all.firstWhere((e) => e.id == eventId); }
      catch (_) {}
    }

    final treasureId = json['currentTreasureRelic'] as String?;
    Relic? treasure;
    if (treasureId != null) {
      try { treasure = GameRelics.all.firstWhere((r) => r.id == treasureId); }
      catch (_) {}
    }

    final rawDeck      = (json['deck']        as List?)?.cast<Map<String, dynamic>>() ?? [];
    final rawNodes     = (json['mapNodes']    as List?)?.cast<Map<String, dynamic>>() ?? [];
    final rawReward    = (json['rewardCards'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final rawShopCards = (json['shopCards']   as List?)?.cast<Map<String, dynamic>>() ?? [];
    final shopCardPrices  = (json['shopCardPrices'] as List?)?.map((e) => e as int).toList()  ?? const <int>[];
    final shopCardSold    = (json['shopCardSold']   as List?)?.map((e) => e as bool).toList() ?? const <bool>[];
    final shopRelicIds    = List<String>.from(json['shopRelics'] as List? ?? []);
    final shopRelics      = shopRelicIds.map((id) {
          try { return GameRelics.all.firstWhere((r) => r.id == id); }
          catch (_) { return null; }
        }).whereType<Relic>().toList();
    final shopRelicPrices = (json['shopRelicPrices'] as List?)?.map((e) => e as int).toList()  ?? const <int>[];
    final shopRelicSold   = (json['shopRelicSold']   as List?)?.map((e) => e as bool).toList() ?? const <bool>[];

    return RunState(
      phase:              RunPhase.values.byName(json['phase'] as String? ?? 'map'),
      floor:              json['floor']    as int? ?? -1,
      playerHp:           json['playerHp'] as int? ?? Player.maxHp,
      gold:               json['gold']     as int? ?? 0,
      deck:               rawDeck.map(cardFromJson).toList(),
      mapNodes:           rawNodes.map(nodeFromJson).toList(),
      currentNodeId:      json['currentNodeId'] as String?,
      visitedNodeIds:     List<String>.from(json['visitedNodeIds'] as List? ?? []),
      isRunOver:          json['isRunOver'] as bool? ?? false,
      rewardCards:        rawReward.map(cardFromJson).toList(),
      relics:             relics,
      currentEvent:       event,
      currentTreasureRelic: treasure,
      shopCards:          rawShopCards.map(cardFromJson).toList(),
      shopCardPrices:     shopCardPrices,
      shopCardSold:       shopCardSold,
      shopRelics:         shopRelics,
      shopRelicPrices:    shopRelicPrices,
      shopRelicSold:      shopRelicSold,
      shopCardRemovalDone: json['shopCardRemovalDone'] as bool? ?? false,
      pendingGoldReward:  json['pendingGoldReward'] as int? ?? 0,
      goldClaimed:        json['goldClaimed'] as bool? ?? false,
      xpGainedThisRun:    json['xpGainedThisRun'] as int? ?? 0,
      newlyUnlockedCardsThisRun:
          List<String>.from(json['newlyUnlockedCardsThisRun'] as List? ?? []),
    );
  }

  /// 세이브 슬롯 저장 시 JSON 문자열로 인코딩한다.
  String toJsonString() => jsonEncode(toJson());

  /// JSON 문자열에서 [RunState]를 복원한다.
  static RunState fromJsonString(String s) =>
      fromJson(jsonDecode(s) as Map<String, dynamic>);

  static GameCard _cardForType(CardType type) => switch (type) {
    CardType.strike          => Cards.strike,
    CardType.bash            => Cards.bash,
    CardType.swiftCut        => Cards.swiftCut,
    CardType.defend          => Cards.defend,
    CardType.ironWall        => Cards.ironWall,
    CardType.focus           => Cards.focus,
    CardType.recover         => Cards.recover,
    CardType.rageBurst       => Cards.rageBurst,
    CardType.toxicJab        => Cards.toxicJab,
    CardType.regroup         => Cards.regroup,
    CardType.crushingBlow    => Cards.crushingBlow,
    CardType.fury            => Cards.fury,
    CardType.tripleSlash     => Cards.tripleSlash,
    CardType.quickMend       => Cards.quickMend,
    CardType.swiftGuard      => Cards.swiftGuard,
    CardType.exploitWeakness => Cards.exploitWeakness,
    CardType.sharpen         => Cards.sharpen,
    CardType.weakSlash       => Cards.weakSlash,
    CardType.blockStrike     => Cards.blockStrike,
    CardType.bloodRush       => Cards.bloodRush,
    CardType.devilsDeal      => Cards.devilsDeal,
    CardType.battleCry       => Cards.battleCry,
    CardType.indomitable     => Cards.indomitable,
    CardType.comboStrike     => Cards.comboStrike,
    CardType.gamble          => Cards.gamble,
    CardType.poisonDart      => Cards.poisonDart,
    CardType.limitBreak      => Cards.limitBreak,
    CardType.impervious      => Cards.impervious,
    CardType.doubleTap       => Cards.doubleTap,
    CardType.fiendFire       => Cards.fiendFire,
  };

  // ── 파생 값 (getter) ───────────────────────────────────────────────────

  /// 현재 floor를 BattleEngine 스테이지로 변환한다.
  ///
  /// SPECS.md 스테이지 공식 매핑 (5층 맵 기준):
  /// - Floor 0·1 → 스테이지 1 (일반 구역)
  /// - Floor 2·3 → 스테이지 2 (심층 구역)
  /// - Floor 4+  → 스테이지 3 (보스 구역)
  int get currentStage => switch (floor) {
        0 || 1 => 1,
        2 || 3 => 2,
        _      => 3,
      };

  /// 현재 위치한 [MapNode]. 미시작([currentNodeId]가 null)이면 null.
  MapNode? get currentNode {
    if (currentNodeId == null) return null;
    try {
      return mapNodes.firstWhere((n) => n.id == currentNodeId);
    } catch (_) {
      return null;
    }
  }

  // ── copyWith ──────────────────────────────────────────────────────────

  /// 변경할 필드만 교체한 새 [RunState]를 반환한다.
  ///
  /// [currentNodeId]를 null로 되돌려야 할 경우에는
  /// [RunNotifier.startNewRun]처럼 [RunState]를 통째로 교체한다.
  static const _kClearEvent = Object();
  static const _kClearTreasure = Object();

  RunState copyWith({
    RunPhase? phase,
    int? floor,
    int? playerHp,
    int? gold,
    List<GameCard>? deck,
    List<MapNode>? mapNodes,
    String? currentNodeId,
    List<String>? visitedNodeIds,
    bool? isRunOver,
    List<GameCard>? rewardCards,
    List<Relic>? relics,
    // GameEvent?를 null로 되돌리려면 currentEvent: null을 전달한다.
    Object? currentEvent = _kClearEvent,
    // Relic?을 null로 되돌리려면 currentTreasureRelic: null을 전달한다.
    Object? currentTreasureRelic = _kClearTreasure,
    List<GameCard>? shopCards,
    List<int>? shopCardPrices,
    List<bool>? shopCardSold,
    List<Relic>? shopRelics,
    List<int>? shopRelicPrices,
    List<bool>? shopRelicSold,
    bool? shopCardRemovalDone,
    int? pendingGoldReward,
    bool? goldClaimed,
    int? xpGainedThisRun,
    List<String>? newlyUnlockedCardsThisRun,
  }) =>
      RunState(
        phase: phase ?? this.phase,
        floor: floor ?? this.floor,
        playerHp: playerHp ?? this.playerHp,
        gold: gold ?? this.gold,
        deck: deck ?? this.deck,
        mapNodes: mapNodes ?? this.mapNodes,
        currentNodeId: currentNodeId ?? this.currentNodeId,
        visitedNodeIds: visitedNodeIds ?? this.visitedNodeIds,
        isRunOver: isRunOver ?? this.isRunOver,
        rewardCards: rewardCards ?? this.rewardCards,
        relics: relics ?? this.relics,
        currentEvent: identical(currentEvent, _kClearEvent)
            ? this.currentEvent
            : currentEvent as GameEvent?,
        currentTreasureRelic: identical(currentTreasureRelic, _kClearTreasure)
            ? this.currentTreasureRelic
            : currentTreasureRelic as Relic?,
        shopCards:           shopCards           ?? this.shopCards,
        shopCardPrices:      shopCardPrices      ?? this.shopCardPrices,
        shopCardSold:        shopCardSold        ?? this.shopCardSold,
        shopRelics:          shopRelics          ?? this.shopRelics,
        shopRelicPrices:     shopRelicPrices     ?? this.shopRelicPrices,
        shopRelicSold:       shopRelicSold       ?? this.shopRelicSold,
        shopCardRemovalDone: shopCardRemovalDone ?? this.shopCardRemovalDone,
        pendingGoldReward:   pendingGoldReward   ?? this.pendingGoldReward,
        goldClaimed:         goldClaimed         ?? this.goldClaimed,
        xpGainedThisRun:     xpGainedThisRun     ?? this.xpGainedThisRun,
        newlyUnlockedCardsThisRun:
            newlyUnlockedCardsThisRun ?? this.newlyUnlockedCardsThisRun,
      );
}

// ──────────────────────────────────────────────────────────────────────────
// Provider
// ──────────────────────────────────────────────────────────────────────────

/// Act 1 맵 노드 목록 Provider.
///
/// 테스트에서 overrideWith()로 고정 맵을 주입할 수 있다.
/// 프로덕션에서는 [MapGenerator.generateAct1]로 절차적 생성된 맵을 반환한다.
final mapNodesProvider = Provider<List<MapNode>>((ref) {
  return MapGenerator.generateAct1();
});

/// 런 상태 Provider.
final runProvider = NotifierProvider<RunNotifier, RunState>(RunNotifier.new);

// ──────────────────────────────────────────────────────────────────────────
// RunNotifier
// ──────────────────────────────────────────────────────────────────────────

/// 맵 이동·플레이어 영구 상태(HP·골드·덱)·런 단계([RunPhase])를 소유하는
/// Application 계층 Notifier.
///
/// **화면 전환 흐름:**
/// ```
/// moveToNode(combatNode) → phase = RunPhase.battle
///   AppRouter 감지 → BattleScreen 표시 + BattleNotifier 새 전투 시작
///
/// startReward(...)      → phase = RunPhase.reward
///   AppRouter 감지 → RewardScreen 표시 (카드 3장 선택)
///
/// selectRewardCard(...) → phase = RunPhase.map
/// skipReward()          → phase = RunPhase.map
///
/// exitBattleToMap(...)  → phase = RunPhase.map (보스 승리 전용)
/// ```
///
/// [BuildContext]를 절대 받지 않는다. UI 이벤트는 순수한 값 인자로만 전달받는다.
class RunNotifier extends Notifier<RunState> {
  /// 기본 덱: 강타(Strike) 5장 + 방어(Defend) 5장. SPECS.md §2 참조.
  static const int _defaultStrikeCount = 5;
  static const int _defaultDefendCount = 5;

  /// 전투·이벤트 보상으로 제시 가능한 전체 카드 목록 (기본 덱 카드 제외).
  /// 실제 보상 풀은 [_unlockedRewardPool]에서 MetaProgress 해금 목록으로 필터링된다.
  static const List<GameCard> _allRewardCards = [
    Cards.bash,
    Cards.swiftCut,
    Cards.ironWall,
    Cards.focus,
    Cards.recover,
    Cards.rageBurst,
    Cards.toxicJab,
    Cards.regroup,
    Cards.crushingBlow,
    Cards.fury,
    Cards.tripleSlash,
    Cards.quickMend,
    Cards.swiftGuard,
    Cards.exploitWeakness,
    Cards.sharpen,
    Cards.weakSlash,
    Cards.blockStrike,
    Cards.bloodRush,
    Cards.devilsDeal,
    Cards.battleCry,
    Cards.indomitable,
    Cards.comboStrike,
    Cards.gamble,
    Cards.poisonDart,
  ];

  /// MetaProgress에서 해금된 카드만 필터링한 보상 풀을 반환한다.
  List<GameCard> _unlockedRewardPool() {
    final unlocked = ref.read(metaProgressProvider).unlockedCardTypes.toSet();
    return _allRewardCards.where((c) => unlocked.contains(c.type.name)).toList();
  }

  final _random = Random();

  @override
  RunState build() => _initialState();

  RunState _initialState() => RunState(
        phase: RunPhase.map,
        floor: -1,
        playerHp: Player.maxHp,
        gold: 75,
        deck: [
          ...List.generate(_defaultStrikeCount, (_) => Cards.strike),
          ...List.generate(_defaultDefendCount, (_) => Cards.defend),
        ],
        mapNodes: ref.read(mapNodesProvider),
        currentNodeId: null,
        visitedNodeIds: const [],
        isRunOver: false,
        rewardCards: const [],
      );

  // ── 맵 이동 ────────────────────────────────────────────────────────────

  /// 지정 [nodeId]로 이동한다.
  ///
  /// 이동 조건:
  /// - 런이 종료되지 않았어야 한다.
  /// - 첫 이동: [nodeId]는 floor 0 노드이어야 한다.
  /// - 이후 이동: [nodeId]는 현재 노드의 [MapNode.connectedNodeIds]에 포함되어야 한다.
  ///
  /// 조건을 만족하지 않으면 상태 변경 없이 반환한다.
  ///
  /// 이동에 성공하면 노드 유형에 따라 [RunPhase]를 자동으로 결정한다:
  /// - 전투 노드(Monster·Elite·Boss) → [RunPhase.battle]
  /// - 비전투 노드(Rest·Shop·Treasure·Event) → [RunPhase.map] 유지
  void moveToNode(String nodeId) {
    if (state.isRunOver) return;

    final target = _findNode(nodeId);
    if (target == null) return;

    if (state.currentNodeId == null) {
      // 첫 이동: 반드시 floor 0 노드이어야 한다.
      if (target.floor != 0) return;
    } else {
      // 이후 이동: 현재 노드와 연결된 노드이어야 한다.
      final current = _findNode(state.currentNodeId!);
      if (current == null) return;
      if (!current.connectedNodeIds.contains(nodeId)) return;
    }

    final nextPhase = _phaseFor(target.type);
    final nextEvent = target.type == NodeType.event
        ? GameEvents.random(_random)
        : null;
    final nextTreasure = target.type == NodeType.treasure
        ? _pickTreasureRelic()
        : null;

    List<GameCard>? shopCards;
    List<int>? shopCardPrices;
    List<bool>? shopCardSold;
    List<Relic>? shopRelics;
    List<int>? shopRelicPrices;
    List<bool>? shopRelicSold;
    if (target.type == NodeType.shop) {
      final inv   = _generateShopInventory();
      shopCards      = inv.cards;
      shopCardPrices = inv.cardPrices;
      shopCardSold   = List.unmodifiable(List.filled(inv.cards.length, false));
      shopRelics      = inv.relics;
      shopRelicPrices = inv.relicPrices;
      shopRelicSold   = List.unmodifiable(List.filled(inv.relics.length, false));
    }

    state = state.copyWith(
      floor: target.floor,
      currentNodeId: nodeId,
      visitedNodeIds: List.unmodifiable([...state.visitedNodeIds, nodeId]),
      phase: nextPhase,
      currentEvent: nextEvent,
      currentTreasureRelic: nextTreasure,
      shopCards:          shopCards      ?? const [],
      shopCardPrices:     shopCardPrices ?? const [],
      shopCardSold:       shopCardSold   ?? const [],
      shopRelics:          shopRelics      ?? const [],
      shopRelicPrices:     shopRelicPrices ?? const [],
      shopRelicSold:       shopRelicSold   ?? const [],
      shopCardRemovalDone: false,
    );
  }

  // ── 보상 선택 ─────────────────────────────────────────────────────────

  /// 일반 전투 승리 후 보상 화면으로 전환한다.
  ///
  /// [remainingHp]: 전투 후 남은 플레이어 HP.
  /// [goldEarned]: 이번 전투에서 획득한 골드. 보상 화면에서 클릭해 획득하기 전까지는
  /// [RunState.pendingGoldReward]에 보류되며 [RunState.gold]에는 반영되지 않는다.
  /// 전풀에서 무작위로 고른 카드 3장이 [RunState.rewardCards]에 담긴다.
  void startReward({required int remainingHp, required int goldEarned}) {
    final clampedHp = remainingHp.clamp(0, Player.maxHp);
    state = state.copyWith(
      phase: RunPhase.reward,
      playerHp: clampedHp,
      pendingGoldReward: goldEarned,
      goldClaimed: false,
      rewardCards: _generateRewardCards(),
    );
  }

  /// 보상 화면에서 보류 중인 골드([RunState.pendingGoldReward])를 획득한다.
  ///
  /// [RunPhase.reward]가 아니거나 이미 획득했으면 아무것도 하지 않는다(중복 지급 방지).
  void claimGoldReward() {
    if (state.phase != RunPhase.reward) return;
    if (state.goldClaimed) return;
    state = state.copyWith(
      gold: state.gold + state.pendingGoldReward,
      goldClaimed: true,
    );
  }

  /// 보상 화면에서 카드를 선택한다.
  ///
  /// 선택한 [card]를 덱에 추가하고 맵 화면으로 돌아간다.
  /// 보류 중인 골드를 아직 획득하지 않았다면 자동으로 합산하여 잃지 않도록 한다.
  void selectRewardCard(GameCard card) {
    if (state.phase != RunPhase.reward) return;
    final unclaimedGold = state.goldClaimed ? 0 : state.pendingGoldReward;
    state = state.copyWith(
      phase: RunPhase.map,
      gold: state.gold + unclaimedGold,
      deck: List.unmodifiable([...state.deck, card]),
      rewardCards: const [],
      pendingGoldReward: 0,
      goldClaimed: false,
    );
  }

  /// 보상을 건너뛰고 맵 화면으로 돌아간다.
  ///
  /// 보류 중인 골드를 아직 획득하지 않았다면 자동으로 합산하여 잃지 않도록 한다.
  void skipReward() {
    if (state.phase != RunPhase.reward) return;
    final unclaimedGold = state.goldClaimed ? 0 : state.pendingGoldReward;
    state = state.copyWith(
      phase: RunPhase.map,
      gold: state.gold + unclaimedGold,
      rewardCards: const [],
      pendingGoldReward: 0,
      goldClaimed: false,
    );
  }

  // ── 전투 결과 반영 ─────────────────────────────────────────────────────

  /// 전투 승리 후 결과를 반영하고 **맵 화면으로 돌아간다**.
  ///
  /// 보스 노드에서 승리 시 또는 패배 시 사용한다.
  /// 일반 전투 승리에는 [startReward]를 사용한다.
  ///
  /// [remainingHp]: 전투 후 남은 플레이어 HP.
  /// [goldEarned]: 이번 전투에서 획득한 골드.
  void exitBattleToMap({required int remainingHp, required int goldEarned}) {
    final clampedHp = remainingHp.clamp(0, Player.maxHp);
    final isBossCleared = state.currentNode?.type == NodeType.boss;

    state = state.copyWith(
      phase: RunPhase.map,
      playerHp: clampedHp,
      gold: state.gold + goldEarned,
      isRunOver: isBossCleared,
      rewardCards: const [],
    );
  }

  /// 전투 결과를 런 상태에 반영한다 (단계 전환 없음).
  ///
  /// 기존 테스트 호환용. 화면 전환이 필요한 경우 [exitBattleToMap]을 사용한다.
  void applyBattleResult({required int remainingHp, required int goldEarned}) {
    final clampedHp = remainingHp.clamp(0, Player.maxHp);
    final isDead = clampedHp <= 0;
    final isBossVictory =
        !isDead && (state.currentNode?.type == NodeType.boss);

    state = state.copyWith(
      playerHp: clampedHp,
      gold: state.gold + goldEarned,
      isRunOver: isDead || isBossVictory,
    );
  }

  // ── 덱 관리 ────────────────────────────────────────────────────────────

  // ── 유물 관리 ────────────────────────────────────────────────────────────

  // ── 휴식처 ────────────────────────────────────────────────────────────

  /// 최대 HP의 30%를 회복하고 맵으로 돌아간다.
  void rest() {
    if (state.phase != RunPhase.rest) return;
    final heal = (Player.maxHp * 0.3).floor();
    final newHp = (state.playerHp + heal).clamp(0, Player.maxHp);
    state = state.copyWith(phase: RunPhase.map, playerHp: newHp);
  }

  /// 휴식처를 건너뛰고 맵으로 돌아간다.
  void skipRest() {
    if (state.phase != RunPhase.rest) return;
    state = state.copyWith(phase: RunPhase.map);
  }

  // ── 유물 관리 ────────────────────────────────────────────────────────────

  /// 유물을 런 보유 목록에 추가한다.
  ///
  /// 같은 [Relic.id]가 이미 있으면 중복 추가하지 않는다.
  void addRelic(Relic relic) {
    if (state.relics.any((r) => r.id == relic.id)) return;
    state = state.copyWith(
      relics: List.unmodifiable([...state.relics, relic]),
    );
  }

  /// 보상 카드를 덱에 추가한다.
  void addCardToDeck(GameCard card) {
    state = state.copyWith(deck: List.unmodifiable([...state.deck, card]));
  }

  /// 덱에서 [card]를 제거한다.
  ///
  /// 동일한 카드가 여러 장이면 첫 번째만 제거된다.
  /// 덱에 없으면 상태 변경 없이 반환한다.
  void removeCardFromDeck(GameCard card) {
    final idx = state.deck.indexOf(card);
    if (idx < 0) return;
    final newDeck = List<GameCard>.of(state.deck)..removeAt(idx);
    state = state.copyWith(deck: List.unmodifiable(newDeck));
  }

  /// 덱에서 [card]를 강화 버전으로 교체하고 맵으로 돌아간다.
  ///
  /// 이미 강화된 카드이거나 덱에 없으면 상태 변경 없이 반환한다.
  void upgradeCard(GameCard card) {
    if (state.phase != RunPhase.rest) return;
    if (card.isUpgraded) return;
    final idx = state.deck.indexOf(card);
    if (idx < 0) return;
    final newDeck = List<GameCard>.of(state.deck)
      ..[idx] = Cards.upgrade(card);
    state = state.copyWith(
      phase: RunPhase.map,
      deck: List.unmodifiable(newDeck),
    );
  }

  // ── XP 누적 ────────────────────────────────────────────────────────────

  /// 전투 종료 시 획득한 [xp]와 신규 해금 카드를 이번 런 누적치에 더한다.
  ///
  /// [RunEndScreen]에서 [RunState.xpGainedThisRun]·
  /// [RunState.newlyUnlockedCardsThisRun]으로 표시된다.
  /// [newlyUnlockedCards]는 기존 누적 목록과 중복 없이 병합된다.
  void recordXpGain({required int xp, List<String> newlyUnlockedCards = const []}) {
    state = state.copyWith(
      xpGainedThisRun: state.xpGainedThisRun + xp,
      newlyUnlockedCardsThisRun: List.unmodifiable({
        ...state.newlyUnlockedCardsThisRun,
        ...newlyUnlockedCards,
      }),
    );
  }

  // ── 런 종료 ────────────────────────────────────────────────────────────

  /// 보스 처치 또는 플레이어 사망 후 [RunPhase.runEnd]로 전환한다.
  ///
  /// [RunEndScreen]에서 결과를 표시하고 "새 런 시작"으로 [startNewRun]을 호출한다.
  void endRun({required int remainingHp, required int goldEarned}) {
    state = state.copyWith(
      phase: RunPhase.runEnd,
      playerHp: remainingHp.clamp(0, Player.maxHp),
      gold: state.gold + goldEarned,
      isRunOver: true,
      rewardCards: const [],
    );
  }

  /// 상점 화면을 닫고 맵으로 돌아간다.
  void exitShop() {
    if (state.phase != RunPhase.shop) return;
    state = state.copyWith(
      phase: RunPhase.map,
      shopCards: const [],
      shopCardPrices: const [],
      shopCardSold: const [],
      shopRelics: const [],
      shopRelicPrices: const [],
      shopRelicSold: const [],
      shopCardRemovalDone: false,
    );
  }

  /// 상점에서 [index]번 카드를 구매한다.
  ///
  /// 골드 부족 또는 이미 구매한 경우 무시한다.
  void buyShopCard(int index) {
    if (state.phase != RunPhase.shop) return;
    if (index < 0 || index >= state.shopCards.length) return;
    if (state.shopCardSold[index]) return;
    final price = state.shopCardPrices[index];
    if (state.gold < price) return;
    final newSold = List<bool>.of(state.shopCardSold)..[index] = true;
    state = state.copyWith(
      gold: state.gold - price,
      deck: List.unmodifiable([...state.deck, state.shopCards[index]]),
      shopCardSold: List.unmodifiable(newSold),
    );
  }

  /// 상점에서 [index]번 유물을 구매한다.
  ///
  /// 골드 부족 또는 이미 구매한 경우 무시한다.
  void buyShopRelic(int index) {
    if (state.phase != RunPhase.shop) return;
    if (index < 0 || index >= state.shopRelics.length) return;
    if (state.shopRelicSold[index]) return;
    final price = state.shopRelicPrices[index];
    if (state.gold < price) return;
    final relic = state.shopRelics[index];
    if (state.relics.any((r) => r.id == relic.id)) return;
    final newSold = List<bool>.of(state.shopRelicSold)..[index] = true;
    state = state.copyWith(
      gold: state.gold - price,
      relics: List.unmodifiable([...state.relics, relic]),
      shopRelicSold: List.unmodifiable(newSold),
    );
  }

  /// 카드 제거 서비스 비용 (고정 30G).
  static const int shopRemovalCost = 30;

  /// 상점 카드 제거 서비스로 [card]를 덱에서 제거하고 골드를 소비한다.
  ///
  /// 이번 방문에서 이미 사용했거나 골드가 부족하면 무시한다.
  void removeCardInShop(GameCard card) {
    if (state.phase != RunPhase.shop) return;
    if (state.shopCardRemovalDone) return;
    if (state.gold < shopRemovalCost) return;
    final idx = state.deck.indexOf(card);
    if (idx < 0) return;
    final newDeck = List<GameCard>.of(state.deck)..removeAt(idx);
    state = state.copyWith(
      gold: state.gold - shopRemovalCost,
      deck: List.unmodifiable(newDeck),
      shopCardRemovalDone: true,
    );
  }

  // ── 런 리셋 ────────────────────────────────────────────────────────────

  /// 현재 런을 종료하고 초기 상태(새 런)로 리셋한다.
  void startNewRun() {
    state = _initialState();
  }

  /// 세이브 슬롯에서 로드된 [savedState]를 현재 런으로 복원한다.
  void restoreFromSaveSlot(RunState savedState) {
    state = savedState;
  }

  // ── 내부 헬퍼 ──────────────────────────────────────────────────────────

  // ── 이벤트 처리 ────────────────────────────────────────────────────────

  /// 이벤트 선택지를 확정하고 효과를 적용한 뒤 맵 화면으로 돌아간다.
  ///
  /// [choice]의 [EventEffect]를 순서대로 적용한다:
  /// 1. HP 변화 (clamp: 1 ~ [Player.maxHp])
  /// 2. 골드 변화 (clamp: 0 이상)
  /// 3. 카드 추가 ([EventEffect.addRandomCard]가 true면 보상 풀에서 1장)
  /// 이벤트 카드 보상 미리보기용으로 해금 풀에서 카드 1장을 뽑아 반환한다.
  /// 해금된 카드가 없으면 null을 반환한다.
  GameCard? pickPreviewCard() {
    final pool = _unlockedRewardPool();
    if (pool.isEmpty) return null;
    final shuffled = List.of(pool)..shuffle(_random);
    return shuffled.first;
  }

  /// [prePickedCard]가 있으면 해당 카드를 덱에 추가한다.
  /// 없으면 해금 풀에서 새로 뽑는다. 풀이 비어 있으면 카드 추가를 건너뛴다.
  void resolveEvent(EventChoice choice, {GameCard? prePickedCard}) {
    if (state.phase != RunPhase.event) return;

    final effect = choice.effect;
    final newHp = (state.playerHp + effect.hpDelta).clamp(1, Player.maxHp);
    final newGold = (state.gold + effect.goldDelta).clamp(0, 99999);

    var newDeck = state.deck;
    if (effect.addRandomCard) {
      final card = prePickedCard ?? pickPreviewCard();
      if (card != null) {
        newDeck = List.unmodifiable([...state.deck, card]);
      }
    }

    state = state.copyWith(
      phase: RunPhase.map,
      playerHp: newHp,
      gold: newGold,
      deck: newDeck,
      currentEvent: null,
    );
  }

  /// 유물 보관소에서 제시할 유물을 결정한다.
  /// 아직 보유하지 않은 유물 중 무작위로 1개를 고른다.
  Relic _pickTreasureRelic() {
    final owned = state.relics.map((r) => r.id).toSet();
    final available = GameRelics.all.where((r) => !owned.contains(r.id)).toList();
    if (available.isEmpty) return GameRelics.all[_random.nextInt(GameRelics.all.length)];
    return available[_random.nextInt(available.length)];
  }

  /// 상점 입장 시 판매 카드 3장과 유물 2개를 무작위로 결정한다.
  ({
    List<GameCard> cards,
    List<int> cardPrices,
    List<Relic> relics,
    List<int> relicPrices,
  }) _generateShopInventory() {
    final pool     = _unlockedRewardPool();
    final shuffled = List.of(pool)..shuffle(_random);
    final cards      = shuffled.take(3).toList();
    final cardPrices = List.generate(cards.length, (_) => 30 + _random.nextInt(16));

    final owned     = state.relics.map((r) => r.id).toSet();
    final available = GameRelics.all.where((r) => !owned.contains(r.id)).toList()
      ..shuffle(_random);
    final relics      = available.take(2).toList();
    final relicPrices = List.generate(relics.length, (_) => 80 + _random.nextInt(31));

    return (
      cards:       List.unmodifiable(cards),
      cardPrices:  List.unmodifiable(cardPrices),
      relics:      List.unmodifiable(relics),
      relicPrices: List.unmodifiable(relicPrices),
    );
  }

  /// 유물 보관소에서 유물을 획득하고 맵으로 돌아간다.
  void takeTreasure() {
    if (state.phase != RunPhase.treasure) return;
    final relic = state.currentTreasureRelic;
    if (relic == null) return;
    state = state.copyWith(
      phase: RunPhase.map,
      relics: List.unmodifiable([...state.relics, relic]),
      currentTreasureRelic: null,
    );
  }

  /// 유물 보관소를 건너뛰고 맵으로 돌아간다.
  void skipTreasure() {
    if (state.phase != RunPhase.treasure) return;
    state = state.copyWith(
      phase: RunPhase.map,
      currentTreasureRelic: null,
    );
  }

  /// 노드 유형에 따라 전환할 [RunPhase]를 결정한다.
  RunPhase _phaseFor(NodeType type) => switch (type) {
        NodeType.monster || NodeType.elite || NodeType.boss => RunPhase.battle,
        NodeType.event    => RunPhase.event,
        NodeType.treasure => RunPhase.treasure,
        NodeType.rest     => RunPhase.rest,
        NodeType.shop     => RunPhase.shop,
      };

  MapNode? _findNode(String nodeId) {
    try {
      return state.mapNodes.firstWhere((n) => n.id == nodeId);
    } catch (_) {
      return null;
    }
  }

  /// 해금된 카드 중 무작위로 최대 3장을 뽑는다. 해금 카드가 없으면 빈 리스트를 반환한다.
  List<GameCard> _generateRewardCards() {
    final pool = _unlockedRewardPool();
    if (pool.isEmpty) return const [];
    final shuffled = List.of(pool)..shuffle(_random);
    return List.unmodifiable(shuffled.take(3).toList());
  }
}
