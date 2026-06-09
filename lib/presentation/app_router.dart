import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/battle_provider.dart';
import '../application/run_provider.dart';
import '../domain/map/node_type.dart';
import 'battle/battle_screen.dart';
import 'event/event_screen.dart';
import 'map/map_screen.dart';
import 'rest/rest_screen.dart';
import 'reward/reward_screen.dart';
import 'run_end/run_end_screen.dart';
import 'shared/top_bar_widget.dart';
import 'shop/shop_screen.dart';
import 'treasure/treasure_screen.dart';

/// 런(Run) 단계([RunPhase])에 따라 화면을 교체하는 최상위 라우터 위젯.
///
/// [RunPhase.runEnd]를 제외한 모든 단계에서 [TopBarWidget]이 상단에 고정된다.
/// [TopBarWidget]은 Stack 최상단에 [SafeArea]로 감싸 올려 놓아, 각 화면의
/// 레이아웃을 수정하지 않고 글로벌 HUD를 제공한다.
class AppRouter extends ConsumerWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(runProvider.select((s) => s.phase));

    ref.listen<RunState>(runProvider, (prev, next) {
      if (prev?.phase != RunPhase.battle && next.phase == RunPhase.battle) {
        ref.read(battleProvider.notifier).startBattle(
              next.currentStage,
              relics: next.relics,
              cards: next.deck,
              playerHp: next.playerHp,
              nodeType: next.currentNode?.type ?? NodeType.monster,
            );
      }
    });

    final screen = switch (phase) {
      RunPhase.map      => const MapScreen(),
      RunPhase.battle   => const BattleScreen(),
      RunPhase.reward   => const RewardScreen(),
      RunPhase.event    => const EventScreen(),
      RunPhase.treasure => const TreasureScreen(),
      RunPhase.rest     => const RestScreen(),
      RunPhase.shop     => const ShopScreen(),
      RunPhase.runEnd   => const RunEndScreen(),
    };

    // Map·Battle·RunEnd는 TopBar 불필요.
    // (Battle은 HUD에 골드가 포함되고, Map은 자체 상태표시가 있음)
    if (phase == RunPhase.map ||
        phase == RunPhase.battle ||
        phase == RunPhase.runEnd) {
      return screen;
    }

    return Stack(
      children: [
        screen,
        Positioned(
          top: 0, left: 0, right: 0,
          child: SafeArea(
            bottom: false,
            child: const TopBarWidget(),
          ),
        ),
      ],
    );
  }
}
