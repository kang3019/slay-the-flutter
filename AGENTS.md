# AGENTS.md — AI 개발자 행동 원칙

이 문서는 이 프로젝트에서 AI 코드 생성 에이전트(Claude)가 반드시 준수해야 할 개발 원칙을 정의합니다.

---

## 1. 아키텍처 원칙: MVVM 엄수

- **모든 코드는 MVVM(Model-View-ViewModel) 패턴을 따른다.**
  - `lib/models/`: 순수 데이터 구조 및 비즈니스 로직 (Dart 클래스, 불변 객체 우선)
  - `lib/viewmodels/`: 상태 관리 및 뷰와 모델 사이의 중개 (Riverpod `Notifier` 또는 `StateNotifier` 사용)
  - `lib/views/`: UI 위젯만 포함. 로직을 직접 작성하지 않는다.
- ViewModel은 View를 절대 import하지 않는다.
- Model은 ViewModel이나 View를 절대 import하지 않는다.

## 2. UI와 로직의 분리

- 비즈니스 로직(데미지 계산, 카드 효과 적용, 퀘스트 판정 등)은 반드시 `models/` 또는 `viewmodels/`에 위치한다.
- `views/` 내부 위젯은 오직 ViewModel의 상태를 **읽고**, 사용자 인터랙션을 ViewModel에 **전달**하는 역할만 수행한다.
- `Widget.build()` 내부에 조건 분기 로직이 3줄을 초과할 경우 별도 메서드나 위젯으로 분리한다.

## 3. 주석 작성 원칙

- **모든 public 클래스, 메서드, 필드에는 dartdoc 주석(`///`)을 필수로 작성한다.**
- 주석은 *무엇을 하는지*가 아니라 *왜 이렇게 설계했는지*를 설명한다.
- 복잡한 게임 공식(데미지 계산, 확률 등)이 포함된 코드 블록 위에는 반드시 계산 근거를 주석으로 남긴다.
- TODO 주석은 `// TODO(kang3019): 내용` 형식을 따른다.

## 4. 테스트 주도 개발 (TDD)

- 새로운 게임 로직 추가 시, **테스트를 먼저 작성한 후** 구현 코드를 작성한다.
- `test/` 디렉토리 구조는 `lib/` 구조를 그대로 미러링한다 (예: `lib/models/card.dart` → `test/models/card_test.dart`).
- 모든 Model 클래스의 핵심 메서드는 단위 테스트 커버리지 80% 이상을 목표로 한다.
- ViewModel 테스트는 Riverpod `ProviderContainer`를 사용하여 UI 없이 검증한다.

## 5. 상태 관리: Riverpod

- 전역 상태는 반드시 Riverpod Provider를 통해 관리한다.
- `ref.watch`는 `build()` 또는 `Widget` 내부에서만 사용한다.
- Provider 파일은 `lib/viewmodels/` 폴더에 위치하며, `_provider.dart` 접미사를 붙인다.
- `StateNotifier`보다 최신 API인 `Notifier` / `AsyncNotifier`를 우선 사용한다.

## 6. 코드 품질

- `flutter analyze`가 경고 없이 통과해야 한다.
- 불필요한 `print()` 문은 커밋 전에 제거한다.
- 매직 넘버(예: `42`, `0.85`)는 상수(`const`)로 추출하여 이름을 부여한다.
- 파일 하나의 길이가 300줄을 초과하면 분리를 검토한다.

## 7. 금지 사항

- `setState()`를 ViewModel 외부 로직에 사용하지 않는다.
- `BuildContext`를 ViewModel에 전달하지 않는다.
- 하드코딩된 한국어/영어 문자열을 View 로직 안에 직접 넣지 않는다 (별도 상수 파일 사용).
