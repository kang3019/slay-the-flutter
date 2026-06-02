import 'package:flutter/material.dart';

import '../../../domain/map/map_node.dart';
import '../map_constants.dart';

// ──────────────────────────────────────────────────────────────────────────
// 캔버스 크기 계산
// ──────────────────────────────────────────────────────────────────────────

/// 노드 목록과 화면 너비를 받아 전체 맵 캔버스 크기를 계산한다.
///
/// 층당 [MapSizes.floorHeight] 고정 간격을 사용하므로
/// 층수가 많을수록 캔버스가 세로로 길어진다 (→ 스크롤로 탐색).
Size computeCanvasSize(List<MapNode> nodes, double screenWidth) {
  if (nodes.isEmpty) return Size(screenWidth, 600);
  final maxFloor = nodes.map((n) => n.floor).reduce((a, b) => a > b ? a : b);
  final height = 2 * MapSizes.paddingV + maxFloor * MapSizes.floorHeight;
  return Size(screenWidth, height);
}

// ──────────────────────────────────────────────────────────────────────────
// 노드 좌표 계산
// ──────────────────────────────────────────────────────────────────────────

/// 노드 목록과 캔버스 크기를 받아 각 노드의 화면 픽셀 좌표를 계산한다.
///
/// **좌표 공식:**
/// - **Y축**: 층당 [MapSizes.floorHeight] 고정 간격. Floor 0(시작)이 아래, 보스가 위.
///   ```
///   y = paddingV + (maxFloor - floor) × floorHeight
///   ```
/// - **X축**: 층 내 균등 배치 기준에 노드 ID 기반 결정론적 지터(jitter)를 추가한다.
///   지터는 인접 노드 간격의 ±40% 이내로 제한되어 경로 교차를 방지한다.
///
/// 동일한 함수를 [MapPainter]와 [_MapCanvasState]가 공유하므로
/// "그려지는 위치 = 탭 인식 위치"가 항상 일치한다.
Map<String, Offset> computeNodePositions(List<MapNode> nodes, Size size) {
  if (nodes.isEmpty) return {};

  final maxFloor = nodes.map((n) => n.floor).reduce((a, b) => a > b ? a : b);
  final drawWidth = size.width - 2 * MapSizes.paddingH;

  final byFloor = <int, List<MapNode>>{};
  for (final node in nodes) {
    (byFloor[node.floor] ??= []).add(node);
  }
  for (final list in byFloor.values) {
    list.sort((a, b) => a.id.compareTo(b.id));
  }

  final positions = <String, Offset>{};

  for (final entry in byFloor.entries) {
    final floor      = entry.key;
    final floorNodes = entry.value;
    final count      = floorNodes.length;

    final y = MapSizes.paddingV + (maxFloor - floor) * MapSizes.floorHeight;

    for (int i = 0; i < count; i++) {
      final xFraction = count > 1 ? i / (count - 1) : 0.5;
      final baseX     = MapSizes.paddingH + xFraction * drawWidth;

      // 노드 ID 기반 결정론적 지터 — 같은 노드는 항상 같은 위치.
      // 지터 폭 = 인접 간격의 40% → 경로 교차 없음.
      final laneWidth = count > 1 ? drawWidth / (count - 1) : drawWidth;
      final jitter    = _idJitter(floorNodes[i].id) * laneWidth * 0.40;
      final x         = (baseX + jitter).clamp(
        MapSizes.paddingH,
        MapSizes.paddingH + drawWidth,
      );

      positions[floorNodes[i].id] = Offset(x, y);
    }
  }

  return positions;
}

/// 노드 ID 문자열을 [-1, 1] 범위의 결정론적 값으로 해싱한다.
double _idJitter(String id) {
  int hash = 0;
  for (final c in id.codeUnits) {
    hash = (hash * 31 + c) & 0x7FFFFFFF;
  }
  return (hash % 1000) / 1000.0 * 2.0 - 1.0;
}

// ──────────────────────────────────────────────────────────────────────────
// MapPainter
// ──────────────────────────────────────────────────────────────────────────

/// DAG(방향 비순환 그래프) 형태의 던전 맵을 Canvas에 그리는 [CustomPainter].
///
/// **그리기 순서 (Painter's Algorithm):**
/// 1. 비활성·방문 완료 경로 선  ← 가장 아래 레이어
/// 2. 활성(이동 가능) 경로 선   ← 비활성 선 위
/// 3. 노드 원(글로우 → 링 → 본체 → 테두리)
/// 4. 노드 아이콘 (이모지)      ← 가장 위 레이어
///
/// 경로선은 S자 3차 베지어(cubic bezier) 곡선으로 렌더링한다.
class MapPainter extends CustomPainter {
  final List<MapNode> nodes;
  final String? currentNodeId;
  final List<String> visitedNodeIds;

