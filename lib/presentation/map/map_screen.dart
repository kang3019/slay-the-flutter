import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/run_provider.dart';
import '../../domain/map/map_node.dart';
import 'map_constants.dart';
import 'widgets/map_painter.dart';

// ──────────────────────────────────────────────────────────────────────────
// MapScreen — 공개 진입점
// ──────────────────────────────────────────────────────────────────────────

/// 던전 맵 화면.
///
/// [runProvider]를 구독해 런 상태를 가져오고 [_MapCanvas]에 전달한다.
/// 맵은 세로 스크롤 가능하며 현재 위치로 자동 스크롤된다.
class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final run = ref.watch(runProvider);

    return Scaffold(
      backgroundColor: MapColors.background,
      appBar: _buildAppBar(run),
      body: Column(
        children: [
          Expanded(
            child: _MapCanvas(
              nodes: run.mapNodes,
              currentNodeId: run.currentNodeId,
              visitedNodeIds: run.visitedNodeIds,
              isRunOver: run.isRunOver,
              onNodeTapped: (id) => ref.read(runProvider.notifier).moveToNode(id),
            ),
          ),
          _BottomHintBar(
            nodes: run.mapNodes,
            currentNodeId: run.currentNodeId,
            isRunOver: run.isRunOver,
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(RunState run) {
    final floorLabel = run.currentNodeId == null
        ? '— — —'
        : '${MapStrings.floorPrefix} ${run.floor + 1}';

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: const Text(
        MapStrings.screenTitle,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          fontSize: 18,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20.0),
          child: Center(
            child: Text(
              floorLabel,
              style: const TextStyle(
                color: MapColors.ringCurrent,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// _MapCanvas — 스크롤 가능 캔버스 + 탭 인식
// ──────────────────────────────────────────────────────────────────────────

/// 세로 스크롤 가능한 맵 캔버스 위젯.
///
/// [SingleChildScrollView]를 사용해 7~10층 맵이 화면을 넘을 때 스크롤된다.
/// [reverse: true]로 Floor 0(시작)이 아래에, 보스가 위에 표시된다.
/// 현재 노드([currentNodeId])가 바뀌면 해당 노드가 화면 중앙에 오도록 자동 스크롤한다.
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
    if (old.currentNodeId != widget.currentNodeId) {
      _scrollToCurrentNode();
    }
  }

  /// 현재 노드가 화면 중앙에 오도록 부드럽게 스크롤한다.
  ///
  /// [SingleChildScrollView] reverse=true 환경에서 offset은
  /// "캔버스 하단으로부터의 거리"를 의미한다.
  void _scrollToCurrentNode() {
    final nodeId = widget.currentNodeId;
    if (nodeId == null) return;

    final currentNode = widget.nodes
        .where((n) => n.id == nodeId)
        .firstOrNull;
    if (currentNode == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;

      // 현재 노드의 캔버스 하단으로부터 거리
      final distFromBottom =
          MapSizes.paddingV + currentNode.floor * MapSizes.floorHeight;

      final viewportHeight = _scrollCtrl.position.viewportDimension;
      final target = (distFromBottom - viewportHeight / 2)
          .clamp(0.0, _scrollCtrl.position.maxScrollExtent);

      _scrollCtrl.animateTo(
        target,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = computeCanvasSize(widget.nodes, constraints.maxWidth);

        return SingleChildScrollView(
          controller: _scrollCtrl,
          // reverse: true → 콘텐츠가 아래서 위로 쌓임.
          // Floor 0(시작)이 하단에 보이고 보스가 상단에 배치된다.
          reverse: true,
          child: GestureDetector(
            onTapUp: widget.isRunOver
                ? null
                : (d) => _onTap(d, canvasSize),
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

  /// 탭 좌표를 분석해 어느 노드를 탭했는지 판별하고 [onNodeTapped]를 호출한다.
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
// _BottomHintBar — 하단 안내 바
// ──────────────────────────────────────────────────────────────────────────

/// 현재 런 상태에 따라 플레이어에게 다음 행동을 안내하는 하단 바.
class _BottomHintBar extends StatelessWidget {
  const _BottomHintBar({
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
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white12)),
        color: Color(0xFF0D1B2A),
      ),
      child: Text(
        _message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _color,
          fontSize: 13,
          letterSpacing: 0.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String get _message {
    if (isRunOver) return MapStrings.hintRunOver;
    if (currentNodeId == null) return MapStrings.hintFirst;

    final current = _findNode(currentNodeId!);
    if (current == null) return MapStrings.hintMove;

    final icon  = MapStrings.iconFor(current.type);
    final label = MapStrings.labelFor(current.type);
    return '$icon $label  →  ${MapStrings.hintMove}';
  }

  Color get _color {
    if (isRunOver) return Colors.redAccent;
    if (currentNodeId == null) return MapColors.ringCurrent;
    return Colors.white70;
  }

  MapNode? _findNode(String id) {
    try {
      return nodes.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }
}
