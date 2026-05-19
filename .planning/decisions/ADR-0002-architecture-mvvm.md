# ADR-0002: 아키텍처 패턴으로 MVVM 선택

## 상태

**수용됨** — 2026-05-19

---

## 배경

Slay the Flutter는 데미지 계산, 상태 이상(취약·약화) 적용, 턴 판정, 덱 셔플 등 복잡한 게임 비즈니스 로직을 포함한다. 이러한 로직이 UI 코드와 혼재될 경우 다음과 같은 문제가 발생한다.

- **테스트 불가** — 위젯 트리 없이 게임 로직만 단독으로 단위 테스트하기 어렵다.
- **유지보수 저하** — 화면 변경이 규칙 변경을 유발하거나, 반대로 규칙 변경이 레이아웃 코드를 건드려야 하는 결합이 생긴다.
- **TDD 도입 불가** — 프로젝트의 핵심 원칙인 Test-Driven Development는 로직이 UI와 분리되어 있어야 실천 가능하다.

MVP, MVC, MVVM 세 가지 패턴을 검토하였다.

---

## 결정 사항

**아키텍처 패턴으로 MVVM(Model–View–ViewModel)을 채택한다.**

계층 경계는 아래와 같이 정의하며, `lib/` 디렉터리 구조가 이를 직접 반영한다.

```
lib/
├── models/      — 순수 Dart: 데이터 구조 + 게임 비즈니스 로직
├── viewmodels/  — Riverpod Notifier: 상태 소유 및 명령 처리
└── views/       — Flutter 위젯: 상태 표시 + 이벤트 전달만 담당
```

각 계층 간 단방향 의존성(`views → viewmodels → models`)을 강제하며, 역방향 임포트는 금지한다.

---

## 대안 및 선택 이유

### 검토된 대안

| 옵션 | 설명 | 탈락 이유 |
|------|------|-----------|
| MVC | Controller가 View와 Model을 중재 | Flutter의 위젯 중심 선언형 UI와 Controller 개념의 경계가 모호하여, 실제로는 로직이 위젯 클래스 안에 섞이는 경향이 강함 |
| MVP | Presenter가 View를 직접 업데이트 | View 인터페이스 정의가 필요하여 보일러플레이트가 증가하고, Flutter의 상태 관리 패키지(Riverpod 등)와 자연스럽게 연계되지 않음 |

### MVVM을 선택한 이유

1. **게임 로직의 완전한 UI 분리** — 데미지 계산(`BattleEngine`), 상태 이상 효과(`StatusEffect`), 덱 관리(`Deck`) 등 핵심 도메인 로직이 순수 Dart 클래스인 Model 계층에 위치하므로, Flutter 의존성 없이 단위 테스트를 작성할 수 있다.
2. **TDD 친화성** — ViewModel은 `ProviderContainer`만으로 인스턴스화하여 테스트할 수 있어, 위젯 트리 없이도 상태 전이를 검증할 수 있다.
3. **단방향 데이터 흐름** — View는 ViewModel의 상태를 구독하고, 사용자 입력을 ViewModel의 메서드 호출로 전달하는 단순한 구조이므로, 화면 복잡도가 높아져도 데이터 흐름을 추적하기 쉽다.
4. **Riverpod과의 자연스러운 결합** — Riverpod의 `Notifier` / `AsyncNotifier`는 MVVM의 ViewModel 역할을 직접 수행하도록 설계되어 있어, 별도의 글루 코드 없이 패턴을 구현할 수 있다.

---

## 결과

### 장점

- `models/` 계층의 단위 테스트 커버리지 80% 목표를 현실적으로 달성할 수 있다.
- View 코드가 표시 로직에만 집중하므로, 디자인 변경이 게임 규칙에 영향을 주지 않는다.
- ViewModel의 상태를 `ProviderContainer`로 격리하여 테스트할 수 있어 CI 파이프라인 구성이 단순하다.

### 단점

- 초기 파일 수가 늘어나 소규모 기능에도 Model/ViewModel/View 세 파일을 작성해야 할 수 있다.
- 계층 경계를 팀 전체가 일관되게 준수해야 하며, 이를 강제하는 린트 규칙이 없으면 점진적으로 무너질 위험이 있다.
- `BuildContext`를 ViewModel로 전달하는 실수를 코드 리뷰에서 반드시 차단해야 한다.

---

## 관련 결정

- [ADR-0001: 모바일 프레임워크로 Flutter 선택](ADR-0001-mobile-framework-flutter.md)
- [ADR-0003: 전역 상태 관리로 Riverpod 선택](ADR-0003-state-management-riverpod.md)
