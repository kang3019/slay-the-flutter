import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/map/node_type.dart';

/// MapPainter와 NodeIconWidget이 공유하는 노드 아이콘 드로잉 유틸리티.
///
/// 모든 메서드는 static — 인스턴스 불필요.
/// [c]: 캔버스 중심, [r]: 아이콘 반경, [opacity]: 0.0~1.0.
abstract final class NodeIconDraw {
  static void drawIcon(
      Canvas canvas, NodeType type, Offset c, double r, double opacity) {
    switch (type) {
      case NodeType.monster:  drawSkull(canvas, c, r, opacity, isElite: false);
      case NodeType.elite:    drawSkull(canvas, c, r, opacity, isElite: true);
      case NodeType.boss:     drawCrown(canvas, c, r, opacity);
      case NodeType.rest:     drawFlame(canvas, c, r, opacity);
      case NodeType.shop:     drawPouch(canvas, c, r, opacity);
      case NodeType.treasure: drawChest(canvas, c, r, opacity);
      case NodeType.event:    drawMystic(canvas, c, r, opacity);
    }
  }

  // ── 해골 (Monster / Elite) ─────────────────────────────────────────────

  static void drawSkull(Canvas canvas, Offset c, double r, double opacity,
      {required bool isElite}) {
    final bone = const Color(0xFFDDD5C0).withValues(alpha: opacity);
    final dark = const Color(0xFF06080E).withValues(alpha: opacity);

    if (isElite) {
      final hornP = Paint()
        ..color      = bone
        ..style      = PaintingStyle.stroke
        ..strokeWidth = r * 0.20
        ..strokeCap  = StrokeCap.round;
      canvas.drawPath(
          Path()
            ..moveTo(c.dx - r * 0.26, c.dy - r * 0.68)
            ..quadraticBezierTo(
                c.dx - r * 0.65, c.dy - r * 1.25, c.dx - r * 0.48, c.dy - r * 1.48),
          hornP);
      canvas.drawPath(
          Path()
            ..moveTo(c.dx + r * 0.26, c.dy - r * 0.68)
            ..quadraticBezierTo(
                c.dx + r * 0.65, c.dy - r * 1.25, c.dx + r * 0.48, c.dy - r * 1.48),
          hornP);
    }

    canvas.drawOval(
        Rect.fromCenter(center: c + Offset(0, -r * 0.16), width: r * 1.52, height: r * 1.22),
        Paint()..color = bone);
    canvas.drawOval(
        Rect.fromCenter(center: c + Offset(0, r * 0.56), width: r * 1.08, height: r * 0.50),
        Paint()..color = bone);
    for (final dx in [-0.33, 0.33]) {
      canvas.drawOval(
          Rect.fromCenter(
              center: c + Offset(r * dx, -r * 0.20), width: r * 0.48, height: r * 0.38),
          Paint()..color = dark);
    }
    final eyeP = Paint()
      ..color      = const Color(0xFFFF2020).withValues(alpha: opacity * 0.88)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    for (final dx in [-0.33, 0.33]) {
      canvas.drawOval(
          Rect.fromCenter(
              center: c + Offset(r * dx, -r * 0.22), width: r * 0.30, height: r * 0.22),
          eyeP);
    }
    canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy + r * 0.06)
          ..lineTo(c.dx - r * 0.12, c.dy + r * 0.27)
          ..lineTo(c.dx + r * 0.12, c.dy + r * 0.27)
          ..close(),
        Paint()..color = dark);
    for (int i = 0; i < 4; i++) {
      final tx = c.dx - r * 0.42 + i * r * 0.285;
      canvas.drawPath(
          Path()
            ..moveTo(tx, c.dy + r * 0.40)
            ..lineTo(tx + r * 0.21, c.dy + r * 0.40)
            ..lineTo(tx + r * 0.105, c.dy + r * 0.68)
            ..close(),
          Paint()..color = bone);
      canvas.drawRect(
          Rect.fromLTWH(tx + r * 0.21 - 0.8, c.dy + r * 0.40, 1.6, r * 0.28),
          Paint()..color = dark);
    }
  }

  // ── 왕관 (Boss) ───────────────────────────────────────────────────────

  static void drawCrown(Canvas canvas, Offset c, double r, double opacity) {
    final gold  = const Color(0xFFFFD700).withValues(alpha: opacity);
    final dGold = const Color(0xFFB8860B).withValues(alpha: opacity);

    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: c + Offset(0, r * 0.35), width: r * 2.0, height: r * 0.60),
            Radius.circular(r * 0.08)),
        Paint()..color = dGold);
    for (final (xi, hi) in [
      (-0.78, -0.28), (-0.39, -0.62), (0.0, -0.92), (0.39, -0.62), (0.78, -0.28)
    ]) {
      canvas.drawPath(
          Path()
            ..moveTo(c.dx + xi * r - r * 0.20, c.dy + r * 0.06)
            ..lineTo(c.dx + xi * r + r * 0.20, c.dy + r * 0.06)
            ..lineTo(c.dx + xi * r, c.dy + hi * r)
            ..close(),
          Paint()..color = gold);
    }
    for (final (xi, color) in [
      (-0.40, const Color(0xFFFF3030)),
      (0.0,   const Color(0xFF3090FF)),
      (0.40,  const Color(0xFFFF3030)),
    ]) {
      canvas.drawCircle(c + Offset(xi * r, r * 0.35), r * 0.13,
          Paint()..color = color.withValues(alpha: opacity));
      canvas.drawCircle(c + Offset(xi * r, r * 0.35), r * 0.13,
          Paint()
            ..color       = Colors.white.withValues(alpha: opacity * 0.35)
            ..style       = PaintingStyle.stroke
            ..strokeWidth = 0.8);
    }
  }

  // ── 불꽃 (Rest) ───────────────────────────────────────────────────────

  static void drawFlame(Canvas canvas, Offset c, double r, double opacity) {
    for (final (dx, color) in [
      (-r * 0.22, const Color(0xFF5C3310)),
      ( r * 0.22, const Color(0xFF4A2208)),
    ]) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: c + Offset(dx, r * 0.72), width: r * 0.75, height: r * 0.20),
              Radius.circular(r * 0.05)),
          Paint()..color = color.withValues(alpha: opacity));
    }
    canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy + r * 0.62)
          ..cubicTo(c.dx - r * 0.52, c.dy + r * 0.18, c.dx - r * 0.62, c.dy - r * 0.22, c.dx, c.dy - r * 0.82)
          ..cubicTo(c.dx + r * 0.10, c.dy - r * 0.42, c.dx + r * 0.35, c.dy - r * 0.56, c.dx + r * 0.22, c.dy - r * 0.18)
          ..cubicTo(c.dx + r * 0.56, c.dy + r * 0.05, c.dx + r * 0.52, c.dy + r * 0.32, c.dx, c.dy + r * 0.62)
          ..close(),
        Paint()..color = const Color(0xFFFF5500).withValues(alpha: opacity));
    canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy + r * 0.42)
          ..cubicTo(c.dx - r * 0.28, c.dy + r * 0.08, c.dx - r * 0.32, c.dy - r * 0.22, c.dx, c.dy - r * 0.60)
          ..cubicTo(c.dx + r * 0.32, c.dy - r * 0.22, c.dx + r * 0.28, c.dy + r * 0.08, c.dx, c.dy + r * 0.42)
          ..close(),
        Paint()..color = const Color(0xFFFF9900).withValues(alpha: opacity));
    canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy + r * 0.22)
          ..cubicTo(c.dx - r * 0.14, c.dy, c.dx - r * 0.14, c.dy - r * 0.32, c.dx, c.dy - r * 0.44)
          ..cubicTo(c.dx + r * 0.14, c.dy - r * 0.32, c.dx + r * 0.14, c.dy, c.dx, c.dy + r * 0.22)
          ..close(),
        Paint()..color = const Color(0xFFFFEE00).withValues(alpha: opacity));
  }

  // ── 주머니 (Shop) ─────────────────────────────────────────────────────

  static void drawPouch(Canvas canvas, Offset c, double r, double opacity) {
    final brown  = const Color(0xFF8B4513).withValues(alpha: opacity);
    final dBrown = const Color(0xFF5C2E0A).withValues(alpha: opacity);
    final gold   = const Color(0xFFFFD700).withValues(alpha: opacity);

    canvas.drawOval(
        Rect.fromCenter(center: c + Offset(0, r * 0.20), width: r * 1.62, height: r * 1.42),
        Paint()..color = brown);
    canvas.drawOval(
        Rect.fromCenter(center: c + Offset(r * 0.28, r * 0.42), width: r * 0.75, height: r * 0.65),
        Paint()..color = const Color(0xFF5C2E0A).withValues(alpha: opacity * 0.45));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: c + Offset(0, -r * 0.56), width: r * 0.62, height: r * 0.48),
            Radius.circular(r * 0.10)),
        Paint()..color = dBrown);
    canvas.drawOval(
        Rect.fromCenter(center: c + Offset(0, -r * 0.80), width: r * 0.82, height: r * 0.22),
        Paint()..color = const Color(0xFFC4A050).withValues(alpha: opacity));
    canvas.drawCircle(c + Offset(r * 0.10, r * 0.24), r * 0.28, Paint()..color = gold);
    canvas.drawCircle(c + Offset(r * 0.10, r * 0.24), r * 0.28,
        Paint()
          ..color       = const Color(0xFFB8860B).withValues(alpha: opacity)
          ..style       = PaintingStyle.stroke
          ..strokeWidth = 1.4);
    canvas.drawLine(c + Offset(r * 0.10, r * 0.01), c + Offset(r * 0.10, r * 0.46),
        Paint()
          ..color       = const Color(0xFFB8860B).withValues(alpha: opacity)
          ..strokeWidth = 1.6);
  }

  // ── 보물 상자 (Treasure) ──────────────────────────────────────────────

  static void drawChest(Canvas canvas, Offset c, double r, double opacity) {
    final wood  = const Color(0xFF7B3B10).withValues(alpha: opacity);
    final dWood = const Color(0xFF4A2208).withValues(alpha: opacity);
    final gold  = const Color(0xFFFFD700).withValues(alpha: opacity);

    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: c + Offset(0, r * 0.30), width: r * 1.78, height: r * 0.92),
            Radius.circular(r * 0.10)),
        Paint()..color = wood);
    canvas.drawRect(
        Rect.fromCenter(center: c + Offset(0, r * 0.30), width: r * 1.78, height: r * 0.10),
        Paint()..color = const Color(0xFFFFD700).withValues(alpha: opacity * 0.75));
    final lidPath = Path()
      ..moveTo(c.dx - r * 0.89, c.dy - r * 0.12)
      ..lineTo(c.dx + r * 0.89, c.dy - r * 0.12)
      ..lineTo(c.dx + r * 0.91, c.dy - r * 0.58)
      ..arcToPoint(Offset(c.dx - r * 0.91, c.dy - r * 0.58),
          radius: Radius.circular(r * 0.18), clockwise: false)
      ..close();
    canvas.drawPath(lidPath, Paint()..color = dWood);
    canvas.drawPath(lidPath,
        Paint()
          ..color       = const Color(0xFFFFD700).withValues(alpha: opacity * 0.65)
          ..style       = PaintingStyle.stroke
          ..strokeWidth = 1.4);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: c + Offset(0, r * 0.10), width: r * 0.36, height: r * 0.40),
            Radius.circular(r * 0.07)),
        Paint()..color = gold);
    canvas.drawOval(
        Rect.fromCenter(center: c + Offset(0, -r * 0.40), width: r * 0.95, height: r * 0.20),
        Paint()
          ..color      = const Color(0xFFFFD700).withValues(alpha: opacity * 0.42)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
  }

  // ── 신비 문양 (Event) ─────────────────────────────────────────────────

  static void drawMystic(Canvas canvas, Offset c, double r, double opacity) {
    const blue = Color(0xFF29B6F6);

    canvas.drawCircle(c, r * 0.82,
        Paint()
          ..color      = const Color(0xFF0288D1).withValues(alpha: opacity * 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));

    final qPaint = Paint()
      ..color       = blue.withValues(alpha: opacity)
      ..style       = PaintingStyle.stroke
      ..strokeWidth = r * 0.20
      ..strokeCap   = StrokeCap.round;
    canvas.drawArc(
        Rect.fromCenter(center: c + Offset(0, -r * 0.26), width: r * 0.85, height: r * 0.85),
        math.pi * 0.85, math.pi * 1.30, false, qPaint);
    canvas.drawLine(c + Offset(0, r * 0.10), c + Offset(0, r * 0.34), qPaint);
    canvas.drawCircle(c + Offset(0, r * 0.58), r * 0.10,
        Paint()..color = blue.withValues(alpha: opacity));

    final pPaint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    for (final (dx, dy, pr, pa) in [
      (-0.65, -0.42, 0.07, 0.68),
      ( 0.70, -0.28, 0.06, 0.52),
      (-0.52,  0.48, 0.08, 0.60),
      ( 0.58,  0.52, 0.05, 0.48),
    ]) {
      canvas.drawCircle(c + Offset(r * dx, r * dy), r * pr,
          pPaint..color = blue.withValues(alpha: opacity * pa));
    }
  }
}
