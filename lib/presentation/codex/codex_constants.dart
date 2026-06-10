import 'package:flutter/material.dart';

/// 카드 도감 화면 문자열 상수.
abstract final class CodexStrings {
  static const title           = '카드 도감';
  static const baseSectionLabel = '기본 해금';
  static const baseSectionDesc  = '항상 보상·이벤트·상점에 등장';
  static const starterDeckSuffix = ' · 스타터 덱';
  static const closeHint = '탭하여 닫기';

  static String levelLabel(int level) => 'Lv.$level';
}

/// 카드 도감 화면 색상 상수.
abstract final class CodexColors {
  static const background   = Color(0xFF1A1A2E);
  static const appBar       = Color(0xFF16213E);

  static const unlockedBg     = Color(0xFF1A2C22);
  static const unlockedBorder = Color(0xFF2D6A4F);
  static const unlockedLabel  = Color(0xFF95D5B2);

  static const lockedBg     = Color(0xFF161420);
  static const lockedBorder = Color(0xFF3D3020);
  static const lockedLabel  = Colors.white38;
}
