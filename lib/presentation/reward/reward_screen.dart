import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/run_provider.dart';
import '../../domain/entities/card.dart';
import '../battle/battle_constants.dart';
import '../shared/relic_reward_badge.dart';
import 'reward_constants.dart';

/// 전투 승리 직후 자동으로 표시되는 보상 팝업.
///
/// [AppRouter]가 전투 화면 위에 겹쳐 그리므로, 어두운 스크림으로 그
/// 아래 전투 장면을 가린 채 "전투 승리!" 헤더와 함께 골드 보상(클릭해야
/// 획득)·카드 3장을 보여준다.
/// [RunState.rewardCards] 중 1장을 탭하면 덱에 추가되고 [RunPhase.map]으로
/// 전환된다. "건너뛰기" 버튼으로 카드 없이 넘어갈 수 있다.
class RewardScreen extends ConsumerWidget {
  const RewardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final run      = ref.watch(runProvider);
    final notifier = ref.read(runProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── 전투 화면을 어둡게 덮는 스크림 ─────────────────────────────
          const Positioned.fill(
            child: ColoredBox(color: BattleColors.popupScrim),
          ),
          // ── 중앙 팝업 카드 ───────────────────────────────────────────
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: RewardColors.popupBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: RewardColors.popupBorder, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: RewardColors.popupBorder.withValues(alpha: 0.25),
                          blurRadius: 40,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ── 승리 헤더 ─────────────────────────────────
                          const Icon(Icons.emoji_events, size: 48, color: RewardColors.gold),
                          const SizedBox(height: 10),
                          const Text(
                            RewardStrings.victoryTitle,
                            style: TextStyle(
                              color: RewardColors.gold,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),

                          // ── 골드 보상 (클릭해야 획득) ───────────────────
                          if (run.pendingGoldReward > 0) ...[
                            const SizedBox(height: 16),
                            _GoldRewardChip(
                              amount: run.pendingGoldReward,
                              claimed: run.goldClaimed,
                              onTap: notifier.claimGoldReward,
                            ),
                          ],

                          // ── 유물 보상 (엘리트 처치) ───────────────────────
                          if (run.pendingRelicReward != null) ...[
                            const SizedBox(height: 16),
                            RelicRewardBadge(relic: run.pendingRelicReward!),
                          ],

                          const SizedBox(height: 20),
                          const Text(
                            RewardStrings.subtitle,
                            style: TextStyle(color: Colors.white54, fontSize: 14),
                          ),
                          const SizedBox(height: 16),

                          // ── 카드 3장 ───────────────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: run.rewardCards
                                .map(
                                  (card) => Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6),
                                      child: _RewardCardTile(
                                        card: card,
                                        onTap: () => notifier.selectRewardCard(card),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),

                          const SizedBox(height: 20),

                          // ── 건너뛰기 ───────────────────────────────────
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
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// _GoldRewardChip — 골드 보상 (탭하여 획득)
// ──────────────────────────────────────────────────────────────────────────

/// 보상 화면의 골드 칩. 탭하면 [onTap]을 호출해 골드를 획득한다.
///
/// [claimed]가 true면 체크 아이콘과 함께 비활성 상태로 표시된다.
class _GoldRewardChip extends StatelessWidget {
  final int amount;
  final bool claimed;
  final VoidCallback onTap;

  const _GoldRewardChip({
    required this.amount,
    required this.claimed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = claimed ? RewardColors.claimedAccent : RewardColors.gold;

    return GestureDetector(
      onTap: claimed ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              claimed ? Icons.check_circle : Icons.toll,
              color: accentColor,
              size: 22,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  RewardStrings.goldLabel(amount),
                  style: const TextStyle(
                    color: RewardColors.gold,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  claimed ? RewardStrings.claimedLabel : RewardStrings.claimButton,
                  style: TextStyle(
                    color: claimed ? RewardColors.claimedAccent : Colors.white60,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
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
        height: RewardSizes.cardTileHeight,
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
