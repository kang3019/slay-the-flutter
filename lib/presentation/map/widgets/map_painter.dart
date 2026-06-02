import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/map/map_node.dart';
import '../../../domain/map/node_type.dart';
import '../map_constants.dart';

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

  /// 점선 경로 — 고대 지도 잉크 자국 스타일.
  void _drawDashedPath(Canvas canvas, Offset from, Offset to, {required bool isVisited}) {
    final color = isVisited
        ? const Color(0xFF388E3C).withValues(alpha: 0.55)
        : const Color(0xFF2A2A4A).withValues(alpha: 0.80);
    const dashLen = 6.0;
    const gapLen  = 5.0;

    final dx   = to.dx - from.dx;
    final dy   = to.dy - from.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist == 0) return;

    final nx    = dx / dist;
    final ny    = dy / dist;
    final paint = Paint()
      ..color      = color
      ..strokeWidth = isVisited ? 1.8 : 1.2
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

    // 아이콘 (다이아몬드 내부)
    _drawIcon(canvas, node.type, pos, r * 0.52, opacity);
  }

  Path _diamond(Offset c, double r) => Path()
    ..moveTo(c.dx,     c.dy - r)
    ..lineTo(c.dx + r, c.dy)
    ..lineTo(c.dx,     c.dy + r)
    ..lineTo(c.dx - r, c.dy)
    ..close();

  // ── 아이콘 디스패처 ───────────────────────────────────────────────────────

  void _drawIcon(Canvas canvas, NodeType type, Offset c, double r, double opacity) {
    switch (type) {
      case NodeType.monster:  _drawSkull(canvas, c, r, opacity, isElite: false);
      case NodeType.elite:    _drawSkull(canvas, c, r, opacity, isElite: true);
      case NodeType.boss:     _drawCrown(canvas, c, r, opacity);
      case NodeType.rest:     _drawFlame(canvas, c, r, opacity);
      case NodeType.shop:     _drawPouch(canvas, c, r, opacity);
      case NodeType.treasure: _drawChest(canvas, c, r, opacity);
      case NodeType.event:    _drawMystic(canvas, c, r, opacity);
    }
  }

  // ── 해골 (Monster / Elite) ───────────────────────────────────────────────

  void _drawSkull(Canvas canvas, Offset c, double r, double opacity, {required bool isElite}) {
    final bone = const Color(0xFFDDD5C0).withValues(alpha: opacity);
    final dark = const Color(0xFF06080E).withValues(alpha: opacity);

    if (isElite) {
      final hornP = Paint()
        ..color       = bone
        ..style       = PaintingStyle.stroke
        ..strokeWidth  = r * 0.20
        ..strokeCap   = StrokeCap.round;
      canvas.drawPath(Path()
        ..moveTo(c.dx - r * 0.26, c.dy - r * 0.68)
        ..quadraticBezierTo(c.dx - r * 0.65, c.dy - r * 1.25, c.dx - r * 0.48, c.dy - r * 1.48), hornP);
      canvas.drawPath(Path()
        ..moveTo(c.dx + r * 0.26, c.dy - r * 0.68)
        ..quadraticBezierTo(c.dx + r * 0.65, c.dy - r * 1.25, c.dx + r * 0.48, c.dy - r * 1.48), hornP);
    }

    // 두개골
    canvas.drawOval(
      Rect.fromCenter(center: c + Offset(0, -r * 0.16), width: r * 1.52, height: r * 1.22),
      Paint()..color = bone,
    );
    // 턱
    canvas.drawOval(
      Rect.fromCenter(center: c + Offset(0, r * 0.56), width: r * 1.08, height: r * 0.50),
      Paint()..color = bone,
    );
    // 눈 구멍
    for (final dx in [-0.33, 0.33]) {
      canvas.drawOval(
        Rect.fromCenter(center: c + Offset(r * dx, -r * 0.20), width: r * 0.48, height: r * 0.38),
        Paint()..color = dark,
      );
    }
    // 빨간 눈 글로우
    final eyeP = Paint()
      ..color      = const Color(0xFFFF2020).withValues(alpha: opacity * 0.88)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    for (final dx in [-0.33, 0.33]) {
      canvas.drawOval(
        Rect.fromCenter(center: c + Offset(r * dx, -r * 0.22), width: r * 0.30, height: r * 0.22),
        eyeP,
      );
    }
    // 코 구멍
    canvas.drawPath(
      Path()
        ..moveTo(c.dx, c.dy + r * 0.06)
        ..lineTo(c.dx - r * 0.12, c.dy + r * 0.27)
        ..lineTo(c.dx + r * 0.12, c.dy + r * 0.27)
        ..close(),
      Paint()..color = dark,
    );
    // 이빨
    for (int i = 0; i < 4; i++) {
      final tx = c.dx - r * 0.42 + i * r * 0.285;
      canvas.drawPath(
        Path()
          ..moveTo(tx,           c.dy + r * 0.40)
          ..lineTo(tx + r * 0.21, c.dy + r * 0.40)
          ..lineTo(tx + r * 0.105, c.dy + r * 0.68)
          ..close(),
        Paint()..color = bone,
      );
      canvas.drawRect(
        Rect.fromLTWH(tx + r*0.21 - 0.8, c.dy + r*0.40, 1.6, r*0.28),
        Paint()..color = dark,
      );
    }
  }

  // ── 왕관 (Boss) ──────────────────────────────────────────────────────────

  void _drawCrown(Canvas canvas, Offset c, double r, double opacity) {
    final gold  = const Color(0xFFFFD700).withValues(alpha: opacity);
    final dGold = const Color(0xFFB8860B).withValues(alpha: opacity);

    // 왕관 띠
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c + Offset(0, r*0.35), width: r*2.0, height: r*0.60),
        Radius.circular(r*0.08),
      ),
      Paint()..color = dGold,
    );
    // 포인트 5개
    for (final (xi, hi) in [(-0.78,-0.28), (-0.39,-0.62), (0.0,-0.92), (0.39,-0.62), (0.78,-0.28)]) {
      canvas.drawPath(
        Path()
          ..moveTo(c.dx + xi * r - r*0.20, c.dy + r*0.06)
          ..lineTo(c.dx + xi * r + r*0.20, c.dy + r*0.06)
          ..lineTo(c.dx + xi * r,           c.dy + hi * r)
          ..close(),
        Paint()..color = gold,
      );
    }
    // 보석 3개
    for (final (xi, color) in [(-0.40, const Color(0xFFFF3030)), (0.0, const Color(0xFF3090FF)), (0.40, const Color(0xFFFF3030))]) {
      canvas.drawCircle(c + Offset(xi * r, r*0.35), r*0.13,
          Paint()..color = color.withValues(alpha: opacity));
      canvas.drawCircle(c + Offset(xi * r, r*0.35), r*0.13,
          Paint()..color = Colors.white.withValues(alpha: opacity * 0.35)..style = PaintingStyle.stroke..strokeWidth = 0.8);
    }
  }

  // ── 불꽃 (Rest) ──────────────────────────────────────────────────────────

  void _drawFlame(Canvas canvas, Offset c, double r, double opacity) {
    // 통나무
    for (final (dx, color) in [(-r*0.22, const Color(0xFF5C3310)), (r*0.22, const Color(0xFF4A2208))]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: c + Offset(dx, r*0.72), width: r*0.75, height: r*0.20),
          Radius.circular(r*0.05),
        ),
        Paint()..color = color.withValues(alpha: opacity),
      );
    }
    // 외부 불꽃
    canvas.drawPath(
      Path()
        ..moveTo(c.dx, c.dy + r*0.62)
        ..cubicTo(c.dx-r*0.52, c.dy+r*0.18, c.dx-r*0.62, c.dy-r*0.22, c.dx, c.dy-r*0.82)
        ..cubicTo(c.dx+r*0.10, c.dy-r*0.42, c.dx+r*0.35, c.dy-r*0.56, c.dx+r*0.22, c.dy-r*0.18)
        ..cubicTo(c.dx+r*0.56, c.dy+r*0.05, c.dx+r*0.52, c.dy+r*0.32, c.dx, c.dy+r*0.62)
        ..close(),
      Paint()..color = const Color(0xFFFF5500).withValues(alpha: opacity),
    );
    // 중간 불꽃
    canvas.drawPath(
      Path()
        ..moveTo(c.dx, c.dy+r*0.42)
        ..cubicTo(c.dx-r*0.28, c.dy+r*0.08, c.dx-r*0.32, c.dy-r*0.22, c.dx, c.dy-r*0.60)
        ..cubicTo(c.dx+r*0.32, c.dy-r*0.22, c.dx+r*0.28, c.dy+r*0.08, c.dx, c.dy+r*0.42)
        ..close(),
      Paint()..color = const Color(0xFFFF9900).withValues(alpha: opacity),
    );
    // 핵심 불꽃 (노랑)
    canvas.drawPath(
      Path()
        ..moveTo(c.dx, c.dy+r*0.22)
        ..cubicTo(c.dx-r*0.14, c.dy, c.dx-r*0.14, c.dy-r*0.32, c.dx, c.dy-r*0.44)
        ..cubicTo(c.dx+r*0.14, c.dy-r*0.32, c.dx+r*0.14, c.dy, c.dx, c.dy+r*0.22)
        ..close(),
      Paint()..color = const Color(0xFFFFEE00).withValues(alpha: opacity),
    );
  }

  // ── 주머니 (Shop) ─────────────────────────────────────────────────────────

  void _drawPouch(Canvas canvas, Offset c, double r, double opacity) {
    final brown  = const Color(0xFF8B4513).withValues(alpha: opacity);
    final dBrown = const Color(0xFF5C2E0A).withValues(alpha: opacity);
    final gold   = const Color(0xFFFFD700).withValues(alpha: opacity);

    canvas.drawOval(
      Rect.fromCenter(center: c + Offset(0, r*0.20), width: r*1.62, height: r*1.42),
      Paint()..color = brown,
    );
    canvas.drawOval(
      Rect.fromCenter(center: c + Offset(r*0.28, r*0.42), width: r*0.75, height: r*0.65),
      Paint()..color = dBrown..color = const Color(0xFF5C2E0A).withValues(alpha: opacity * 0.45),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c + Offset(0, -r*0.56), width: r*0.62, height: r*0.48),
        Radius.circular(r*0.10),
      ),
      Paint()..color = dBrown,
    );
    canvas.drawOval(
      Rect.fromCenter(center: c + Offset(0, -r*0.80), width: r*0.82, height: r*0.22),
      Paint()..color = const Color(0xFFC4A050).withValues(alpha: opacity),
    );
    // 금화
    canvas.drawCircle(c + Offset(r*0.10, r*0.24), r*0.28, Paint()..color = gold);
    canvas.drawCircle(c + Offset(r*0.10, r*0.24), r*0.28,
      Paint()..color = const Color(0xFFB8860B).withValues(alpha: opacity)..style = PaintingStyle.stroke..strokeWidth = 1.4);
    canvas.drawLine(c + Offset(r*0.10, r*0.01), c + Offset(r*0.10, r*0.46),
      Paint()..color = const Color(0xFFB8860B).withValues(alpha: opacity)..strokeWidth = 1.6);
  }

  // ── 보물 상자 (Treasure) ─────────────────────────────────────────────────

  void _drawChest(Canvas canvas, Offset c, double r, double opacity) {
    final wood  = const Color(0xFF7B3B10).withValues(alpha: opacity);
    final dWood = const Color(0xFF4A2208).withValues(alpha: opacity);
    final gold  = const Color(0xFFFFD700).withValues(alpha: opacity);

    // 몸통
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c + Offset(0, r*0.30), width: r*1.78, height: r*0.92),
        Radius.circular(r*0.10),
      ),
      Paint()..color = wood,
    );
    // 가로 금속 띠
    canvas.drawRect(
      Rect.fromCenter(center: c + Offset(0, r*0.30), width: r*1.78, height: r*0.10),
      Paint()..color = gold..color = const Color(0xFFFFD700).withValues(alpha: opacity * 0.75),
    );
    // 뚜껑 (약간 열림)
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - r*0.89, c.dy - r*0.12)
        ..lineTo(c.dx + r*0.89, c.dy - r*0.12)
        ..lineTo(c.dx + r*0.91, c.dy - r*0.58)
        ..arcToPoint(Offset(c.dx - r*0.91, c.dy - r*0.58),
            radius: Radius.circular(r*0.18), clockwise: false)
        ..close(),
      Paint()..color = dWood,
    );
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - r*0.89, c.dy - r*0.12)
        ..lineTo(c.dx + r*0.89, c.dy - r*0.12)
        ..lineTo(c.dx + r*0.91, c.dy - r*0.58)
        ..arcToPoint(Offset(c.dx - r*0.91, c.dy - r*0.58),
            radius: Radius.circular(r*0.18), clockwise: false)
        ..close(),
      Paint()..color = gold..color = const Color(0xFFFFD700).withValues(alpha: opacity * 0.65)..style = PaintingStyle.stroke..strokeWidth = 1.4,
    );
    // 잠금장치
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c + Offset(0, r*0.10), width: r*0.36, height: r*0.40),
        Radius.circular(r*0.07),
      ),
      Paint()..color = gold,
    );
    // 내부 황금빛
    canvas.drawOval(
      Rect.fromCenter(center: c + Offset(0, -r*0.40), width: r*0.95, height: r*0.20),
      Paint()
        ..color      = const Color(0xFFFFD700).withValues(alpha: opacity * 0.42)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  // ── 신비 문양 (Event) ─────────────────────────────────────────────────────

  void _drawMystic(Canvas canvas, Offset c, double r, double opacity) {
    const blue = Color(0xFF29B6F6);

    // 배경 글로우
    canvas.drawCircle(c, r * 0.82,
      Paint()
        ..color      = const Color(0xFF0288D1).withValues(alpha: opacity * 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));

    final qPaint = Paint()
      ..color       = blue.withValues(alpha: opacity)
      ..style       = PaintingStyle.stroke
      ..strokeWidth  = r * 0.20
      ..strokeCap   = StrokeCap.round;

    // '?' 호
    canvas.drawArc(
      Rect.fromCenter(center: c + Offset(0, -r*0.26), width: r*0.85, height: r*0.85),
      math.pi * 0.85, math.pi * 1.30, false, qPaint,
    );
    // '?' 세로
    canvas.drawLine(c + Offset(0, r*0.10), c + Offset(0, r*0.34), qPaint);
    // '?' 점
    canvas.drawCircle(c + Offset(0, r*0.58), r*0.10,
        Paint()..color = blue.withValues(alpha: opacity));

    // 파티클
    final pPaint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    for (final (dx, dy, pr, pa) in [
      (-0.65, -0.42, 0.07, 0.68),
      ( 0.70, -0.28, 0.06, 0.52),
      (-0.52,  0.48, 0.08, 0.60),
      ( 0.58,  0.52, 0.05, 0.48),
    ]) {
      canvas.drawCircle(c + Offset(r*dx, r*dy), r*pr,
          pPaint..color = blue.withValues(alpha: opacity * pa));
    }
  }

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
