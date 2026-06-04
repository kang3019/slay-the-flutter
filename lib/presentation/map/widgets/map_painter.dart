import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/map/map_node.dart';
import '../map_constants.dart';
import 'node_icon_draw.dart';

// ──────────────────────────────────────────────────────────────────────────
// 캔버스 크기 · 노드 좌표 (map_screen.dart와 공유)
// ──────────────────────────────────────────────────────────────────────────

/// 전체 맵 캔버스 크기를 노드 목록과 화면 너비로 계산한다.
Size computeCanvasSize(List<MapNode> nodes, double screenWidth) {
  if (nodes.isEmpty) return Size(screenWidth, 600);
  final maxFloor = nodes.map((n) => n.floor).reduce((a, b) => a > b ? a : b);
  return Size(screenWidth, 2 * MapSizes.paddingV + maxFloor * MapSizes.floorHeight);
}

/// 각 노드의 캔버스 픽셀 좌표를 계산한다.
///
/// Y: Floor 0(시작) = 하단, 보스 = 상단.
/// X: 층 내 균등 배치 + 노드 ID 기반 결정론적 지터(±40% 인접 간격).
Map<String, Offset> computeNodePositions(List<MapNode> nodes, Size size) {
  if (nodes.isEmpty) return {};

  final maxFloor  = nodes.map((n) => n.floor).reduce((a, b) => a > b ? a : b);
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
      final laneWidth = count > 1 ? drawWidth / (count - 1) : drawWidth;
      final jitter    = _idJitter(floorNodes[i].id) * laneWidth * 0.40;
      final x = (baseX + jitter).clamp(MapSizes.paddingH, MapSizes.paddingH + drawWidth);
      positions[floorNodes[i].id] = Offset(x, y);
    }
  }
  return positions;
}

/// 노드 ID → [-1, 1] 결정론적 해시.
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

