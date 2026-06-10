import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/meta_progress_provider.dart';
import '../../domain/entities/card.dart';
import '../../domain/entities/meta_progress.dart';
import '../battle/widgets/card_detail_overlay.dart';
import '../battle/widgets/card_widget.dart';
import 'codex_constants.dart';

/// 카드 도감 화면 — 게임 내 모든 카드를 해금 그룹별로 보여준다.
///
/// 현재 메타 레벨에 따라 잠긴 카드는 흐리게 표시되고 탭할 수 없다.
class CodexScreen extends ConsumerWidget {
  const CodexScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(metaProgressProvider).level;

    return Scaffold(
      backgroundColor: CodexColors.background,
      appBar: AppBar(
        backgroundColor: CodexColors.appBar,
        foregroundColor: Colors.white,
        title: const Text(
          CodexStrings.title,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CodexSection(
            label: CodexStrings.baseSectionLabel,
            sublabel: CodexStrings.baseSectionDesc,
            cards: _cardsFor(MetaProgress.baseUnlockedCards),
            isUnlocked: true,
          ),
          for (int i = 0; i < MetaProgress.xpThresholds.length; i++)
            _CodexSection(
              label: CodexStrings.levelLabel(i + 1),
              sublabel: i + 1 == 1 ? CodexStrings.starterDeckSuffix : null,
              cards: _cardsFor(MetaProgress.levelUnlocks[i + 1] ?? const []),
              isUnlocked: level >= i + 1,
            ),
        ],
      ),
    );
  }

  List<GameCard> _cardsFor(List<String> typeNames) =>
      typeNames.map(Cards.byTypeName).whereType<GameCard>().toList();
}

// ── 도감 섹션 ────────────────────────────────────────────────────────────────

class _CodexSection extends StatelessWidget {
  const _CodexSection({
    required this.label,
    required this.cards,
    required this.isUnlocked,
    this.sublabel,
  });

  final String label;
  final String? sublabel;
  final List<GameCard> cards;
  final bool isUnlocked;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();

    final borderColor = isUnlocked ? CodexColors.unlockedBorder : CodexColors.lockedBorder;
    final bgColor     = isUnlocked ? CodexColors.unlockedBg     : CodexColors.lockedBg;
    final labelColor  = isUnlocked ? CodexColors.unlockedLabel  : CodexColors.lockedLabel;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
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
              Icon(
                isUnlocked ? Icons.menu_book : Icons.lock_outline,
                color: labelColor,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: labelColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (sublabel != null)
                Text(
                  sublabel!,
                  style: TextStyle(
                    color: labelColor.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final card in cards) _CodexCardTile(card: card, isUnlocked: isUnlocked),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 카드 타일 ────────────────────────────────────────────────────────────────

class _CodexCardTile extends StatelessWidget {
  const _CodexCardTile({required this.card, required this.isUnlocked});

  final GameCard card;
  final bool isUnlocked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUnlocked ? () => _showCardDetail(context, card) : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CardWidget(card: card, canPlay: isUnlocked),
          if (!isUnlocked)
            const Icon(Icons.lock, color: Colors.white54, size: 28),
        ],
      ),
    );
  }
}

void _showCardDetail(BuildContext context, GameCard card) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.transparent,
    builder: (_) => CardDetailOverlay(
      card: card,
      onDismiss: () => Navigator.of(context).pop(),
    ),
  );
}
