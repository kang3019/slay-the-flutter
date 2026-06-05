import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/entities/card.dart';
import '../battle_constants.dart';
import 'card_detail_overlay.dart';
import 'card_widget.dart';

/// 플레이어의 손패를 부채꼴(Fan) 레이아웃으로 표시한다.
///
/// 탭: 카드 사용 / 위로 드래그: 드래그 시 카드 사용 / 꾹 누름: 카드 상세 오버레이 표시.
class HandWidget extends StatefulWidget {
  final List<GameCard> hand;
  final int energy;
  final void Function(GameCard) onCardTap;

  const HandWidget({
    super.key,
    required this.hand,
    required this.energy,
    required this.onCardTap,
  });

  @override
  State<HandWidget> createState() => _HandWidgetState();
}

class _HandWidgetState extends State<HandWidget> {
  int? _pressedIndex;
  int? _dragIndex;
  double _dragDy = 0;

  OverlayEntry? _detailEntry;

  static const double _kMaxCardStep  = 58.0;
  static const double _kMinCardStep  = 24.0;
  static const double _kMaxHalfAngle = 12.0 * math.pi / 180;
  static const double _kHandHeight   = 182.0;
  static const double _kSelectedLift = 36.0;
  static const double _kSelectedScale = 1.18;
  /// 드래그 거리가 이 값(px 위) 이상이면 카드 사용으로 판정한다.
  static const double _kPlayThreshold = -80.0;

  @override
  void dispose() {
    _removeDetail();
    super.dispose();
  }

  // ── 오버레이 ──────────────────────────────────────────────────────────

  void _showDetail(BuildContext ctx, int index) {
    _removeDetail();
    _detailEntry = OverlayEntry(
      builder: (_) => CardDetailOverlay(
        card: widget.hand[index],
        onDismiss: _removeDetail,
      ),
    );
    Overlay.of(ctx).insert(_detailEntry!);
  }

  void _removeDetail() {
    _detailEntry?.remove();
    _detailEntry = null;
  }

