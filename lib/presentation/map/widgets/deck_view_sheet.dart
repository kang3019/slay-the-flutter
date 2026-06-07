import 'package:flutter/material.dart';

import '../../../domain/entities/card.dart';
import '../../battle/battle_constants.dart';

/// 현재 덱에 있는 카드 목록을 표시하는 바텀시트.
class DeckViewSheet extends StatelessWidget {
  final List<GameCard> deck;
  const DeckViewSheet({super.key, required this.deck});

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.75;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── 핸들 ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // ── 타이틀 ─────────────────────────────────────────────────
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [Color(0xFFB8860B), Color(0xFFFFD700), Color(0xFFB8860B)],
              ).createShader(b),
              child: Text(
                '내 덱  (${deck.length}장)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 20),
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
            const SizedBox(height: 8),
            // ── 카드 목록 ───────────────────────────────────────────────
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: deck.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (_, i) => _DeckCardRow(card: deck[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeckCardRow extends StatelessWidget {
  final GameCard card;
  const _DeckCardRow({required this.card});

  @override
  Widget build(BuildContext context) {
    final color  = BattleColors.forCard(card.effectType);
    final border = BattleColors.borderForCard(card.effectType);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          // 비용 뱃지
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: border.withValues(alpha: 0.25),
              shape: BoxShape.circle,
              border: Border.all(color: color),
            ),
            child: Center(
              child: Text(
                card.cost < 0 ? 'X' : '${card.cost}',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 이름 + 효과
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.isUpgraded ? '${card.name}+' : card.name,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  BattleStrings.cardEffect(card),
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          if (card.isUpgraded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                ),
              ),
              child: const Text(
                '강화',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
