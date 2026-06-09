import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/run_provider.dart';
import '../../domain/entities/player.dart';
import '../map/widgets/map_painter.dart';

/// 이벤트·강화 화면에서 현재 지도를 확인하는 읽기 전용 바텀시트.
///
/// 노드를 탭해도 이동하지 않는다. 상태(HP·골드·층) 표시와 지도 스크롤만 제공한다.
class MapOverlaySheet extends ConsumerWidget {
  const MapOverlaySheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final run = ref.watch(runProvider);
    final screenH = MediaQuery.sizeOf(context).height;

    final hpRatio = run.playerHp / Player.maxHp;
    final hpColor = hpRatio > 0.5
        ? const Color(0xFF66BB6A)
        : hpRatio > 0.25
            ? const Color(0xFFFFB300)
            : const Color(0xFFEF5350);

    final floorLabel = run.floor < 0 ? '시작' : '${run.floor + 1}F';

    return Container(
      height: screenH * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF090D18),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          // 핸들
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          // 상태 표시줄
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.layers_outlined,
                    size: 13, color: Color(0xFFB8860B)),
                const SizedBox(width: 5),
                Text(
                  floorLabel,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.favorite, size: 13, color: hpColor),
                const SizedBox(width: 5),
                Text(
                  '${run.playerHp} / ${Player.maxHp}',
                  style: TextStyle(
                    color: hpColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.monetization_on,
                    size: 13, color: Color(0xFFFFD700)),
                const SizedBox(width: 5),
                Text(
                  '${run.gold} G',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close,
                      color: Colors.white38, size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  const Color(0xFFFFD700).withValues(alpha: 0.40),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // 지도 캔버스 (읽기 전용)
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final canvasSize =
                    computeCanvasSize(run.mapNodes, constraints.maxWidth);
                return SingleChildScrollView(
                  reverse: true,
                  child: CustomPaint(
                    size: canvasSize,
                    painter: MapPainter(
                      nodes: run.mapNodes,
                      currentNodeId: run.currentNodeId,
                      visitedNodeIds: run.visitedNodeIds,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
