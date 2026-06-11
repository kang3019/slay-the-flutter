import 'dart:math';

import 'map_node.dart';
import 'node_type.dart';

/// Act 맵을 절차적으로 생성하는 팩토리 클래스.
///
/// 순수 Dart 클래스 — Flutter·Riverpod 임포트 금지.
///
/// 생성 규칙 (Slay the Spire 룰셋):
/// - 총 16층 (Floor 0-15) 고정.
/// - Floor 0 = Monster, Floor 8 = Treasure, Floor 14 = Rest, Floor 15 = Boss.
/// - Floor 0~4 구간: Elite 배치 금지.
/// - 어떤 경로든 Elite·Shop·Rest 연속 등장 금지.
/// - 모든 연결은 앞 방향(floor 증가)만 허용. 교차 없는 DAG.
class MapGenerator {
  MapGenerator._();

  static const int _totalFloors       = 12;
  static const int _floorStart        = 0;
  static const int _floorTreasure     = 5;  // 정중앙 — Treasure 고정
  static const int _floorPreBoss      = 10;
  static const int _floorBoss         = 11;

  /// Elite가 허용되기 시작하는 최초 floor (0~3 제외 → 4부터 가능, 12층 기준 ~33%).
  static const int _eliteAllowedFrom  = 4;

  static const Set<int> _fixedFloors  = {
    _floorStart, _floorTreasure, _floorPreBoss, _floorBoss,
  };

  // ── 공개 API ──────────────────────────────────────────────────────────────

  /// Act 1 맵을 절차적으로 생성한다.
  ///
  /// [random]을 지정하면 결정론적 생성이 가능하다 — 테스트에서 시드 고정에 활용.
  static List<MapNode> generateAct1({Random? random}) {
    final rng = random ?? Random();

    final nodeCounts  = _buildNodeCounts(rng);
    final connections = _buildConnections(nodeCounts, rng);
    final typeGrid    = _assignTypes(rng, nodeCounts, connections);

    return [
      for (int f = 0; f < _totalFloors; f++)
        for (int i = 0; i < nodeCounts[f]; i++)
          MapNode(
            id: 'f${f}n$i',
            type: typeGrid[f][i],
            floor: f,
            connectedNodeIds:
                List.unmodifiable(connections['f${f}n$i'] ?? const []),
          ),
    ];
  }

  // ── 층별 노드 수 결정 ─────────────────────────────────────────────────────

  static List<int> _buildNodeCounts(Random rng) {
    final counts = List<int>.filled(_totalFloors, 0);
    counts[_floorStart] = rng.nextInt(2) + 3; // 3 또는 4
    counts[_floorBoss]  = 1;
    for (int f = 1; f < _totalFloors - 1; f++) {
      counts[f] = rng.nextInt(4) + 1; // 1~4
    }
    return counts;
  }

  // ── 노드 타입 배정 ────────────────────────────────────────────────────────

  /// 고정 층을 먼저 채운 뒤, 비고정 층을 순서대로 배정한다.
  ///
  /// 각 노드의 forbidden 집합은 두 가지 소스에서 온다:
  /// (a) 부모 노드 타입 — 연속 등장 방지
  /// (b) 고정 자식 층 타입 — 예: Floor 13 → Floor 14(Rest) 연속 방지
  static List<List<NodeType>> _assignTypes(
    Random rng,
    List<int> nodeCounts,
    Map<String, List<String>> connections,
  ) {
    final grid = List<List<NodeType>>.generate(_totalFloors, (_) => <NodeType>[]);

    // Pass 1: 고정 층 선배정 (look-ahead에서 참조).
    for (final f in _fixedFloors) {
      grid[f] = _fixedFloorTypes(f, nodeCounts[f]);
    }

    // 자식 → 부모 타입 집합을 누적하는 맵.
    final parentTypesOf = <String, Set<NodeType>>{};

    // Pass 2: 전체 층을 순서대로 순회.
    for (int f = 0; f < _totalFloors; f++) {
      if (!_fixedFloors.contains(f)) {
        grid[f] = List.generate(nodeCounts[f], (i) {
          final nodeId      = 'f${f}n$i';
          final parents     = parentTypesOf[nodeId] ?? const {};
          final fixedChildren =
              _fixedChildTypes(nodeId, f + 1, grid, connections);
          return _pickType(rng, f, {...parents, ...fixedChildren});
        });
      }

      // 이 층 타입을 다음 층의 parentTypesOf에 전파.
      for (int i = 0; i < nodeCounts[f]; i++) {
        final nodeId = 'f${f}n$i';
        for (final childId in (connections[nodeId] ?? const [])) {
          (parentTypesOf[childId] ??= {}).add(grid[f][i]);
        }
      }
    }

    _guaranteeContent(grid, nodeCounts, connections, rng);
    return grid;
  }

