import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/battle_provider.dart';
import '../../application/meta_progress_provider.dart';
import '../../application/run_provider.dart';
import '../../domain/battle_engine.dart';
import '../../domain/entities/relic.dart';
import '../../domain/map/node_type.dart';
import '../shared/hp_bar_widget.dart';
import 'battle_constants.dart';
import 'widgets/hand_widget.dart';
import 'widgets/monster_widget.dart';

/// 전투 화면. battleProvider를 구독해 상태 변경 시 자동 재빌드된다.
///
/// ref.watch는 이 build() 안에서만 사용한다.
/// 자식 위젯은 콜백을 받는 순수 StatelessWidget으로 유지된다.
class BattleScreen extends ConsumerWidget {
  const BattleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(battleProvider);
    final notifier = ref.read(battleProvider.notifier);
    final runState = ref.watch(runProvider);

    // 전투가 승리로 끝나는 순간 한 번만 XP를 적립한다.
    ref.listen<BattleState>(battleProvider, (prev, next) {
      if (next.isBattleOver &&
          next.result == BattleResult.playerWon &&
          (prev == null || !prev.isBattleOver)) {
        ref
            .read(metaProgressProvider.notifier)
            .addXp(BattleXpRewards.xpForStage(next.stage));
      }
    });

    // 현재 전투가 보스 전투인지 판별한다.
    final isBossBattle = runState.currentNode?.type == NodeType.boss;

    return Scaffold(
      backgroundColor: BattleColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StageHeader(stage: state.stage),
                  const SizedBox(height: 8),
                  if (runState.relics.isNotEmpty)
                    _RelicRow(relics: runState.relics),
                  const SizedBox(height: 8),
                  MonsterWidget(
                    hp: state.monsterHp,
                    maxHp: state.monsterMaxHp,
                    name: state.monsterName,
                    intentType: state.monsterIntentType,
                    intentLabel: state.monsterIntentLabel,
                    intentDescription: state.monsterIntentDescription,
                    attackPower: state.monsterAttackPower,
                    isVulnerable: state.monsterIsVulnerable,
                  ),
                  const Spacer(),
                  _PlayerStatusSection(state: state),
                  const SizedBox(height: 12),
                  HandWidget(
                    hand: state.hand,
                    energy: state.energy,
                    onCardTap: notifier.playCard,
                  ),
                  const SizedBox(height: 12),
                  _EndTurnButton(
                    isBattleOver: state.isBattleOver,
                    onPressed: notifier.endTurn,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          if (state.isBattleOver)
            _BattleResultOverlay(
              result: state.result!,
              xpGained: BattleXpRewards.xpForStage(state.stage),
              goldEarned: BattleGoldRewards.forStage(state.stage),
              isBossBattle: isBossBattle,
              // 일반 승리: 보상 카드 선택 화면으로 전환
              onReturnToMap: () => ref
                  .read(runProvider.notifier)
                  .startReward(
                    remainingHp: state.playerHp,
                    goldEarned: BattleGoldRewards.forStage(state.stage),
                  ),
              // 패배: 런을 초기화하고 맵으로 돌아간다
              onNewRun: () =>
                  ref.read(runProvider.notifier).startNewRun(),
            ),
        ],
      ),
    );
  }
}

// ─── 비공개 위젯 ──────────────────────────────────────────────────────────────

class _RelicRow extends StatelessWidget {
  final List<Relic> relics;
  const _RelicRow({required this.relics});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: relics.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) => _RelicChip(relic: relics[i]),
      ),
    );
  }
}

class _RelicChip extends StatelessWidget {
  final Relic relic;
  const _RelicChip({required this.relic});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: BattleColors.surface,
          title: Text(
            relic.name,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            relic.description,
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기', style: TextStyle(color: Colors.amber)),
            ),
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A4A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFD700), width: 1),
        ),
        child: Text(
          relic.name,
          style: const TextStyle(
            color: Color(0xFFFFD700),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _StageHeader extends StatelessWidget {
  final int stage;
  const _StageHeader({required this.stage});

  @override
  Widget build(BuildContext context) {
    return Text(
      '${BattleStrings.stageLabel} $stage',
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _PlayerStatusSection extends StatelessWidget {
  final BattleState state;
  const _PlayerStatusSection({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BattleColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: HpBarWidget(
              label: 'HP',
              current: state.playerHp,
              max: state.playerMaxHp,
              barColor: Colors.green,
              block: state.playerBlock,
            ),
          ),
          const SizedBox(width: 16),
          _EnergyDisplay(current: state.energy, max: state.maxEnergy),
        ],
      ),
    );
  }
}

class _EnergyDisplay extends StatelessWidget {
  final int current;
  final int max;
  const _EnergyDisplay({required this.current, required this.max});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('⚡', style: TextStyle(fontSize: 22)),
        Text(
          '$current / $max',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _EndTurnButton extends StatelessWidget {
  final bool isBattleOver;
  final VoidCallback onPressed;
  const _EndTurnButton({required this.isBattleOver, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isBattleOver ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber[800],
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey[800],
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text(
        BattleStrings.endTurn,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// 전투 결과 오버레이.
///
/// 승리·패배·보스 클리어 세 가지 상황을 구분해 표시한다.
///
/// - 일반 승리: "승리!" + XP·골드 → "맵으로 이동" → [onReturnToMap]
/// - 보스 승리: "런 클리어!" + XP → "새 런 시작" → [onNewRun]
/// - 패배:      "패배..." → "새 런 시작" → [onNewRun]
class _BattleResultOverlay extends StatelessWidget {
  final BattleResult result;
  final int xpGained;
  final int goldEarned;
  final bool isBossBattle;
  final VoidCallback onReturnToMap;
  final VoidCallback onNewRun;

  const _BattleResultOverlay({
    required this.result,
    required this.xpGained,
    required this.goldEarned,
    required this.isBossBattle,
    required this.onReturnToMap,
    required this.onNewRun,
  });

  bool get _isVictory => result == BattleResult.playerWon;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
          decoration: BoxDecoration(
            color: BattleColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── 타이틀 ──────────────────────────────────────────────
              Text(
                _titleText,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: _isVictory ? Colors.amber : Colors.redAccent,
                ),
              ),

              // ── XP 표시 (승리 시) ───────────────────────────────────
              if (_isVictory) ...[
                const SizedBox(height: 8),
                Text(
                  BattleXpRewards.xpGainedLabel(xpGained),
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],

              // ── 골드 표시 (일반 승리 시만) ───────────────────────────
              if (_isVictory && !isBossBattle && goldEarned > 0) ...[
                const SizedBox(height: 4),
                Text(
                  BattleGoldRewards.goldLabel(goldEarned),
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // ── 액션 버튼 ────────────────────────────────────────────
              ElevatedButton(
                onPressed: _buttonAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isVictory && !isBossBattle ? Colors.amber[800] : Colors.blueGrey[700],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 36,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  _buttonLabel,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _titleText {
    if (!_isVictory) return BattleStrings.defeat;
    if (isBossBattle) return BattleStrings.runClear;
    return BattleStrings.victory;
  }

  String get _buttonLabel {
    if (_isVictory && !isBossBattle) return BattleStrings.selectReward;
    return BattleStrings.restart;
  }

  VoidCallback get _buttonAction {
    if (_isVictory && !isBossBattle) return onReturnToMap;
    return onNewRun;
  }
}
