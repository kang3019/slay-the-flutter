# 05-sprint-plan.md — 주차별 스프린트 계획

**버전**: 1.0 | **생성일**: 2026-05-22 (AI Agent 자동 생성)

---

## 스프린트 개요

| 스프린트 | 기간 | 목표 | 상태 |
|----------|------|------|------|
| Sprint 1 | 05/12 ~ 05/16 | 기획 & 환경 구축 | ✅ 완료 |
| Sprint 2 | 05/19 ~ 05/23 | 아키텍처 설계 확정 | ✅ 완료 |
| Sprint 3 | 05/26 ~ 05/30 | 핵심 로직 + UI 착수 | ✅ 완료 |
| Sprint 4 | 06/02 ~ 06/06 | 로직 완성 + UI 개발 | ✅ 완료 |
| Sprint 5 | 06/09 ~ 06/13 | 통합 + 마무리 | 🔄 진행 중 |
| Sprint 6 | 06/16 ~ 06/20 | QA + 발표 준비 | ⏳ 예정 |

---

## Sprint 1 — 기획 & 환경 구축 (05/12 ~ 05/16)

**목표**: 개발을 시작할 수 있는 기반을 완성한다.

### 태스크

| ID | 태스크 | 담당 | 산출물 |
|----|--------|------|--------|
| T001 | 비전 문서 작성 | A | `.planning/00-vision.md` |
| T002 | MoSCoW 요구사항 | B | `.planning/01-requirements.md` |
| T003 | WBS 일정 수립 | A | `.planning/02-wbs.json` |
| T004 | 팀 역할 분담 | A+B | 역할 정의 완료 |
| T005 | 개발 환경 구성 | A | Flutter SDK, 에뮬레이터 정상 동작 |
| T006 | GitHub 레포 설정 | A | main 브랜치, CI 워크플로 |

### 완료 기준
- `flutter run` 정상 실행 (Hello World 수준)
- `flutter analyze` 경고 0건
- 기획 문서 4종 PR 머지 완료

---

## Sprint 2 — 아키텍처 설계 확정 (05/19 ~ 05/23)

**목표**: 코드 작성 전 설계를 확정하고 빈 폴더 구조를 생성한다.

### 태스크

| ID | 태스크 | 담당 | 산출물 |
|----|--------|------|--------|
| T007 | 아키텍처 문서 | A | `docs/architecture.md` |
| T008 | ADR 3종 작성 | B | `docs/decisions/ADR-000*.md` |
| T009 | 폴더 구조 생성 | A | `lib/domain/`, `lib/application/` 등 |
| T010 | 도메인 모델 설계 | B | `Card`, `Player`, `Monster` 클래스 인터페이스 |
| T011 | Riverpod 구조 설계 | A | Provider 목록 및 상태 타입 정의 |
| T012 | 저장소 기술 선정 | A+B | ADR-0004: SharedPreferences 확정 |

### 완료 기준
- `lib/` 4계층 폴더 구조 존재
- 핵심 도메인 엔티티 클래스 정의 완료 (구현 없이 시그니처만)
- `flutter analyze` 경고 0건

---

## Sprint 3 — 핵심 로직 시작 + UI 착수 (05/26 ~ 05/30)

**목표**: BattleEngine 핵심 로직과 CardWidget 초안을 완성한다.

### 태스크

| ID | 태스크 | 담당 | 산출물 |
|----|--------|------|--------|
| T013 | BattleEngine 데미지 | A | `BattleEngine.calculateDamage()` + 테스트 |
| T014 | 방어도 시스템 | A | `BattleEngine.applyBlock()` + 테스트 |
| T015 | 상태이상 취약/약화 | A | `StatusEffect` 열거형 + 배율 로직 |
| T016 | 에너지/드로우 | A | `Player.energy`, `Deck.draw()` |
| T020 | CardWidget 디자인 | B | 카드 UI 컴포넌트 초안 |

### 완료 기준
- `flutter test test/domain/` 모두 GREEN
- 데미지 공식 단위 테스트: `취약 적용 시 base × 1.5`, `약화 적용 시 base × 0.75 (floor)` 검증
- CardWidget 스크린샷 리뷰 완료

### 핵심 공식 (테스트 기준)
```
일반 데미지    = base
취약 데미지    = floor(base × 1.5)
약화 데미지    = floor(base × 0.75)
취약+약화 동시 = floor(floor(base × 0.75) × 1.5)
방어도 적용    = max(0, damage - block)
```

---

## Sprint 4 — 로직 완성 + UI 개발 (06/02 ~ 06/06)

**목표**: M3 전투 로직을 완성하고 BattleScreen 레이아웃을 구성한다.

### 태스크

