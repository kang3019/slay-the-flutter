import 'package:flutter/material.dart';

import '../../../domain/entities/card.dart';
import '../battle_constants.dart';
import 'card_widget.dart';

/// 플레이어의 현재 손패를 가로 스크롤로 표시한다.
class HandWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (hand.isEmpty) {
      return const SizedBox(
        height: 140,
        child: Center(
          child: Text(
            BattleStrings.emptyHand,
            style: TextStyle(color: Colors.white54),
          ),
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
      ),
    );
  }
}
