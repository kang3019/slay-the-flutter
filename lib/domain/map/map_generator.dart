import 'map_node.dart';
import 'node_type.dart';

/// Act 맵을 생성하는 팩토리 클래스.
///
/// 순수 Dart 클래스 — Flutter·Riverpod 임포트 금지.
///
/// 생성 규칙 (SPECS.md §8):
/// - 시작 노드는 2~3개 (멀티 분기 출발).
/// - 중간 노드들은 합쳐지거나 갈라질 수 있다.
/// - 마지막 노드는 반드시 [NodeType.boss] 하나로 수렴.
/// - 모든 연결은 앞 방향(floor 증가)만 허용 — 역방향 금지.
class MapGenerator {
  MapGenerator._();

  // ──────────────────────────────────────────────────────────────
  // Act 1 고정 레이아웃 상수
  //
  //  Floor 0 [시작]: Monster(f0n0), Monster(f0n1), Event(f0n2)
  //  Floor 1 [중간]: Monster(f1n0), Elite(f1n1), Treasure(f1n2)
  //  Floor 2 [수렴]: Rest(f2n0), Shop(f2n1)
  //  Floor 3 [보스]: Boss(f3n0)
  //
  //  연결 구조:
  //    f0n0 → f1n0, f1n1
  //    f0n1 → f1n0, f1n2
  //    f0n2 → f1n1, f1n2
  //    f1n0 → f2n0, f2n1
  //    f1n1 → f2n0, f2n1
  //    f1n2 → f2n1
  //    f2n0 → f3n0
  //    f2n1 → f3n0
  //    f3n0 → (없음)
  // ──────────────────────────────────────────────────────────────

  static const _act1Connections = <String, List<String>>{
    // Floor 0 → 1
    'f0n0': ['f1n0', 'f1n1'],
    'f0n1': ['f1n0', 'f1n2'],
    'f0n2': ['f1n1', 'f1n2'],
    // Floor 1 → 2
    'f1n0': ['f2n0', 'f2n1'],
    'f1n1': ['f2n0', 'f2n1'],
    'f1n2': ['f2n1'],
    // Floor 2 → 3 (Boss)
    'f2n0': ['f3n0'],
    'f2n1': ['f3n0'],
    // Boss: 나가는 연결 없음
    'f3n0': [],
  };

  /// Act 1 (챕터 1) 맵을 생성한다.
  ///
  /// 총 9개 노드, 3-layer 분기·수렴 구조.
  /// 엘리트·상점·유물 보관소·휴식처를 각 1개 이상 보장한다.
  static List<MapNode> generateAct1() {
    final rawNodes = _act1RawNodes();
    return rawNodes
        .map(
          (n) => n.withConnections(
            List<String>.unmodifiable(_act1Connections[n.id] ?? const []),
          ),
        )
        .toList();
  }

  /// 연결 정보 없이 노드만 생성한다.
  /// [generateAct1]에서 [withConnections]로 연결을 붙인다.
  static List<MapNode> _act1RawNodes() => const [
        // ── Floor 0: 시작 노드 ─────────────────────────────────────
        MapNode(id: 'f0n0', type: NodeType.monster,  floor: 0, connectedNodeIds: []),
        MapNode(id: 'f0n1', type: NodeType.monster,  floor: 0, connectedNodeIds: []),
        MapNode(id: 'f0n2', type: NodeType.event,    floor: 0, connectedNodeIds: []),

        // ── Floor 1: 중간 노드 ─────────────────────────────────────
        MapNode(id: 'f1n0', type: NodeType.monster,  floor: 1, connectedNodeIds: []),
        MapNode(id: 'f1n1', type: NodeType.elite,    floor: 1, connectedNodeIds: []),
        MapNode(id: 'f1n2', type: NodeType.treasure, floor: 1, connectedNodeIds: []),

        // ── Floor 2: 보스 전 수렴 ──────────────────────────────────
        MapNode(id: 'f2n0', type: NodeType.rest,     floor: 2, connectedNodeIds: []),
        MapNode(id: 'f2n1', type: NodeType.shop,     floor: 2, connectedNodeIds: []),

        // ── Floor 3: 챕터 보스 ─────────────────────────────────────
        MapNode(id: 'f3n0', type: NodeType.boss,     floor: 3, connectedNodeIds: []),
      ];
}
