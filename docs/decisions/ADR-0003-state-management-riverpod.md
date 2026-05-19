# ADR-0003: 전역 상태 관리로 Riverpod 선택

| 항목 | 내용 |
|------|------|
| **상태** | 승인(Accepted) |
| **결정일** | 2026-05-19 |
| **결정자** | kang3019 |

---

## 컨텍스트

카드 게임은 전투 중 플레이어 HP, 에너지, 핸드 카드, 덱 상태, 몬스터 상태, 유물 효과 등 여러 전역 상태가 동시에 맞물린다. 상태 관리 라이브러리를 고를 때 아래 세 가지가 핵심 기준이었다.

1. **테스트 격리** — 테스트마다 독립적인 상태를 가져야 한다. 전역 싱글톤은 테스트 간 상태 누출을 유발한다.
2. **`BuildContext` 없이 Provider 참조** — ViewModel이 Flutter 위젯 트리를 몰라야 MVVM 원칙이 지켜진다.
3. **비동기 상태 명시** — 저장소 로드·레벨업 이펙트 등 비동기 작업의 로딩·에러 상태를 타입으로 표현해야 한다.

---

## 검토된 선택지

| 옵션 | 설명 | 탈락 이유 |
|------|------|-----------|
| **Provider** (flutter_provider) | Flutter 팀 기본 패키지 | `BuildContext` 없이 다른 Provider를 읽을 수 없어 MVVM 원칙이 무너짐 |
| **Bloc/Cubit** | 이벤트 기반 상태 기계 | 카드 한 장의 효과조차 Event → State 변환 코드가 과도하게 장황해짐 |
| **GetX** | 올인원 프레임워크 | 전역 싱글톤 기반으로 테스트 격리가 근본적으로 불가, 컴파일 타임 안전성 없음 |
| **Riverpod** | `ref` 기반 Provider 그래프 | 세 가지 기준을 모두 충족 |

---

## 결정

**Riverpod(`flutter_riverpod`)** 을 채택한다.

ViewModel은 `Notifier` / `AsyncNotifier`를 상속하여 구현한다.

```dart
// 전투 상태 ViewModel 예시
@riverpod
class BattleViewModel extends _$BattleViewModel {
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

- ViewModel 단위 테스트에 위젯 트리·`BuildContext`·`MediaQuery`가 전혀 필요 없다.
- 존재하지 않는 Provider를 참조하면 빌드 에러가 발생해 런타임 오류를 사전 차단한다.
- `AsyncValue<T>`가 로딩·데이터·에러 세 상태를 타입으로 강제해 UI 누락을 컴파일러가 경고한다.

### 부정적 / 감수하는 트레이드오프

- `ref.watch`는 `build()` 또는 위젯 트리 내부에서만 호출 가능한 규칙이 있어 생명주기 실수가 생기기 쉽다.
- code_gen(`@riverpod`) 사용 시 `build_runner` 실행이 워크플로에 추가된다.

---

## 관련 문서

- [ADR-0001: 플랫폼 — Flutter](ADR-0001-mobile-platform.md)
- [ADR-0002: 아키텍처 — MVVM](ADR-0002-architecture-mvvm.md)
- [ADR-0004: 영속성 — 로컬 우선](ADR-0004-persistence-local.md)
