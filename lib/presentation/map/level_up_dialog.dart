import 'package:flutter/material.dart';

import '../../domain/entities/card.dart';
import '../../domain/entities/meta_progress.dart';
import '../battle/battle_constants.dart';
import '../battle/widgets/card_widget.dart';

/// 전투 종료 후 맵으로 돌아올 때 레벨업 결과를 표시하는 다이얼로그.
class LevelUpDialog extends StatelessWidget {
  const LevelUpDialog({super.key, required this.result});

  final LevelUpResult result;

  @override
  Widget build(BuildContext context) {
    final newCards = result.newlyUnlockedCards
        .map(Cards.byTypeName)
        .whereType<GameCard>()
        .toList();

    return Dialog(
      backgroundColor: const Color(0xFF12100E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Header(newLevel: result.newLevel),
          const Divider(color: Color(0xFF3D3020), height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                children: [
                  _LevelBadge(
                    previousLevel: result.previousLevel,
                    newLevel: result.newLevel,
                  ),
                  const SizedBox(height: 20),
                  if (newCards.isNotEmpty) ...[
                    const Text(
                      '해금된 카드',
                      style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _CardGrid(cards: newCards),
                  ] else
                    const Text(
                      '새 카드 해금 없음',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  '확인',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 헤더 ─────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.newLevel});
  final int newLevel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2C2000), Color(0xFF1A1400)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: Color(0xFFFFD700), size: 22),
          const SizedBox(width: 8),
          Text(
            'LEVEL UP!  →  Lv.$newLevel',
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 레벨 뱃지 ────────────────────────────────────────────────────────────────

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.previousLevel, required this.newLevel});
  final int previousLevel;
  final int newLevel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LevelCircle(level: previousLevel, active: false),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Icon(Icons.arrow_forward, color: Color(0xFFFFD700), size: 28),
        ),
        _LevelCircle(level: newLevel, active: true),
      ],
    );
  }
}

class _LevelCircle extends StatelessWidget {
  const _LevelCircle({required this.level, required this.active});
  final int level;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? const Color(0xFFFFD700) : const Color(0xFF2A2415),
        border: Border.all(
          color: active ? const Color(0xFFFFD700) : const Color(0xFF3D3020),
          width: 2,
        ),
        boxShadow: active
            ? [
                const BoxShadow(
                  color: Color(0x80FFD700),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          'Lv.$level',
          style: TextStyle(
            color: active ? Colors.black : Colors.white38,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ── 카드 그리드 ───────────────────────────────────────────────────────────────

class _CardGrid extends StatelessWidget {
  const _CardGrid({required this.cards});
  final List<GameCard> cards;

  static const double _scale = 1.4;
  static const double _w = CardWidget.cardWidth  * _scale;
  static const double _h = CardWidget.cardHeight * _scale;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: cards
          .map((c) => GestureDetector(
                onTap: () => _showDetail(context, c),
                child: SizedBox(
                  width:  _w,
                  height: _h,
                  child: FittedBox(
                    child: SizedBox(
                      width:  CardWidget.cardWidth,
                      height: CardWidget.cardHeight,
                      child: CardWidget(card: c, canPlay: true),
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  void _showDetail(BuildContext context, GameCard card) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        behavior: HitTestBehavior.opaque,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width:  CardWidget.cardWidth  * 2.2,
                  height: CardWidget.cardHeight * 2.2,
                  child: FittedBox(
                    child: SizedBox(
                      width:  CardWidget.cardWidth,
                      height: CardWidget.cardHeight,
                      child: CardWidget(card: card, canPlay: true),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  decoration: BoxDecoration(
                    color: const Color(0xCC16213E),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF3D3020)),
                  ),
                  child: Text(
                    BattleStrings.cardEffect(card),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '탭하여 닫기',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