/// 다크 판타지 스타일 던전 맵을 Canvas에 렌더링하는 [CustomPainter].
///
/// 레이어 순서:
///   1. 돌 질감 배경 + 비네트
///   2. 비활성·방문 점선 경로
///   3. 활성 황금 글로우 경로
///   4. 노드 그림자 → 다이아몬드 프레임 → 아이콘 → 링
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
    _paintBackground(canvas, size);

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

  // ── 배경: 돌 질감 + 비네트 ───────────────────────────────────────────────

  void _paintBackground(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // 딥 옵시디언 기본
    canvas.drawRect(rect, Paint()..color = const Color(0xFF06080F));

    // 돌 블록 텍스처 (결정론적 패치)
    final texPaint = Paint()..color = Colors.white.withValues(alpha: 0.011);
    for (int i = 0; i < 60; i++) {
      final x = (i * 137.508) % size.width;
      final y = (i * 89.318 + size.height * 0.08) % size.height;
      final w = 18.0 + (i * 23.7) % 52;
      final h = 5.0  + (i * 11.3) % 13;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(2)),
        texPaint,
      );
    }

    // 균열선 (돌 질감 강화)
    final crackPaint = Paint()
      ..color       = Colors.white.withValues(alpha: 0.016)
      ..strokeWidth = 0.7;
    for (int i = 0; i < 14; i++) {
      final sx = (i * 179.3) % size.width;
      final sy = (i * 113.7) % size.height;
      final a  = (i * 47.0) * math.pi / 180;
      final l  = 35.0 + (i * 23) % 55;
      canvas.drawLine(
        Offset(sx, sy),
        Offset(sx + math.cos(a) * l, sy + math.sin(a) * l),
        crackPaint,
      );
    }

    // 주변 비네트 (가장자리 → 검정)
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.80,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.68)],
          stops: const [0.42, 1.0],
        ).createShader(rect),
    );
  }

  // ── 경로 ─────────────────────────────────────────────────────────────────

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
        isActive ? _drawGlowPath(canvas, from, to) : _drawDashedPath(canvas, from, to, isVisited: isVisited);
      }
    }
  }

  /// 황금 글로우 경로 — 여러 겹의 넓은 반투명 선으로 소프트 글로우를 시뮬레이션.
  void _drawGlowPath(Canvas canvas, Offset from, Offset to) {
    const gold = Color(0xFFFFD700);
    final midY = (from.dy + to.dy) / 2;

    for (final (w, a) in [(18.0, 0.05), (10.0, 0.11), (5.0, 0.26), (2.5, 0.92)]) {
      final path = Path()
        ..moveTo(from.dx, from.dy)
        ..cubicTo(from.dx, midY, to.dx, midY, to.dx, to.dy);
      canvas.drawPath(path, Paint()
        ..color       = gold.withValues(alpha: a)
        ..strokeWidth  = w
        ..style       = PaintingStyle.stroke
        ..strokeCap   = StrokeCap.round);
    }
  }

  /// 방문 완료 경로 — 진한 녹색 실선으로 지나온 길을 강조.
  void _drawVisitedPath(Canvas canvas, Offset from, Offset to) {
    final midY = (from.dy + to.dy) / 2;
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..cubicTo(from.dx, midY, to.dx, midY, to.dx, to.dy);

    // 글로우 레이어
    canvas.drawPath(path, Paint()
      ..color      = const Color(0xFF4CAF50).withValues(alpha: 0.30)
      ..strokeWidth = 8.0
      ..style      = PaintingStyle.stroke
      ..strokeCap  = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

    // 코어 실선
    canvas.drawPath(path, Paint()
      ..color      = const Color(0xFF66BB6A)
      ..strokeWidth = 3.0
      ..style      = PaintingStyle.stroke
      ..strokeCap  = StrokeCap.round);
  }

  /// 비활성 점선 경로 — 고대 지도 잉크 자국 스타일.
  void _drawDashedPath(Canvas canvas, Offset from, Offset to, {required bool isVisited}) {
    if (isVisited) {
      _drawVisitedPath(canvas, from, to);
      return;
    }

    const color   = Color(0xFF2A2A4A);
    const dashLen = 6.0;
    const gapLen  = 5.0;

    final dx   = to.dx - from.dx;
    final dy   = to.dy - from.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist == 0) return;

    final nx    = dx / dist;
    final ny    = dy / dist;
    final paint = Paint()
      ..color      = color.withValues(alpha: 0.80)
      ..strokeWidth = 1.2
      ..strokeCap  = StrokeCap.round;

    double pos = 0;
    bool dash = true;
    while (pos < dist) {
      final segLen = dash ? dashLen : gapLen;
      final end    = math.min(pos + segLen, dist);
      if (dash) {
        canvas.drawLine(
          Offset(from.dx + nx * pos, from.dy + ny * pos),
          Offset(from.dx + nx * end, from.dy + ny * end),
          paint,
        );
      }
      pos  = end;
      dash = !dash;
    }
  }

  // ── 노드 ─────────────────────────────────────────────────────────────────

  void _drawNode(
    Canvas canvas, MapNode node, Offset pos,
    Set<String> visitedSet, Set<String> reachable,
  ) {
    final isCurrent   = node.id == currentNodeId;
    final isReachable = reachable.contains(node.id);
    final isVisited   = visitedSet.contains(node.id);
    final opacity     = (isCurrent || isReachable || isVisited) ? 1.0 : 0.28;

    final nodeColor = MapColors.forType(node.type);
    final r         = MapSizes.nodeRadius;

    // 이동 가능 노드 글로우
    if (isReachable && !isCurrent) {
      canvas.drawPath(
        _diamond(pos, r + 13),
        Paint()
          ..color      = nodeColor.withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
      );
    }

    // 드롭 섀도
    canvas.drawPath(
      _diamond(pos + const Offset(2.5, 3.5), r),
      Paint()..color = Colors.black.withValues(alpha: 0.50 * opacity),
    );

    // 외부 다이아몬드 (노드 색상)
    canvas.drawPath(_diamond(pos, r), Paint()..color = nodeColor.withValues(alpha: opacity));

    // 내부 다이아몬드 (어두운 배경)
    canvas.drawPath(
      _diamond(pos, r * 0.78),
      Paint()..color = const Color(0xFF080A14).withValues(alpha: opacity),
    );

    // 현재 위치 링
    if (isCurrent) {
      canvas.drawPath(
        _diamond(pos, r + 9),
        Paint()
          ..color      = MapColors.ringCurrent
          ..style      = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
      canvas.drawPath(
        _diamond(pos, r + 16),
        Paint()
          ..color      = MapColors.ringCurrent.withValues(alpha: 0.14)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }

    // 아이콘 — NodeIconDraw 공유 (범례와 동일한 드로잉)
    NodeIconDraw.drawIcon(canvas, node.type, pos, r * 0.52, opacity);
  }

  Path _diamond(Offset c, double r) => Path()
    ..moveTo(c.dx,     c.dy - r)
    ..lineTo(c.dx + r, c.dy)
    ..lineTo(c.dx,     c.dy + r)
    ..lineTo(c.dx - r, c.dy)
    ..close();

  // ── 보조 ─────────────────────────────────────────────────────────────────

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
