# Slay the Flutter

> 덱을 구성하고 몬스터를 처치하며 보스를 향해 나아가는 Flutter 덱빌딩 로그라이크 카드 게임

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey)
![License](https://img.shields.io/badge/License-MIT-green)

Android / iOS 크로스플랫폼. MVVM + Riverpod 아키텍처.

---

## 게임 개요

스테이지 1 → 2 → 3 → 보스로 이어지는 던전을 카드로 돌파하는 로그라이크 카드 게임이다. 매 런마다 카드와 유물을 획득해 덱을 강화하고, 런이 끝나면 누적된 XP로 레벨업해 새로운 카드·유물을 영구 해금한다.

- **전투**: 에너지 3으로 카드를 사용해 공격·방어하고 몬스터를 처치
- **런 내 성장**: 보상으로 카드를 추가하고 유물을 장착해 덱을 강화
- **메타 성장**: XP 누적 → 레벨업 → 카드/유물 영구 해금

전체 게임 규칙은 [`SPECS.md`](SPECS.md), 개발 원칙은 [`AGENTS.md`](AGENTS.md) 참조.

---

## 개발 환경 요구사항

| 도구 | 최소 버전 |
|------|----------|
| Flutter | 3.32.x (stable) |
| Dart | 3.9.x |
| Android Studio / Xcode | 최신 stable |

```bash
flutter --version   # 버전 확인
flutter doctor      # 환경 점검
```

---

## 시작하기

```bash
# 의존성 설치
flutter pub get

# 실행 (debug)
flutter run

# 린트 검사 (커밋 전 필수, 경고 0건)
flutter analyze

# 포맷
dart format lib/ test/

# 전체 테스트
flutter test

# 커버리지 측정
flutter test --coverage
```

---

## 아키텍처

MVVM with Riverpod. 레이어 간 단방향 의존성을 엄수한다.

```
lib/
├── models/        # 순수 Dart — 데이터 구조 + 비즈니스 로직
├── viewmodels/    # Riverpod Notifier/AsyncNotifier 프로바이더 (*_provider.dart)
└── views/         # Flutter 위젯 — 상태 읽기 + 이벤트 전달만 담당
```

---

## 기술 스택

| 역할 | 라이브러리 |
|------|-----------|
| 프레임워크 | Flutter (Dart) |
| 상태 관리 | flutter_riverpod |
| 로컬 저장소 | shared_preferences |
| 테스트 | flutter_test, mockito |

---

## 테스트

`test/` 디렉토리는 `lib/`를 그대로 미러링한다.

```
test/
├── models/
│   ├── card_test.dart
│   ├── character_test.dart
│   ├── monster_test.dart
│   └── battle_engine_test.dart
└── viewmodels/
    ├── battle_viewmodel_test.dart
    └── quest_viewmodel_test.dart
```

커버리지 목표: `models/` ≥ 80%, `viewmodels/` ≥ 70%

---

## 기획 문서

| 파일 | 내용 |
|------|------|
| `.planning/00-vision.md` | 게임 비전 및 단계 로드맵 |
| `.planning/01-requirements.md` | MoSCoW 기능 요구사항 |
| `.planning/02-wbs.json` | WBS 작업 데이터 |
| `SPECS.md` | 카드, 몬스터, 전투 규칙 전체 명세 |
