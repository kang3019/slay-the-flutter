# 005 — ADR의 예시 코드 vs 실제 구현: Riverpod codegen 패턴 불일치

| 항목 | 내용 |
|------|------|
| **날짜** | 2026-06-11 (발견) / 2026-05-19 (ADR 작성) |
| **카테고리** | 모델/도구별 차이점 |
| **발견 경위** | BONUS.md 가산점 항목을 점검하며 ADR-0003과 실제 `lib/application/*.dart`를 나란히 대조 |
| **수정 파일** | (문서만 — 코드 변경 없음, 기록 목적) |
| **관련 문서** | `docs/decisions/ADR-0003-state-management-riverpod.md`, `lib/application/battle_provider.dart` |

---

## AI가 한 것

ADR-0003 "결정" 섹션에서 Riverpod Notifier 구현 예시로 다음과 같은 **코드 생성(codegen) 어노테이션 패턴**을 제시했다.

```dart
// ADR-0003에 적힌 예시
@riverpod
class BattleNotifier extends _$BattleNotifier {
  @override
  BattleState build() => BattleState.initial();
}
```

## 무엇이 다른가

실제 `lib/application/battle_provider.dart`의 구현은 `@riverpod` codegen을 전혀 쓰지 않는다.

```dart
// 실제 구현
final battleProvider =
    NotifierProvider<BattleNotifier, BattleState>(BattleNotifier.new);

class BattleNotifier extends Notifier<BattleState> {
  @override
  BattleState build() => ...;
}
```

`meta_progress_provider.dart`, `run_provider.dart`, `save_slot_provider.dart` 등 다른 모든 Notifier도 동일하게 **수동 `Notifier` 상속 + `NotifierProvider` 선언** 패턴이다.

## 왜 이렇게 됐는가

`@riverpod` codegen 어노테이션은 Riverpod 커뮤니티/공식 문서가 "최신 권장" 패턴으로 자주 소개하는 방식이라, AI가 ADR 예시 코드를 작성할 때 자연스럽게 그 패턴을 끌어왔다. 하지만 codegen은 `build_runner` 실행을 워크플로에 추가하는 트레이드오프가 있고, ADR-0003 "결과(Consequences)" 섹션도 이를 "감수하는 트레이드오프"로 명시했다 — 즉 **ADR이 스스로 언급한 단점 때문에, 실제로는 그 패턴을 채택하지 않았다.**

## 배운 것

> AI가 작성한 설계 문서(ADR 등)의 "예시 코드"는 **그 문서가 작성된 시점의 일반론**일 뿐, 실제 구현과 다를 수 있다. 특히 "라이브러리의 최신 권장 패턴"과 "이 프로젝트가 실제로 채택한 패턴"은 별개다.

ADR을 발표 자료나 가산점 근거로 인용할 때는, 코드 스니펫이 `lib/`의 실제 코드와 일치하는지 한 번 더 대조해야 한다. (이번 점검에서는 실제 구현 쪽이 ADR이 언급한 트레이드오프를 더 잘 반영하고 있어, ADR 본문은 그대로 두고 이 위키 항목으로만 기록한다.)
