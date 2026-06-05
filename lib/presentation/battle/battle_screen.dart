import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/battle_provider.dart';
import '../../application/meta_progress_provider.dart';
import '../../application/run_provider.dart';
import '../../domain/battle_engine.dart';
import '../../domain/map/node_type.dart';
import 'battle_constants.dart';
import 'widgets/hand_widget.dart';
import 'widgets/monster_widget.dart';

/// 전투 화면. 배경 이미지 위에 반투명 패널을 올린 다크 판타지 레이아웃.
///
/// 하단 좌측: 플레이어 HP / 우측: 에너지 원형 / 우하단: 턴 종료 버튼.
class BattleScreen extends ConsumerWidget {
  const BattleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(battleProvider);
    final notifier = ref.read(battleProvider.notifier);
    final runState = ref.watch(runProvider);

    ref.listen<BattleState>(battleProvider, (prev, next) {
      if (next.isBattleOver &&
          next.result == BattleResult.playerWon &&
          (prev == null || !prev.isBattleOver)) {
        ref.read(metaProgressProvider.notifier)
            .addXp(BattleXpRewards.xpForStage(next.stage));
      }
    });

    final isBossBattle = runState.currentNode?.type == NodeType.boss;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset(BattleAssets.background, fit: BoxFit.cover)),
          const Positioned.fill(child: ColoredBox(color: BattleColors.backgroundOverlay)),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StageHeader(stage: state.stage),
                const SizedBox(height: 8),
                // ── 몬스터 영역 ─────────────────────────────────────────
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: MonsterWidget(
                      hp: state.monsterHp,
                      maxHp: state.monsterMaxHp,
                      block: state.monsterBlock,
                      intent: state.monsterIntent,
                      isVulnerable: state.monsterIsVulnerable,
                    ),
                  ),
                ),
                // ── 플레이어 캐릭터 자리 (추후 스프라이트 배치 영역) ────
                const Expanded(flex: 2, child: SizedBox.shrink()),
                // ── 하단 HUD: HP(좌) + 에너지 원(우) ───────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _HpBlock(state: state),
                      const Spacer(),
                      _EnergyCircle(current: state.energy, max: state.maxEnergy),
                    ],
                  ),
                ),
                // ── 손패 ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: HandWidget(
                    hand: state.hand,
                    energy: state.energy,
                    onCardTap: notifier.playCard,
                  ),
                ),
                // ── 턴 종료 버튼 (우하단 정렬) ──────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 16, 14),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _EndTurnButton(
                      isBattleOver: state.isBattleOver,
                      onPressed: notifier.endTurn,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (state.isBattleOver)
            _BattleResultOverlay(
              result: state.result!,
              xpGained: BattleXpRewards.xpForStage(state.stage),
              goldEarned: BattleGoldRewards.forStage(state.stage),
              isBossBattle: isBossBattle,
              onReturnToMap: () => ref.read(runProvider.notifier).startReward(
                    remainingHp: state.playerHp,
                    goldEarned: BattleGoldRewards.forStage(state.stage),
                  ),
              onNewRun: () => ref.read(runProvider.notifier).startNewRun(),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          const Icon(Icons.shield, size: 13, color: BattleColors.torchGold),
          const SizedBox(width: 5),
          Text(
            '${BattleStrings.stageLabel} $stage',
            style: const TextStyle(
              color: BattleColors.torchGold,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          const Icon(Icons.local_fire_department, size: 13, color: BattleColors.torchOrange),
        ],
      ),
    );
  }
}

/// 플레이어 HP와 방어도를 좌측 하단에 표시하는 컴팩트 블록.
class _HpBlock extends StatelessWidget {
  final BattleState state;
  const _HpBlock({required this.state});

  static const double _barWidth = 116.0;

  @override
  Widget build(BuildContext context) {
    final ratio = (state.playerHp / state.playerMaxHp).clamp(0.0, 1.0);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: BattleColors.panelBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BattleColors.panelBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite, size: 12, color: BattleColors.playerHpBar),
                const SizedBox(width: 4),
                Text(
                  '${state.playerHp} / ${state.playerMaxHp}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: _barWidth,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 6,
                  backgroundColor: const Color(0xFF333333),
                  valueColor: const AlwaysStoppedAnimation<Color>(BattleColors.playerHpBar),
                ),
              ),
            ),
            if (state.playerBlock > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shield, size: 11, color: Color(0xFF64B5F6)),
                  const SizedBox(width: 3),
                  Text(
                    '${state.playerBlock}',
                    style: const TextStyle(
                      color: Color(0xFF64B5F6),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 현재/최대 에너지를 원형 테두리 안에 숫자로 표시한다.
///
/// 간결하고 시인성이 높아 한 손 조작 환경에서 빠른 파악이 가능하다.
class _EnergyCircle extends StatelessWidget {
  final int current;
  final int max;
  const _EnergyCircle({required this.current, required this.max});

  static const double _size = 64.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: BattleColors.panelBg,
        border: Border.all(color: BattleColors.torchGold, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: BattleColors.torchGold.withValues(alpha: 0.55),
            blurRadius: 14,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$current/$max',
            style: const TextStyle(
              color: BattleColors.torchGold,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'EP',
            style: TextStyle(
              color: BattleColors.torchGold.withValues(alpha: 0.65),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// 우하단에 배치되는 컴팩트 턴 종료 버튼.
class _EndTurnButton extends StatelessWidget {
  final bool isBattleOver;
  final VoidCallback onPressed;
  const _EndTurnButton({required this.isBattleOver, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isBattleOver ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: BattleColors.torchOrange,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFF333333),
        minimumSize: const Size(104, 38),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: BattleColors.torchGold, width: 1.2),
        ),
        elevation: 6,
        shadowColor: BattleColors.torchGold,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text(BattleStrings.endTurn, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          SizedBox(width: 4),
          Icon(Icons.arrow_forward_ios, size: 11),
        ],
      ),
    );
  }
}

/// 전투 결과 오버레이 (승리·패배·보스 클리어).
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
    return ColoredBox(
      color: const Color(0x99000000),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: BattleColors.panelBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _isVictory ? BattleColors.torchGold : const Color(0xFFB71C1C),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (_isVictory ? BattleColors.torchGold : const Color(0xFFB71C1C))
                    .withValues(alpha: 0.4),
                blurRadius: 20,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isVictory ? Icons.emoji_events : Icons.sentiment_very_dissatisfied,
                  size: 48,
                  color: _isVictory ? BattleColors.torchGold : const Color(0xFFEF5350),
                ),
                const SizedBox(height: 10),
                Text(
                  _titleText,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: _isVictory ? BattleColors.torchGold : const Color(0xFFEF5350),
                    letterSpacing: 1,
                  ),
                ),
                if (_isVictory) ...[
                  const SizedBox(height: 8),
                  Text(
                    BattleXpRewards.xpGainedLabel(xpGained),
                    style: const TextStyle(color: Color(0xFF66BB6A), fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
                if (_isVictory && !isBossBattle && goldEarned > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    BattleGoldRewards.goldLabel(goldEarned),
                    style: const TextStyle(color: BattleColors.torchGold, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _isVictory && !isBossBattle ? onReturnToMap : onNewRun,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isVictory ? BattleColors.torchOrange : const Color(0xFF455A64),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(_buttonLabel, style: const TextStyle(color: Colors.white, fontSize: 14)),
                ),
              ],
            ),
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

  String get _buttonLabel =>
      _isVictory && !isBossBattle ? BattleStrings.selectReward : BattleStrings.restart;
}