| ID | 태스크 | 담당 | 산출물 |
|----|--------|------|--------|
| T017 | 덱 관리 시스템 | A | `Deck.shuffle()`, `Deck.discard()` |
| T018 | 몬스터 AI 패턴 | A | `Monster.nextIntent()` (공격/방어 의도) |
| T019 | BattleProvider | A | `BattleNotifier` 완성, 상태 전이 |
| T021 | BattleScreen 레이아웃 | B | 전투 화면 전체 구조 |
| T022 | 플레이어 상태 위젯 | B | HP 바, 에너지 표시 |
| T023 | 몬스터 위젯 | B | 몬스터 HP, 의도 아이콘 |
| T027 | GameRepository | B | `SharedPreferences` XP/레벨 저장 |

### 완료 기준
- 카드 사용 → 데미지 → 상태 갱신 end-to-end 동작
- BattleScreen에서 실제 전투 한 라운드 진행 가능
- `flutter test` 전체 GREEN

---

## Sprint 5 — 통합 & 마무리 (06/09 ~ 06/13) 🔄 진행 중

**목표**: 미구현 화면 완성, 전체 게임 루프 완결.

### 태스크

| ID | 태스크 | 상태 | 산출물 |
|----|--------|------|--------|
| T024 | RewardScreen | ✅ 완료 | `reward_screen.dart` |
| T025 | MapScreen 스테이지 | ✅ 완료 | `map_screen.dart` (절차적 생성 맵) |
| T026 | MetaScreen 해금 | ⚠️ 부분 | 도메인·Provider 완성, 전용 화면 접근 경로 미완 |
| T028 | XP/레벨업 시스템 | ✅ 완료 | `MetaProgress.addXp()` |
| T029 | 해금 시스템 | ✅ 완료 | `MetaProgress.computeUnlockedCards()` |
| T030 | 맵/런 진행 Provider | ✅ 완료 | `RunProvider` (6가지 RunPhase) |
| T031 | UI-ViewModel 통합 | ⚠️ 부분 | Shop·RunEnd 화면 미구현 |
| T032 | BattleEngine 테스트 | ✅ 완료 | 421개 전부 통과 |
| T033 | 모델 단위 테스트 | ✅ 완료 | `test/domain/` |
| T034 | ViewModel 테스트 | ✅ 완료 | `test/application/` |
| T035 | 위젯 테스트 | ✅ 완료 | `widget_test.dart` |
| T036 | 통합 테스트 80% | ⚠️ 미측정 | `flutter test --coverage` 실행 필요 |
| T043 | ShopScreen 구현 | ⬜ 미착수 | 골드 소비, 카드 구매·제거, 유물 구매 |
| T044 | RunEndScreen 구현 | ⬜ 미착수 | 승리/패배 결과, XP 지급, 레벨업 연출 |
| T045 | MetaProgressScreen 연결 | ⬜ 미착수 | 레벨·XP 바·해금 카드 목록 접근 경로 |

### 완료 기준
- 런 시작 → 전투 → 보상 → 다음 스테이지 → 보스 → 런 종료 전 흐름 동작
- ShopScreen에서 골드로 카드 구매·제거 가능
- RunEndScreen에서 XP 지급 및 레벨업 연출 동작
- `flutter test` 전체 GREEN
- `flutter analyze` 경고 0건

---

## Sprint 6 — QA & 발표 준비 (06/16 ~ 06/20)

**목표**: 버그를 수정하고 발표를 준비한다.

### 태스크

| ID | 태스크 | 담당 | 산출물 |
|----|--------|------|--------|
| T037 | 버그 수정 & QA | A+B | Known bug 0건 |
| T038 | README 업데이트 | B | 설치·실행 가이드 포함 README |
| T039 | 발표 슬라이드 | B | 발표용 PPT/PDF |
| T040 | 데모 시나리오 | A | 시연 스크립트 |
| T041 | 전체 리허설 | A+B | 리허설 1회 완료 |
| T042 | 최종 발표 | A+B | 🎯 발표 완료 |

### QA 체크리스트
```
[ ] 카드 사용 → 데미지 정상 적용
[ ] 방어도 턴 종료 시 소멸
[ ] 취약/약화 배율 공식 정확
[ ] 몬스터 HP 0 → 승리 화면 전환
[ ] 플레이어 HP 0 → 패배 화면 전환
[ ] XP 저장 → 앱 재시작 후 유지
[ ] 레벨업 시 카드 해금 정상 등록
[ ] 보스전 패턴 정상 동작
[ ] 메모리 누수 없음 (ProviderContainer dispose)
```

---

## 스프린트별 리스크

| 스프린트 | 주요 리스크 | 대응 |
|----------|-------------|------|
| Sprint 3 | BattleEngine 복잡도 과소평가 | 공식 단위 분리, TDD 선행 |
| Sprint 4 | UI-로직 인터페이스 불일치 | Provider 계약 먼저 문서화 |
| Sprint 5 | 커버리지 부족 | Sprint 4 말에 테스트 갭 점검 |
| Sprint 6 | 발표 준비 시간 부족 | T037~T040 병렬 진행 |
