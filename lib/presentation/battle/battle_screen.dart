import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/battle_provider.dart';
import '../../domain/battle_engine.dart';
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
    final state = ref.watch(battleProvider);
    final notifier = ref.read(battleProvider.notifier);

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
                  const SizedBox(height: 12),
                  MonsterWidget(
                    hp: state.monsterHp,
                    maxHp: state.monsterMaxHp,
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
              onRestart: () => notifier.startBattle(1),
            ),
        ],
      ),
    );
  }
}

// ─── 비공개 위젯 ──────────────────────────────────────────────────────────────

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

class _BattleResultOverlay extends StatelessWidget {
  final BattleResult result;
  final VoidCallback onRestart;
  const _BattleResultOverlay({required this.result, required this.onRestart});

  @override
  Widget build(BuildContext context) {
    final isVictory = result == BattleResult.playerWon;
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
              Text(
                isVictory ? BattleStrings.victory : BattleStrings.defeat,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: isVictory ? Colors.amber : Colors.redAccent,
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: onRestart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[800],
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  BattleStrings.restart,
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
