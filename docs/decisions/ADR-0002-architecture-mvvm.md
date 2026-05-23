# ADR-0002: 아키텍처 패턴 — 4-Layer Layered Architecture + Riverpod

| 항목 | 내용 |
|------|------|
| **상태** | 승인(Accepted) |
| **결정일** | 2026-05-19 |
| **결정자** | kang3019 |

---

## 컨텍스트

Slay the Flutter는 데미지 계산, 상태 이상(취약·약화) 적용, 턴 판정, 덱 셔플 등 복잡한 게임 비즈니스 로직을 포함한다. 이 로직이 UI 코드와 섞이면 세 가지 문제가 생긴다.

1. **테스트 불가** — 화면을 띄우지 않으면 게임 규칙을 테스트할 수 없다.
2. **유지보수 붕괴** — 화면 레이아웃을 바꾸다가 게임 규칙이 깨지거나, 반대로 규칙을 바꾸다가 UI 코드를 건드려야 하는 상황이 발생한다.
3. **TDD 불가** — 프로젝트 핵심 원칙인 '테스트 먼저 작성'은 로직이 UI와 분리되어 있어야만 실천할 수 있다.

---

## 검토된 선택지

| 옵션 | 설명 | 탈락 이유 |
|------|------|-----------|
| **MVC** | Controller가 View와 Model을 중재 | Flutter의 선언형 위젯 구조와 Controller 개념의 경계가 모호해 실제로는 로직이 위젯 안에 섞이는 경향이 강함 |
| **MVP** | Presenter가 View를 직접 업데이트 | View 인터페이스 정의가 필요해 보일러플레이트가 많고, Riverpod과 자연스럽게 연계되지 않음 |
| **MVVM** | ViewModel이 상태를 소유, View는 구독만 | Riverpod `Notifier`가 ViewModel 역할을 직접 수행 → 별도 글루 코드 없이 패턴 완성 |

---

## 결정

**4-Layer Layered Architecture + Riverpod** 를 채택한다.  
Use Case 레이어는 프로젝트 규모(1인 단기 개발)에 맞게 Application 계층에 통합한다.

```
lib/
├── presentation/ ← 화면에 그리고 버튼 이벤트만 전달 (Flutter 위젯)
├── application/  ← 상태 소유 + 명령 처리 (Riverpod Notifier, Use Case 겸임)
├── domain/       ← 게임 규칙만 담당 (순수 Dart, Flutter 임포트 없음)
└── data/         ← 로컬 저장소 읽기/쓰기 캡슐화 (SharedPreferences)
```

계층 간 의존 방향은 단방향으로 고정한다: `Presentation → Application → Domain ← Data`  
역방향 임포트는 금지한다.

---

## 결과 (Consequences)

### 긍정적

- `models/` 단위 테스트 커버리지 80% 목표를 현실적으로 달성할 수 있다.
- View는 표시만 담당하므로 디자인 변경이 게임 규칙에 영향을 주지 않는다.
- ViewModel을 `ProviderContainer`로 격리해 Flutter 없이 테스트 가능하다.

### 부정적 / 감수하는 트레이드오프

- 소규모 기능에도 Model / ViewModel / View 세 파일을 작성해야 해 파일 수가 늘어난다.
- `BuildContext`를 ViewModel로 넘기는 실수를 코드 리뷰에서 반드시 차단해야 한다.

---

## 관련 문서

- [ADR-0001: 플랫폼 — Flutter](ADR-0001-mobile-platform.md)
- [ADR-0003: 상태관리 — Riverpod](ADR-0003-state-management-riverpod.md)
- `AGENTS.md` — Layered Architecture 임포트 규칙 강제 원칙
