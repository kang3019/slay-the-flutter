import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/battle_provider.dart';
import '../../application/meta_progress_provider.dart';
import '../../application/run_provider.dart';
import '../../domain/battle_engine.dart';
import '../../domain/entities/card.dart';
import '../../domain/entities/meta_progress.dart';
import '../../domain/entities/monster.dart';
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

  /// XP 계산(async)이 진행 중인 동안 true — 결과 오버레이를 가려 레이스 컨디션을 방지.
  bool _isProcessingXp = false;

  /// 레벨업 발생 시 보상 카드 선택 오버레이 표시용 상태.
  LevelUpResult? _pendingLevelUp;

  /// 레벨업 보상 풀에서 무작위로 뽑은 3장.
  List<GameCard> _levelUpRewardCards = const [];

  final _random = Random();

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

  NodeType _currentNodeType() =>
      ref.read(runProvider).currentNode?.type ?? NodeType.monster;

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(battleProvider);
    final runState = ref.watch(runProvider);

    // ── 전투 종료 감지: XP 지급 + 레벨업 보상 트리거 ──────────────────────
    ref.listen<BattleState>(battleProvider, (prev, next) async {
      if (!next.isBattleOver || (prev?.isBattleOver ?? false)) return;

      // XP 처리 시작: 결과 오버레이를 숨겨 조기 탭을 방지한다.
      if (mounted) setState(() => _isProcessingXp = true);

      try {
        final nodeType  = _currentNodeType();
        final isVictory = next.result == BattleResult.playerWon;
        final xp        = BattleXpRewards.xpFor(nodeType, isVictory: isVictory);

        if (xp > 0) {
          final levelUpResult =
              await ref.read(metaProgressProvider.notifier).addXp(xp);

          if (!mounted) return;

          // 일반·엘리트 승리에서 레벨업 시 보상 카드 제공.
          // 보스 또는 패배 시는 런이 종료 또는 무의미하므로 생략.
          if (levelUpResult.didLevelUp && isVictory && nodeType != NodeType.boss) {
            final pool = List<GameCard>.of(
              MetaProgress.rewardPoolForLevel(levelUpResult.newLevel),
            )..shuffle(_random);
            setState(() {
              _isProcessingXp     = false;
              _pendingLevelUp     = levelUpResult;
              _levelUpRewardCards = pool.take(3).toList();
            });
            return;
          }
        }
      } catch (_) {
        // XP 저장 실패 시에도 전투 결과 오버레이는 반드시 표시한다.
      }

      if (mounted) setState(() => _isProcessingXp = false);
    });

    final isBossBattle = runState.currentNode?.type == NodeType.boss;
    final nodeType     = runState.currentNode?.type ?? NodeType.monster;
    final isVictory    = state.result == BattleResult.playerWon;
    final xpGained     = state.isBattleOver
        ? BattleXpRewards.xpFor(nodeType, isVictory: isVictory)
        : 0;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset(BattleAssets.background, fit: BoxFit.cover)),
          const Positioned.fill(child: ColoredBox(color: BattleColors.backgroundOverlay)),
          // ── 몬스터: 배경 문 앞에 위치 ───────────────────────────────────
          _MonsterBackgroundImage(monsterType: state.monsterType),
          // ── 플레이어 캐릭터: 하단 레이어 ────────────────────────────────
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
                    monsterType: state.monsterType,
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
          if (state.isBattleOver && !_isProcessingXp && _pendingLevelUp == null)
            _BattleResultOverlay(
              result: state.result!,
              xpGained: xpGained,
              goldEarned: BattleGoldRewards.forStage(state.stage),
              isBossBattle: isBossBattle,
              onReturnToMap: () => ref.read(runProvider.notifier).startReward(
                    remainingHp: state.playerHp,
                    goldEarned: BattleGoldRewards.forStage(state.stage),
                  ),
              onNewRun: () => ref.read(runProvider.notifier).startNewRun(),
            ),
          // ── 레벨업 보상 카드 선택 오버레이 ──────────────────────────────
          if (_pendingLevelUp != null)
            _LevelUpRewardOverlay(
              result: _pendingLevelUp!,
              rewardCards: _levelUpRewardCards,
              onCardSelected: (card) {
                ref.read(runProvider.notifier).addCardToDeck(card);
                setState(() => _pendingLevelUp = null);
                // 레벨업 보상 선택 후 일반 결과 오버레이로 이동.
                // 다음 build()에서 _pendingLevelUp == null 이 되어
                // _BattleResultOverlay 가 표시된다.
              },
              onSkip: () => setState(() => _pendingLevelUp = null),
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
                // ── XP 표시 (승리·패배 모두) ──────────────────────────
                if (xpGained > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    _isVictory
                        ? BattleXpRewards.xpGainedLabel(xpGained)
                        : BattleXpRewards.xpLostLabel(xpGained),
                    style: TextStyle(
                      color: _isVictory
                          ? const Color(0xFF66BB6A)
                          : const Color(0xFF90A4AE),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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

/// 레벨업 보상 카드 선택 오버레이.
///
/// 일반·엘리트 전투 승리 후 레벨업 시 표시되며, 3장 중 1장을 덱에 추가한다.
class _LevelUpRewardOverlay extends StatelessWidget {
  final LevelUpResult result;
  final List<GameCard> rewardCards;
  final ValueChanged<GameCard> onCardSelected;
  final VoidCallback onSkip;

  const _LevelUpRewardOverlay({
    required this.result,
    required this.rewardCards,
    required this.onCardSelected,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xCC000000),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── 레벨업 타이틀 ─────────────────────────────────────
              const Icon(Icons.star, size: 48, color: Color(0xFFFFD700)),
              const SizedBox(height: 8),
              Text(
                'LEVEL UP!  Lv.${result.previousLevel} → Lv.${result.newLevel}',
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '덱에 추가할 카드를 선택하세요',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 24),
              // ── 카드 3장 ─────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: rewardCards.map((card) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _LevelUpCardItem(
                    card: card,
                    onTap: () => onCardSelected(card),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: onSkip,
                child: const Text(
                  '건너뛰기',
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelUpCardItem extends StatelessWidget {
  final GameCard card;
  final VoidCallback onTap;
  const _LevelUpCardItem({required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color  = BattleColors.forCard(card.effectType);
    final border = BattleColors.borderForCard(card.effectType);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0A07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 1.5),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              card.name,
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              BattleStrings.cardEffect(card),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                card.cost < 0 ? 'X' : '${card.cost} EP',
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 몬스터 이미지를 배경 문 앞에 배치한다.
///
/// 오버레이 위에 그려져 몬스터가 던전 문을 막고 서 있는 것처럼 보인다.
class _MonsterBackgroundImage extends StatelessWidget {
  final MonsterType monsterType;
  const _MonsterBackgroundImage({required this.monsterType});

  @override
  Widget build(BuildContext context) {
    final imagePath = MonsterAssets.forTypeName(monsterType.name);
    if (imagePath == null) return const SizedBox.shrink();

    final screenH = MediaQuery.of(context).size.height;
    return Positioned(
      top: screenH * 0.08,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Align(
          alignment: Alignment.topCenter,
          child: Image.asset(
            imagePath,
            height: screenH * 0.42,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );
  }
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
