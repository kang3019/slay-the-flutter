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
import 'shared/run_bottom_hud.dart';
import 'shared/top_bar_widget.dart';
import 'shop/shop_screen.dart';
import 'treasure/treasure_screen.dart';

/// 런(Run) 단계([RunPhase])에 따라 화면을 교체하는 최상위 라우터 위젯.
///
/// [RunPhase.reward]·[RunPhase.runEnd]를 제외한 모든 단계에서
/// [TopBarWidget]이 상단에 고정된다. [TopBarWidget]은 Stack 최상단에
/// [SafeArea]로 감싸 올려 놓아, 각 화면의 레이아웃을 수정하지 않고
/// 글로벌 HUD를 제공한다.
///
/// [RunPhase.reward]·[RunPhase.runEnd]는 [BattleScreen] 위에 겹쳐 그려
/// (전투 결과를 보여주는) 팝업처럼 표시된다. [_BattleStack]을 참고.
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
      RunPhase.battle   => const _BattleStack(overlay: SizedBox.shrink()),
      RunPhase.reward   => const _BattleStack(overlay: RewardScreen()),
      RunPhase.event    => const EventScreen(),
      RunPhase.treasure => const TreasureScreen(),
      RunPhase.rest     => const RestScreen(),
      RunPhase.shop     => const ShopScreen(),
      RunPhase.runEnd   => const _BattleStack(overlay: RunEndScreen()),
    };

    // Map·Battle·Reward·RunEnd는 TopBar 불필요.
    // (Battle은 HUD에 골드가 포함되고, Map은 자체 상태표시가 있음.
    //  Reward·RunEnd는 전투 화면 위 팝업이라 전투 HUD가 그대로 비친다)
    if (phase == RunPhase.map ||
        phase == RunPhase.battle ||
        phase == RunPhase.reward ||
        phase == RunPhase.runEnd ||
        phase == RunPhase.shop) {
      return screen;
    }

    // 이벤트·강화 화면은 TopBar 대신 하단 HUD로 HP·골드 표시 및 지도 접근 제공.
    if (phase == RunPhase.event || phase == RunPhase.rest) {
      return Column(
        children: [
          Expanded(child: screen),
          const RunBottomHud(),
        ],
      );
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

/// [BattleScreen]을 항상 바닥에 깔고 [overlay]를 그 위에 겹쳐 그린다.
///
/// [RunPhase.battle]→[RunPhase.reward]/[RunPhase.runEnd] 전환 시에도
/// [BattleScreen]이 같은 트리 위치([Stack]의 첫 번째 자식)를 유지해
/// 위젯이 재생성되지 않는다. 덕분에 몬스터 처치 애니메이션·배경 영상 같은
/// 진행 중인 상태가 끊기지 않고, 결과 팝업 아래로 전투 장면이 그대로 비친다.
class _BattleStack extends StatelessWidget {
  const _BattleStack({required this.overlay});

  /// [RunPhase.battle]일 때는 [SizedBox.shrink]로 비워 둔다.
  final Widget overlay;

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          const BattleScreen(),
          overlay,
        ],
      );
}
