import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:slay_the_flutter/domain/map/map_generator.dart';
import 'package:slay_the_flutter/domain/map/map_node.dart';
import 'package:slay_the_flutter/domain/map/node_type.dart';

// 여러 시드로 돌려서 확률적 불변식을 검증한다.
const _seeds = [0, 7, 42, 100, 777, 1234, 9999, 31415, 65536, 99991];

void main() {
  List<MapNode> nodesFor(int seed) =>
      MapGenerator.generateAct1(random: Random(seed));

  Map<String, MapNode> nodeMapOf(List<MapNode> nodes) =>
      {for (final n in nodes) n.id: n};

  void forAllSeeds(
    String description,
    void Function(List<MapNode> nodes, Map<String, MapNode> nodeMap) body,
  ) {
    test(description, () {
      for (final seed in _seeds) {
        final nodes   = nodesFor(seed);
        final nodeMap = nodeMapOf(nodes);
        body(nodes, nodeMap);
      }
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 1. 구조적 무결성
  // ──────────────────────────────────────────────────────────────────────────

  group('[구조] 맵 기본 형태', () {
    forAllSeeds('총 12층(Floor 0-11)이 모두 존재한다', (nodes, _) {
      final floors = nodes.map((n) => n.floor).toSet();
      for (int f = 0; f <= 11; f++) {
        expect(floors, contains(f), reason: 'Floor $f 가 존재하지 않음');
      }
      expect(floors.length, 12);
    });

    forAllSeeds('모든 노드 ID는 유일하다', (nodes, _) {
      final ids = nodes.map((n) => n.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    forAllSeeds('Floor 0 노드 수는 3~4개다', (nodes, _) {
      final count = nodes.where((n) => n.floor == 0).length;
      expect(count, inInclusiveRange(3, 4));
    });

    forAllSeeds('보스 이외의 모든 노드는 나가는 연결이 하나 이상이다', (nodes, _) {
      for (final node in nodes.where((n) => n.type != NodeType.boss)) {
        expect(
          node.connectedNodeIds,
          isNotEmpty,
          reason: '${node.id}(${node.type}, floor ${node.floor}) 나가는 연결 없음',
        );
      }
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 2. 방향성 무결성
  // ──────────────────────────────────────────────────────────────────────────

  group('[방향성] 연결 무결성', () {
    forAllSeeds('모든 연결은 더 높은 floor로만 향한다 (역방향 없음)', (nodes, nodeMap) {
      for (final node in nodes) {
        for (final connId in node.connectedNodeIds) {
          expect(
            nodeMap[connId]!.floor,
            greaterThan(node.floor),
            reason:
                '${node.id}(floor ${node.floor}) → '
                '$connId(floor ${nodeMap[connId]!.floor}): 역방향 금지',
          );
        }
      }
    });

    forAllSeeds('연결된 노드 ID는 모두 실존 노드를 참조한다', (nodes, nodeMap) {
      for (final node in nodes) {
        for (final connId in node.connectedNodeIds) {
          expect(nodeMap, contains(connId),
              reason: '${node.id}의 연결 "$connId" 가 존재하지 않음');
        }
      }
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 3. 도달 가능성
  // ──────────────────────────────────────────────────────────────────────────

  group('[도달성] 모든 경로 연결', () {
    forAllSeeds('모든 시작 노드(floor 0)에서 보스까지 경로가 존재한다', (nodes, nodeMap) {
      final boss = nodes.firstWhere((n) => n.type == NodeType.boss);
      for (final start in nodes.where((n) => n.floor == 0)) {
        expect(_canReach(start.id, boss.id, nodeMap), isTrue,
            reason: '${start.id}에서 보스(${boss.id})까지 경로 없음');
      }
    });

    forAllSeeds('Floor 1 이상의 모든 노드는 시작 노드에서 도달 가능하다', (nodes, nodeMap) {
      final reachable = <String>{};
      for (final start in nodes.where((n) => n.floor == 0)) {
        _collectReachable(start.id, nodeMap, reachable);
      }
      for (final node in nodes.where((n) => n.floor > 0)) {
        expect(reachable, contains(node.id),
            reason: '${node.id}(floor ${node.floor}) 도달 불가');
      }
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 4. 고정 노드 룰
  // ──────────────────────────────────────────────────────────────────────────

  group('[고정 노드] Floor별 강제 타입', () {
    forAllSeeds('Floor 0 노드는 모두 Monster다', (nodes, _) {
      for (final node in nodes.where((n) => n.floor == 0)) {
        expect(node.type, NodeType.monster,
            reason: '${node.id}(floor 0)이 Monster가 아님: ${node.type}');
      }
    });

    forAllSeeds('Floor 5 노드는 모두 Treasure다', (nodes, _) {
      final floor5 = nodes.where((n) => n.floor == 5).toList();
      expect(floor5, isNotEmpty, reason: 'Floor 5 노드 없음');
      for (final node in floor5) {
        expect(node.type, NodeType.treasure,
            reason: '${node.id}(floor 5)이 Treasure가 아님: ${node.type}');
      }
    });

    forAllSeeds('Floor 10 노드는 모두 Rest다', (nodes, _) {
      final floor10 = nodes.where((n) => n.floor == 10).toList();
      expect(floor10, isNotEmpty, reason: 'Floor 10 노드 없음');
      for (final node in floor10) {
        expect(node.type, NodeType.rest,
            reason: '${node.id}(floor 10)이 Rest가 아님: ${node.type}');
      }
    });

    forAllSeeds('Floor 11은 노드가 정확히 1개이고 Boss다', (nodes, _) {
      final floor11 = nodes.where((n) => n.floor == 11).toList();
      expect(floor11.length, 1, reason: 'Floor 11 노드가 1개가 아님');
      expect(floor11.first.type, NodeType.boss);
    });

    forAllSeeds('Boss 노드는 나가는 연결이 없다', (nodes, _) {
      final boss = nodes.firstWhere((n) => n.type == NodeType.boss);
      expect(boss.connectedNodeIds, isEmpty);
    });

    forAllSeeds('Boss 노드는 정확히 1개다', (nodes, _) {
      expect(nodes.where((n) => n.type == NodeType.boss).length, 1);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 5. Treasure 전용 룰
  // ──────────────────────────────────────────────────────────────────────────

  group('[Treasure] Floor 5 전용', () {
    forAllSeeds('Treasure는 Floor 5에서만 등장한다', (nodes, _) {
      for (final node in nodes.where((n) => n.type == NodeType.treasure)) {
        expect(node.floor, 5,
            reason:
                '${node.id}(floor ${node.floor})에 Treasure: Floor 5 전용 위반');
      }
    });

    forAllSeeds('Floor 5 이외의 비고정 층에는 Treasure가 없다', (nodes, _) {
      for (final node in nodes.where((n) => n.floor != 5)) {
        expect(node.type, isNot(NodeType.treasure),
            reason: '${node.id}(floor ${node.floor})에 Treasure 배치됨');
      }
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 6. Elite 룰
  // ──────────────────────────────────────────────────────────────────────────

  group('[Elite] 배치 제약', () {
    forAllSeeds('Floor 0~3에는 Elite 노드가 없다', (nodes, _) {
      for (final node in nodes.where((n) => n.floor <= 3)) {
        expect(node.type, isNot(NodeType.elite),
            reason: '${node.id}(floor ${node.floor})에 Elite가 배치됨');
      }
    });

    forAllSeeds(
        'Elite 노드의 직접 연결 대상이 Elite인 경우가 없다 (연속 Elite 불가)',
        (nodes, nodeMap) {
      for (final node in nodes.where((n) => n.type == NodeType.elite)) {
        for (final connId in node.connectedNodeIds) {
          expect(nodeMap[connId]!.type, isNot(NodeType.elite),
              reason:
                  '${node.id}(Elite) → $connId(Elite): 연속 Elite 금지 위반');
        }
      }
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 7. Shop 룰
  // ──────────────────────────────────────────────────────────────────────────

  group('[Shop] 배치 제약', () {
    forAllSeeds(
        'Shop 노드의 직접 연결 대상이 Shop인 경우가 없다 (연속 Shop 불가)',
        (nodes, nodeMap) {
      for (final node in nodes.where((n) => n.type == NodeType.shop)) {
        for (final connId in node.connectedNodeIds) {
          expect(nodeMap[connId]!.type, isNot(NodeType.shop),
              reason:
                  '${node.id}(Shop) → $connId(Shop): 연속 Shop 금지 위반');
        }
      }
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 8. Rest 룰
  // ──────────────────────────────────────────────────────────────────────────

  group('[Rest] 배치 제약', () {
    forAllSeeds(
        'Rest 노드의 직접 연결 대상이 Rest인 경우가 없다 (연속 Rest 불가)',
        (nodes, nodeMap) {
      for (final node in nodes.where((n) => n.type == NodeType.rest)) {
        for (final connId in node.connectedNodeIds) {
          expect(nodeMap[connId]!.type, isNot(NodeType.rest),
              reason:
                  '${node.id}(Rest) → $connId(Rest): 연속 Rest 금지 위반');
        }
      }
    });

    forAllSeeds(
        'Floor 9 노드는 Rest가 없다 (Floor 10이 Rest이므로 연속 방지)',
        (nodes, _) {
      for (final node in nodes.where((n) => n.floor == 9)) {
        expect(node.type, isNot(NodeType.rest),
            reason: '${node.id}(floor 9)이 Rest: Floor 10(Rest)와 연속됨');
      }
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 9. 콘텐츠 보장
  // ──────────────────────────────────────────────────────────────────────────

  group('[콘텐츠] 필수 노드 보장', () {
    forAllSeeds('Elite 노드가 하나 이상 존재한다', (nodes, _) {
      expect(nodes.any((n) => n.type == NodeType.elite), isTrue,
          reason: 'Elite 노드 없음');
    });

    forAllSeeds('Shop 노드가 하나 이상 존재한다', (nodes, _) {
      expect(nodes.any((n) => n.type == NodeType.shop), isTrue,
          reason: 'Shop 노드 없음');
    });

    forAllSeeds('Treasure 노드가 하나 이상 존재한다 (Floor 5 고정)', (nodes, _) {
      expect(nodes.any((n) => n.type == NodeType.treasure), isTrue,
          reason: 'Treasure 노드 없음');
    });

    forAllSeeds('Rest 노드가 하나 이상 존재한다 (Floor 10 고정)', (nodes, _) {
      expect(nodes.any((n) => n.type == NodeType.rest), isTrue,
          reason: 'Rest 노드 없음');
    });
  });
}

// ── 테스트 유틸리티 ──────────────────────────────────────────────────────────

bool _canReach(
  String startId,
  String targetId,
  Map<String, MapNode> nodeMap,
) {
  final visited = <String>{};
  final queue   = [startId];
  while (queue.isNotEmpty) {
    final current = queue.removeAt(0);
    if (current == targetId) return true;
    if (!visited.add(current)) continue;
    queue.addAll(nodeMap[current]?.connectedNodeIds ?? const []);
  }
  return false;
}

void _collectReachable(
  String startId,
  Map<String, MapNode> nodeMap,
  Set<String> result,
) {
  final visited = <String>{};
  final queue   = [startId];
  while (queue.isNotEmpty) {
    final current = queue.removeAt(0);
    if (!visited.add(current)) continue;
    result.add(current);
    queue.addAll(nodeMap[current]?.connectedNodeIds ?? const []);
  }
}
