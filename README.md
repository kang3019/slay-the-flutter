# Slay the Flutter

> 매 런마다 덱을 새로 구성해 던전을 돌파하는 순수 로그라이크 덱빌딩 카드 게임 — Flutter로 만든 모바일 게임

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey)
![License](https://img.shields.io/badge/License-MIT-green)

Android / iOS 크로스플랫폼. 4-Layer Layered Architecture + Riverpod 아키텍처.

---

## 게임 개요

스테이지 1 → 2 → 3 → 보스로 이어지는 던전을 카드로 돌파하는 로그라이크 카드 게임이다. 매 런마다 카드와 유물을 획득해 덱을 강화하고, 런이 끝나면 누적된 XP로 레벨업해 새로운 카드·유물을 영구 해금한다.

### 핵심 시스템 (Must Have)

| 시스템 | 내용 |
|--------|------|
| **카드 전투** | 에너지 3으로 카드를 사용해 공격·방어, 몬스터 처치 |
| **덱 사이클** | 턴 시작 5장 드로우, 덱 소진 시 버림 덱 자동 셔플 |
| **런 내 성장** | 전투 승리 시 카드 보상 3장 중 1장 선택 |
| **메타 성장** | XP 누적 → 레벨업 → 카드/유물 영구 해금 |
| **로그라이크 진행** | 패배 시 Soft Reset (HP 절반·스테이지 1), 전투 결과에 따라 XP 누적 저장 |
| **상태 이상** | 취약(받는 데미지 ×1.5), 약화(주는 데미지 ×0.75) |

전체 게임 규칙은 [`SPECS.md`](SPECS.md), 개발 원칙은 [`AGENTS.md`](AGENTS.md) 참조.

---

## 시작하기

환경 설정 상세는 **[docs/setup.md](docs/setup.md)** 를 참고한다.

```bash
git clone https://github.com/kang3019/slay-the-flutter.git
cd slay-the-flutter
flutter pub get
flutter run
```

### 자주 쓰는 명령어

```bash
flutter analyze          # 정적 분석 (커밋 전 경고 0건 필수)
dart format lib/ test/   # 코드 포맷
flutter test             # 전체 테스트
flutter test --coverage  # 커버리지 측정 → coverage/lcov.info
flutter clean && flutter pub get  # 빌드 캐시 초기화
```

---

## 아키텍처

4-Layer Layered Architecture + Riverpod. 상위 계층은 하위 계층만 알 수 있으며 역방향 임포트는 금지한다.

```
Presentation → Application → Domain ← Data
```

| 계층 | 폴더 | 책임 |
|------|------|------|
| **Presentation** | `lib/presentation/` | 화면에 그리고, 버튼 입력을 Application으로 전달 |
| **Application** | `lib/application/` | Riverpod Notifier — 상태 소유 + 게임 규칙 호출 |
| **Domain** | `lib/domain/` | 데미지 계산·카드 효과·덱 셔플 등 순수 게임 규칙 (Flutter import 없음) |
| **Data** | `lib/data/` | XP·레벨·해금 카드를 SharedPreferences에 저장·불러오기 |

```
lib/
├── presentation/   # 위젯만 (battle/, map/, shared/)
├── application/    # battle_provider.dart, deck_provider.dart, run_provider.dart
├── domain/         # entities/, battle_engine.dart, deck.dart, status_effect.dart
├── data/           # local_storage.dart
└── main.dart
```

구조 상세 및 Q&A는 **[docs/architecture.md](docs/architecture.md)** 참조.

---

## 기술 스택

| 역할 | 선택 | 이유 |
|------|------|------|
| 프레임워크 | Flutter (Dart) | 단일 코드로 Android·iOS 동시 지원, 자체 렌더링 엔진으로 카드 UI 자유도 높음 |
| 상태 관리 | flutter_riverpod | `ProviderContainer`로 위젯 없이 Application 계층 테스트 가능, Layered Architecture와 자연스럽게 매핑 |
| 로컬 저장소 | shared_preferences | 서버 불필요, 저장 데이터가 레벨/XP/해금 목록 수준으로 단순함 |
| 테스트 | flutter_test, mockito | — |

아키텍처 결정 근거는 `docs/decisions/` 의 ADR 4개에 기록되어 있다.

---

## 테스트

`test/` 는 `lib/` 의 Domain·Application 계층을 미러링한다.

```
test/
├── domain/
│   ├── card_test.dart
│   ├── player_test.dart
│   ├── monster_test.dart
│   └── battle_engine_test.dart
└── application/
    ├── battle_provider_test.dart
    └── run_provider_test.dart
```

커버리지 목표: `domain/` ≥ 80%, `application/` ≥ 70%

Application 계층 테스트는 `ProviderContainer`를 매 `setUp`마다 새로 생성해 상태를 격리한다.

```dart
setUp(() => container = ProviderContainer());
tearDown(() => container.dispose());
```

---

## 기획 문서

| 파일 | 내용 |
|------|------|
| [docs/setup.md](docs/setup.md) | 개발 환경 설정 (Flutter 설치 → 첫 실행까지) |
| [docs/architecture.md](docs/architecture.md) | 4계층 구조 상세 및 의존성 흐름 |
| [docs/testing.md](docs/testing.md) | TDD 가이드 + 테스트 작성 예시 |
| [docs/decisions/](docs/decisions/) | ADR 0001–0004 (플랫폼·아키텍처·상태관리·영속성 결정) |
| `.planning/00-vision.md` | 게임 비전 및 단계 로드맵 |
| `.planning/01-requirements.md` | MoSCoW 기능 요구사항 |
| `.planning/02-wbs.json` | WBS 태스크 데이터 (상태 업데이트 시 직접 편집) |
| `.planning/03-risks.md` | 위험 등록부 (R-01~R-05) |
| `.planning/04-schedule.md` | 6주 마일스톤 + 간트 차트 사용법 |
| `SPECS.md` | 카드, 몬스터, 전투 규칙 전체 명세 |
| `BONUS.md` | 가산점 항목 트래킹 (+6점) |
