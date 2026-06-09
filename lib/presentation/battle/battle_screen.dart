import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/battle_provider.dart';
import '../../application/level_up_pending_provider.dart';
import '../../application/meta_progress_provider.dart';
import '../../application/run_provider.dart';
import '../../domain/battle_engine.dart';
import '../../domain/entities/card.dart';
import '../../domain/entities/monster.dart';
import '../../domain/entities/relic.dart';
import '../../domain/map/map_node.dart';
import '../../domain/map/node_type.dart';
import '../map/map_constants.dart';
import '../map/widgets/map_painter.dart';
import 'battle_constants.dart';
import 'particles/iron_golem_particle_game.dart';
import 'widgets/hand_widget.dart';
import 'widgets/looping_video_bg.dart';
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

class _BattleScreenState extends ConsumerState<BattleScreen>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<int>  _attackTrigger      = ValueNotifier(0);
  final ValueNotifier<int>  _monsterHitTrigger  = ValueNotifier(0);
  final ValueNotifier<bool> _monsterDeadTrigger = ValueNotifier(false);

  /// 철갑골렘 전용 파티클 게임 인스턴스 — 리빌드마다 재생성되지 않도록 late final로 보관.
  late final IronGolemParticleGame _particleGame = IronGolemParticleGame();

  late final AnimationController _shakeCtrl;
  late final Animation<double>   _shakeAnim;
  bool _showRedBorder      = false;
  bool _pendingEndTurnShake = false;

  bool _isProcessingXp = false;
  String? _levelUpBanner;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -6.0),  weight: 1),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 3.0),   weight: 1),
      TweenSequenceItem(tween: Tween(begin: 3.0, end: 0.0),    weight: 1),
    ]).animate(_shakeCtrl);
  }

  @override
  void dispose() {
    _attackTrigger.dispose();
    _monsterHitTrigger.dispose();
    _monsterDeadTrigger.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _handleCardTap(GameCard card) {
    if (card.effectType == CardEffectType.damage) {
      _attackTrigger.value++;
      _monsterHitTrigger.value++;
    }
    ref.read(battleProvider.notifier).playCard(card);
  }

  void _handleEndTurn() {
    _pendingEndTurnShake = true;
    ref.read(battleProvider.notifier).endTurn();
  }

  Future<void> _triggerDamageEffect({required bool redBorder}) async {
    if (!mounted) return;
    _shakeCtrl.forward(from: 0.0);
    if (redBorder) {
      setState(() => _showRedBorder = true);
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) setState(() => _showRedBorder = false);
    }
  }

  NodeType _currentNodeType() =>
      ref.read(runProvider).currentNode?.type ?? NodeType.monster;

  void _showMapPeek(BuildContext context) {
    final run = ref.read(runProvider);
    showDialog<void>(
      context: context,
      builder: (_) => _MapPeekDialog(
        mapNodes: run.mapNodes,
        currentNodeId: run.currentNodeId,
        visitedNodeIds: run.visitedNodeIds,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(battleProvider);
    final runState = ref.watch(runProvider);

    // ── 전투 종료 감지: XP 지급 + 레벨업 보상 트리거 ──────────────────────
    ref.listen<BattleState>(battleProvider, (prev, next) async {
      // HP 감소 시 빨간 테두리
      if (prev != null && next.playerHp < prev.playerHp) {
        _triggerDamageEffect(redBorder: true);
      }

      // 몬스터 공격 턴: 화면 흔들림 (HP 감소 없이 블록만 깎인 경우 포함)
      if (_pendingEndTurnShake && prev != null) {
        _pendingEndTurnShake = false;
        final wasAttack = prev.monsterIntentType == MonsterIntentType.attack ||
                          prev.monsterIntentType == MonsterIntentType.attackDebuff;
        if (wasAttack && next.playerHp >= prev.playerHp) {
          _triggerDamageEffect(redBorder: false);
        }
      }

      if (!next.isBattleOver || (prev?.isBattleOver ?? false)) return;

      // 승리 시 몬스터 사망 애니메이션 트리거
      if (next.result == BattleResult.playerWon) {
        _monsterDeadTrigger.value = true;
      }

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

          // 레벨업 시 배너를 2초간 표시한다. 카드 선택 없이 해금만 적용된다.
          if (levelUpResult.didLevelUp) {
            // 맵 화면 다이얼로그를 위해 결과를 보관한다.
            ref.read(levelUpPendingProvider.notifier).state = levelUpResult;

            setState(() {
              _levelUpBanner = 'LEVEL UP!  Lv.${levelUpResult.newLevel}';
            });
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) setState(() => _levelUpBanner = null);
            });
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
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              // StackFit.expand으로 resize 시 자식에 tight 제약 전달
              layoutBuilder: (currentChild, previousChildren) => Stack(
                fit: StackFit.expand,
                children: [
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              ),
              child: state.monsterType == MonsterType.ironGolem
                  ? Image.asset(
                      BattleAssets.ironGolemBg,
                      key: const ValueKey('ironGolem'),
                      fit: BoxFit.cover,
                    )
                  : const LoopingVideoBg(
                      key: ValueKey('video_bg'),
                      assetPath: BattleAssets.backgroundVideo,
                    ),
            ),
          ),
          // ── 철갑골렘 전용 파티클 오버레이 (보석 반짝임 + 검 이글거림) ───
          if (state.monsterType == MonsterType.ironGolem)
            Positioned.fill(
              child: IgnorePointer(
                child: GameWidget<IronGolemParticleGame>(
                  game: _particleGame,
                ),
              ),
            ),
          const Positioned.fill(child: ColoredBox(color: BattleColors.backgroundOverlay)),
          // ── 몬스터: 배경 문 앞에 위치 (자체 흔들림 포함) ──────────────
          _MonsterBackgroundImage(
            monsterType: state.monsterType,
            hitTrigger: _monsterHitTrigger,
            deadTrigger: _monsterDeadTrigger,
          ),
          // ── 플레이어 + UI: 화면 흔들림 적용 ────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _shakeAnim,
              child: Stack(
                children: [
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
                          _StageHeader(
                            stage: state.stage,
                            onMapPeek: () => _showMapPeek(context),
                          ),
                          const SizedBox(height: 8),
                          if (runState.relics.isNotEmpty) ...[
                            _RelicRow(relics: runState.relics),
                            const SizedBox(height: 4),
                          ],
                          if (state.lastRelicTriggers.isNotEmpty) ...[
                            _RelicTriggerRow(triggers: state.lastRelicTriggers),
                            const SizedBox(height: 4),
                          ],
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
                          Transform.translate(
                            offset: const Offset(0, 48),
                            child: HandWidget(
                              hand: state.hand,
                              energy: state.energy,
                              onCardTap: _handleCardTap,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _PlayerHud(state: state),
                                const SizedBox(width: 8),
                                _GoldChip(gold: runState.gold),
                                const Spacer(),
                                _EndTurnButton(
                                  isBattleOver: state.isBattleOver,
                                  onPressed: _handleEndTurn,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              builder: (context, child) => Transform.translate(
                offset: Offset(_shakeAnim.value, 0),
                child: child,
              ),
            ),
          ),
          // ── 피해 빨간 그라데이션 오버레이 ───────────────────────────────
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _showRedBorder ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 80),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.4,
                      colors: [
                        Color(0x00FF0000),
                        Color(0x00FF0000),
                        Color(0xBBFF0000),
                        Color(0xEEFF0000),
                      ],
                      stops: [0.0, 0.50, 0.78, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (state.isBattleOver && !_isProcessingXp)
            _BattleResultOverlay(
              result: state.result!,
              xpGained: xpGained,
              goldEarned: BattleGoldRewards.forStage(state.stage),
              isBossBattle: isBossBattle,
              onReturnToMap: () => ref.read(runProvider.notifier).startReward(
                    remainingHp: state.playerHp,
                    goldEarned: BattleGoldRewards.forStage(state.stage),
                  ),
              onEndRun: () => ref.read(runProvider.notifier).endRun(
                    remainingHp: state.playerHp,
                    goldEarned: BattleGoldRewards.forStage(state.stage),
                  ),
            ),
          // ── 레벨업 배너 (2초간 표시 후 자동 소멸) ───────────────────────
          if (_levelUpBanner != null)
            IgnorePointer(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xCC000000),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Color(0xFFFFD700), width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Color(0xFFFFD700), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _levelUpBanner!,
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── 비공개 위젯 ──────────────────────────────────────────────────────────────

class _StageHeader extends StatelessWidget {
  final int stage;
  final VoidCallback onMapPeek;
  const _StageHeader({required this.stage, required this.onMapPeek});

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
        GestureDetector(
          onTap: onMapPeek,
          child: const Row(
            children: [
              Icon(Icons.map_outlined, size: 13, color: BattleColors.torchGold),
              SizedBox(width: 3),
              Text(
                BattleStrings.peekMap,
                style: TextStyle(
                  color: BattleColors.torchGold,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
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

/// HP 패널 우측에 나란히 표시되는 골드 표시 칩.
class _GoldChip extends StatelessWidget {
  final int gold;
  const _GoldChip({required this.gold});

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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.monetization_on, size: 14, color: BattleColors.torchGold),
            const SizedBox(width: 5),
            Text(
              '$gold G',
              style: const TextStyle(
                color: BattleColors.torchGold,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
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
  final VoidCallback onEndRun;

  const _BattleResultOverlay({
    required this.result,
    required this.xpGained,
    required this.goldEarned,
    required this.isBossBattle,
    required this.onReturnToMap,
    required this.onEndRun,
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
                  onPressed: _isVictory && !isBossBattle ? onReturnToMap : onEndRun,
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

  String get _buttonLabel {
    if (_isVictory && !isBossBattle) return BattleStrings.selectReward;
    return BattleStrings.viewResult;
  }
}


/// 몬스터 이미지를 배경 문 앞에 배치한다.
/// 피격 시 좌우 흔들림, 사망 시 위로 드리프트하며 페이드아웃 모션을 재생한다.
class _MonsterBackgroundImage extends StatefulWidget {
  final MonsterType monsterType;
  final ValueNotifier<int>  hitTrigger;
  final ValueNotifier<bool> deadTrigger;
  const _MonsterBackgroundImage({
    required this.monsterType,
    required this.hitTrigger,
    required this.deadTrigger,
  });

  @override
  State<_MonsterBackgroundImage> createState() => _MonsterBackgroundImageState();
}

class _MonsterBackgroundImageState extends State<_MonsterBackgroundImage>
    with TickerProviderStateMixin {
  // 피격 흔들림
  late final AnimationController _hitCtrl;
  late final Animation<double>   _shake;

  // 사망 페이드아웃 + 드리프트
  late final AnimationController _deathCtrl;
  late final Animation<double>   _deathOpacity;
  late final Animation<double>   _deathOffsetY;

  @override
  void initState() {
    super.initState();

    _hitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _shake = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -14.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -14.0, end: 14.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 14.0, end: -8.0),  weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 4.0),   weight: 1),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: 0.0),    weight: 1),
    ]).animate(_hitCtrl);

    _deathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _deathOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _deathCtrl, curve: Curves.easeIn),
    );
    _deathOffsetY = Tween<double>(begin: 0.0, end: -40.0).animate(
      CurvedAnimation(parent: _deathCtrl, curve: Curves.easeOut),
    );

    widget.hitTrigger.addListener(_onHit);
    widget.deadTrigger.addListener(_onDead);
  }

  @override
  void dispose() {
    widget.hitTrigger.removeListener(_onHit);
    widget.deadTrigger.removeListener(_onDead);
    _hitCtrl.dispose();
    _deathCtrl.dispose();
    super.dispose();
  }

  void _onHit() => _hitCtrl.forward(from: 0.0);
  void _onDead() {
    if (widget.deadTrigger.value) _deathCtrl.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = MonsterAssets.forTypeName(widget.monsterType.name);
    if (imagePath == null) return const SizedBox.shrink();

    final screenH = MediaQuery.of(context).size.height;
    final isBoss  = widget.monsterType == MonsterType.ironGolem;
    final bottomOffset = isBoss ? screenH * 0.16 : screenH * 0.32;
    final imageHeight  = isBoss ? screenH * 0.50 : screenH * 0.33;

    return Positioned(
      bottom: bottomOffset,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: Listenable.merge([_hitCtrl, _deathCtrl]),
          child: Align(
            alignment: isBoss ? const Alignment(-0.15, 1.0) : Alignment.bottomCenter,
            child: Image.asset(
              imagePath,
              height: imageHeight,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ),
          builder: (context, child) => Transform.translate(
            offset: Offset(_shake.value, _deathOffsetY.value),
            child: Opacity(
              opacity: _deathOpacity.value,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// 전투 중 맵을 읽기 전용으로 엿볼 수 있는 다이얼로그.
class _MapPeekDialog extends StatelessWidget {
  final List<MapNode> mapNodes;
  final String? currentNodeId;
  final List<String> visitedNodeIds;

  const _MapPeekDialog({
    required this.mapNodes,
    required this.currentNodeId,
    required this.visitedNodeIds,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: MapColors.background,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Column(
        children: [
          // ── 타이틀 바 ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.map_outlined, color: Color(0xFFB8860B), size: 18),
                const SizedBox(width: 8),
                const Text(
                  '현재 지도',
                  style: TextStyle(
                    color: Color(0xFFB8860B),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close, color: Colors.white54, size: 20),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF3D3020), height: 1),
          // ── 맵 캔버스 (읽기 전용) ────────────────────────────────────
          Expanded(
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final size = computeCanvasSize(mapNodes, constraints.maxWidth);
                return SingleChildScrollView(
                  reverse: true,
                  child: CustomPaint(
                    size: size,
                    painter: MapPainter(
                      nodes: mapNodes,
                      currentNodeId: currentNodeId,
                      visitedNodeIds: visitedNodeIds,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
