import 'package:flutter/material.dart';

import '../../domain/map/node_type.dart';

// ──────────────────────────────────────────────────────────────────────────
// 색상 상수
// ──────────────────────────────────────────────────────────────────────────

/// 맵 화면 전용 색상 팔레트.
///
/// 노드 유형 색상은 SPECS.md §8 노드 종류 표를 기준으로 정의한다.
/// 어두운 던전 배경 위에서 대비가 충분하도록 채도를 높인 색상을 선택했다.
abstract final class MapColors {
  /// 맵 화면 배경색. [BattleColors.background]보다 조금 더 어두운 남색.
  static const Color background = Color(0xFF16213E);

  /// 현재 노드 → 이동 가능 노드 방향 경로 선 색상 (금색 = "황금길").
  static const Color pathActive = Color(0xFFFFD700);

  /// 이미 지나온 경로 선 색상 (초록 = "발자국").
  static const Color pathVisited = Color(0xFF4CAF50);

  /// 아직 미도달이고 이동 불가한 경로 선 색상 (흰색 20% — 구조만 보임).
  static const Color pathInactive = Color(0x55FFFFFF);

  /// 현재 위치를 감싸는 링 색상.
  static const Color ringCurrent = Color(0xFFFFD700);

  /// 이동 가능 노드의 배경 글로우 색상 (금색 33% 반투명).
  static const Color glowReachable = Color(0x55FFD700);

  /// 노드 유형별 채우기 색상.
  ///
  /// 어두운 배경에서 각 노드가 한눈에 구분되도록 유형마다 다른 색상을 부여한다.
  static Color forType(NodeType type) => switch (type) {
        NodeType.monster  => const Color(0xFFE53935), // 붉은   ⚔️
        NodeType.elite    => const Color(0xFF8E24AA), // 보라   💀
        NodeType.boss     => const Color(0xFFF57F17), // 주황금 👑
        NodeType.rest     => const Color(0xFF43A047), // 초록   🔥
        NodeType.shop     => const Color(0xFF1E88E5), // 파랑   🛒
        NodeType.treasure => const Color(0xFFFDD835), // 노랑   🏺
        NodeType.event    => const Color(0xFF00897B), // 청록   ❓
      };
}

// ──────────────────────────────────────────────────────────────────────────
// 크기 상수
// ──────────────────────────────────────────────────────────────────────────

/// 맵 화면 레이아웃·그리기에 쓰이는 크기 상수.
abstract final class MapSizes {
  /// 노드 원의 반지름(dp).
  static const double nodeRadius = 26.0;

  /// 현재 위치 링이 노드 원 바깥에 띄워지는 간격(dp).
  static const double ringGap = 7.0;

  /// 이동 가능 노드 글로우가 노드 원 바깥에 추가되는 반지름(dp).
  static const double glowExtra = 14.0;

  /// 활성 경로(이동 가능) 선 두께(dp).
  static const double pathActiveWidth = 3.0;

  /// 비활성/방문 경로 선 두께(dp).
  static const double pathInactiveWidth = 1.5;

  /// 캔버스 상·하 여백(dp).
  static const double paddingV = 72.0;

  /// 캔버스 좌·우 여백(dp).
  static const double paddingH = 48.0;

  /// 층(floor) 사이 고정 간격(dp). 이 값으로 전체 캔버스 높이가 결정된다.
  static const double floorHeight = 120.0;

  /// 탭 인식 추가 반경(dp).
  static const double hitSlop = 12.0;
}

// ──────────────────────────────────────────────────────────────────────────
// 문자열 상수
// ──────────────────────────────────────────────────────────────────────────

/// 맵 화면 UI에 표시되는 문자열 상수.
///
/// 뷰 로직 내부에 하드코딩된 문자열을 두지 않기 위해 이 클래스에 모두 정의한다.
abstract final class MapStrings {
  static const String screenTitle = '던전 맵';
  static const String hintFirst   = '출발 방을 선택하세요';
  static const String hintMove    = '다음 방을 선택하세요';
  static const String hintRunOver = '런이 종료되었습니다';
  static const String floorPrefix = 'Floor';

  /// 노드 유형을 SPECS.md §8 아이콘 이모지로 변환한다.
  static String iconFor(NodeType type) => switch (type) {
        NodeType.monster  => '⚔️',
        NodeType.elite    => '💀',
        NodeType.boss     => '👑',
        NodeType.rest     => '🔥',
        NodeType.shop     => '🛒',
        NodeType.treasure => '🏺',
        NodeType.event    => '❓',
      };

  /// 노드 유형의 한글 명칭. 하단 힌트 바에서 사용한다.
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
