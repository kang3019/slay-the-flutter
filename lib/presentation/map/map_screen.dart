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
/// [runProvider]를 구독해 현재 런 상태(맵 노드, 현재 위치, 방문 이력)를 가져오고
/// [_MapCanvas]에 전달해 DAG 형태의 맵을 렌더링한다.
///
/// **데이터 흐름:**
/// ```
/// runProvider(RunState)
///   └─ MapScreen.build()       ← ref.watch
///       └─ _MapCanvas          ← nodes, currentNodeId, visitedNodeIds
///           ├─ MapPainter      ← 시각 렌더링 (CustomPainter)
///           └─ GestureDetector ← 탭 → moveToNode(id)
/// ```
///
/// UI 로직(상호작용·표시)만 담당하며, 비즈니스 로직은 [RunNotifier]에 위임한다.
class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch: RunState가 바뀔 때마다 이 build가 자동으로 재실행된다.
    final run = ref.watch(runProvider);

    return Scaffold(
      backgroundColor: MapColors.background,
      appBar: _buildAppBar(run),
      body: Column(
        children: [
          // ── 맵 캔버스 (화면 대부분을 차지) ───────────────────────────
          Expanded(
            child: _MapCanvas(
              nodes: run.mapNodes,
              currentNodeId: run.currentNodeId,
              visitedNodeIds: run.visitedNodeIds,
              isRunOver: run.isRunOver,
              // 탭 시 Application 계층 Notifier에 이동 요청만 전달한다.
              // GestureDetector → RunNotifier.moveToNode() — 비즈니스 로직은
              // Application 계층에 있으며, 여기서는 ID만 전달한다.
              onNodeTapped: (id) =>
                  ref.read(runProvider.notifier).moveToNode(id),
            ),
          ),

          // ── 하단 힌트 바 ─────────────────────────────────────────────
          _BottomHintBar(
            nodes: run.mapNodes,
            currentNodeId: run.currentNodeId,
            isRunOver: run.isRunOver,
          ),
        ],
      ),
    );
  }

  /// 앱 바: 타이틀 + 현재 층 표시.
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
// _MapCanvas — 캔버스 + 탭 인식
// ──────────────────────────────────────────────────────────────────────────

/// [CustomPaint]와 [GestureDetector]를 결합한 맵 캔버스 위젯.
///
/// **탭 인식 원리:**
/// [LayoutBuilder]로 실제 렌더링 크기를 얻고,
/// 동일한 [computeNodePositions] 함수를 사용해 "어느 노드가 탭됐는지"를
/// 픽셀 거리로 판별한다. Painter와 GestureDetector가 같은 좌표 함수를 공유하므로
/// "그려지는 위치 = 탭 인식 위치"가 항상 일치한다.
class _MapCanvas extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // LayoutBuilder: 이 위젯이 실제로 할당받은 크기를 런타임에 얻는다.
    // MediaQuery.of(context).size 대신 사용하는 이유:
    //   - AppBar·BottomBar 등을 제외한 정확한 캔버스 영역 크기를 알 수 있다.
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(
          // 런이 종료되면 탭을 비활성화한다.
          onTapUp: isRunOver ? null : (d) => _onTap(d, canvasSize),
          child: CustomPaint(
            size: canvasSize,
            painter: MapPainter(
              nodes: nodes,
              currentNodeId: currentNodeId,
              visitedNodeIds: visitedNodeIds,
            ),
          ),
        );
      },
    );
  }

  /// 탭 좌표를 분석해 어느 노드를 탭했는지 판별하고 [onNodeTapped]를 호출한다.
  ///
  /// **히트 테스트 알고리즘:**
  /// 1. [computeNodePositions]으로 각 노드의 캔버스 좌표를 계산한다.
  /// 2. 탭 좌표와 각 노드 중심 사이의 거리를 비교한다.
  /// 3. 거리가 `nodeRadius + hitSlop` 이하인 노드가 있으면 그 노드를 선택한다.
  void _onTap(TapUpDetails details, Size canvasSize) {
    final tapPos = details.localPosition;

    // Painter와 동일한 좌표 함수를 사용 → "그려지는 위치 = 탭 위치" 보장.
    final positions = computeNodePositions(nodes, canvasSize);

    // 탭 인식 반경 = 노드 반지름 + 여유 간격(hitSlop).
    const hitRadius = MapSizes.nodeRadius + MapSizes.hitSlop;

    for (final entry in positions.entries) {
      if ((entry.value - tapPos).distance <= hitRadius) {
        // RunNotifier.moveToNode()가 이동 가능 여부를 내부에서 검증한다.
        // Presentation 계층은 ID만 전달하면 된다.
        onNodeTapped(entry.key);
        return;
      }
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────
// _BottomHintBar — 하단 안내 바
// ──────────────────────────────────────────────────────────────────────────

/// 현재 런 상태에 따라 플레이어에게 다음 행동을 안내하는 하단 바.
///
/// 표시 규칙:
/// - 런 종료 → 종료 메시지 (빨간색)
/// - 미시작  → "출발 방을 선택하세요" (금색)
/// - 진행 중 → 현재 노드 이름 + "→ 다음 방 선택" (흰색)
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

    // "⚔️ 일반 전투  →  다음 방을 선택하세요" 형식
    final icon  = MapStrings.iconFor(current.type);
    final label = MapStrings.labelFor(current.type);
    return '$icon $label  →  ${MapStrings.hintMove}';
  }

  Color get _color {
    if (isRunOver) return Colors.redAccent;
    if (currentNodeId == null) return MapColors.ringCurrent;
    return Colors.white70;
  }

  /// nodes 리스트에서 [id]에 해당하는 노드를 찾는다.
  /// 없으면 null을 반환한다 (try/catch 패턴으로 firstWhere 예외를 처리).
  MapNode? _findNode(String id) {
    try {
      return nodes.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }
}
