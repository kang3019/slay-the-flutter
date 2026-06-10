# Slay the Flutter

> 매 런마다 덱을 새로 구성해 던전을 돌파하는 미니멀 덱빌딩 로그라이크 — Flutter 단일 코드베이스로 Android·iOS 동시 지원

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)
![Tests](https://img.shields.io/badge/Tests-431%20passing-brightgreen)
![Analyze](https://img.shields.io/badge/flutter%20analyze-0%20warnings-brightgreen)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey)

---

## 게임 개요

턴제 카드 전투 + 덱빌딩 + 로그라이크 진행 구조를 결합한 모바일 게임이다.
매 런마다 기본 덱(강타 ×5 / 방어 ×5)으로 시작해 카드와 유물을 획득하며 보스를 향해 나아간다.
런이 끝나면 XP를 정산해 레벨업하고, 새 카드·유물이 영구 해금되어 다음 런의 선택 폭이 넓어진다.

### 핵심 게임 루프

```
[런 시작] 기본 덱 10장
    │
[맵 이동] 12층 DAG 맵에서 경로 선택
    │
[전투]    카드 사용 → 데미지/방어도 계산 → 상태이상 처리
    │
[보상]    카드 추가 / 유물 획득 / 골드
    │
[반복] → 보스 처치 → 런 클리어
       → 패배    → 런 종료
    │
[XP 정산] 누적 XP → 레벨업 → 카드·유물 영구 해금
```

---

## 구현 완료 기능

| 시스템 | 상세 |
|--------|------|
| **카드 전투** | 에너지 3, 드로우 5, 방어도·상태이상 포함 전투 상태 머신 |
| **카드 30종 (업그레이드 포함 62종)** | 공격·방어·버프·X비용 카드, 소멸·복사 메커니즘 |
| **몬스터 5종** | 각 고유 행동 패턴 (슬라임·고철수집가·독파수꾼·석굴수호자·철갑골렘 보스) |
| **상태이상 3종** | 취약(×1.5), 약화(×0.75), 독(방어도 무시 피해) |
| **유물 20종** | 전투 시작·턴 종료·부활·힘 버프 등 패시브 효과 |
| **12층 DAG 맵** | 절차적 생성, 교차 없는 연결, Elite·Shop 최소 보장 |
| **7종 노드** | Monster, Elite, Boss, Rest, Shop, Treasure, Event |
| **이벤트 10종** | 2지선다 선택지, 결과 서사, HP·골드·카드 효과 |
| **상점** | 카드·유물 구매, 카드 제거 서비스 (1회) |
| **휴식처** | HP 30% 회복 또는 카드 강화 선택 |
| **메타 진행** | XP → 레벨 10 상한, 카드 10단계 해금 |
| **세이브 슬롯 3개** | SharedPreferences JSON 직렬화, 슬롯 저장·로드·삭제 |
| **인트로 화면** | 타이틀·파티클 애니메이션 |
| **카드 도감** | 전체 카드 목록 조회 |

---

## 시작하기

환경 설정 상세는 **[docs/setup.md](docs/setup.md)** 참조.

```bash
git clone https://github.com/kang3019/slay-the-flutter.git
cd slay-the-flutter
flutter pub get
flutter run
```

### 자주 쓰는 명령어

```bash
flutter analyze          # 정적 분석 (0 warnings 확인)
dart format lib/ test/   # 코드 포맷
flutter test             # 전체 테스트 (431개 전부 통과)
flutter test --coverage  # 커버리지 → coverage/lcov.info
flutter clean && flutter pub get
```

---

## 아키텍처

4-Layer Layered Architecture + Riverpod. 의존성은 단방향이며 역방향 임포트는 금지한다.

```
Presentation → Application → Domain ← Data
```

| 계층 | 폴더 | 책임 |
|------|------|------|
| **Presentation** | `lib/presentation/` | 위젯만 — 상태 읽기·이벤트 전달 |
| **Application** | `lib/application/` | Riverpod Notifier — 상태 소유·비즈니스 명령 처리 |
| **Domain** | `lib/domain/` | 순수 Dart 게임 규칙 (Flutter import 없음) |
| **Data** | `lib/data/` | SharedPreferences 래퍼 |

```
lib/
├── presentation/   # 화면 위젯 (intro/, battle/, map/, reward/, shop/, ...)
├── application/    # battle_provider.dart, run_provider.dart,
│                   # meta_progress_provider.dart, save_slot_provider.dart
├── domain/         # entities/, battle_engine.dart, deck.dart,
│                   # map/, status_effect.dart
├── data/           # local_storage.dart
└── main.dart
```

구조 상세는 **[docs/architecture.md](docs/architecture.md)** 참조.

---

## 기술 스택

| 역할 | 선택 | 근거 |
|------|------|------|
| 프레임워크 | Flutter (Dart) | 단일 코드로 Android·iOS 동시 지원, 독자 렌더링으로 카드 UI 자유도 확보 |
| 상태 관리 | flutter_riverpod | BuildContext 없이 Application 계층 단독 테스트 가능 |
| 로컬 저장소 | shared_preferences | 오프라인 완전 동작, 저장 데이터 규모가 키-값 수준으로 단순 |
| 게임 엔진 | flame | 보스 배경 파티클 이펙트 |
| 영상 재생 | video_player | 인트로 배경 루프 |
| 테스트 | flutter_test, mockito | 186개 테스트 전량 통과 |

아키텍처 결정 근거는 `docs/decisions/` ADR 5건에 기록되어 있다.

---

## 테스트

`test/`는 Domain·Application·Data 계층을 미러링한다. **431개 전부 통과 (`flutter analyze` 경고 0건).**

```
test/
├── domain/
│   ├── card_test.dart             # 카드 상수 검증
│   ├── player_test.dart           # HP·방어도·상태이상
│   ├── monster_test.dart          # 5종 몬스터 행동 패턴
│   ├── deck_test.dart             # 드로우·셔플·소멸 사이클
│   ├── battle_engine_test.dart    # 전투 흐름 통합
│   ├── event_test.dart            # 이벤트 선택지 효과
│   ├── map_generator_test.dart    # DAG 생성 5대 제약 검증
│   ├── relic_test.dart            # 유물 20종 효과
│   ├── meta_progress_test.dart    # XP·레벨업·해금
│   └── save_slot_test.dart        # JSON 직렬화 왕복
├── application/
│   ├── battle_provider_test.dart
│   ├── run_provider_test.dart
│   ├── meta_progress_provider_test.dart
│   └── save_slot_provider_test.dart
├── data/
│   └── local_storage_test.dart
└── widget_test.dart
```

커버리지 목표: `domain/` ≥ 80%, `application/` ≥ 70%

테스트 가이드는 **[docs/testing.md](docs/testing.md)** 참조.

---

## 기획 문서

| 파일 | 내용 |
|------|------|
| [SPECS.md](SPECS.md) | 카드·몬스터·맵·전투 규칙 전체 도메인 명세 |
| [docs/architecture.md](docs/architecture.md) | 4계층 구조 상세 및 의존성 흐름 |
| [docs/setup.md](docs/setup.md) | 개발 환경 설정 (5분 실행 가이드) |
| [docs/testing.md](docs/testing.md) | TDD 가이드 + 테스트 실행 방법 |
| [docs/decisions/](docs/decisions/) | ADR 0001~0005 |
| [.planning/00-vision.md](.planning/00-vision.md) | 프로젝트 비전 및 로드맵 |
| [.planning/01-requirements.md](.planning/01-requirements.md) | MoSCoW 기능 요구사항 |
| [docs/wbs.json](docs/wbs.json) | WBS 태스크 데이터 |
| [BONUS.md](BONUS.md) | 가산점 항목 트래킹 |
