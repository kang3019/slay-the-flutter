---
marp: true
theme: default
paginate: true
style: |
  section { font-size: 22px; }
  h1 { font-size: 2em; }
  h2 { font-size: 1.5em; border-bottom: 2px solid #4A90D9; padding-bottom: 4px; }
  h3 { font-size: 1.1em; color: #444; }
  table { font-size: 0.85em; }
  code { font-size: 0.8em; }
  blockquote { border-left: 4px solid #4A90D9; padding-left: 12px; color: #555; }
---

<!-- _paginate: false -->
# Slay the Flutter
## 전략적 카드 선택과 끊임없는 도전의 덱빌딩 로그라이크

Flutter · Riverpod · 4-Layer Layered Architecture

**발표자**: kang3019 | **2026-05-23**

<!--
안녕하세요. Slay the Flutter 프로젝트를 발표할 kang3019입니다.
이 게임은 매 런마다 카드를 골라 덱을 구성하고 스테이지를 돌파하는 모바일 덱빌딩 로그라이크입니다.
사용자가 얻는 핵심 가치는 두 가지입니다.
첫째, 매 런마다 다른 덱을 구성하는 '이번엔 어떤 빌드로 가볼까'라는 반복 플레이 동기.
둘째, 런이 끝날 때마다 XP가 쌓여 새 카드와 유물이 영구 해금되는 메타 성장 구조입니다.
짧게 말하면, 플레이할수록 선택지가 넓어지는 게임입니다.
-->

---

## 프로젝트 개요

| 항목 | 내용 |
|------|------|
| **플랫폼** | Android / iOS (Flutter 단일 코드베이스) |
| **장르** | 턴제 덱빌딩 로그라이크 카드 게임 |
| **핵심 루프** | 런 시작 → 카드 전투 → 보상 선택 → 반복 → 런 종료 |
| **메타 성장** | XP 누적 → 레벨업 → 카드·유물 영구 해금 |
| **저장 방식** | 로컬 (SharedPreferences) — 오프라인 완전 동작 |

### 핵심 게임 공식 (SPECS.md 상수화)

| 공식 | 값 |
|------|----|
| 몬스터 HP | `20 + (스테이지 × 10)` |
| 몬스터 공격력 | `8 + (스테이지 × 2)` |
| 취약 피해 배율 | `× 1.5` |
| 약화 피해 배율 | `× 0.75` |
| 에너지 / 드로우 per 턴 | `3 / 5` |

<!--
프로젝트 개요입니다.
Flutter 단일 코드베이스로 Android와 iOS를 동시에 지원합니다.
핵심 루프는 런 시작 → 전투 → 보상의 반복이고, 런 종료 시 XP가 로컬에 영구 저장됩니다.
게임 공식은 모두 SPECS.md에 상수로 관리되어 있어, 밸런스 조정 시 숫자 한 줄만 바꾸면 됩니다.
-->

---

## ADR-0001 — 왜 Flutter인가?

| 대안 | 탈락 이유 |
|------|-----------|
| React Native | JS Bridge 오버헤드 · 카드 애니메이션 커스텀 제약 |
| Android (Kotlin) 단독 | iOS 지원 불가 — 양 플랫폼 요구 미충족 |
| iOS (Swift) 단독 | Android 지원 불가 + macOS 개발 환경 필수 |
| Kotlin Multiplatform | UI 레이어 플랫폼별 별도 구현 → 1인 단기 개발에 부적합 |
| ✅ **Flutter** | 단일 코드베이스 · 독자 렌더링 엔진 · Hot Reload |

### 결정 근거

> **① 단일 코드베이스** — Android·iOS 동시 커버, 1인 개발 공수 절반
> **② 독자 렌더링 엔진** — 네이티브 컴포넌트 불필요, 카드 UI·애니메이션 자유롭게 구현
> **③ Hot Reload** — 짧은 개발 사이클에서 UI 이터레이션 속도 극대화

<!--
플랫폼 선택 근거입니다. 전체 비교 기록은 ADR-0001에 있습니다.
React Native는 JS Bridge 오버헤드와 카드 애니메이션 커스텀 제약이 결정적 탈락 이유였고,
네이티브 단독 개발은 양 플랫폼 요구 사항 자체를 충족하지 못합니다.
Flutter는 독자 렌더링 엔진 덕분에 카드 드래그, 애니메이션 등 커스텀 UI를 자유롭게 구현합니다.
-->

---

## ADR-0002 — 아키텍처: 경량화된 계층형 구조

<div style="display: flex; justify-content: center; align-items: center; margin-top: 20px;">
  <img src="./assets/arch-flow.svg" width="550">
</div>

> **의존 방향**: `Presentation → Application → Domain ← Data`
> Clean Architecture 참고, Use Case 레이어 생략 — 1인 개발 규모에서 오버엔지니어링 판단

<!--
아키텍처는 Clean Architecture를 참고한 4계층 구조입니다.
단, 프로젝트 규모를 고려해 Use Case 레이어를 생략하고
Application 계층의 Riverpod Notifier가 ViewModel과 Use Case를 함께 담당합니다.
의존성은 항상 단방향입니다. Presentation이 Domain을 직접 import하면 아키텍처 위반이고
코드 리뷰에서 즉시 차단합니다.
-->

---

## ADR-0003 — 왜 Riverpod인가?

| 대안 | 탈락 이유 |
|------|-----------|
| Provider | `BuildContext` 없이 다른 Provider 참조 불가 → 계층 분리 원칙 위반 |
| Bloc/Cubit | 카드 한 장 효과에도 Event→State 변환 코드가 과도하게 장황 |
| GetX | 전역 싱글톤 → 테스트 격리 근본적 불가 · 컴파일 타임 안전성 없음 |
| ✅ **Riverpod** | `BuildContext` 없이 참조 · 테스트 격리 · `AsyncValue<T>` 타입 안전 |

### 계층 분리가 가능한 이유

```dart
// Application 계층 Notifier — Flutter 위젯 트리 없이 단독 테스트 가능
class BattleNotifier extends Notifier<BattleState> {
  @override
  BattleState build() => BattleState.initial();
  void playCard(Card card) { /* BattleEngine 호출 */ }
}
// 테스트 — BuildContext, MediaQuery 불필요
setUp(() => container = ProviderContainer());
```

<!--
상태 관리 선택 근거입니다. 전체 비교는 ADR-0003에 있습니다.
핵심은 BuildContext 없이 Provider를 참조할 수 있다는 점입니다.
Provider 패키지는 이게 불가능해서 Application 계층이 Flutter 위젯 트리에 의존하게 됩니다.
Riverpod은 ProviderContainer 하나로 위젯 트리 없이 Notifier를 테스트할 수 있어
TDD 원칙을 실천할 수 있는 기반이 됩니다.
-->

---

## ADR-0004 — 영속성 전략: 무엇으로 저장할 것인가?

> 게임을 종료했다가 다시 켜도 레벨·XP·해금 카드 목록이 유지되어야 한다.

| 대안 | 탈락 이유 |
|------|-----------|
| Firebase Firestore | 인터넷 의존 · 무료 티어 제한 · 계정 시스템 필요 — 게임 규모 대비 과함 |
| Firebase Realtime DB | 동일하게 인터넷 의존 — 오프라인 플레이 요구 미충족 |
| SQLite (drift/sqflite) | 저장 데이터가 키-값 수준 — 스키마 설계·마이그레이션 비용 과도 |
| ✅ **SharedPreferences + JSON** | 로컬 · 오프라인 · 무료 · 설정 불필요 → 요구 사항에 정확히 부합 |

### 저장 대상

| 키 | 타입 | 설명 |
|----|------|------|
| `player_level` | `int` | 현재 레벨 |
| `player_xp` | `int` | 누적 XP |
| `unlocked_cards` | `List<String>` | 해금된 카드 ID 목록 |

<!--
영속성 전략입니다. 전체 비교는 ADR-0004에 있습니다.
Firebase는 인터넷 연결과 계정 시스템이 필요해 오프라인 플레이 요구를 충족하지 못합니다.
SQLite는 저장 데이터가 레벨·XP·해금 목록 정도로 단순해 스키마 설계까지 할 필요가 없습니다.
SharedPreferences는 OS가 기본 제공하는 키-값 저장소로 설정 없이 바로 쓸 수 있고,
서버·인터넷·계정이 전혀 필요 없습니다.
-->

---

## 개발 및 운영 방어

| 질문 | 답 |
|------|----|
| **새 화면 추가 위치** | `lib/presentation/<기능>/` — Widget 코드만 작성 |
| **상태 · 게임 규칙 위치** | 상태 → `lib/application/` · 규칙 → `lib/domain/` |
| **저장소 접근 위치** | `lib/data/local_storage.dart` — Application만 호출 |
| **빌드 실패 시** | `flutter analyze` → `flutter doctor -v` → `flutter clean && flutter pub get` |
| **git clone 후 실행** | `flutter pub get && flutter run` — 한 줄로 끝 |

```bash
git clone https://github.com/kang3019/slay-the-flutter.git \
  && cd slay-the-flutter && flutter pub get && flutter run
```

> 환경 설정 상세 → **`docs/setup.md`** (5분 내 실행 가이드)

<!--
인수인계 관점의 방어 슬라이드입니다.
새 화면은 presentation/ 에만 추가하면 됩니다. 다른 계층은 건드리지 않아도 됩니다.
빌드 실패 시 flutter analyze → flutter doctor → flutter clean 순으로 확인합니다.
git clone 이후 두 명령이면 바로 실행됩니다.
-->

---

## 현재 진행 현황 및 향후 목표

### ✅ 완료 (Phase 1 — 기반)

- 4계층 아키텍처 설계 및 문서화 (ADR 4건, `docs/decisions/`)
- 게임 규칙 명세 (`SPECS.md`) · WBS · 스프린트 계획 수립
- 개발 환경 설정 가이드 (`docs/setup.md`)
- LLM 협업 검토 기록 (`docs/llm-wiki/`)

### 🔜 남은 목표

| 단계 | 내용 | 완료 기준 |
|------|------|-----------|
| **Phase 2** | Domain 엔티티 + BattleEngine 구현 | TDD 적용 · 커버리지 ≥ 80% |
| **Phase 3** | Presentation UI + Application Notifier 연결 | 전투 화면 동작 |
| **Phase 4** | 메타 진행 (XP · 레벨업 · 해금) 구현 | 로컬 저장·불러오기 |
| **Phase 5** | 전체 통합 테스트 · 릴리즈 빌드 | `flutter analyze` 경고 0건 |

<!--
현재 Phase 1 기반 작업이 완료된 상태입니다.
아키텍처 설계, 문서화, 개발 환경 세팅이 끝났고
다음은 Domain 계층의 BattleEngine부터 TDD로 구현합니다.
-->

---

<!-- _paginate: false -->
# Q & A

> **"이 구조에서 가장 중요하게 생각한 것은?"**

Domain을 순수 Dart로 유지한 것.
`flutter test` 하나로 화면 없이 데미지 계산을 검증할 수 있고,
그것이 TDD를 실천 가능하게 만드는 유일한 전제 조건이었다.

---

> 설계 결정의 모든 근거는 `docs/decisions/` ADR 4건에 기록되어 있습니다.

<!--
발표를 마치겠습니다.
이 프로젝트의 모든 설계 결정은 '테스트 가능성'과 '1인 개발 현실성'이라는 두 기준에서 출발했습니다.
질문 받겠습니다.
-->
