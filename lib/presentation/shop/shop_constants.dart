import 'package:flutter/material.dart';

/// 상점 화면 문자열 상수.
abstract final class ShopStrings {
  static const title               = '상점';
  static const tapHint             = '상인을 탭하세요';
  static const cardSection         = '카드';
  static const relicSection        = '유물';
  static const serviceSection      = '서비스';
  static const returnButton        = '다음 층으로';
  static const removalSheetTitle   = '제거할 카드 선택';
  static const removalSheetSubtitle = '덱에서 제거할 카드를 탭하세요';
  static const soldLabel           = '구매 완료';
}

/// 상점 화면 색상 상수.
abstract final class ShopColors {
  static const background  = Color(0xFF0D0A07);
  static const mat         = Color(0xFF1C1207);
  static const matBorder   = Color(0xFF8B6914);
  static const cardSurface = Color(0xFF150F08);
}

/// 상점 에셋 경로 상수.
abstract final class ShopAssets {
  static const merchant         = 'assets/images/merchant.png';
  static const backgroundVideo  = 'assets/images/battle_bg.mp4';
}