  /// 고정 층의 타입 목록을 반환한다.
  static List<NodeType> _fixedFloorTypes(int floor, int count) {
    if (floor == _floorBoss) return [NodeType.boss];
    final type = switch (floor) {
      _floorStart    => NodeType.monster,
      _floorTreasure => NodeType.treasure,
      _floorPreBoss  => NodeType.rest,
      _              => throw StateError('floor $floor is not a fixed floor'),
    };
    return List.filled(count, type);
  }

  /// 다음 층이 고정 층이면, 해당 자식 노드들의 타입 집합을 반환한다.
  ///
  /// Floor 13 노드의 자식은 Floor 14(Rest)이므로 {Rest}를 반환 → Floor 13 = Rest 금지.
  static Set<NodeType> _fixedChildTypes(
    String nodeId,
    int nextFloor,
    List<List<NodeType>> grid,
    Map<String, List<String>> connections,
  ) {
    if (nextFloor >= _totalFloors || !_fixedFloors.contains(nextFloor)) {
      return const {};
    }
    final result = <NodeType>{};
    for (final childId in (connections[nodeId] ?? const [])) {
      final sep = childId.indexOf('n');
      final cf  = int.parse(childId.substring(1, sep));
      final ci  = int.parse(childId.substring(sep + 1));
      if (cf == nextFloor) result.add(grid[cf][ci]);
    }
    return result;
  }

  /// 층 진행도와 인접 타입 집합을 반영해 노드 타입을 결정한다.
  static NodeType _pickType(
    Random rng,
    int floor,
    Set<NodeType> neighborTypes,
  ) {
    final forbidden = <NodeType>{
      if (floor < _eliteAllowedFrom) NodeType.elite,
      for (final t in neighborTypes)
        if (t == NodeType.elite || t == NodeType.shop || t == NodeType.rest) t,
    };

    final ratio = floor / (_totalFloors - 1);
    return _typeFromWeights(rng, ratio, forbidden);
  }

  /// 진행도(ratio)별 가중치 풀에서 forbidden을 제외하고 타입을 선택한다.
  static NodeType _typeFromWeights(
    Random rng,
    double ratio,
    Set<NodeType> forbidden,
  ) {
    final pool = _weightPool(ratio)
        .where((e) => !forbidden.contains(e.$1))
        .toList();

    if (pool.isEmpty) return NodeType.monster; // 폴백

    final total = pool.fold(0.0, (s, e) => s + e.$2);
    var roll    = rng.nextDouble() * total;
    for (final (type, weight) in pool) {
      roll -= weight;
      if (roll <= 0) return type;
    }
    return pool.last.$1;
  }

  /// 층 진행도에 따른 (NodeType, weight) 목록.
  ///
  /// Treasure·Boss는 고정 층에서만 등장하므로 풀에서 제외한다.
  static List<(NodeType, double)> _weightPool(double ratio) {
    if (ratio < 0.35) {
      return [
        (NodeType.monster, 0.65),
        (NodeType.event,   0.20),
        (NodeType.rest,    0.15),
      ];
    } else if (ratio < 0.70) {
      return [
        (NodeType.monster, 0.28),
        (NodeType.rest,    0.20),
        (NodeType.shop,    0.20),
        (NodeType.elite,   0.17),
        (NodeType.event,   0.15),
      ];
    } else {
      return [
        (NodeType.elite,   0.40),
        (NodeType.monster, 0.28),
        (NodeType.shop,    0.16),
        (NodeType.rest,    0.16),
      ];
    }
  }

  // ── 콘텐츠 보장 ───────────────────────────────────────────────────────────

  /// Elite·Shop이 없으면 강제 삽입한다.
  ///
  /// Treasure는 Floor 5 고정, Rest는 Floor 10 고정이므로 별도 보장 불필요.
  static void _guaranteeContent(
    List<List<NodeType>> grid,
    List<int> nodeCounts,
    Map<String, List<String>> connections,
    Random rng,
  ) {
    final reverse = _reverseConnections(connections);
    if (!grid.any((f) => f.contains(NodeType.elite))) {
      _forceInsert(
        grid, NodeType.elite, nodeCounts, connections, reverse, rng,
        minFloor: _eliteAllowedFrom,
      );
    }
    if (!grid.any((f) => f.contains(NodeType.shop))) {
      _forceInsert(
        grid, NodeType.shop, nodeCounts, connections, reverse, rng,
        minFloor: 1,
      );
    }
  }

