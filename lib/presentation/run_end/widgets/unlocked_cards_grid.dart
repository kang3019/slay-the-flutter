import 'package:flutter/material.dart';

import '../../../domain/entities/card.dart';
import '../../battle/battle_constants.dart';
import '../../battle/widgets/card_widget.dart';

/// 새로 해금된 카드들을 격자로 보여주는 위젯. 탭하면 카드 상세 효과를 표시한다.
class UnlockedCardsGrid extends StatelessWidget {
  const UnlockedCardsGrid({super.key, required this.cards});

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
