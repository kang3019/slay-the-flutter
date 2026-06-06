import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/battle_provider.dart';
import '../../application/meta_progress_provider.dart';
import '../../application/run_provider.dart';
import '../../domain/battle_engine.dart';
import '../../domain/entities/card.dart';
import '../../domain/entities/relic.dart';
import '../../domain/map/node_type.dart';
import 'battle_constants.dart';
import 'widgets/hand_widget.dart';
import 'widgets/monster_widget.dart';
import 'widgets/player_character_widget.dart';

/// 전투 화면. 배경 이미지 위에 반투명 패널을 올린 다크 판타지 레이아웃.
///
/// 카드 아래 하단 바: 좌측에 [_PlayerHud](HP·에너지·상태이상), 우측에 턴 종료 버튼.
/// 공격 카드 사용 시 [PlayerCharacterWidget]의 공격 모션을 트리거한다.
class BattleScreen extends ConsumerStatefulWidget {
  const BattleScreen({super.key});

  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends ConsumerState<BattleScreen> {
  /// 공격 카드를 낼 때마다 값을 증가시켜 캐릭터 애니메이션을 트리거한다.
  final ValueNotifier<int> _attackTrigger = ValueNotifier(0);

  @override
  void dispose() {
    _attackTrigger.dispose();
    super.dispose();
  }

  /// 카드를 사용할 때 공격 카드면 캐릭터 모션을 동시에 실행한다.
  void _handleCardTap(GameCard card) {
    if (card.effectType == CardEffectType.damage) {
      _attackTrigger.value++;
    }
    ref.read(battleProvider.notifier).playCard(card);
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(battleProvider);
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
          // ── 플레이어 캐릭터: 카드 패 아래 레이어 ───────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: PlayerCharacterWidget(attackTrigger: _attackTrigger),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StageHeader(stage: state.stage),
                  const SizedBox(height: 8),
                  if (runState.relics.isNotEmpty) ...[
                    _RelicRow(relics: runState.relics),
                    const SizedBox(height: 4),
                  ],
                  if (state.lastRelicTriggers.isNotEmpty) ...[
                    _RelicTriggerRow(triggers: state.lastRelicTriggers),
                    const SizedBox(height: 4),
                  ],
                  // ── 몬스터 영역 ─────────────────────────────────────────
                  MonsterWidget(
                    hp: state.monsterHp,
                    maxHp: state.monsterMaxHp,
                    block: state.monsterBlock,
                    name: state.monsterName,
                    intentType: state.monsterIntentType,
                    intentLabel: state.monsterIntentLabel,
                    intentDescription: state.monsterIntentDescription,
                    attackPower: state.monsterAttackPower,
                    isVulnerable: state.monsterIsVulnerable,
                    isWeak: state.monsterIsWeak,
                    poisonStacks: state.monsterPoisonStacks,
                  ),
                  const Spacer(),
                  // ── 손패 ────────────────────────────────────────────────
                  Transform.translate(
                    offset: const Offset(0, 48),
                    child: HandWidget(
                      hand: state.hand,
                      energy: state.energy,
                      onCardTap: _handleCardTap,
                    ),
                  ),
                  // ── 하단 바: HP/에너지(좌) + 턴 종료(우) ────────────────
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _PlayerHud(state: state),
                        const Spacer(),
                        _EndTurnButton(
                          isBattleOver: state.isBattleOver,
                          onPressed: ref.read(battleProvider.notifier).endTurn,
                        ),
                      ],
                    ),
                  ),
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
    return Row(
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
    );
  }
}

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

/// 좌측 하단 컴팩트 HUD: HP 바 + 에너지 + 상태이상.
class _PlayerHud extends StatelessWidget {
  final BattleState state;
  const _PlayerHud({required this.state});

  static const Color _kHpColor = Color(0xFF66BB6A);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: BattleColors.panelBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: BattleColors.panelBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── HP 수치 + 방어도 ──────────────────────────────────────
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite, size: 14, color: _kHpColor),
                const SizedBox(width: 5),
                Text(
                  '${state.playerHp} / ${state.playerMaxHp}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (state.playerBlock > 0) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.shield, size: 13, color: Color(0xFF64B5F6)),
                  const SizedBox(width: 3),
                  Text(
                    '${state.playerBlock}',
                    style: const TextStyle(
                      color: Color(0xFF64B5F6),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 5),
            // ── HP 바 ─────────────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 160,
                child: LinearProgressIndicator(
                  value: (state.playerHp / state.playerMaxHp).clamp(0.0, 1.0),
                  minHeight: 12,
                  backgroundColor: const Color(0xFF333333),
                  valueColor: const AlwaysStoppedAnimation<Color>(_kHpColor),
                ),
              ),
            ),
            const SizedBox(height: 7),
            // ── 에너지 ────────────────────────────────────────────────
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt, size: 14, color: BattleColors.torchGold),
                const SizedBox(width: 4),
                Text(
                  '${state.energy} / ${state.maxEnergy} EP',
                  style: const TextStyle(
                    color: BattleColors.torchGold,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            // ── 상태이상 ──────────────────────────────────────────────
            if (state.playerIsVulnerable || state.playerIsWeak || state.playerPoisonStacks > 0) ...[
              const SizedBox(height: 5),
              Wrap(
                spacing: 4,
                children: [
                  if (state.playerIsVulnerable)
                    _SmallChip(
                      label: BattleStrings.vulnerable,
                      description: BattleStrings.vulnerableDescription,
                      color: Colors.orange[800]!,
                    ),
                  if (state.playerIsWeak)
                    _SmallChip(
                      label: BattleStrings.weak,
                      description: BattleStrings.weakDescription,
                      color: Colors.purple[700]!,
                    ),
                  if (state.playerPoisonStacks > 0)
                    _SmallChip(
                      label: '${BattleStrings.poison} ${state.playerPoisonStacks}',
                      description: BattleStrings.poisonDescription,
                      color: Colors.green[700]!,
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

class _SmallChip extends StatelessWidget {
  final String label;
  final String description;
  final Color color;
  const _SmallChip({
    required this.label,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF16213E),
          title: Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          content: Text(
            description,
            style: const TextStyle(color: Colors.white70, height: 1.6),
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// 우하단에 배치되는 턴 종료 버튼.
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
        minimumSize: const Size(148, 56),
        padding: const EdgeInsets.symmetric(horizontal: 20),
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
          Text(BattleStrings.endTurn, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(width: 6),
          Icon(Icons.arrow_forward_ios, size: 14),
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

/// 직전 턴 종료 시 발동된 유물 효과를 황금 태그로 나열한다.
class _RelicTriggerRow extends StatelessWidget {
  final List<String> triggers;
  const _RelicTriggerRow({required this.triggers});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final t in triggers)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFD700), width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield, size: 11, color: Color(0xFFFFD700)),
                const SizedBox(width: 4),
                Text(
                  t,
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
