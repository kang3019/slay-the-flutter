import 'package:flutter/material.dart';

import '../../../domain/entities/card.dart';
import '../battle_constants.dart';

/// 손패의 카드 한 장을 표시한다.
/// [canPlay]가 false면 흐리게 표시되고 탭이 비활성화된다.
class CardWidget extends StatelessWidget {
  final GameCard card;
  final bool canPlay;
  final VoidCallback? onTap;

  const CardWidget({
    super.key,
    required this.card,
    required this.canPlay,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = BattleColors.forCard(card.effectType);
    return Opacity(
      opacity: canPlay ? 1.0 : 0.4,
      child: GestureDetector(
        onTap: canPlay ? onTap : null,
        child: Container(
          width: 100,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: BattleColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: _CostBadge(cost: card.cost, color: borderColor),
              ),
              const SizedBox(height: 6),
              Text(
                card.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                BattleStrings.cardEffect(card),
                style: const TextStyle(color: Colors.white70, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CostBadge extends StatelessWidget {
  final int cost;
  final Color color;

  const _CostBadge({required this.cost, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(
        child: Text(
          cost == -1 ? 'X' : '$cost',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
