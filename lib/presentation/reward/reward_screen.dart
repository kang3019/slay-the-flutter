import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/run_provider.dart';
import '../../domain/entities/card.dart';
import 'reward_constants.dart';

/// 전투 승리 후 카드 보상을 선택하는 화면.
///
/// [RunState.rewardCards]에 담긴 3장 중 1장을 탭하면 덱에 추가되고
/// [RunPhase.map]으로 전환된다. "건너뛰기" 버튼으로 카드 없이 넘어갈 수 있다.
class RewardScreen extends ConsumerWidget {
  const RewardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardCards = ref.watch(runProvider.select((s) => s.rewardCards));
    final notifier    = ref.read(runProvider.notifier);

    return Scaffold(
      backgroundColor: RewardColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),

            // ── 타이틀 ────────────────────────────────────────────────────
            const Text(
              RewardStrings.title,
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              RewardStrings.subtitle,
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),

            const SizedBox(height: 40),

            // ── 카드 3장 ───────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: rewardCards
                      .map(
                        (card) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: _RewardCardTile(
                              card: card,
                              onTap: () => notifier.selectRewardCard(card),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── 건너뛰기 ───────────────────────────────────────────────────
            TextButton(
              onPressed: notifier.skipReward,
              child: const Text(
                RewardStrings.skipButton,
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 15,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white38,
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// _RewardCardTile — 카드 한 장 UI
// ──────────────────────────────────────────────────────────────────────────

/// 보상 화면에서 선택 가능한 카드 타일.
///
/// 탭하면 [onTap]을 호출한다. 카드 이름·비용·효과를 세로로 나열한다.
class _RewardCardTile extends StatelessWidget {
  final GameCard card;
  final VoidCallback onTap;

  const _RewardCardTile({required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accentColor = RewardColors.forEffectType(card.effectType);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: RewardColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: RewardColors.cardBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: RewardColors.cardBorder.withValues(alpha: 0.25),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── 비용 뱃지 ───────────────────────────────────────────────
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: accentColor, width: 1.5),
              ),
              child: Center(
                child: Text(
                  card.cost == -1 ? 'X' : '${card.cost}',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── 카드 이름 ────────────────────────────────────────────────
            Text(
              card.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 10),

            // ── 효과 설명 ────────────────────────────────────────────────
            Text(
              RewardStrings.cardEffect(card),
              style: TextStyle(
                color: accentColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
