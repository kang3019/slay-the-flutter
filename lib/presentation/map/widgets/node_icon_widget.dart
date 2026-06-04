import 'package:flutter/material.dart';

import '../../../domain/map/node_type.dart';
import '../map_constants.dart';
import 'node_icon_draw.dart';

/// 맵 노드 아이콘을 MapPainter와 동일한 드로잉으로 렌더링하는 위젯.
///
/// [size]: 위젯의 가로·세로 크기(dp). 기본 40.
class NodeIconWidget extends StatelessWidget {
  final NodeType type;
  final double size;

  const NodeIconWidget(this.type, {super.key, this.size = 40});

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(size, size),
        painter: _NodeIconPainter(type, MapColors.forType(type)),
      );
}

class _NodeIconPainter extends CustomPainter {
  final NodeType type;
  final Color nodeColor;

  const _NodeIconPainter(this.type, this.nodeColor);

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);

    // 어두운 원형 배경
    canvas.drawCircle(c, r * 0.96, Paint()..color = Colors.black87);

    // 타입 색상 테두리
    canvas.drawCircle(
      c, r * 0.96,
      Paint()
        ..color      = nodeColor
        ..style      = PaintingStyle.stroke
        ..strokeWidth = r * 0.10,
    );

    // MapPainter와 동일한 아이콘 — NodeIconDraw 공유
    NodeIconDraw.drawIcon(canvas, type, c, r * 0.52, 1.0);
  }

  @override
  bool shouldRepaint(covariant _NodeIconPainter old) =>
      old.type != type || old.nodeColor != nodeColor;
}
