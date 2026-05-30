import 'package:flutter/material.dart';

import '../../../domain/map/map_node.dart';
import '../map_constants.dart';

// ──────────────────────────────────────────────────────────────────────────
// 노드 좌표 계산 함수 (Painter·GestureDetector 공유)
// ──────────────────────────────────────────────────────────────────────────

/// 노드 목록과 캔버스 크기를 받아 각 노드의 화면 픽셀 좌표를 계산한다.
///
/// **좌표 공식:**
/// - **Y축**: Floor 0(시작)이 아래, 최고 Floor(보스)가 위.
///   ```
///   y = paddingV + (maxFloor - floor) / maxFloor × drawHeight
///   ```
/// - **X축**: 같은 Floor 내 노드를 가로로 균등 분배.
///   ```
///   x = paddingH + index / (count - 1) × drawWidth   // count ≥ 2
///   x = width / 2                                      // count = 1
///   ```
///
/// 이 함수는 [MapPainter]와 [MapScreen]의 GestureDetector에서 **동일하게**
/// 호출되므로 "그려지는 위치 = 탭 인식 위치" 가 항상 보장된다.
///
/// 반환값의 키: [MapNode.id], 값: 캔버스 내 [Offset].
Map<String, Offset> computeNodePositions(List<MapNode> nodes, Size size) {
  if (nodes.isEmpty) return {};

  // ── 최대 floor 계산 ─────────────────────────────────────────────────────
  final maxFloor = nodes.map((n) => n.floor).reduce((a, b) => a > b ? a : b);

  // ── 유효 그리기 영역 ────────────────────────────────────────────────────
  final drawWidth  = size.width  - 2 * MapSizes.paddingH;
  final drawHeight = size.height - 2 * MapSizes.paddingV;

  // ── Floor별 노드 그룹화 ─────────────────────────────────────────────────
  // ID 오름차순으로 정렬하여 "f0n0 → f0n1 → f0n2" 순서로 왼쪽부터 배치한다.
  final byFloor = <int, List<MapNode>>{};
  for (final node in nodes) {
    (byFloor[node.floor] ??= []).add(node);
  }
  for (final list in byFloor.values) {
    list.sort((a, b) => a.id.compareTo(b.id));
  }

  // ── 좌표 계산 ───────────────────────────────────────────────────────────
  final positions = <String, Offset>{};

  for (final entry in byFloor.entries) {
    final floor      = entry.key;
    final floorNodes = entry.value;
    final count      = floorNodes.length;

    // Y: floor 0 → 아래(큰 y), maxFloor → 위(작은 y).
    final yFraction = maxFloor > 0 ? (maxFloor - floor) / maxFloor : 0.5;
    final y = MapSizes.paddingV + yFraction * drawHeight;

    for (int i = 0; i < count; i++) {
      // X: 노드가 1개면 가운데, 2개 이상이면 등간격.
      final xFraction = count > 1 ? i / (count - 1) : 0.5;
      final x = MapSizes.paddingH + xFraction * drawWidth;

      positions[floorNodes[i].id] = Offset(x, y);
    }
  }

  return positions;
}

// ──────────────────────────────────────────────────────────────────────────
// MapPainter
// ──────────────────────────────────────────────────────────────────────────

/// DAG(방향 비순환 그래프) 형태의 던전 맵을 Canvas에 그리는 [CustomPainter].
///
/// **그리기 순서 (Painter's Algorithm):**
/// 1. 비활성·방문 완료 경로 선  ← 가장 아래 레이어
/// 2. 활성(이동 가능) 경로 선   ← 비활성 선 위에 올라와 선명하게 보임
/// 3. 노드 원(글로우 → 링 → 본체 → 테두리)
/// 4. 노드 아이콘 (이모지)      ← 가장 위 레이어
///
/// 좌표 계산은 [computeNodePositions]에 위임하므로,
/// [MapScreen]의 GestureDetector와 항상 동일한 픽셀 위치를 공유한다.
class MapPainter extends CustomPainter {
  /// 현재 런의 전체 노드 목록.
  final List<MapNode> nodes;

