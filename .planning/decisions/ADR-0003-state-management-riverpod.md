# ADR-0003: 전역 상태 관리로 Riverpod 선택

## 상태

**수용됨** — 2026-05-19

---

## 배경

덱빌딩 카드 게임은 전투 중 플레이어 HP, 에너지, 핸드 카드, 덱 상태, 몬스터 상태, 유물(Relic) 효과 등 다수의 전역 상태가 긴밀하게 연동된다. 이를 관리하기 위해 다음 요건이 충족되어야 한다.

1. **컴파일 타임 안정성** — 잘못된 Provider 참조가 런타임이 아닌 빌드 타임에 감지되어야 한다.
2. **테스트 격리** — 각 테스트 케이스가 독립적인 Provider 상태를 가져야 한다. 전역 싱글톤 방식은 테스트 간 상태 누출을 유발한다.
3. **`BuildContext` 독립성** — ViewModel에서 Provider를 참조할 때 `BuildContext`가 필요해서는 안 된다. MVVM 원칙상 ViewModel은 Flutter 위젯 트리를 알아서는 안 된다.
4. **비동기 상태 처리** — 저장소 로드, 레벨업 이펙트 등 비동기 작업의 로딩·에러 상태를 명시적으로 표현할 수 있어야 한다.

Provider(flutter_provider), Bloc/Cubit, Riverpod, GetX 네 가지 옵션을 검토하였다.

---

## 결정 사항

**전역 상태 관리 솔루션으로 Riverpod(flutter_riverpod)을 채택한다.**

Provider는 최상위 수준에서 `@riverpod` 어노테이션(code_gen) 또는 `NotifierProvider` / `AsyncNotifierProvider`로 선언하며, ViewModel 클래스는 `Notifier` / `AsyncNotifier`를 상속하여 구현한다.

```dart
// 예시: 전투 상태 ViewModel
@riverpod
class BattleViewModel extends _$BattleViewModel {
  @override
  BattleState build() => BattleState.initial();
  // ...
}
```

---

## 대안 및 선택 이유

### 검토된 대안

| 옵션 | 설명 | 탈락 이유 |
|------|------|-----------|
| Provider (flutter_provider) | Flutter 팀 권장 기본 패키지 | `BuildContext` 없이 Provider를 읽을 수 없어 ViewModel에서 다른 Provider를 참조할 때 MVVM 원칙이 무너짐 |
| Bloc/Cubit | 이벤트 기반 상태 기계 | 카드 한 장에 대응하는 효과조차 Event → State 변환 코드가 과도하게 장황해짐; 게임처럼 상태 전이가 잦은 도메인에서 보일러플레이트 비용이 과도함 |
| GetX | 올인원 프레임워크 | 전역 싱글톤 기반 상태 공유는 테스트 격리를 근본적으로 방해하며, 컴파일 타임 안전성을 제공하지 않음 |

### Riverpod을 선택한 이유

1. **컴파일 타임 안정성** — 존재하지 않는 Provider를 `ref.watch` / `ref.read`로 참조하면 빌드 에러가 발생하여 런타임 오류를 사전 차단한다.
2. **`BuildContext` 완전 독립** — `ref` 객체만으로 임의의 Provider를 읽고 구독할 수 있으므로, ViewModel이 위젯 트리를 전혀 참조하지 않아도 된다. MVVM 원칙을 자연스럽게 지킬 수 있다.
3. **테스트 격리의 용이성** — `ProviderContainer`를 각 테스트 `setUp`에서 새로 생성하면 Provider 상태가 완전히 격리된다. `container.read(provider)` 호출만으로 비즈니스 로직을 테스트할 수 있다.
4. **Provider 오버라이드** — `ProviderContainer(overrides: [...])` 패턴으로 테스트 시 의존성을 손쉽게 교체할 수 있어, 외부 저장소·API에 의존하는 Provider를 목(Mock) 없이 스텁으로 대체할 수 있다.
5. **`AsyncNotifier`의 명시적 비동기 상태** — `AsyncValue<T>` 타입이 `loading` / `data` / `error` 상태를 타입 수준에서 강제하므로, 누락된 로딩 UI나 에러 핸들링을 컴파일러가 경고한다.

---

## 결과

### 장점

- ViewModel 단위 테스트가 단순하고 빠르다. 위젯 트리, `BuildContext`, `MediaQuery` 등이 전혀 불필요하다.
- Provider 의존 그래프가 코드 상에 명시적으로 드러나 아키텍처 파악이 용이하다.
- 비동기 상태(`AsyncValue`)의 UI 표현이 패턴화되어 일관성을 유지하기 쉽다.

### 단점

- `ref.watch`는 `build()` 메서드 또는 위젯 트리 내부에서만 호출 가능하다는 규칙이 있어, 생명주기를 잘못 이해한 개발자가 실수하기 쉽다.
- code_gen(`@riverpod`) 사용 시 `build_runner` 실행이 필수적으로 동반되어 개발 워크플로에 추가 단계가 생긴다.
- Riverpod 2.x API(Notifier, AsyncNotifier)는 이전 1.x와 마이그레이션 패턴이 달라 레거시 예제 코드 참조 시 혼동이 생길 수 있다.

---

## 관련 결정

- [ADR-0001: 모바일 프레임워크로 Flutter 선택](ADR-0001-mobile-framework-flutter.md)
- [ADR-0002: 아키텍처 패턴으로 MVVM 선택](ADR-0002-architecture-mvvm.md)
