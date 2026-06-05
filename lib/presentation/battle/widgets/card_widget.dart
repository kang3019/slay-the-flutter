import 'package:flutter/material.dart';

import '../../../domain/entities/card.dart';
import '../battle_constants.dart';

/// 손패의 카드 한 장을 다크 판타지 스타일로 표시하는 순수 표시 위젯.
///
/// 제스처 처리는 부모인 HandWidget이 담당한다.
/// [canPlay]가 false이면 불투명도를 낮춰 비활성 상태를 표시한다.
class CardWidget extends StatelessWidget {
  static const double cardWidth  = 92.0;
  static const double cardHeight = 134.0;

  final GameCard card;
  final bool canPlay;

  const CardWidget({super.key, required this.card, required this.canPlay});

  @override
  Widget build(BuildContext context) {
    final typeColor   = BattleColors.forCard(card.effectType);
    final borderColor = BattleColors.borderForCard(card.effectType);

    return Opacity(
      opacity: canPlay ? 1.0 : 0.42,
      child: SizedBox(
        width: cardWidth,
        height: cardHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2A2215), Color(0xFF110E09)],
            ),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: borderColor, width: 1.8),
            boxShadow: [
              BoxShadow(
                color: typeColor.withValues(alpha: canPlay ? 0.4 : 0.12),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              _CardHeader(cost: card.cost, typeColor: typeColor),
              Expanded(child: _CardArt(type: card.type, typeColor: typeColor)),
              _CardFooter(card: card),
              const SizedBox(height: 5),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 비공개 서브위젯 ──────────────────────────────────────────────────────────

class _CardHeader extends StatelessWidget {
  final int cost;
  final Color typeColor;
  const _CardHeader({required this.cost, required this.typeColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      decoration: BoxDecoration(
        color: typeColor.withValues(alpha: 0.85),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          _CostGem(cost: cost),
          const Spacer(),
          Icon(_headerIcon, color: Colors.white, size: 12),
        ],
      ),
    );
  }

  IconData get _headerIcon => switch (cost) {
        0 => Icons.auto_awesome,
        1 => Icons.flash_on,
        _ => Icons.whatshot,
      };
}

class _CostGem extends StatelessWidget {
  final int cost;
  const _CostGem({required this.cost});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF1A1410),
        boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 2)],
      ),
      child: Center(
        child: Text(
          '$cost',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _CardArt extends StatelessWidget {
  final CardType type;
  final Color typeColor;
  const _CardArt({required this.type, required this.typeColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(5, 4, 5, 4),
      decoration: BoxDecoration(
        color: const Color(0x33000000),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: typeColor.withValues(alpha: 0.25)),
      ),
      child: Center(
        child: Icon(_artIcon, size: 36, color: typeColor.withValues(alpha: 0.82)),
      ),
    );
  }

  IconData get _artIcon => switch (type) {
        CardType.strike   => Icons.sports_martial_arts,
        CardType.bash     => Icons.fitness_center,
        CardType.swiftCut => Icons.air,
        CardType.defend   => Icons.shield_outlined,
        CardType.ironWall => Icons.security,
        CardType.focus    => Icons.visibility,
        CardType.recover  => Icons.healing,
      };
}

class _CardFooter extends StatelessWidget {
  final GameCard card;
  const _CardFooter({required this.card});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        children: [
          Text(
            card.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
          const SizedBox(height: 2),
          Text(
            BattleStrings.cardEffect(card),
            style: const TextStyle(color: Color(0xFFB0A080), fontSize: 9),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