  /// 현재 플레이어가 위치한 노드 ID. null이면 아직 시작 노드를 선택하지 않은 상태.
  final String? currentNodeId;

  /// 이번 런에서 방문 완료된 노드 ID 목록.
  final List<String> visitedNodeIds;

  const MapPainter({
    required this.nodes,
    required this.currentNodeId,
    required this.visitedNodeIds,
  });

  // ── paint 진입점 ─────────────────────────────────────────────────────────

  @override
  void paint(Canvas canvas, Size size) {
    final positions  = computeNodePositions(nodes, size);
    final nodeMap    = {for (final n in nodes) n.id: n};
    final visitedSet = visitedNodeIds.toSet();
    final reachable  = _computeReachable(nodeMap);

    // ── Step 1 & 2: 경로 선 ───────────────────────────────────────────────
    // 비활성 선을 먼저 그리고, 활성 선을 나중에 그려 위에 올라오도록 한다.
    _drawAllPaths(
      canvas, positions, visitedSet, reachable,
      activeOnly: false, // 비활성·방문 경로
    );
    _drawAllPaths(
      canvas, positions, visitedSet, reachable,
      activeOnly: true,  // 활성 경로 (위 레이어)
    );

    // ── Step 3 & 4: 노드 및 아이콘 ───────────────────────────────────────
    for (final node in nodes) {
      final pos = positions[node.id];
      if (pos != null) {
        _drawNode(canvas, node, pos, visitedSet, reachable);
      }
    }
  }

  // ── 경로 선 그리기 ────────────────────────────────────────────────────────

  /// [activeOnly]가 true이면 활성 경로만, false이면 그 외 경로만 그린다.
  ///
  /// 두 번 호출하는 이유: 활성 선이 비활성 선 위에 항상 렌더링되도록 하기 위함.
  void _drawAllPaths(
    Canvas canvas,
    Map<String, Offset> positions,
    Set<String> visitedSet,
    Set<String> reachable, {
    required bool activeOnly,
  }) {
    for (final node in nodes) {
      final from = positions[node.id];
      if (from == null) continue;

      for (final connId in node.connectedNodeIds) {
        final to = positions[connId];
        if (to == null) continue;

        // 활성 경로: "현재 노드 → 이동 가능 노드" 방향의 선만 활성으로 판단.
        final isActive =
            node.id == currentNodeId && reachable.contains(connId);

        // 이번 패스에서 그려야 할 종류인지 확인.
        if (activeOnly != isActive) continue;

        final isVisited =
            visitedSet.contains(node.id) && visitedSet.contains(connId);

        _drawLine(canvas, from, to, isActive: isActive, isVisited: isVisited);
      }
    }
  }

  void _drawLine(
    Canvas canvas,
    Offset from,
    Offset to, {
    required bool isActive,
    required bool isVisited,
  }) {
    final Color lineColor;
    final double lineWidth;

    if (isActive) {
      // 금색 굵은 선 — "여기로 이동할 수 있습니다"
      lineColor = MapColors.pathActive;
      lineWidth = MapSizes.pathActiveWidth;
    } else if (isVisited) {
      // 초록 얇은 선 — "이미 지나온 경로"
      lineColor = MapColors.pathVisited.withValues(alpha: 0.65);
      lineWidth = MapSizes.pathInactiveWidth;
    } else {
      // 흰색 반투명 — "아직 닿지 않은 경로 (구조 파악용)"
      lineColor = MapColors.pathInactive;
      lineWidth = MapSizes.pathInactiveWidth;
    }

    canvas.drawLine(
      from,
      to,
      Paint()
        ..color      = lineColor
        ..strokeWidth = lineWidth
        ..strokeCap  = StrokeCap.round
        ..style      = PaintingStyle.stroke,
    );
  }

  // ── 노드 그리기 ───────────────────────────────────────────────────────────

