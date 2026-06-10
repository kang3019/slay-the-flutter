import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slay_the_flutter/application/meta_progress_provider.dart';
import 'package:slay_the_flutter/application/run_provider.dart';
import 'package:slay_the_flutter/data/local_storage.dart';
import 'package:slay_the_flutter/domain/entities/card.dart';
import 'package:slay_the_flutter/domain/entities/meta_progress.dart';
import 'package:slay_the_flutter/domain/entities/player.dart';
import 'package:slay_the_flutter/domain/events/game_event.dart';
import 'package:slay_the_flutter/domain/map/map_node.dart';
import 'package:slay_the_flutter/domain/map/node_type.dart';

/// 테스트용 고정 맵 — 구 Act 1 레이아웃 (5층 12노드).
///
/// 절차적 생성에 의존하지 않고 하드코딩된 노드 ID로 테스트할 수 있도록
/// [mapNodesProvider]에 주입하는 결정론적 맵이다.
///
/// 레이아웃:
///   Floor 0: f0n0(monster), f0n1(monster), f0n2(event)
///   Floor 1: f1n0(monster), f1n1(elite),   f1n2(treasure)
///   Floor 2: f2n0(rest),    f2n1(shop),    f2n2(monster)
///   Floor 3: f3n0(elite),   f3n1(rest)
///   Floor 4: f4n0(boss)
const _testMapNodes = <MapNode>[
  MapNode(id: 'f0n0', type: NodeType.monster,  floor: 0, connectedNodeIds: ['f1n0', 'f1n1']),
  MapNode(id: 'f0n1', type: NodeType.monster,  floor: 0, connectedNodeIds: ['f1n1', 'f1n2']),
  MapNode(id: 'f0n2', type: NodeType.event,    floor: 0, connectedNodeIds: ['f1n2']),
  MapNode(id: 'f1n0', type: NodeType.monster,  floor: 1, connectedNodeIds: ['f2n0', 'f2n1']),
  MapNode(id: 'f1n1', type: NodeType.elite,    floor: 1, connectedNodeIds: ['f2n1', 'f2n2']),
  MapNode(id: 'f1n2', type: NodeType.treasure, floor: 1, connectedNodeIds: ['f2n2']),
  MapNode(id: 'f2n0', type: NodeType.rest,     floor: 2, connectedNodeIds: ['f3n0']),
  MapNode(id: 'f2n1', type: NodeType.shop,     floor: 2, connectedNodeIds: ['f3n0', 'f3n1']),
  MapNode(id: 'f2n2', type: NodeType.monster,  floor: 2, connectedNodeIds: ['f3n1']),
  MapNode(id: 'f3n0', type: NodeType.elite,    floor: 3, connectedNodeIds: ['f4n0']),
  MapNode(id: 'f3n1', type: NodeType.rest,     floor: 3, connectedNodeIds: ['f4n0']),
  MapNode(id: 'f4n0', type: NodeType.boss,     floor: 4, connectedNodeIds: []),
];

/// 고정 테스트 맵과 LocalStorage를 주입한 [ProviderContainer]를 반환한다.
///
/// 보상 풀은 MetaProgress.unlockedCardTypes로 필터링되므로,
/// 모든 카드가 해금된 레벨 10 상태를 prefs에 주입해 기존 테스트가 통과하도록 한다.
Future<ProviderContainer> _makeContainer() async {
  final allUnlocked = MetaProgress.computeUnlockedCards(10);
  SharedPreferences.setMockInitialValues({
    'meta_level': 10,
    'meta_xp': MetaProgress.xpThresholds.last,
    'meta_unlocked_cards': jsonEncode(allUnlocked),
  });
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [
      mapNodesProvider.overrideWith((_) => _testMapNodes),
      localStorageProvider.overrideWithValue(LocalStorage(prefs)),
    ],
  );
}

