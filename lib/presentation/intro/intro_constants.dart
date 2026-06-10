import 'package:flutter/material.dart';

/// 인트로(타이틀) 화면 문자열 상수.
abstract final class IntroStrings {
  static const startGame = '게임 시작';
  static const settings  = '설정';
  static const codex     = '도감';
  static const saveFiles = '세이브 파일';
}

/// 인트로(타이틀) 화면 색상·에셋 상수.
abstract final class IntroAssets {
  static const background = 'assets/images/intro_bg.png';
  static const titleLogo  = 'assets/images/intro_title.png';
}

/// 인트로(타이틀) 화면 색상 상수.
abstract final class IntroColors {
  static const buttonBackground = Color(0xCC1A1510);
  static const buttonBorder     = Color(0xFFB8860B);
  static const buttonText       = Color(0xFFFFD700);
  static const primaryButtonBg  = Color(0xFFB8860B);
  static const primaryButtonText = Color(0xFF1A1510);
  static const primaryGlow      = Color(0xFFFFD700);
  static const emberColor       = Color(0xFF8FFFC2);
}

/// 인트로(타이틀) 화면 연출 애니메이션 타이밍·수치 상수.
abstract final class IntroAnim {
  /// 배경 천천히 확대·축소(켄 번즈 효과) 주기.
  static const zoomDuration = Duration(seconds: 24);

  /// 배경 확대 비율 (1.0 ~ 1.0+delta).
  static const zoomScaleDelta = 0.06;

  /// 메뉴 버튼 등장(페이드·슬라이드) 애니메이션 총 시간.
  static const entranceDuration = Duration(milliseconds: 900);

  /// 버튼 간 등장 시작 시점 간격 (0~1 비율).
  static const buttonStagger = 0.12;

  /// 버튼 1개의 등장 애니메이션이 차지하는 구간 길이 (0~1 비율).
  static const entranceSpan = 0.6;

  /// 게임 시작 버튼 빛 번짐(펄스) 주기.
  static const pulseDuration = Duration(milliseconds: 1600);

  /// 펄스 최소·최대 그림자 번짐 반경.
  static const pulseGlowMin = 4.0;
  static const pulseGlowMax = 18.0;

  /// 타이틀 로고를 배경 대비 가로로 살짝 이동시키는 비율 (화면 너비 기준).
  /// 양수면 우측, 음수면 좌측으로 이동한다.
  static const titleOffsetX = 0.04;
}
