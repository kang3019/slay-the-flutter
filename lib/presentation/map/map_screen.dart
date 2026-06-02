import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/run_provider.dart';
import '../../domain/map/map_node.dart';
import 'map_constants.dart';
import 'widgets/map_painter.dart';

// ──────────────────────────────────────────────────────────────────────────
// MapScreen
// ──────────────────────────────────────────────────────────────────────────

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final run = ref.watch(runProvider);

    return Scaffold(
      backgroundColor: MapColors.background,
      body: Column(
        children: [
          _GothicAppBar(run: run),
          Expanded(
            child: _MapCanvas(
              nodes: run.mapNodes,
              currentNodeId: run.currentNodeId,
              visitedNodeIds: run.visitedNodeIds,
              isRunOver: run.isRunOver,
              onNodeTapped: (id) => ref.read(runProvider.notifier).moveToNode(id),
            ),
          ),
          _ParchmentHintBar(
            nodes: run.mapNodes,
            currentNodeId: run.currentNodeId,
            isRunOver: run.isRunOver,
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// _GothicAppBar — 철제 프레임 판타지 상단바
// ──────────────────────────────────────────────────────────────────────────

class _GothicAppBar extends StatelessWidget {
  final RunState run;
  const _GothicAppBar({required this.run});

  @override
  Widget build(BuildContext context) {
    final floorLabel = run.currentNodeId == null
        ? '⬥ ⬥ ⬥'
        : '${MapStrings.floorPrefix} ${run.floor + 1}';

    return SafeArea(
      bottom: false,
      child: Container(
        color: const Color(0xFF090D18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 왼쪽 장식선
                  _GoldDivider(flex: 1),
                  const SizedBox(width: 12),

                  // 타이틀 (황금 그라디언트)
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFB8860B), Color(0xFFFFD700), Color(0xFFFFF8DC), Color(0xFFFFD700), Color(0xFFB8860B)],
                      stops: [0.0, 0.25, 0.50, 0.75, 1.0],
                    ).createShader(bounds),
                    child: const Text(
                      MapStrings.screenTitle,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 오른쪽 장식선 + 층 표시
                  _GoldDivider(flex: 1),
                  const SizedBox(width: 10),
                  Text(
                    floorLabel,
                    style: const TextStyle(
                      color: MapColors.ringCurrent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // 황금 구분선
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    const Color(0xFFFFD700).withValues(alpha: 0.55),
                    const Color(0xFFFFD700).withValues(alpha: 0.55),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.2, 0.8, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 황금 그라디언트 수평 구분선 위젯.
class _GoldDivider extends StatelessWidget {
  final int flex;
  const _GoldDivider({required this.flex});

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Container(
          height: 1,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, Color(0x88FFD700)],
            ),
          ),
        ),
      );
}

// ──────────────────────────────────────────────────────────────────────────
// _MapCanvas — 세로 스크롤 + 자동 스크롤
// ──────────────────────────────────────────────────────────────────────────

class _MapCanvas extends StatefulWidget {
  const _MapCanvas({
    required this.nodes,
    required this.currentNodeId,
    required this.visitedNodeIds,
    required this.isRunOver,
    required this.onNodeTapped,
  });

  final List<MapNode> nodes;
  final String? currentNodeId;
  final List<String> visitedNodeIds;
  final bool isRunOver;
  final void Function(String nodeId) onNodeTapped;

  @override
  State<_MapCanvas> createState() => _MapCanvasState();
}

class _MapCanvasState extends State<_MapCanvas> {
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void didUpdateWidget(_MapCanvas old) {
    super.didUpdateWidget(old);
    if (old.currentNodeId != widget.currentNodeId) _scrollToCurrentNode();
  }

  void _scrollToCurrentNode() {
    final nodeId = widget.currentNodeId;
    if (nodeId == null) return;

    final node = widget.nodes.where((n) => n.id == nodeId).firstOrNull;
    if (node == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      final distFromBottom = MapSizes.paddingV + node.floor * MapSizes.floorHeight;
      final viewH   = _scrollCtrl.position.viewportDimension;
      final target  = (distFromBottom - viewH / 2)
          .clamp(0.0, _scrollCtrl.position.maxScrollExtent);
      _scrollCtrl.animateTo(target,
          duration: const Duration(milliseconds: 450), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = computeCanvasSize(widget.nodes, constraints.maxWidth);
        return SingleChildScrollView(
          controller: _scrollCtrl,
          reverse: true,
          child: GestureDetector(
            onTapUp: widget.isRunOver ? null : (d) => _onTap(d, canvasSize),
            child: CustomPaint(
              size: canvasSize,
              painter: MapPainter(
                nodes: widget.nodes,
                currentNodeId: widget.currentNodeId,
                visitedNodeIds: widget.visitedNodeIds,
              ),
            ),
          ),
        );
      },
    );
  }

  void _onTap(TapUpDetails details, Size canvasSize) {
    final tapPos    = details.localPosition;
    final positions = computeNodePositions(widget.nodes, canvasSize);
    const hitRadius = MapSizes.nodeRadius + MapSizes.hitSlop;
    for (final entry in positions.entries) {
      if ((entry.value - tapPos).distance <= hitRadius) {
        widget.onNodeTapped(entry.key);
        return;
      }
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }
}

// ──────────────────────────────────────────────────────────────────────────
// _ParchmentHintBar — 양피지 두루마리 스타일 하단 안내바
// ──────────────────────────────────────────────────────────────────────────

class _ParchmentHintBar extends StatelessWidget {
  const _ParchmentHintBar({
    required this.nodes,
    required this.currentNodeId,
    required this.isRunOver,
  });

  final List<MapNode> nodes;
  final String? currentNodeId;
  final bool isRunOver;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A0F06), Color(0xFF251508)],
        ),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFFFD700).withValues(alpha: 0.28),
            width: 1,
          ),
        ),
      ),
      child: Stack(
        children: [
          // 양피지 텍스처 레이어
          Positioned.fill(
            child: CustomPaint(painter: _ParchmentTexturePainter()),
          ),
          // 텍스트
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isRunOver && currentNodeId != null) ...[
                  const Text('⬥ ', style: TextStyle(color: Color(0xFFFFD700), fontSize: 10)),
                ],
                Flexible(
                  child: Text(
                    _message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 13,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ),
                if (!isRunOver && currentNodeId != null) ...[
                  const Text(' ⬥', style: TextStyle(color: Color(0xFFFFD700), fontSize: 10)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _message {
    if (isRunOver) return MapStrings.hintRunOver;
    if (currentNodeId == null) return MapStrings.hintFirst;
    final current = _findNode(currentNodeId!);
    if (current == null) return MapStrings.hintMove;
    final label = MapStrings.labelFor(current.type);
    return '$label  →  ${MapStrings.hintMove}';
  }

  Color get _textColor {
    if (isRunOver) return Colors.redAccent;
    if (currentNodeId == null) return const Color(0xFFFFD700);
    return const Color(0xFFD4B896);
  }

  MapNode? _findNode(String id) {
    try {
      return nodes.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// 양피지 질감을 표현하는 배경 페인터.
class _ParchmentTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.018);
    for (int i = 0; i < 12; i++) {
      final x = (i * 43.7) % size.width;
      final w = 18.0 + (i * 11) % 30;
      canvas.drawRect(Rect.fromLTWH(x, 0, w, size.height), p);
    }
    // 상단 얇은 황금 하이라이트
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, 1),
      Paint()..color = const Color(0xFFFFD700).withValues(alpha: 0.06),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
