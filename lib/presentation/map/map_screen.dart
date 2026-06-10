import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/run_provider.dart';
import '../../domain/entities/card.dart';
import '../../domain/entities/player.dart';
import '../../domain/map/map_node.dart';
import '../../domain/map/node_type.dart';
import '../save_slot/save_slot_screen.dart';
import '../settings/settings_screen.dart';
import 'map_constants.dart';
import 'widgets/deck_view_sheet.dart';
import 'widgets/map_painter.dart';
import 'widgets/node_icon_widget.dart';

// ──────────────────────────────────────────────────────────────────────────
// MapScreen
// ──────────────────────────────────────────────────────────────────────────

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  @override
  Widget build(BuildContext context) {
    final run = ref.watch(runProvider);

    return Scaffold(
      backgroundColor: MapColors.background,
      body: Column(
        children: [
          _GothicAppBar(
            run: run,
            onSettingsTap: () => _showSettings(context, ref),
            onLegendTap: () => _showLegend(context),
            onDeckTap: () => _showDeckViewer(context, run.deck),
          ),
          Expanded(
            child: _MapCanvas(
              nodes: run.mapNodes,
              currentNodeId: run.currentNodeId,
              visitedNodeIds: run.visitedNodeIds,
              isRunOver: run.isRunOver,
              onNodeTapped: (id) => ref.read(runProvider.notifier).moveToNode(id),
            ),
          ),
          // 노드 범례 스트립 — 첫 이동 전에만 자동 표시
          if (run.currentNodeId == null && !run.isRunOver)
            const _LegendStrip(),
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

void _showDeckViewer(BuildContext context, List<GameCard> deck) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF0D1220),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => DeckViewSheet(deck: deck),
  );
}

void _showLegend(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF0D1220),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      final maxH = MediaQuery.sizeOf(ctx).height * 0.65;
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: const _LegendSheet(),
      );
    },
  );
}

void _showSettings(BuildContext context, WidgetRef ref) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF0D1220),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _SettingsSheet(
      onNewRun: () {
        Navigator.pop(context);
        ref.read(runProvider.notifier).startNewRun();
      },
      onSaveSlot: () {
        Navigator.pop(context);
        Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => SaveSlotScreen(
              onSlotLoaded: () => Navigator.pop(context),
            ),
          ),
        );
      },
      onSettings: () {
        Navigator.pop(context);
        Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
      },
    ),
  );
}

// ──────────────────────────────────────────────────────────────────────────
// _SettingsSheet — 설정 바텀시트
// ──────────────────────────────────────────────────────────────────────────

