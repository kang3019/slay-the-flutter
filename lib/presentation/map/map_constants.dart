import 'package:flutter/material.dart';

import '../../domain/map/node_type.dart';

// ──────────────────────────────────────────────────────────────────────────
// 색상 상수 — 딥 옵시디언 × 번니시드 골드 다크 판타지 팔레트
// ──────────────────────────────────────────────────────────────────────────

abstract final class MapColors {
  /// 맵 캔버스 기본 배경. MapPainter가 덮어쓰므로 실질적으로는 보이지 않음.
  static const Color background = Color(0xFF06080F);

  /// 활성 경로 (황금빛 아우라).
  static const Color pathActive = Color(0xFFFFD700);

  /// 방문 완료 경로 (짙은 녹색).
  static const Color pathVisited = Color(0xFF388E3C);

  /// 비활성 경로 (거의 보이지 않는 남색).
  static const Color pathInactive = Color(0xFF2A2A4A);

  /// 현재 위치 링 색상 (번니시드 골드).
  static const Color ringCurrent = Color(0xFFFFD700);

  /// 이동 가능 노드 글로우 (반투명 골드).
  static const Color glowReachable = Color(0x33FFD700);

  /// 노드 유형별 테두리·프레임 색상.
  static Color forType(NodeType type) => switch (type) {
        NodeType.monster  => const Color(0xFFCC2200), // 크림슨 레드
        NodeType.elite    => const Color(0xFF9B1AC8), // 다크 퍼플
        NodeType.boss     => const Color(0xFFFF9500), // 몰튼 골드
        NodeType.rest     => const Color(0xFF2E7D32), // 포레스트 그린
        NodeType.shop     => const Color(0xFF1565C0), // 네이비
        NodeType.treasure => const Color(0xFFE6B800), // 황금
        NodeType.event    => const Color(0xFF00838F), // 딥 틸
      };
}

// ──────────────────────────────────────────────────────────────────────────
// 크기 상수
// ──────────────────────────────────────────────────────────────────────────

abstract final class MapSizes {
  /// 다이아몬드 노드의 중심에서 꼭짓점까지 거리(dp).
  static const double nodeRadius = 28.0;

  /// 현재 위치 링의 추가 반경(dp).
  static const double ringGap = 8.0;

  /// 이동 가능 노드 글로우 추가 반경(dp).
  static const double glowExtra = 12.0;

  /// 활성 경로 선 두께 (글로우 레이어 코어, dp).
  static const double pathActiveWidth = 2.5;

  /// 비활성 경로 점선 두께(dp).
  static const double pathInactiveWidth = 1.2;

  /// 캔버스 상·하 여백(dp).
  static const double paddingV = 72.0;

  /// 캔버스 좌·우 여백(dp).
  static const double paddingH = 52.0;

  /// 층(floor) 사이 고정 간격(dp). 전체 캔버스 높이를 결정한다.
  static const double floorHeight = 120.0;

  /// 탭 인식 추가 반경(dp).
  static const double hitSlop = 14.0;
}

// ──────────────────────────────────────────────────────────────────────────
// 문자열 상수
// ──────────────────────────────────────────────────────────────────────────

abstract final class MapStrings {
  static const String screenTitle = 'MAP  —  ACT I';
  static const String hintFirst   = '출발 방을 선택하세요';
  static const String hintMove    = '다음 방을 선택하세요';
  static const String hintRunOver = '런이 종료되었습니다';
  static const String floorPrefix = 'Floor';

  static String labelFor(NodeType type) => switch (type) {
        NodeType.monster  => '일반 전투',
        NodeType.elite    => '엘리트',
        NodeType.boss     => '챕터 보스',
        NodeType.rest     => '휴식처',
        NodeType.shop     => '상점',
        NodeType.treasure => '유물 보관소',
        NodeType.event    => '이벤트',
      };
}