void main() {
  group('RunNotifier', () {
    late ProviderContainer container;

    setUp(() async => container = await _makeContainer());
    tearDown(() => container.dispose());

    // ──────────────────────────────────────────────
    // 초기 상태
    // ──────────────────────────────────────────────

    group('초기 상태', () {
      test('floor는 -1이다 (시작 전)', () {
        expect(container.read(runProvider).floor, -1);
      });

      test('currentNodeId는 null이다', () {
        expect(container.read(runProvider).currentNodeId, isNull);
      });

      test('플레이어 HP는 최대치(70)이다', () {
        expect(container.read(runProvider).playerHp, Player.maxHp);
      });

      test('골드는 0이다', () {
        expect(container.read(runProvider).gold, 0);
      });

      test('기본 덱은 10장이다 (강타 5 + 방어 5)', () {
        expect(container.read(runProvider).deck.length, 10);
      });

      test('isRunOver는 false이다', () {
        expect(container.read(runProvider).isRunOver, isFalse);
      });

      test('visitedNodeIds는 비어 있다', () {
        expect(container.read(runProvider).visitedNodeIds, isEmpty);
      });

      test('맵 노드가 존재한다', () {
        expect(container.read(runProvider).mapNodes, isNotEmpty);
      });
    });

    // ──────────────────────────────────────────────
    // moveToNode — 첫 이동
    // ──────────────────────────────────────────────

    group('moveToNode — 첫 이동', () {
      test('floor 0 노드로 이동하면 currentNodeId와 floor가 갱신된다', () {
        final state = container.read(runProvider);
        final startNode = state.mapNodes.firstWhere((n) => n.floor == 0);

        container.read(runProvider.notifier).moveToNode(startNode.id);

        final after = container.read(runProvider);
        expect(after.currentNodeId, equals(startNode.id));
        expect(after.floor, 0);
      });

      test('floor 0이 아닌 노드로 첫 이동하면 상태가 변하지 않는다', () {
        final state = container.read(runProvider);
        final nonStartNode = state.mapNodes.firstWhere((n) => n.floor > 0);

        container.read(runProvider.notifier).moveToNode(nonStartNode.id);

        final after = container.read(runProvider);
        expect(after.currentNodeId, isNull);
        expect(after.floor, -1);
      });

      test('이동하면 visitedNodeIds에 기록된다', () {
        final state = container.read(runProvider);
        final startNode = state.mapNodes.firstWhere((n) => n.floor == 0);

        container.read(runProvider.notifier).moveToNode(startNode.id);

        expect(
          container.read(runProvider).visitedNodeIds,
          contains(startNode.id),
        );
      });

      test('존재하지 않는 nodeId로 이동하면 상태가 변하지 않는다', () {
        container.read(runProvider.notifier).moveToNode('invalid_id');

        expect(container.read(runProvider).currentNodeId, isNull);
        expect(container.read(runProvider).floor, -1);
      });
    });

    // ──────────────────────────────────────────────
    // moveToNode — 연속 이동
    // ──────────────────────────────────────────────

    group('moveToNode — 연속 이동', () {
      test('현재 노드에 연결된 다음 노드로 이동할 수 있다', () {
        final notifier = container.read(runProvider.notifier);
        final mapNodes = container.read(runProvider).mapNodes;
        final nodeMap = {for (final n in mapNodes) n.id: n};

        final startNode = mapNodes.firstWhere((n) => n.floor == 0);
        notifier.moveToNode(startNode.id);

        final nextNodeId = startNode.connectedNodeIds.first;
        notifier.moveToNode(nextNodeId);

        final after = container.read(runProvider);
        expect(after.currentNodeId, equals(nextNodeId));
        expect(after.floor, equals(nodeMap[nextNodeId]!.floor));
      });

      test('현재 노드에 연결되지 않은 노드로 이동하면 상태가 변하지 않는다', () {
        final notifier = container.read(runProvider.notifier);
        final mapNodes = container.read(runProvider).mapNodes;

        final startNode = mapNodes.firstWhere((n) => n.floor == 0);
        notifier.moveToNode(startNode.id);

        // 보스 노드(floor 3)는 floor 0에서 직접 연결되어 있지 않다.
        final bossNode = mapNodes.firstWhere((n) => n.type == NodeType.boss);
        notifier.moveToNode(bossNode.id);

        final after = container.read(runProvider);
        expect(after.currentNodeId, equals(startNode.id));
        expect(after.floor, 0);
      });

      test('여러 노드를 순서대로 이동하면 visitedNodeIds에 모두 기록된다', () {
        final notifier = container.read(runProvider.notifier);
        final mapNodes = container.read(runProvider).mapNodes;

        // floor 0 → floor 1 → floor 2 경로 탐색
        final f0 = mapNodes.firstWhere((n) => n.floor == 0);
        notifier.moveToNode(f0.id);

        final f1Id = f0.connectedNodeIds.first;
        notifier.moveToNode(f1Id);

        final f1 = mapNodes.firstWhere((n) => n.id == f1Id);
        final f2Id = f1.connectedNodeIds.first;
        notifier.moveToNode(f2Id);

        final visited = container.read(runProvider).visitedNodeIds;
        expect(visited, containsAll([f0.id, f1Id, f2Id]));
        expect(visited.length, 3);
      });
    });

    // ──────────────────────────────────────────────
    // applyBattleResult
    // ──────────────────────────────────────────────

    group('applyBattleResult', () {
      test('전투 결과를 반영하면 HP와 골드가 갱신된다', () {
        container.read(runProvider.notifier).applyBattleResult(
              remainingHp: 50,
              goldEarned: 20,
            );

        final state = container.read(runProvider);
        expect(state.playerHp, 50);
        expect(state.gold, 20);
      });

      test('HP가 최대치를 초과하지 않는다', () {
        container.read(runProvider.notifier).applyBattleResult(
              remainingHp: 9999,
              goldEarned: 0,
            );

        expect(container.read(runProvider).playerHp, Player.maxHp);
      });

      test('HP가 0 이하이면 isRunOver가 true가 된다 (패배)', () {
        container.read(runProvider.notifier).applyBattleResult(
              remainingHp: 0,
              goldEarned: 0,
            );

        expect(container.read(runProvider).isRunOver, isTrue);
      });

      test('HP가 남아 있으면 isRunOver가 false를 유지한다', () {
        container.read(runProvider.notifier).applyBattleResult(
              remainingHp: 1,
              goldEarned: 0,
            );

        expect(container.read(runProvider).isRunOver, isFalse);
      });

      test('골드가 누적된다', () {
        final notifier = container.read(runProvider.notifier);
        notifier.applyBattleResult(remainingHp: 70, goldEarned: 15);
        notifier.applyBattleResult(remainingHp: 70, goldEarned: 20);

        expect(container.read(runProvider).gold, 35);
      });
    });

    // ──────────────────────────────────────────────
    // addCardToDeck / removeCardFromDeck
    // ──────────────────────────────────────────────

    group('addCardToDeck / removeCardFromDeck', () {
      test('addCardToDeck 하면 덱이 1장 늘어난다', () {
        final before = container.read(runProvider).deck.length;
        container.read(runProvider.notifier).addCardToDeck(Cards.bash);
        expect(container.read(runProvider).deck.length, before + 1);
      });

      test('removeCardFromDeck 하면 덱이 1장 줄어든다', () {
        container.read(runProvider.notifier).addCardToDeck(Cards.bash);
        final before = container.read(runProvider).deck.length;
        container.read(runProvider.notifier).removeCardFromDeck(Cards.bash);
        expect(container.read(runProvider).deck.length, before - 1);
      });

      test('존재하지 않는 카드를 제거해도 상태가 변하지 않는다', () {
        final before = container.read(runProvider).deck.length;
        // 기본 덱에는 bash가 없다.
        container.read(runProvider.notifier).removeCardFromDeck(Cards.bash);
        expect(container.read(runProvider).deck.length, before);
      });

      test('같은 카드가 여러 장이면 첫 번째만 제거된다', () {
        container.read(runProvider.notifier).addCardToDeck(Cards.bash);
        container.read(runProvider.notifier).addCardToDeck(Cards.bash);
        final before = container.read(runProvider).deck.length;

        container.read(runProvider.notifier).removeCardFromDeck(Cards.bash);

        expect(container.read(runProvider).deck.length, before - 1);
        // bash가 1장 남아 있어야 한다.
        expect(
          container.read(runProvider).deck.where((c) => c == Cards.bash).length,
          1,
        );
      });
    });

    // ──────────────────────────────────────────────
    // isRunOver 상태에서의 보호
    // ──────────────────────────────────────────────

    group('isRunOver 보호', () {
      test('런 종료 후 moveToNode를 호출해도 상태가 변하지 않는다', () {
        // HP 0으로 런 종료
        container.read(runProvider.notifier).applyBattleResult(
              remainingHp: 0,
              goldEarned: 0,
            );

        final beforeNodeId = container.read(runProvider).currentNodeId;
        final startNode =
            container.read(runProvider).mapNodes.firstWhere((n) => n.floor == 0);
        container.read(runProvider.notifier).moveToNode(startNode.id);

        // 런이 끝났으므로 이동 불가.
        expect(container.read(runProvider).currentNodeId, equals(beforeNodeId));
      });
    });

    // ──────────────────────────────────────────────
    // RunPhase 전환
    // ──────────────────────────────────────────────

    group('RunPhase 전환', () {
      test('초기 phase는 RunPhase.map이다', () {
        expect(container.read(runProvider).phase, RunPhase.map);
      });

      test('Monster 노드로 이동하면 phase가 RunPhase.battle이 된다', () {
        // f0n0은 NodeType.monster — 전투 전환 노드
        container.read(runProvider.notifier).moveToNode('f0n0');

        expect(container.read(runProvider).phase, RunPhase.battle);
      });

      test('Elite 노드로 이동하면 phase가 RunPhase.battle이 된다', () {
        // f0n1(monster)로 먼저 이동 후 f1n1(elite)로 이동
        container.read(runProvider.notifier).moveToNode('f0n1');
        container.read(runProvider.notifier).moveToNode('f1n1');

        expect(container.read(runProvider).phase, RunPhase.battle);
      });

      test('Event 노드로 이동하면 phase가 RunPhase.event가 된다', () {
        // f0n2는 NodeType.event
        container.read(runProvider.notifier).moveToNode('f0n2');

        expect(container.read(runProvider).phase, RunPhase.event);
      });

      test('exitBattleToMap 호출 시 phase가 RunPhase.map으로 전환된다', () {
        container.read(runProvider.notifier).moveToNode('f0n0'); // battle
        expect(container.read(runProvider).phase, RunPhase.battle);

        container.read(runProvider.notifier).exitBattleToMap(
          remainingHp: 60,
          goldEarned: 15,
        );

        expect(container.read(runProvider).phase, RunPhase.map);
      });

      test('exitBattleToMap 호출 시 HP와 골드가 갱신된다', () {
        container.read(runProvider.notifier).moveToNode('f0n0');
        container.read(runProvider.notifier).exitBattleToMap(
          remainingHp: 55,
          goldEarned: 20,
        );

        final state = container.read(runProvider);
        expect(state.playerHp, 55);
        expect(state.gold, 20);
      });

      test('exitBattleToMap HP가 최대치를 초과하지 않는다', () {
        container.read(runProvider.notifier).moveToNode('f0n0');
        container.read(runProvider.notifier).exitBattleToMap(
          remainingHp: 9999,
          goldEarned: 0,
        );

        expect(container.read(runProvider).playerHp, Player.maxHp);
      });

      test('Boss 노드에서 exitBattleToMap 호출 시 isRunOver가 true가 된다', () {
        final notifier = container.read(runProvider.notifier);

        // f0n0(monster) → f1n0(monster) → f2n0(rest) → f3n0(elite) → f4n0(boss) 경로
        notifier.moveToNode('f0n0');
        notifier.moveToNode('f1n0');
        notifier.moveToNode('f2n0');
        notifier.moveToNode('f3n0');
        notifier.moveToNode('f4n0');

        expect(container.read(runProvider).currentNodeId, 'f4n0');

        notifier.exitBattleToMap(remainingHp: 40, goldEarned: 0);

        expect(container.read(runProvider).isRunOver, isTrue);
      });

      test('일반 노드에서 exitBattleToMap 호출 시 isRunOver가 false를 유지한다', () {
        final notifier = container.read(runProvider.notifier);
        notifier.moveToNode('f0n0');
        notifier.exitBattleToMap(remainingHp: 60, goldEarned: 15);

        expect(container.read(runProvider).isRunOver, isFalse);
      });
    });

    // ──────────────────────────────────────────────
    // startReward / selectRewardCard / skipReward
    // ──────────────────────────────────────────────

    group('startReward', () {
      test('startReward 호출 시 phase가 RunPhase.reward가 된다', () {
        container.read(runProvider.notifier).startReward(
          remainingHp: 60,
          goldEarned: 10,
        );
        expect(container.read(runProvider).phase, RunPhase.reward);
      });

      test('startReward 호출 시 HP는 갱신되지만 골드는 보류 상태로 대기한다', () {
        final goldBefore = container.read(runProvider).gold;
        container.read(runProvider.notifier).startReward(
          remainingHp: 55,
          goldEarned: 15,
        );
        final state = container.read(runProvider);
        expect(state.playerHp, 55);
        expect(state.gold, goldBefore);
        expect(state.pendingGoldReward, 15);
        expect(state.goldClaimed, isFalse);
      });

      test('startReward 호출 시 rewardCards가 정확히 3장이다', () {
        container.read(runProvider.notifier).startReward(
          remainingHp: 70,
          goldEarned: 0,
        );
        expect(container.read(runProvider).rewardCards.length, 3);
      });

      test('rewardCards는 기본 덱(강타·방어)이 아닌 카드로만 구성된다', () {
        container.read(runProvider.notifier).startReward(
          remainingHp: 70,
          goldEarned: 0,
        );
        final cards = container.read(runProvider).rewardCards;
        for (final card in cards) {
          expect(card.type, isNot(CardType.strike));
          expect(card.type, isNot(CardType.defend));
        }
      });
    });

    group('claimGoldReward', () {
      test('호출 시 pendingGoldReward만큼 gold가 증가하고 goldClaimed가 true가 된다', () {
        final notifier = container.read(runProvider.notifier);
        final goldBefore = container.read(runProvider).gold;
        notifier.startReward(remainingHp: 60, goldEarned: 20);

        notifier.claimGoldReward();

        final state = container.read(runProvider);
        expect(state.gold, goldBefore + 20);
        expect(state.goldClaimed, isTrue);
      });

      test('이미 획득한 골드는 다시 호출해도 중복 지급되지 않는다', () {
        final notifier = container.read(runProvider.notifier);
        notifier.startReward(remainingHp: 60, goldEarned: 20);
        notifier.claimGoldReward();
        final goldAfterFirstClaim = container.read(runProvider).gold;

        notifier.claimGoldReward();

        expect(container.read(runProvider).gold, goldAfterFirstClaim);
      });

      test('reward 페이즈가 아닐 때 claimGoldReward는 아무것도 하지 않는다', () {
        final goldBefore = container.read(runProvider).gold;
        container.read(runProvider.notifier).claimGoldReward();
        expect(container.read(runProvider).gold, goldBefore);
      });
    });

    group('selectRewardCard', () {
      test('카드를 선택하면 덱에 추가되고 phase가 RunPhase.map이 된다', () {
        container.read(runProvider.notifier).startReward(
          remainingHp: 70,
          goldEarned: 0,
        );
        final rewardCard = container.read(runProvider).rewardCards.first;
        final deckBefore = container.read(runProvider).deck.length;

        container.read(runProvider.notifier).selectRewardCard(rewardCard);

        final state = container.read(runProvider);
        expect(state.phase, RunPhase.map);
        expect(state.deck.length, deckBefore + 1);
        expect(state.rewardCards, isEmpty);
        expect(state.pendingGoldReward, 0);
        expect(state.goldClaimed, isFalse);
      });

      test('골드를 획득하지 않은 상태로 카드를 선택하면 보류 골드가 자동으로 합산된다', () {
        final notifier = container.read(runProvider.notifier);
        final goldBefore = container.read(runProvider).gold;
        notifier.startReward(remainingHp: 70, goldEarned: 15);
        final rewardCard = container.read(runProvider).rewardCards.first;

        notifier.selectRewardCard(rewardCard);

        final state = container.read(runProvider);
        expect(state.gold, goldBefore + 15);
        expect(state.pendingGoldReward, 0);
        expect(state.goldClaimed, isFalse);
      });

      test('골드를 이미 획득한 상태로 카드를 선택하면 골드가 중복 합산되지 않는다', () {
        final notifier = container.read(runProvider.notifier);
        notifier.startReward(remainingHp: 70, goldEarned: 15);
        notifier.claimGoldReward();
        final goldAfterClaim = container.read(runProvider).gold;
        final rewardCard = container.read(runProvider).rewardCards.first;

        notifier.selectRewardCard(rewardCard);

        expect(container.read(runProvider).gold, goldAfterClaim);
      });

      test('reward 페이즈가 아닐 때 selectRewardCard는 아무것도 하지 않는다', () {
        final deckBefore = container.read(runProvider).deck.length;
        container.read(runProvider.notifier).selectRewardCard(Cards.bash);
        expect(container.read(runProvider).deck.length, deckBefore);
      });
    });

    group('skipReward', () {
      test('건너뛰기 시 덱이 변하지 않고 phase가 RunPhase.map이 된다', () {
        container.read(runProvider.notifier).startReward(
          remainingHp: 70,
          goldEarned: 0,
        );
        final deckBefore = container.read(runProvider).deck.length;

        container.read(runProvider.notifier).skipReward();

        final state = container.read(runProvider);
        expect(state.phase, RunPhase.map);
        expect(state.deck.length, deckBefore);
        expect(state.rewardCards, isEmpty);
        expect(state.pendingGoldReward, 0);
        expect(state.goldClaimed, isFalse);
      });

      test('건너뛰기 시 미획득 골드가 자동으로 합산된다', () {
        final notifier = container.read(runProvider.notifier);
        final goldBefore = container.read(runProvider).gold;
        notifier.startReward(remainingHp: 70, goldEarned: 12);

        notifier.skipReward();

        final state = container.read(runProvider);
        expect(state.gold, goldBefore + 12);
        expect(state.pendingGoldReward, 0);
        expect(state.goldClaimed, isFalse);
      });

      test('reward 페이즈가 아닐 때 skipReward는 아무것도 하지 않는다', () {
        expect(container.read(runProvider).phase, RunPhase.map);
        container.read(runProvider.notifier).skipReward();
        expect(container.read(runProvider).phase, RunPhase.map);
      });
    });

    // ──────────────────────────────────────────────
    // resolveEvent
    // ──────────────────────────────────────────────

    group('resolveEvent', () {
      void enterEventNode() {
        // f0n2는 NodeType.event
        container.read(runProvider.notifier).moveToNode('f0n2');
      }

      test('Event 노드 진입 시 currentEvent가 설정된다', () {
        enterEventNode();
        expect(container.read(runProvider).currentEvent, isNotNull);
      });

      test('resolveEvent 후 phase가 RunPhase.map으로 돌아간다', () {
        enterEventNode();
        final choice = container.read(runProvider).currentEvent!.choices[0];
        container.read(runProvider.notifier).resolveEvent(choice);
        expect(container.read(runProvider).phase, RunPhase.map);
      });

      test('resolveEvent 후 currentEvent가 null이 된다', () {
        enterEventNode();
        final choice = container.read(runProvider).currentEvent!.choices[0];
        container.read(runProvider.notifier).resolveEvent(choice);
        expect(container.read(runProvider).currentEvent, isNull);
      });

      test('HP 회복 효과가 적용된다', () {
        // HP를 50으로 낮춘 뒤 이벤트로 회복
        container.read(runProvider.notifier).applyBattleResult(
          remainingHp: 50,
          goldEarned: 0,
        );
        enterEventNode();

        const healChoice = EventChoice(
          label: '테스트',
          effectDescription: 'HP +15',
          resultDescription: '',
          effect: EventEffect(hpDelta: 15),
        );
        container.read(runProvider.notifier).resolveEvent(healChoice);

        expect(container.read(runProvider).playerHp, 65);
      });

      test('HP는 최대치를 초과하지 않는다', () {
        // 만피에서 회복 시도
        enterEventNode();
        const healChoice = EventChoice(
          label: '테스트',
          effectDescription: 'HP +999',
          resultDescription: '',
          effect: EventEffect(hpDelta: 999),
        );
        container.read(runProvider.notifier).resolveEvent(healChoice);
        expect(container.read(runProvider).playerHp, Player.maxHp);
      });

      test('HP 피해 효과가 적용된다', () {
        enterEventNode();
        const damageChoice = EventChoice(
          label: '테스트',
          effectDescription: 'HP -8',
          resultDescription: '',
          effect: EventEffect(hpDelta: -8),
        );
        container.read(runProvider.notifier).resolveEvent(damageChoice);
        expect(container.read(runProvider).playerHp, Player.maxHp - 8);
      });

      test('HP는 1 미만으로 내려가지 않는다 (이벤트로 사망 없음)', () {
        enterEventNode();
        const damageChoice = EventChoice(
          label: '테스트',
          effectDescription: 'HP -9999',
          resultDescription: '',
          effect: EventEffect(hpDelta: -9999),
        );
        container.read(runProvider.notifier).resolveEvent(damageChoice);
        expect(container.read(runProvider).playerHp, 1);
      });

      test('골드 획득 효과가 적용된다', () {
        enterEventNode();
        const goldChoice = EventChoice(
          label: '테스트',
          effectDescription: '골드 +25',
          resultDescription: '',
          effect: EventEffect(goldDelta: 25),
        );
        container.read(runProvider.notifier).resolveEvent(goldChoice);
        expect(container.read(runProvider).gold, 25);
      });

      test('addRandomCard가 true면 덱에 카드가 1장 추가된다', () {
        enterEventNode();
        final deckBefore = container.read(runProvider).deck.length;
        const cardChoice = EventChoice(
          label: '테스트',
          effectDescription: '카드 획득',
          resultDescription: '',
          effect: EventEffect(addRandomCard: true),
        );
        container.read(runProvider.notifier).resolveEvent(cardChoice);
        expect(container.read(runProvider).deck.length, deckBefore + 1);
      });

      test('event 페이즈가 아닐 때 resolveEvent는 아무것도 하지 않는다', () {
        final hpBefore = container.read(runProvider).playerHp;
        const choice = EventChoice(
          label: '테스트',
          effectDescription: 'HP +15',
          resultDescription: '',
          effect: EventEffect(hpDelta: 15),
        );
        container.read(runProvider.notifier).resolveEvent(choice);
        expect(container.read(runProvider).playerHp, hpBefore);
      });
    });

    // ──────────────────────────────────────────────
    // recordXpGain
    // ──────────────────────────────────────────────

    group('recordXpGain', () {
      test('xpGainedThisRun이 누적된다', () {
        final notifier = container.read(runProvider.notifier);

        notifier.recordXpGain(xp: 10);
        notifier.recordXpGain(xp: 5);

        expect(container.read(runProvider).xpGainedThisRun, 15);
      });

      test('newlyUnlockedCardsThisRun에 신규 해금 카드가 중복 없이 누적된다', () {
        final notifier = container.read(runProvider.notifier);

        notifier.recordXpGain(xp: 10, newlyUnlockedCards: ['bash', 'swiftCut']);
        notifier.recordXpGain(xp: 10, newlyUnlockedCards: ['swiftCut', 'ironWall']);

        final unlocked = container.read(runProvider).newlyUnlockedCardsThisRun;
        expect(unlocked.toSet(), {'bash', 'swiftCut', 'ironWall'});
        expect(unlocked.length, 3);
      });
    });

    // ──────────────────────────────────────────────
    // startNewRun
    // ──────────────────────────────────────────────

    group('startNewRun', () {
      test('startNewRun 호출 시 모든 상태가 초기화된다', () {
        final notifier = container.read(runProvider.notifier);
        final mapNodes = container.read(runProvider).mapNodes;
        final startNode = mapNodes.firstWhere((n) => n.floor == 0);

        notifier.moveToNode(startNode.id);
        notifier.applyBattleResult(remainingHp: 30, goldEarned: 20);
        notifier.addCardToDeck(Cards.bash);
        notifier.startNewRun();

        final state = container.read(runProvider);
        expect(state.floor, -1);
        expect(state.currentNodeId, isNull);
        expect(state.playerHp, Player.maxHp);
        expect(state.gold, 0);
        expect(state.deck.length, 10);
        expect(state.visitedNodeIds, isEmpty);
        expect(state.isRunOver, isFalse);
        expect(state.phase, RunPhase.map);
        expect(state.rewardCards, isEmpty);
      });

      test('startNewRun 호출 시 보상·XP 누적 필드가 초기화된다', () {
        final notifier = container.read(runProvider.notifier);

        notifier.recordXpGain(xp: 50, newlyUnlockedCards: ['bash']);
        notifier.startReward(remainingHp: 30, goldEarned: 10);

        notifier.startNewRun();

        final state = container.read(runProvider);
        expect(state.pendingGoldReward, 0);
        expect(state.goldClaimed, isFalse);
        expect(state.xpGainedThisRun, 0);
        expect(state.newlyUnlockedCardsThisRun, isEmpty);
      });
    });
  });
}
