# ADR-0003: 전역 상태 관리로 Riverpod 선택

| 항목 | 내용 |
|------|------|
| **상태** | 승인(Accepted) |
| **결정일** | 2026-05-19 |
| **결정자** | kang3019 |

---

## 컨텍스트

### "상태(State)"와 "상태 관리"란 무엇인가

**상태**란 화면에 표시되는 데이터를 말한다. 예를 들어 플레이어 HP가 50이면 HP 바가 절반을 표시하고, 손패에 카드가 5장이면 카드 5장이 보인다. 이 숫자들이 바뀔 때마다 화면이 자동으로 갱신되어야 한다.

**문제**: 이 데이터는 한 화면에만 필요한 게 아니다.  
전투 화면은 HP·에너지·핸드 카드를, 지도 화면은 현재 스테이지를, 보상 화면은 덱 목록을 읽어야 한다. 즉, **여러 화면이 같은 데이터를 공유**해야 한다.

**상태 관리 라이브러리**는 이 공유 데이터를 어디에 보관하고, 어떻게 읽고 쓰고, 변경 시 어떤 화면을 다시 그릴지 결정하는 도구다.

### 선택 기준

이 프로젝트에서 상태 관리 라이브러리를 고를 때 세 가지가 핵심 기준이었다.

1. **테스트 격리** — 테스트마다 독립적인 상태를 가져야 한다. 전역 싱글톤(앱 전체에 하나뿐인 객체)은 테스트 간 데이터가 섞이는 문제를 유발한다.
2. **`BuildContext` 없이 Provider 참조** — Application 계층이 Flutter 위젯 트리를 몰라야 Layered Architecture 원칙이 지켜진다. (BuildContext = Flutter 화면 구조를 가리키는 핸들)
3. **비동기 상태 명시** — 저장소 로드·레벨업 이펙트 등 비동기 작업의 로딩·에러 상태를 타입으로 표현해야 한다.

---

## 검토된 선택지

| 옵션 | 설명 | 탈락 이유 |
|------|------|-----------|
| **Provider** (flutter_provider) | Flutter 팀 기본 패키지 | `BuildContext` 없이 다른 Provider를 읽을 수 없어 Layered Architecture 원칙이 무너짐 |
| **Bloc/Cubit** | 이벤트 기반 상태 기계 | 카드 한 장의 효과조차 Event → State 변환 코드가 과도하게 장황해짐 |
| **GetX** | 올인원 프레임워크 | 전역 싱글톤 기반으로 테스트 격리가 근본적으로 불가, 컴파일 타임 안전성 없음 |
| **Riverpod** | `ref` 기반 Provider 그래프 | 세 가지 기준을 모두 충족 |

---

## 결정

**Riverpod(`flutter_riverpod`)** 을 채택한다.

Application 계층 Notifier는 `Notifier` / `AsyncNotifier`를 상속하여 구현한다.

```dart
// 전투 상태 Notifier 예시
@riverpod
class BattleNotifier extends _$BattleNotifier {
  @override
  BattleState build() => BattleState.initial();
}
```

테스트에서는 `ProviderContainer`를 매 `setUp`마다 새로 생성해 상태를 완전히 격리한다.

```dart
setUp(() => container = ProviderContainer());
tearDown(() => container.dispose());
```

---

## 결과 (Consequences)

### 긍정적

- Application 계층(Notifier) 단위 테스트에 위젯 트리·`BuildContext`·`MediaQuery`가 전혀 필요 없다.
- 존재하지 않는 Provider를 참조하면 빌드 에러가 발생해 런타임 오류를 사전 차단한다.
- `AsyncValue<T>`가 로딩·데이터·에러 세 상태를 타입으로 강제해 UI 누락을 컴파일러가 경고한다.

### 부정적 / 감수하는 트레이드오프

- `ref.watch`는 `build()` 또는 위젯 트리 내부에서만 호출 가능한 규칙이 있어 생명주기 실수가 생기기 쉽다.
- code_gen(`@riverpod`) 사용 시 `build_runner` 실행이 워크플로에 추가된다.

---

## 관련 문서

- [ADR-0001: 플랫폼 — Flutter](ADR-0001-mobile-platform.md)
- [ADR-0002: 아키텍처 — Layered Architecture](ADR-0002-architecture-mvvm.md)
- [ADR-0004: 영속성 — 로컬 우선](ADR-0004-persistence-local.md)
