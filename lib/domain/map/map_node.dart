import 'node_type.dart';

/// 맵의 단일 노드. 위치(floor)·종류·연결 관계를 보유하는 불변 값 객체.
///
/// 순수 Dart 클래스 — Flutter·Riverpod 임포트 금지.
///
/// [connectedNodeIds]는 이 노드에서 이동 가능한 다음 노드 ID 목록이다.
/// 모든 연결은 더 높은 [floor]를 향한 단방향(앞 방향)만 허용된다.
class MapNode {
  /// 노드 고유 식별자. 형식: "f{floor}n{index}" (예: "f0n0", "f1n2").
  final String id;

  /// 노드 종류. 방문 시 실행할 컨텐츠를 결정한다.
  final NodeType type;

  /// 0부터 시작하는 층(floor) 번호.
  /// 숫자가 클수록 보스에 가깝다.
  final int floor;

  /// 이 노드에서 이동 가능한 다음 노드 ID 목록.
  /// [NodeType.boss]는 항상 빈 목록을 가진다.
  final List<String> connectedNodeIds;

  const MapNode({
    required this.id,
    required this.type,
    required this.floor,
    required this.connectedNodeIds,
  });

  /// [connectedNodeIds]만 교체한 새 인스턴스를 반환한다.
  ///
  /// MapGenerator가 노드 생성 후 연결 정보를 적용할 때 사용한다.
  MapNode withConnections(List<String> connections) => MapNode(
        id: id,
        type: type,
        floor: floor,
        connectedNodeIds: List.unmodifiable(connections),
      );

  @override
  String toString() => 'MapNode($id, $type, floor=$floor, '
      'connections=${connectedNodeIds.join(",")})';
}
