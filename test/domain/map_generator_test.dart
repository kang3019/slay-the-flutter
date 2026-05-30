import 'package:flutter_test/flutter_test.dart';
import 'package:slay_the_flutter/domain/map/map_generator.dart';
import 'package:slay_the_flutter/domain/map/map_node.dart';
import 'package:slay_the_flutter/domain/map/node_type.dart';

void main() {
  group('MapGenerator.generateAct1', () {
    late List<MapNode> nodes;
    late Map<String, MapNode> nodeMap;

    setUp(() {
      nodes = MapGenerator.generateAct1();
      nodeMap = {for (final n in nodes) n.id: n};
    });

    // ──────────────────────────────────────────────
    // 구조적 무결성
    // ──────────────────────────────────────────────

    test('보스 노드는 정확히 하나이다', () {
      final bossNodes = nodes.where((n) => n.type == NodeType.boss).toList();
      expect(bossNodes.length, 1);
    });

    test('보스 노드는 가장 높은 floor에 위치한다', () {
      final maxFloor =
          nodes.map((n) => n.floor).reduce((a, b) => a > b ? a : b);
      final bossNode = nodes.firstWhere((n) => n.type == NodeType.boss);
      expect(bossNode.floor, equals(maxFloor));
    });

    test('보스 노드는 나가는 연결(connectedNodeIds)이 없다', () {
      final bossNode = nodes.firstWhere((n) => n.type == NodeType.boss);
      expect(bossNode.connectedNodeIds, isEmpty);
    });

    test('시작 노드(floor 0)가 2개 이상 존재한다', () {
      final startNodes = nodes.where((n) => n.floor == 0).toList();
      expect(startNodes.length, greaterThanOrEqualTo(2));
    });

    test('모든 노드 ID는 유일하다', () {
      final ids = nodes.map((n) => n.id).toList();
      expect(ids.toSet().length, equals(ids.length));
    });

    test('보스 이외의 모든 노드는 나가는 연결이 하나 이상이다', () {
      for (final node in nodes) {
        if (node.type == NodeType.boss) continue;
        expect(
          node.connectedNodeIds,
          isNotEmpty,
          reason: '노드 ${node.id}(${node.type})는 나가는 연결이 없음',
        );
      }
    });

    // ──────────────────────────────────────────────
    // 방향성 무결성 — "역방향 이동 없음" 핵심 검증
    // ──────────────────────────────────────────────

    test('모든 연결은 앞 방향(더 높은 floor)으로만 존재한다 — 역방향 없음', () {
      for (final node in nodes) {
        for (final connId in node.connectedNodeIds) {
          final target = nodeMap[connId]!;
          expect(
            target.floor,
            greaterThan(node.floor),
            reason:
                '${node.id}(floor ${node.floor}) → '
                '${target.id}(floor ${target.floor}): 역방향 또는 같은 floor 연결 금지',
          );
        }
      }
    });

    test('연결된 노드 ID는 모두 실제 존재하는 노드를 참조한다', () {
      final allIds = nodes.map((n) => n.id).toSet();
      for (final node in nodes) {
        for (final connId in node.connectedNodeIds) {
          expect(
            allIds,
            contains(connId),
            reason: '노드 ${node.id}의 connectedNodeId "$connId" 가 존재하지 않음',
          );
        }
      }
    });

    // ──────────────────────────────────────────────
    // 도달 가능성 — "모든 시작 → 보스" 핵심 검증
    // ──────────────────────────────────────────────

    test('모든 시작 노드에서 보스까지 경로가 존재한다', () {
      final bossNode = nodes.firstWhere((n) => n.type == NodeType.boss);
      final startNodes = nodes.where((n) => n.floor == 0).toList();

      for (final start in startNodes) {
        expect(
          _canReach(start.id, bossNode.id, nodeMap),
          isTrue,
          reason: '시작 노드 ${start.id}에서 보스(${bossNode.id})까지 경로 없음',
        );
      }
    });

    test('floor 1 이상의 모든 노드는 최소 하나의 시작 노드에서 도달 가능하다', () {
      final startNodes = nodes.where((n) => n.floor == 0).toList();
      final reachableFromStart = <String>{};

      for (final start in startNodes) {
        _collectReachable(start.id, nodeMap, reachableFromStart);
      }

      for (final node in nodes.where((n) => n.floor > 0)) {
        expect(
          reachableFromStart,
          contains(node.id),
          reason: '노드 ${node.id}(floor ${node.floor})는 어떤 시작 노드에서도 도달 불가',
        );
      }
    });

    // ──────────────────────────────────────────────
    // 콘텐츠 보장 (SPECS.md §8)
    // ──────────────────────────────────────────────

    test('엘리트 노드가 하나 이상 존재한다', () {
      expect(nodes.any((n) => n.type == NodeType.elite), isTrue);
    });

    test('상점 노드가 하나 이상 존재한다', () {
      expect(nodes.any((n) => n.type == NodeType.shop), isTrue);
    });

    test('휴식처 또는 유물 보관소 노드가 하나 이상 존재한다', () {
      final hasRestOrTreasure = nodes.any(
        (n) => n.type == NodeType.rest || n.type == NodeType.treasure,
      );
      expect(hasRestOrTreasure, isTrue);
    });

    test('총 노드 수는 6개 이상이다', () {
      expect(nodes.length, greaterThanOrEqualTo(6));
    });
  });
}

/// BFS로 [startId]에서 [targetId]까지 도달 가능한지 확인한다.
bool _canReach(
  String startId,
  String targetId,
  Map<String, MapNode> nodeMap,
) {
  final visited = <String>{};
  final queue = [startId];

  while (queue.isNotEmpty) {
    final current = queue.removeAt(0);
    if (current == targetId) return true;
    if (visited.contains(current)) continue;
    visited.add(current);

    final node = nodeMap[current];
    if (node != null) {
      queue.addAll(node.connectedNodeIds);
    }
  }
  return false;
}

/// BFS로 [startId]에서 도달 가능한 모든 노드 ID를 [result]에 수집한다.
void _collectReachable(
  String startId,
  Map<String, MapNode> nodeMap,
  Set<String> result,
) {
  final visited = <String>{};
  final queue = [startId];

  while (queue.isNotEmpty) {
    final current = queue.removeAt(0);
    if (visited.contains(current)) continue;
    visited.add(current);
    result.add(current);

    final node = nodeMap[current];
    if (node != null) {
      queue.addAll(node.connectedNodeIds);
    }
  }
}