class _SettingsSheet extends StatelessWidget {
  final VoidCallback onNewRun;
  final VoidCallback onSaveSlot;
  final VoidCallback onSettings;
  const _SettingsSheet({
    required this.onNewRun,
    required this.onSaveSlot,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 손잡이 핸들
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [Color(0xFFB8860B), Color(0xFFFFD700), Color(0xFFB8860B)],
              ).createShader(b),
              child: const Text(
                '설  정',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 6,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _SettingsTile(
              icon: Icons.save_outlined,
              label: '세이브 슬롯',
              color: const Color(0xFFF59E0B),
              onTap: onSaveSlot,
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.tune,
              label: '설정',
              color: const Color(0xFF64B5F6),
              onTap: onSettings,
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.refresh,
              label: '새 런 시작',
              color: const Color(0xFFEF5350),
              onTap: onNewRun,
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.close,
              label: '닫기',
              color: Colors.white54,
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// _GothicAppBar — 철제 프레임 판타지 상단바
// ──────────────────────────────────────────────────────────────────────────

class _GothicAppBar extends StatelessWidget {
  final RunState run;
  final VoidCallback onSettingsTap;
  final VoidCallback onLegendTap;
  final VoidCallback onDeckTap;
  const _GothicAppBar({
    required this.run,
    required this.onSettingsTap,
    required this.onLegendTap,
    required this.onDeckTap,
  });

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

            // 상태 바 (HP / 덱 / 골드 / 범례 / 설정)
            _RunStatusBar(
              run: run,
              onSettingsTap: onSettingsTap,
              onLegendTap: onLegendTap,
              onDeckTap: onDeckTap,
            ),

            // 하단 구분선
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    const Color(0xFFFFD700).withValues(alpha: 0.22),
                    const Color(0xFFFFD700).withValues(alpha: 0.22),
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

// ──────────────────────────────────────────────────────────────────────────
// _RunStatusBar — HP / 덱 / 골드 / 설정 한 줄 상태 바
// ──────────────────────────────────────────────────────────────────────────

class _RunStatusBar extends StatelessWidget {
  final RunState run;
  final VoidCallback onSettingsTap;
  final VoidCallback onLegendTap;
  final VoidCallback onDeckTap;
  const _RunStatusBar({
    required this.run,
    required this.onSettingsTap,
    required this.onLegendTap,
    required this.onDeckTap,
  });

  @override
  Widget build(BuildContext context) {
    final hpRatio  = run.playerHp / Player.maxHp;
    final hpColor  = hpRatio > 0.5
        ? const Color(0xFF66BB6A)
        : hpRatio > 0.25
            ? const Color(0xFFFFB300)
            : const Color(0xFFEF5350);

    return Container(
      color: const Color(0xFF07090F),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Row(
        children: [
          // HP
          _StatChip(
            icon: Icons.favorite,
            color: hpColor,
            label: '${run.playerHp} / ${Player.maxHp}',
          ),
          const SizedBox(width: 16),
          // 덱 — 탭 시 덱 목록 표시
          GestureDetector(
            onTap: onDeckTap,
            child: _StatChip(
              icon: Icons.style,
              color: const Color(0xFF64B5F6),
              label: '${run.deck.length}장',
            ),
          ),
          const Spacer(),
          // 골드
          _StatChip(
            icon: Icons.toll,
            color: const Color(0xFFFFD700),
            label: '${run.gold} G',
          ),
          const SizedBox(width: 4),
          // 범례
          _IconButton(icon: Icons.help_outline, onTap: onLegendTap),
          const SizedBox(width: 6),
          // 설정
          _IconButton(icon: Icons.settings, onTap: onSettingsTap),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Icon(icon, color: Colors.white54, size: 16),
        ),
      );
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  const _StatChip({required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// _LegendSheet — 노드 아이콘 범례 바텀시트
// ──────────────────────────────────────────────────────────────────────────

// ──────────────────────────────────────────────────────────────────────────
// _LegendStrip — 게임 시작 전 자동 표시되는 인라인 범례
// ──────────────────────────────────────────────────────────────────────────

class _LegendStrip extends StatelessWidget {
  const _LegendStrip();

  static const _types = NodeType.values;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF080B14),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFFFD700).withValues(alpha: 0.20),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '— 출발 방을 선택하세요 —',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                for (final type in _types) _LegendStripItem(type: type),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '위에 있는 ',
                style: TextStyle(color: Colors.white38, fontSize: 10),
              ),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.help_outline, size: 11, color: Colors.white38),
              ),
              const Text(
                ' 을 클릭하여 다시 볼 수 있습니다',
                style: TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _LegendStripItem extends StatelessWidget {
  final NodeType type;
  const _LegendStripItem({required this.type});

  @override
  Widget build(BuildContext context) {
    final color = MapColors.forType(type);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NodeIconWidget(type, size: 40),
          const SizedBox(height: 5),
          Text(
            MapStrings.labelFor(type),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// _LegendSheet — ? 버튼으로 접근하는 상세 범례 바텀시트
// ──────────────────────────────────────────────────────────────────────────

class _LegendSheet extends StatelessWidget {
  const _LegendSheet();

  static const _entries = [
    (NodeType.monster,  '카드 전투, 승리 시 카드·골드 보상'),
    (NodeType.elite,    '강화된 몬스터, 추가 유물 보상'),
    (NodeType.boss,     '챕터 최종 전투, 클리어 시 진행'),
    (NodeType.rest,     'HP 회복 또는 카드 1장 강화'),
    (NodeType.shop,     '골드로 카드·유물 구매, 카드 제거'),
    (NodeType.treasure, '유물 1개 무료 획득'),
    (NodeType.event,    '무작위 이벤트, 선택에 따라 이득·손해'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [Color(0xFFB8860B), Color(0xFFFFD700), Color(0xFFB8860B)],
              ).createShader(b),
              child: const Text(
                '노드 범례',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 5,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(vertical: 12),
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
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.6,
              children: [
                for (final (type, desc) in _entries)
                  _LegendTile(type: type, desc: desc),
              ],
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _LegendTile extends StatelessWidget {
  final NodeType type;
  final String desc;
  const _LegendTile({required this.type, required this.desc});

  @override
  Widget build(BuildContext context) {
    final color = MapColors.forType(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          NodeIconWidget(type, size: 36),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  MapStrings.labelFor(type),
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 9,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
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
