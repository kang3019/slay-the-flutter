import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slay_the_flutter/application/run_provider.dart';
import 'package:slay_the_flutter/domain/entities/card.dart';
import 'package:slay_the_flutter/domain/entities/player.dart';
import 'package:slay_the_flutter/domain/map/node_type.dart';

void main() {
  group('RunNotifier', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
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

      test('비전투 노드(Event)로 첫 이동하면 phase가 map을 유지한다', () {
        // f0n2는 NodeType.event — 비전투 노드
        container.read(runProvider.notifier).moveToNode('f0n2');

        expect(container.read(runProvider).phase, RunPhase.map);
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

      test('startReward 호출 시 HP와 골드가 갱신된다', () {
        container.read(runProvider.notifier).startReward(
          remainingHp: 55,
          goldEarned: 15,
        );
        final state = container.read(runProvider);
        expect(state.playerHp, 55);
        expect(state.gold, 15);
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
      });

      test('reward 페이즈가 아닐 때 skipReward는 아무것도 하지 않는다', () {
        expect(container.read(runProvider).phase, RunPhase.map);
        container.read(runProvider.notifier).skipReward();
        expect(container.read(runProvider).phase, RunPhase.map);
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
    });
  });
}
