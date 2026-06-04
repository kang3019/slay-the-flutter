import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/card.dart';
import '../domain/entities/player.dart';
import '../domain/entities/relic.dart';
import '../domain/events/game_event.dart';
import '../domain/map/map_generator.dart';
import '../domain/map/map_node.dart';
import '../domain/map/node_type.dart';

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
  });

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
      );
}

// ──────────────────────────────────────────────────────────────────────────
// Provider
// ──────────────────────────────────────────────────────────────────────────

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

  /// 전투 보상으로 제시할 수 있는 카드 풀 (기본 덱 카드 제외).
  static const List<GameCard> _rewardPool = [
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
  ];

  final _random = Random();

  @override
  RunState build() => _initialState();

  RunState _initialState() => RunState(
        phase: RunPhase.map,
        floor: -1,
        playerHp: Player.maxHp,
        gold: 0,
        deck: [
          ...List.generate(_defaultStrikeCount, (_) => Cards.strike),
          ...List.generate(_defaultDefendCount, (_) => Cards.defend),
        ],
        mapNodes: MapGenerator.generateAct1(),
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

    state = state.copyWith(
      floor: target.floor,
      currentNodeId: nodeId,
      visitedNodeIds: List.unmodifiable([...state.visitedNodeIds, nodeId]),
      phase: nextPhase,
      currentEvent: nextEvent,
      currentTreasureRelic: nextTreasure,
    );
  }

  // ── 보상 선택 ─────────────────────────────────────────────────────────

  /// 일반 전투 승리 후 보상 화면으로 전환한다.
  ///
  /// [remainingHp]: 전투 후 남은 플레이어 HP.
  /// [goldEarned]: 이번 전투에서 획득한 골드.
  /// 전풀에서 무작위로 고른 카드 3장이 [RunState.rewardCards]에 담긴다.
  void startReward({required int remainingHp, required int goldEarned}) {
    final clampedHp = remainingHp.clamp(0, Player.maxHp);
    state = state.copyWith(
      phase: RunPhase.reward,
      playerHp: clampedHp,
      gold: state.gold + goldEarned,
      rewardCards: _generateRewardCards(),
    );
  }

  /// 보상 화면에서 카드를 선택한다.
  ///
  /// 선택한 [card]를 덱에 추가하고 맵 화면으로 돌아간다.
  void selectRewardCard(GameCard card) {
    if (state.phase != RunPhase.reward) return;
    state = state.copyWith(
      phase: RunPhase.map,
      deck: List.unmodifiable([...state.deck, card]),
      rewardCards: const [],
    );
  }

  /// 보상을 건너뛰고 맵 화면으로 돌아간다.
  void skipReward() {
    if (state.phase != RunPhase.reward) return;
    state = state.copyWith(
      phase: RunPhase.map,
      rewardCards: const [],
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

  // ── 런 리셋 ────────────────────────────────────────────────────────────

  /// 현재 런을 종료하고 초기 상태(새 런)로 리셋한다.
  void startNewRun() {
    state = _initialState();
  }

  // ── 내부 헬퍼 ──────────────────────────────────────────────────────────

  // ── 이벤트 처리 ────────────────────────────────────────────────────────

  /// 이벤트 선택지를 확정하고 효과를 적용한 뒤 맵 화면으로 돌아간다.
  ///
  /// [choice]의 [EventEffect]를 순서대로 적용한다:
  /// 1. HP 변화 (clamp: 1 ~ [Player.maxHp])
  /// 2. 골드 변화 (clamp: 0 이상)
  /// 3. 카드 추가 ([EventEffect.addRandomCard]가 true면 보상 풀에서 1장)
  void resolveEvent(EventChoice choice) {
    if (state.phase != RunPhase.event) return;

    final effect = choice.effect;
    final newHp = (state.playerHp + effect.hpDelta).clamp(1, Player.maxHp);
    final newGold = (state.gold + effect.goldDelta).clamp(0, 99999);

    var newDeck = state.deck;
    if (effect.addRandomCard) {
      final shuffled = List.of(_rewardPool)..shuffle(_random);
      newDeck = List.unmodifiable([...state.deck, shuffled.first]);
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
        _                 => RunPhase.map,
      };

  MapNode? _findNode(String nodeId) {
    try {
      return state.mapNodes.firstWhere((n) => n.id == nodeId);
    } catch (_) {
      return null;
    }
  }

  /// 보상 풀에서 무작위로 3장을 뽑는다.
  List<GameCard> _generateRewardCards() {
    final shuffled = List.of(_rewardPool)..shuffle(_random);
    return List.unmodifiable(shuffled.take(3).toList());
  }
}
