import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/battle_provider.dart';
import '../application/run_provider.dart';
import 'battle/battle_screen.dart';
import 'event/event_screen.dart';
import 'map/map_screen.dart';
import 'reward/reward_screen.dart';
import 'rest/rest_screen.dart';
import 'treasure/treasure_screen.dart';

/// 런(Run) 단계([RunPhase])에 따라 [MapScreen]과 [BattleScreen]을 교체하는
/// 최상위 라우터 위젯.
///
/// **화면 전환 흐름:**
/// ```
/// 지도에서 전투 노드 탭
///   → RunNotifier.moveToNode() → RunPhase.battle
///   → AppRouter 감지 → BattleScreen 표시
///                     + BattleNotifier.startBattle(stage) 자동 호출
///
/// 전투 승리 후 "맵으로 이동" 탭
///   → RunNotifier.exitBattleToMap() → RunPhase.map
///   → AppRouter 감지 → MapScreen 복귀
/// ```
///
/// Navigator를 사용하지 않고 [RunPhase] 값만으로 화면을 결정하는 이유:
/// - 런 전체가 단일 '상태 머신'이므로 뒤로가기(Back) 개념이 없다.
/// - 화면 전환 로직이 Application 계층([RunNotifier])에 집중되어 테스트 가능하다.
class AppRouter extends ConsumerWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(runProvider.select((s) => s.phase));

    // ── 단계 전환 감지: map → battle ──────────────────────────────────────
    // RunPhase가 battle로 바뀌는 순간 BattleNotifier에 올바른 스테이지로
    // 새 전투를 시작하도록 지시한다.
    //
    // ref.listen은 build() 안에서 호출하는 것이 Riverpod 2.x 공식 패턴이다.
    // 콜백은 상태가 바뀔 때마다 한 번만 실행되며, build를 다시 트리거하지 않는다.
    ref.listen<RunState>(runProvider, (prev, next) {
      if (prev?.phase != RunPhase.battle && next.phase == RunPhase.battle) {
        // 새 전투 시작 — 유물 목록을 함께 전달해 전투 시작 시 유물 효과를 적용한다.
        ref.read(battleProvider.notifier).startBattle(
              next.currentStage,
              relics: next.relics,
            );
      }
    });

    // ── 단계에 따른 화면 결정 ─────────────────────────────────────────────
    return switch (phase) {
      RunPhase.map      => const MapScreen(),
      RunPhase.battle   => const BattleScreen(),
      RunPhase.reward   => const RewardScreen(),
      RunPhase.event    => const EventScreen(),
      RunPhase.treasure => const TreasureScreen(),
      RunPhase.rest     => const RestScreen(),
    };
  }
}