  // ── 빌드 ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (widget.hand.isEmpty) {
      return const SizedBox(
        height: _kHandHeight,
        child: Center(
          child: Text(BattleStrings.emptyHand, style: TextStyle(color: Color(0x80FFFFFF))),
        ),
      );
    }
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: hand.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final card = hand[index];
          return CardWidget(
            card: card,
            canPlay: card.cost == -1 ? energy > 0 : energy >= card.cost,
            onTap: () => onCardTap(card),
          );
        },
      height: _kHandHeight,
      child: LayoutBuilder(
        builder: (ctx, constraints) => Stack(
          clipBehavior: Clip.none,
          children: _buildFanCards(ctx, constraints.maxWidth),
        ),
      ),
    );
  }

  List<Widget> _buildFanCards(BuildContext ctx, double stackWidth) {
    final n = widget.hand.length;
    final drawOrder = _computeDrawOrder(n);

    return drawOrder.map((i) {
      final card     = widget.hand[i];
      final canPlay  = widget.energy >= card.cost;
      final isSelected = i == _pressedIndex && _dragIndex == null;
      final isDragging = i == _dragIndex;
      final (left, angle) = _cardLayout(i, n, stackWidth);
      final bool isPastThreshold = isDragging && _dragDy <= _kPlayThreshold;

      return Positioned(
        key: ValueKey(i),
        bottom: 0,
        left: left,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressedIndex = i),
          onTapUp: (_) {
            if (_dragIndex != null) return;
            setState(() => _pressedIndex = null);
            if (canPlay) widget.onCardTap(card);
          },
          onTapCancel: () {
            if (_dragIndex == null) setState(() => _pressedIndex = null);
          },
          // ── 꾹 눌러 상세보기 (탭으로 닫기) ──────────────────────────
          onLongPressStart: (_) {
            setState(() => _pressedIndex = null);
            _showDetail(ctx, i);
          },
          // ── 드래그 ────────────────────────────────────────────────────
          onVerticalDragStart: (_) {
            _removeDetail();
            setState(() {
              _dragIndex = i;
              _pressedIndex = null;
              _dragDy = 0;
            });
          },
          onVerticalDragUpdate: (d) {
            if (_dragIndex == i) {
              setState(() => _dragDy = (_dragDy + d.delta.dy).clamp(-260, 12));
            }
          },
          onVerticalDragEnd: (_) {
            if (_dragIndex == i) {
              final play = _dragDy <= _kPlayThreshold && canPlay;
              setState(() { _dragIndex = null; _dragDy = 0; });
              if (play) widget.onCardTap(card);
            }
          },
          onVerticalDragCancel: () {
            if (_dragIndex == i) setState(() { _dragIndex = null; _dragDy = 0; });
          },
          child: isDragging
              ? _buildDraggingCard(card, angle, canPlay, isPastThreshold)
              : _buildStaticCard(card, angle, canPlay, isSelected),
        ),
      );
    }).toList();
  }

  // ── 정적 카드 (탭·선택 애니메이션) ───────────────────────────────────

  Widget _buildStaticCard(
    GameCard card, double angle, bool canPlay, bool isSelected,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, isSelected ? -_kSelectedLift : 0, 0),
      child: Transform(
        alignment: Alignment.bottomCenter,
        transform: Matrix4.rotationZ(angle),
        child: AnimatedScale(
          scale: isSelected ? _kSelectedScale : 1.0,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          alignment: Alignment.bottomCenter,
          child: CardWidget(card: card, canPlay: canPlay),
        ),
      ),
    );
  }

  // ── 드래그 중인 카드 (즉각 반응, 임계값 초과 시 글로우) ─────────────

  Widget _buildDraggingCard(
    GameCard card, double fanAngle, bool canPlay, bool isPastThreshold,
  ) {
    // 위로 드래그할수록 부채꼴 각도가 0으로 수렴한다.
    final double liftRatio = (_dragDy / -_kPlayThreshold).clamp(0.0, 1.0);
    final double reducedAngle = fanAngle * (1.0 - liftRatio);
    final double scale = 1.20 + liftRatio * 0.06;
    final Color glowColor = isPastThreshold
        ? const Color(0xFF43A047)
        : BattleColors.forCard(card.effectType);

    return Transform.translate(
      offset: Offset(0, _dragDy),
      child: Transform(
        alignment: Alignment.bottomCenter,
        transform: Matrix4.rotationZ(reducedAngle),
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.bottomCenter,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: glowColor.withValues(alpha: isPastThreshold ? 0.85 : 0.5),
                      blurRadius: isPastThreshold ? 26 : 12,
                      spreadRadius: isPastThreshold ? 6 : 2,
                    ),
                  ],
                ),
                child: CardWidget(card: card, canPlay: canPlay),
              ),
              if (isPastThreshold)
                const Positioned(
                  top: -38,
                  left: 0,
                  right: 0,
                  child: Center(child: _PlayBadge()),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 레이아웃 계산 ─────────────────────────────────────────────────────

  /// 바깥쪽 카드부터 안쪽 순으로 렌더링하여 중앙 카드가 최상단에 표시된다.
  List<int> _computeDrawOrder(int n) {
    final result = <int>[];
    var lo = 0;
    var hi = n - 1;
    while (lo <= hi) {
      if (lo == hi) {
        result.add(lo);
      } else {
        result
          ..add(lo)
          ..add(hi);
      }
      lo++;
      hi--;
    }
    if (_dragIndex != null) {
      result.remove(_dragIndex!);
      result.add(_dragIndex!);
    } else if (_pressedIndex != null) {
      result.remove(_pressedIndex!);
      result.add(_pressedIndex!);
    }
    return result;
  }

  /// 카드 i의 좌측 x 좌표(left)와 회전 각도를 반환한다.
  (double left, double angle) _cardLayout(int i, int n, double stackWidth) {
    if (n == 1) {
      return ((stackWidth - CardWidget.cardWidth) / 2, 0.0);
    }
    final double naturalStep =
        (stackWidth - CardWidget.cardWidth) / (n - 1);
    final double step      = naturalStep.clamp(_kMinCardStep, _kMaxCardStep);
    final double totalSpan = step * (n - 1);
    final double startLeft =
        (stackWidth - totalSpan - CardWidget.cardWidth) / 2;

    final double left  = startLeft + i * step;
    final double t     = (i / (n - 1)) - 0.5;
    final double angle = t * 2.0 * _kMaxHalfAngle;
    return (left, angle);
  }
}

// ─── 비공개 서브위젯 ──────────────────────────────────────────────────────────

/// 드래그 임계값을 넘었을 때 카드 위에 표시되는 '사용' 배지.
class _PlayBadge extends StatelessWidget {
  const _PlayBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF388E3C),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4)],
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Text(
          '▲ 사용',
          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
