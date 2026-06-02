import 'dart:math';

import 'map_node.dart';
import 'node_type.dart';

/// Act 맵을 절차적으로 생성하는 팩토리 클래스.
///
/// 순수 Dart 클래스 — Flutter·Riverpod 임포트 금지.
///
/// 생성 규칙 (SPECS.md §8):
/// - 시작 노드는 2~3개 (멀티 분기 출발).
/// - 총 층수는 7~10층으로 랜덤 결정된다.
/// - 중간 층은 1~3개 노드로 구성되어 런마다 다른 경로가 생성된다.
/// - 마지막 노드는 반드시 [NodeType.boss] 하나로 수렴.
/// - 모든 연결은 앞 방향(floor 증가)만 허용 — 역방향 금지.
/// - 같은 층 노드들이 다음 층으로 연결될 때 선이 교차하지 않도록
///   비례 구간(interval) 매핑을 사용한다.
class MapGenerator {
  MapGenerator._();

  /// Act 1 (챕터 1) 맵을 절차적으로 생성한다.
  ///
  /// [random]을 지정하면 결정론적 생성이 가능하다 — 테스트에서 시드 고정에 활용.
  /// 총 7~10층, 층당 1~3개 노드(시작 층은 2~3개), 보스 층은 1개 노드.
  /// 엘리트·상점·(휴식처 또는 유물)을 각 1개 이상 보장한다.
  static List<MapNode> generateAct1({Random? random}) {
    final rng = random ?? Random();

    final totalFloors   = rng.nextInt(4) + 7;              // 7 ~ 10
    final nodeCounts    = _buildNodeCounts(rng, totalFloors);
    final typeGrid      = _assignTypes(rng, nodeCounts, totalFloors);
    final connections   = _buildConnections(nodeCounts, totalFloors, rng);

    final nodes = <MapNode>[];
    for (int f = 0; f < totalFloors; f++) {
      for (int i = 0; i < nodeCounts[f]; i++) {
        final id   = 'f${f}n$i';
        final conn = List<String>.unmodifiable(connections[id] ?? const []);
        nodes.add(MapNode(id: id, type: typeGrid[f][i], floor: f, connectedNodeIds: conn));
      }
    }
    return nodes;
  }

  // ── 층별 노드 수 결정 ────────────────────────────────────────────────────────

  static List<int> _buildNodeCounts(Random rng, int totalFloors) {
    final counts = <int>[];
    counts.add(rng.nextInt(2) + 2); // floor 0: 2 or 3
    for (int f = 1; f < totalFloors - 1; f++) {
      counts.add(rng.nextInt(3) + 1); // middle: 1~3
    }
    counts.add(1); // boss floor
    return counts;
  }

  // ── 노드 타입 배정 ───────────────────────────────────────────────────────────

  static List<List<NodeType>> _assignTypes(
    Random rng, List<int> nodeCounts, int totalFloors) {
    final grid = <List<NodeType>>[];

    // Floor 0: 몬스터·이벤트만 허용
    grid.add(List.generate(nodeCounts[0], (_) =>
        rng.nextDouble() < 0.7 ? NodeType.monster : NodeType.event));

    // Middle floors: 층 진행도(ratio)에 따라 가중치 풀 적용
    for (int f = 1; f < totalFloors - 1; f++) {
      final ratio = f / (totalFloors - 1);
      grid.add(List.generate(nodeCounts[f], (_) => _typeForRatio(rng, ratio)));
    }

    // Boss floor
    grid.add([NodeType.boss]);

    _guaranteeContent(grid, nodeCounts, totalFloors, rng);
    return grid;
  }

  /// 층 진행도(0.0 = 시작, 1.0 = 보스 직전)에 따라 노드 타입을 뽑는다.
  static NodeType _typeForRatio(Random rng, double ratio) {
    final roll = rng.nextDouble();
    if (ratio < 0.35) {
      // 초반: 몬스터 위주 + 이벤트·유물
      if (roll < 0.60) return NodeType.monster;
      if (roll < 0.80) return NodeType.event;
      if (roll < 0.92) return NodeType.treasure;
      return NodeType.rest;
    } else if (ratio < 0.68) {
      // 중반: 휴식·상점·엘리트 등장
      if (roll < 0.32) return NodeType.monster;
      if (roll < 0.52) return NodeType.rest;
      if (roll < 0.67) return NodeType.shop;
      if (roll < 0.82) return NodeType.elite;
      return NodeType.event;
    } else {
      // 후반(보스 전): 엘리트·몬스터 위주
      if (roll < 0.45) return NodeType.elite;
      if (roll < 0.72) return NodeType.monster;
      if (roll < 0.86) return NodeType.rest;
      return NodeType.event;
    }
  }