  static void _forceInsert(
    List<List<NodeType>> grid,
    NodeType target,
    List<int> nodeCounts,
    Map<String, List<String>> connections,
    Map<String, List<String>> reverse,
    Random rng, {
    required int minFloor,
  }) {
    const replaceable = {NodeType.monster, NodeType.event};
    final candidates  = <(int, int)>[];

    for (int f = minFloor; f < _totalFloors - 1; f++) {
      if (_fixedFloors.contains(f)) continue;
      for (int i = 0; i < nodeCounts[f]; i++) {
        if (!replaceable.contains(grid[f][i])) continue;
        final id = 'f${f}n$i';
        if ((reverse[id] ?? []).any((p) => _typeOf(p, grid) == target)) continue;
        if ((connections[id] ?? []).any((c) => _typeOf(c, grid) == target)) continue;
        candidates.add((f, i));
      }
    }

    if (candidates.isEmpty) return;
    final (f, i) = candidates[rng.nextInt(candidates.length)];
    grid[f][i] = target;
  }

  static NodeType _typeOf(String id, List<List<NodeType>> grid) {
    final sep = id.indexOf('n');
    final f   = int.parse(id.substring(1, sep));
    final i   = int.parse(id.substring(sep + 1));
    return grid[f][i];
  }

  // ── 역방향 연결 맵 ────────────────────────────────────────────────────────

  static Map<String, List<String>> _reverseConnections(
    Map<String, List<String>> connections,
  ) {
    final rev = <String, List<String>>{};
    for (final entry in connections.entries) {
      for (final childId in entry.value) {
        (rev[childId] ??= []).add(entry.key);
      }
    }
    return rev;
  }

  // ── 층간 연결(DAG, 교차 없음) ─────────────────────────────────────────────

  /// 모든 층 쌍에 대해 교차 없는 DAG 연결을 생성한다.
  ///
  /// 알고리즘:
  /// 1. 각 F+1 노드 j에 "자연 소유자" F 노드를 배정 → 진입 연결 보장.
  /// 2. F 노드 중 출력 연결이 없으면 비례 위치로 연결 추가.
  /// 3. 각 F 노드에 50% 확률로 구간 내 추가 연결 1개 부여.
  static Map<String, List<String>> _buildConnections(
    List<int> nodeCounts,
    Random rng,
  ) {
    final conn = <String, List<String>>{
      for (int f = 0; f < _totalFloors; f++)
        for (int i = 0; i < nodeCounts[f]; i++) 'f${f}n$i': [],
    };

    for (int f = 0; f < _totalFloors - 1; f++) {
      final m = nodeCounts[f];
      final n = nodeCounts[f + 1];

      // Step 1: F+1 각 노드에 진입 연결 보장
      for (int j = 0; j < n; j++) {
        final srcI = _proportional(j, n, m);
        final key  = 'f${f}n$srcI';
        final tgt  = 'f${f + 1}n$j';
        if (!conn[key]!.contains(tgt)) conn[key]!.add(tgt);
      }

      // Step 2: 출력 연결 없는 F 노드 보완
      for (int i = 0; i < m; i++) {
        if (conn['f${f}n$i']!.isEmpty) {
          conn['f${f}n$i']!.add('f${f + 1}n${_proportional(i, m, n)}');
        }
      }

      // Step 3: 구간 내 추가 연결 (50%)
      for (int i = 0; i < m; i++) {
        if (!rng.nextBool()) continue;
        final lo      = (i * n / m).floor().clamp(0, n - 1);
        final hi      = ((i + 1) * n / m).ceil().clamp(0, n) - 1;
        final existing = conn['f${f}n$i']!;
        final extra   = [
          for (int j = lo; j <= hi; j++)
            if (!existing.contains('f${f + 1}n$j')) 'f${f + 1}n$j',
        ];
        if (extra.isNotEmpty) {
          conn['f${f}n$i']!.add(extra[rng.nextInt(extra.length)]);
        }
      }
    }

    return conn.map((k, v) => MapEntry(k, List.unmodifiable(v)));
  }

  /// 소스 인덱스 [i] (0..srcCount-1)를 대상 범위 0..dstCount-1로 비례 매핑.
  ///
  /// 교차 없는 DAG 연결을 보장하는 핵심 함수.
  static int _proportional(int i, int srcCount, int dstCount) {
    if (srcCount == 1) return dstCount ~/ 2;
    return (i * (dstCount - 1) / (srcCount - 1)).round().clamp(0, dstCount - 1);
  }
}