  void _drawNode(
    Canvas canvas,
    MapNode node,
    Offset pos,
    Set<String> visitedSet,
    Set<String> reachable,
  ) {
    final isCurrent   = node.id == currentNodeId;
    final isReachable = reachable.contains(node.id);
    final isVisited   = visitedSet.contains(node.id);

    // 불투명도: 현재·이동 가능·방문 완료 → 완전 불투명.
    //           그 외(미도달·이동 불가) → 35% 희미하게.
    final opacity = (isCurrent || isReachable || isVisited) ? 1.0 : 0.35;

    // ── Layer 1: 글로우 (이동 가능 노드에만) ──────────────────────────────
    // 현재 위치 노드에는 글로우 대신 링을 사용하므로 제외한다.
    if (isReachable && !isCurrent) {
      canvas.drawCircle(
        pos,
        MapSizes.nodeRadius + MapSizes.glowExtra,
        Paint()..color = MapColors.glowReachable,
      );
    }

    // ── Layer 2: 링 (현재 위치 노드에만) ──────────────────────────────────
    // 링은 노드 원 바깥에 그려지므로 노드 본체와 겹치지 않는다.
    if (isCurrent) {
      canvas.drawCircle(
        pos,
        MapSizes.nodeRadius + MapSizes.ringGap,
        Paint()
          ..color       = MapColors.ringCurrent
          ..style       = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    // ── Layer 3: 노드 본체 원 ─────────────────────────────────────────────
    canvas.drawCircle(
      pos,
      MapSizes.nodeRadius,
      Paint()..color = MapColors.forType(node.type).withValues(alpha: opacity),
    );

    // ── Layer 4: 노드 테두리 (얇은 흰색 윤곽선) ──────────────────────────
    canvas.drawCircle(
      pos,
      MapSizes.nodeRadius,
      Paint()
        ..color       = Colors.white.withValues(alpha: opacity * 0.55)
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // ── Layer 5: 이모지 아이콘 ────────────────────────────────────────────
    _drawIcon(canvas, pos, node, opacity);
  }

  /// 노드 중앙에 이모지 아이콘을 그린다.
  ///
  /// [TextPainter]를 사용하여 이모지 문자열을 Canvas에 직접 렌더링한다.
  /// 텍스트를 layout 후 중앙 정렬 좌표로 paint한다.
  void _drawIcon(Canvas canvas, Offset pos, MapNode node, double opacity) {
    final tp = TextPainter(
      text: TextSpan(
        text: MapStrings.iconFor(node.type),
        style: TextStyle(
          fontSize: 17,
          color: Colors.white.withValues(alpha: opacity),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // 텍스트 중앙이 노드 원 중심에 오도록 오프셋을 보정한다.
    tp.paint(
      canvas,
      Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2),
    );
  }

  // ── 보조 로직 ─────────────────────────────────────────────────────────────

  /// 현재 상태에서 플레이어가 이동할 수 있는 노드 ID 집합을 계산한다.
  ///
  /// - [currentNodeId]가 null(미시작): Floor 0 노드 전체.
  /// - 그 외: 현재 노드의 [MapNode.connectedNodeIds].
  Set<String> _computeReachable(Map<String, MapNode> nodeMap) {
    if (currentNodeId == null) {
      // 아직 시작 전 → Floor 0 노드 전체가 선택 가능.
      return nodes
          .where((n) => n.floor == 0)
          .map((n) => n.id)
          .toSet();
    }
    return nodeMap[currentNodeId]?.connectedNodeIds.toSet() ?? {};
  }

  // ── shouldRepaint ─────────────────────────────────────────────────────────

  /// 상태가 바뀐 경우에만 재드로우한다.
  ///
  /// [visitedNodeIds]는 List 참조 동일성으로 비교한다.
  /// RunNotifier는 이동할 때마다 새 List 인스턴스를 만들어 state를 교체하므로,
  /// 이동 후에는 참조가 달라져 자연스럽게 재드로우가 트리거된다.
  @override
  bool shouldRepaint(covariant MapPainter old) =>
      old.currentNodeId != currentNodeId ||
      !identical(old.visitedNodeIds, visitedNodeIds) ||
      old.nodes.length != nodes.length;
}
