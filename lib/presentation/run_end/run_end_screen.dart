import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/meta_progress_provider.dart';
import '../../application/run_provider.dart';
import '../../domain/entities/card.dart';
import '../../domain/entities/player.dart';
import '../battle/battle_constants.dart';
import '../shared/relic_reward_badge.dart';
import 'widgets/unlocked_cards_grid.dart';

/// 보스 처치(런 클리어) 또는 플레이어 사망 후 표시되는 런 종료 결과 팝업.
///
/// [AppRouter]가 전투 화면 위에 겹쳐 그리므로, 어두운 스크림으로 그
/// 아래 전투 장면을 가린 채 중간 크기 카드를 띄운다.
/// [RunState.playerHp] > 0 이면 승리, 0 이면 패배로 판단한다.
class RunEndScreen extends ConsumerWidget {
  const RunEndScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final run       = ref.watch(runProvider);
    final meta      = ref.watch(metaProgressProvider);
    final isVictory = run.playerHp > 0;

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
                constraints: const BoxConstraints(maxWidth: 360),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1510),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isVictory
                            ? const Color(0xFFB8860B)
                            : const Color(0xFF5C2020),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isVictory
                                  ? const Color(0xFFB8860B)
                                  : const Color(0xFFEF5350))
                              .withValues(alpha: 0.25),
                          blurRadius: 40,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      child: _RunEndContent(
                        run: run,
                        meta: meta,
                        isVictory: isVictory,
                        onNewRun: () =>
                            ref.read(runProvider.notifier).startNewRun(),
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

// ── 팝업 내부 콘텐츠 ──────────────────────────────────────────────────────────

class _RunEndContent extends StatelessWidget {
  final RunState run;
  final dynamic meta;
  final bool isVictory;
  final VoidCallback onNewRun;

  const _RunEndContent({
    required this.run,
    required this.meta,
    required this.isVictory,
    required this.onNewRun,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor =
        isVictory ? const Color(0xFFFFD700) : const Color(0xFFEF5350);
    final title = isVictory ? BattleStrings.runClear : BattleStrings.defeat;
    final icon  = isVictory
        ? Icons.emoji_events_outlined
        : Icons.sentiment_very_dissatisfied_outlined;
    final floorsCleared = run.floor + 1;
    final newlyUnlockedCards = run.newlyUnlockedCardsThisRun
        .map(Cards.byTypeName)
        .whereType<GameCard>()
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── 아이콘 + 타이틀 ─────────────────────────────────────────────
        Icon(icon, size: 56, color: titleColor),
        const SizedBox(height: 10),
        Text(
          title,
          style: TextStyle(
            color: titleColor,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 24),

        // ── 런 통계 ──────────────────────────────────────────────────────
        _Divider(color: titleColor.withValues(alpha: 0.3)),
        const SizedBox(height: 12),
        _StatRow(icon: Icons.layers, label: '클리어 층수',
            value: '${floorsCleared}F'),
        _StatRow(
          icon: Icons.favorite,
          label: '잔여 HP',
          value: '${run.playerHp} / ${Player.maxHp}',
          valueColor: run.playerHp <= Player.maxHp * 0.3
              ? const Color(0xFFEF5350)
              : null,
        ),
        _StatRow(
          icon: Icons.monetization_on,
          label: '보유 골드',
          value: '${run.gold} G',
          valueColor: const Color(0xFFFFD700),
        ),
        _StatRow(icon: Icons.style, label: '덱 카드 수',
            value: '${run.deck.length}장'),
        if (run.relics.isNotEmpty)
          _StatRow(icon: Icons.auto_awesome, label: '획득 유물',
              value: '${run.relics.length}개'),
        const SizedBox(height: 12),

        // ── 메타 진행 ─────────────────────────────────────────────────────
        _Divider(color: titleColor.withValues(alpha: 0.3)),
        const SizedBox(height: 12),
        _StatRow(
          icon: Icons.star,
          label: '현재 레벨',
          value: 'Lv. ${meta.level}',
          valueColor: const Color(0xFFFFD700),
        ),
        _StatRow(icon: Icons.trending_up, label: '누적 XP',
            value: '${meta.xp} XP'),
        _StatRow(
          icon: Icons.bolt,
          label: '이번 런 획득 XP',
          value: '${run.xpGainedThisRun} XP',
          valueColor: const Color(0xFF66BB6A),
        ),

        // ── 신규 해금 카드 ───────────────────────────────────────────────
        if (newlyUnlockedCards.isNotEmpty) ...[
          const SizedBox(height: 12),
          _Divider(color: titleColor.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          const Text(
            '신규 해금 카드',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          UnlockedCardsGrid(cards: newlyUnlockedCards),
        ],

        // ── 신규 획득 유물 (보스 처치) ─────────────────────────────────────
        if (run.pendingRelicReward != null) ...[
          const SizedBox(height: 12),
          _Divider(color: titleColor.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          RelicRewardBadge(relic: run.pendingRelicReward!),
        ],
        const SizedBox(height: 24),

        // ── 새 런 시작 버튼 ───────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onNewRun,
            style: ElevatedButton.styleFrom(
              backgroundColor: isVictory
                  ? const Color(0xFFB8860B)
                  : const Color(0xFF37474F),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              BattleStrings.restart,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  final Color color;
  const _Divider({required this.color});

  @override
  Widget build(BuildContext context) =>
      Divider(color: color, height: 1, thickness: 1);
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white38),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
