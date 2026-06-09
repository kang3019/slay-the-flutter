import 'package:flutter/material.dart';

import '../../domain/entities/card.dart';
import '../../domain/entities/meta_progress.dart';
import '../battle/battle_constants.dart';
import '../battle/widgets/card_widget.dart';

/// 레벨 1~10 해금 진행도를 표시하는 다이얼로그.
class LevelProgressDialog extends StatelessWidget {
  const LevelProgressDialog({
    super.key,
    required this.currentLevel,
    required this.currentXp,
  });

  final int currentLevel;
  final int currentXp;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          const Divider(color: Color(0xFF3D3020), height: 1),
          Flexible(
            child: ListView(
              padding: const EdgeInsets.all(14),
              shrinkWrap: true,
              children: [
                _BaseTile(
                  cards: MetaProgress.baseUnlockedCards
                      .map(_cardFor)
                      .whereType<GameCard>()
                      .toList(),
                ),
                const SizedBox(height: 8),
                for (int i = 0; i < MetaProgress.xpThresholds.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _LevelTile(
                      level: i + 1,
                      requiredXp: MetaProgress.xpThresholds[i],
                      currentXp: currentXp,
                      cards: (MetaProgress.levelUnlocks[i + 1] ?? [])
                          .map(_cardFor)
                          .whereType<GameCard>()
                          .toList(),
                      currentLevel: currentLevel,
                      isStarterDeck: i + 1 == 1,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 8, 12),
      child: Row(
        children: [
          const Icon(Icons.bar_chart, color: Color(0xFFFFD700), size: 22),
          const SizedBox(width: 8),
          const Text(
            '레벨 진행도',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

// ── 카드 룩업 ─────────────────────────────────────────────────────────────────

GameCard? _cardFor(String type) => Cards.byTypeName(type);

// ── 카드 팝업 ─────────────────────────────────────────────────────────────────

void _showCardDetail(BuildContext context, GameCard card) {
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
                width:  CardWidget.cardWidth  * 2.0,
                height: CardWidget.cardHeight * 2.0,
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

// ── 기본 해금 카드 타일 ───────────────────────────────────────────────────────

class _BaseTile extends StatelessWidget {
  const _BaseTile({required this.cards});

  final List<GameCard> cards;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2C22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2D6A4F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.star, color: Color(0xFFFFD700), size: 15),
              SizedBox(width: 6),
              Text(
                '기본 해금  —  항상 보상·이벤트·상점에 등장',
                style: TextStyle(
                  color: Color(0xFF95D5B2),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 5,
            children: cards
                .map((c) => _CardChip(
                      card: c,
                      color: _ChipColor.base,
                      onTap: () => _showCardDetail(context, c),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ── 레벨별 타일 ──────────────────────────────────────────────────────────────

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.level,
    required this.requiredXp,
    required this.currentXp,
    required this.cards,
    required this.currentLevel,
    required this.isStarterDeck,
  });

  final int level;
  final int requiredXp;
  final int currentXp;
  final List<GameCard> cards;
  final int currentLevel;
  final bool isStarterDeck;

  @override
  Widget build(BuildContext context) {
    final isCompleted = level < currentLevel;
    final isCurrent   = level == currentLevel;
    final isLocked    = level > currentLevel;

    final Color borderColor;
    final Color bgColor;
    final Color labelColor;
    final Widget statusIcon;

    if (isCompleted) {
      borderColor = const Color(0xFF2D6A4F);
      bgColor     = const Color(0xFF121E17);
      labelColor  = const Color(0xFF95D5B2);
      statusIcon  =
          const Icon(Icons.check_circle, color: Color(0xFF52B788), size: 15);
    } else if (isCurrent) {
      borderColor = const Color(0xFFFFD700);
      bgColor     = const Color(0xFF221D00);
      labelColor  = const Color(0xFFFFD700);
      statusIcon  = const Icon(Icons.star, color: Color(0xFFFFD700), size: 15);
    } else {
      borderColor = const Color(0xFF3D3020);
      bgColor     = const Color(0xFF161420);
      labelColor  = Colors.white38;
      statusIcon  =
          const Icon(Icons.lock_outline, color: Colors.white38, size: 15);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              statusIcon,
              const SizedBox(width: 6),
              Text(
                'Lv.$level',
                style: TextStyle(
                  color: labelColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isStarterDeck) ...[
                const SizedBox(width: 6),
                Text(
                  '스타터 덱',
                  style: TextStyle(
                    color: labelColor.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
              ],
              if (isCurrent) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '현재',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          _XpRow(
            requiredXp: requiredXp,
            currentXp: currentXp,
            isCompleted: isCompleted,
            isCurrent: isCurrent,
            labelColor: labelColor,
          ),
          const SizedBox(height: 8),
          if (cards.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 5,
              children: cards
                  .map((c) => _CardChip(
                        card: c,
                        color:
                            isLocked ? _ChipColor.locked : _ChipColor.unlocked,
                        onTap: () => _showCardDetail(context, c),
                      ))
                  .toList(),
            )
          else
            Text(
              '새 카드 해금 없음',
              style: TextStyle(
                color: isLocked ? Colors.white24 : Colors.white38,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}

// ── XP 행 ────────────────────────────────────────────────────────────────────

class _XpRow extends StatelessWidget {
  const _XpRow({
    required this.requiredXp,
    required this.currentXp,
    required this.isCompleted,
    required this.isCurrent,
    required this.labelColor,
  });

  final int requiredXp;
  final int currentXp;
  final bool isCompleted;
  final bool isCurrent;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    final String xpText;
    final Color xpColor;

    if (requiredXp == 0) {
      xpText  = '시작 레벨';
      xpColor = labelColor.withValues(alpha: 0.6);
    } else if (isCompleted) {
      xpText  = '달성 (필요 XP $requiredXp)';
      xpColor = const Color(0xFF52B788);
    } else if (isCurrent) {
      final gap = requiredXp - currentXp;
      xpText  = '현재 $currentXp XP  /  필요 $requiredXp XP  (${gap > 0 ? "-$gap" : "달성"})';
      xpColor = const Color(0xFFFFD700);
    } else {
      final gap = requiredXp - currentXp;
      xpText  = '필요 $requiredXp XP  (${gap > 0 ? "$gap 부족" : "달성 가능"})';
      xpColor = labelColor.withValues(alpha: 0.7);
    }

    return Row(
      children: [
        Icon(Icons.star_outline, color: xpColor, size: 12),
        const SizedBox(width: 4),
        Text(xpText, style: TextStyle(color: xpColor, fontSize: 11)),
      ],
    );
  }
}

// ── 카드 칩 ──────────────────────────────────────────────────────────────────

enum _ChipColor { base, unlocked, locked }

class _CardChip extends StatelessWidget {
  const _CardChip({
    required this.card,
    required this.color,
    required this.onTap,
  });

  final GameCard card;
  final _ChipColor color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
    final Color text;

    switch (color) {
      case _ChipColor.base:
        bg     = const Color(0xFF0D2A1A);
        border = const Color(0xFF2D6A4F);
        text   = const Color(0xFF95D5B2);
      case _ChipColor.unlocked:
        bg     = const Color(0xFF0D1E2F);
        border = const Color(0xFF3A6D9E);
        text   = const Color(0xFF90CAF9);
      case _ChipColor.locked:
        bg     = const Color(0xFF1A1A1A);
        border = const Color(0xFF3D3020);
        text   = Colors.white24;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(card.name, style: TextStyle(color: text, fontSize: 12)),
            const SizedBox(width: 3),
            Icon(Icons.info_outline, color: text, size: 11),
          ],
        ),
      ),
    );
  }
}