  /// 엘리트·상점·(휴식처 또는 유물) 각 1개 이상 보장한다.
  ///
  /// 없으면 중간 층의 몬스터/이벤트 노드를 하나 교체한다.
  static void _guaranteeContent(
    List<List<NodeType>> grid, List<int> nodeCounts, int totalFloors, Random rng) {
    if (!grid.any((f) => f.contains(NodeType.elite))) {
      _forceInsert(grid, NodeType.elite, totalFloors, rng);
    }
    if (!grid.any((f) => f.contains(NodeType.shop))) {
      _forceInsert(grid, NodeType.shop, totalFloors, rng);
    }
    final hasRestOrTreasure = grid.any(
      (f) => f.any((t) => t == NodeType.rest || t == NodeType.treasure),
    );
    if (!hasRestOrTreasure) {
      _forceInsert(grid, NodeType.rest, totalFloors, rng);
    }
  }

  static void _forceInsert(
    List<List<NodeType>> grid, NodeType target, int totalFloors, Random rng) {
    const replaceable = [NodeType.monster, NodeType.event];

    final candidates = <(int f, int i)>[];
    for (int f = 1; f < totalFloors - 1; f++) {
      for (int i = 0; i < grid[f].length; i++) {
        if (replaceable.contains(grid[f][i])) candidates.add((f, i));
      }
    }
    if (candidates.isEmpty) return;

    final (f, i) = candidates[rng.nextInt(candidates.length)];
    grid[f][i] = target;
  }

  // ── 층간 연결(DAG, 교차 없음) ────────────────────────────────────────────────

  /// 모든 층 쌍에 대해 교차 없는 DAG 연결을 생성한다.
  ///
  /// 알고리즘:
  /// 1. 각 F+1 노드 j에 대해 "자연 소유자" F 노드 srcI를 배정 (비례 매핑).
  ///    → 모든 F+1 노드가 최소 1개의 진입 연결을 가진다.
  /// 2. F 노드 i에 아직 연결이 없으면 비례 위치의 F+1 노드로 연결.
  ///    → 모든 F 노드가 최소 1개의 출력 연결을 가진다.
  /// 3. 각 F 노드에 50% 확률로 구간 내 추가 연결 1개를 부여.
  ///    구간: [floor(i·n/m), ceil((i+1)·n/m)−1] — 이 범위 내 연결은 교차 없음이 보장된다.
  static Map<String, List<String>> _buildConnections(
    List<int> nodeCounts, int totalFloors, Random rng) {
    final conn = <String, List<String>>{};

    // 모든 노드에 빈 목록 초기화
    for (int f = 0; f < totalFloors; f++) {
      for (int i = 0; i < nodeCounts[f]; i++) {
        conn['f${f}n$i'] = [];
      }
    }

    for (int f = 0; f < totalFloors - 1; f++) {
      final m = nodeCounts[f];
      final n = nodeCounts[f + 1];

      // Step 1: 각 F+1 노드에 진입 연결 보장
      final hasIncoming = List.filled(n, false);
      for (int j = 0; j < n; j++) {
        final srcI = _proportional(j, n, m);
        final key  = 'f${f}n$srcI';
        final tgt  = 'f${f + 1}n$j';
        if (!conn[key]!.contains(tgt)) conn[key]!.add(tgt);
        hasIncoming[j] = true;
      }

      // Step 2: F 노드 중 출력 연결이 없는 노드에 연결 추가
      for (int i = 0; i < m; i++) {
        if (conn['f${f}n$i']!.isEmpty) {
          final j   = _proportional(i, m, n);
          conn['f${f}n$i']!.add('f${f + 1}n$j');
        }
      }

      // Step 3: 구간 내 추가 연결 (50% 확률)
      for (int i = 0; i < m; i++) {
        if (!rng.nextBool()) continue;
        final lo = (i * n / m).floor().clamp(0, n - 1);
        final hi = ((i + 1) * n / m).ceil().clamp(0, n) - 1;
        final existing = conn['f${f}n$i']!;
        final extra = [
          for (int j = lo; j <= hi; j++)
            if (!existing.contains('f${f + 1}n$j')) 'f${f + 1}n$j',
        ];
        if (extra.isNotEmpty) {
          conn['f${f}n$i']!.add(extra[rng.nextInt(extra.length)]);
        }
      }
    }

    // 불변 리스트로 변환
    return conn.map((k, v) => MapEntry(k, List.unmodifiable(v)));
  }

  /// 소스 인덱스 [i] (범위 0..srcCount-1)를 대상 범위 0..dstCount-1로 비례 매핑한다.
  ///
  /// 교차 없는 DAG 연결을 보장하는 핵심 함수.
  static int _proportional(int i, int srcCount, int dstCount) {
    if (srcCount == 1) return dstCount ~/ 2;
    return (i * (dstCount - 1) / (srcCount - 1)).round().clamp(0, dstCount - 1);
  }
}