  const MapPainter({
    required this.nodes,
    required this.currentNodeId,
    required this.visitedNodeIds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final positions  = computeNodePositions(nodes, size);
    final nodeMap    = {for (final n in nodes) n.id: n};
    final visitedSet = visitedNodeIds.toSet();
    final reachable  = _computeReachable(nodeMap);

    _drawAllPaths(canvas, positions, visitedSet, reachable, activeOnly: false);
    _drawAllPaths(canvas, positions, visitedSet, reachable, activeOnly: true);

    for (final node in nodes) {
      final pos = positions[node.id];
      if (pos != null) _drawNode(canvas, node, pos, visitedSet, reachable);
    }
  }

  // ── 경로선 ───────────────────────────────────────────────────────────────

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

        final isActive  = node.id == currentNodeId && reachable.contains(connId);
        if (activeOnly != isActive) continue;

        final isVisited = visitedSet.contains(node.id) && visitedSet.contains(connId);
        _drawBezierPath(canvas, from, to, isActive: isActive, isVisited: isVisited);
      }
    }
  }

  /// S자 3차 베지어 곡선으로 두 노드 사이를 연결한다.
  ///
  /// 제어점은 출발·도착 노드의 X를 유지하면서 Y를 중간으로 당겨
  /// 부드러운 S자 곡선을 만든다.
  void _drawBezierPath(
    Canvas canvas,
    Offset from,
    Offset to, {
    required bool isActive,
    required bool isVisited,
  }) {
    final Color lineColor;
    final double lineWidth;

    if (isActive) {
      lineColor = MapColors.pathActive;
      lineWidth = MapSizes.pathActiveWidth;
    } else if (isVisited) {
      lineColor = MapColors.pathVisited.withValues(alpha: 0.6);
      lineWidth = MapSizes.pathInactiveWidth;
    } else {
      lineColor = MapColors.pathInactive;
      lineWidth = MapSizes.pathInactiveWidth;
    }

    final paint = Paint()
      ..color       = lineColor
      ..strokeWidth  = lineWidth
      ..strokeCap   = StrokeCap.round
      ..style       = PaintingStyle.stroke;

    final midY = (from.dy + to.dy) / 2;
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..cubicTo(from.dx, midY, to.dx, midY, to.dx, to.dy);

    canvas.drawPath(path, paint);
  }

  // ── 노드 그리기 ──────────────────────────────────────────────────────────

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

    final opacity = (isCurrent || isReachable || isVisited) ? 1.0 : 0.30;

    // Layer 1: 넓은 반투명 글로우 (이동 가능 노드)
    if (isReachable && !isCurrent) {
      canvas.drawCircle(
        pos,
        MapSizes.nodeRadius + MapSizes.glowExtra,
        Paint()..color = MapColors.glowReachable,
      );
    }

    // Layer 2: 현재 위치 링
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

    // Layer 3: 노드 본체
    canvas.drawCircle(
      pos,
      MapSizes.nodeRadius,
      Paint()..color = MapColors.forType(node.type).withValues(alpha: opacity),
    );

    // Layer 4: 흰색 테두리 윤곽선
    canvas.drawCircle(
      pos,
      MapSizes.nodeRadius,
      Paint()
        ..color       = Colors.white.withValues(alpha: opacity * 0.5)
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Layer 5: 이모지 아이콘
    _drawIcon(canvas, pos, node, opacity);
  }

  void _drawIcon(Canvas canvas, Offset pos, MapNode node, double opacity) {
    final tp = TextPainter(
      text: TextSpan(
        text: MapStrings.iconFor(node.type),
        style: TextStyle(
          fontSize: 18,
          color: Colors.white.withValues(alpha: opacity),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2),
    );
  }

  // ── 보조 로직 ─────────────────────────────────────────────────────────────

  Set<String> _computeReachable(Map<String, MapNode> nodeMap) {
    if (currentNodeId == null) {
      return nodes.where((n) => n.floor == 0).map((n) => n.id).toSet();
    }
    return nodeMap[currentNodeId]?.connectedNodeIds.toSet() ?? {};
  }

  @override
  bool shouldRepaint(covariant MapPainter old) =>
      old.currentNodeId != currentNodeId ||
      !identical(old.visitedNodeIds, visitedNodeIds) ||
      old.nodes.length != nodes.length;
}
