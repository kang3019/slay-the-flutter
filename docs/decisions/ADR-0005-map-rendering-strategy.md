# ADR-0005: 맵 UI 렌더링 전략 — CustomPaint 채택

| 항목 | 내용 |
|------|------|
| 작성일 | 2026-05-27 |
| 상태 | Accepted |
| 작성자 | kang3019 |
| 관련 파일 | `lib/presentation/map/widgets/map_painter.dart` |
|           | `lib/presentation/map/map_screen.dart` |

---

## 1. 배경 (Context)

던전 맵 화면은 **방향 비순환 그래프(DAG, Directed Acyclic Graph)** 구조를 시각화해야 한다.
구체적으로 다음 세 가지를 동시에 만족해야 한다.

1. **노드 배치**: 같은 Floor(층)의 노드는 가로로 균등 분배, 층 간격은 세로로 균등 분배
2. **연결선 렌더링**: 노드와 노드 사이를 잇는 대각선 경로(Path)를 그려야 함
3. **상태별 시각 피드백**: 이동 가능 경로는 금색·굵게, 방문 완료 경로는 초록·흐리게,
   미도달 경로는 흰색 반투명으로 각각 다르게 표시해야 함

이 세 가지 요구사항을 어떤 기술로 구현할지 결정해야 했다.

---

## 2. 결정 (Decision)

**`CustomPaint` + `CustomPainter`를 채택**한다.

`CustomPainter.paint(Canvas, Size)` 안에서 Canvas API를 직접 호출해
노드 원·연결선·아이콘을 픽셀 단위로 그린다.

```dart
// 핵심 설계 패턴
Map<String, Offset> computeNodePositions(List<MapNode> nodes, Size size) { ... }

class MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final positions = computeNodePositions(nodes, size); // ① 좌표 계산
    _drawAllPaths(canvas, positions, ...);               // ② 경로 선 (하위 레이어)
    _drawNodes(canvas, positions, ...);                  // ③ 노드 원·아이콘 (상위 레이어)
  }
}
```

**GestureDetector의 히트 테스트도 동일한 `computeNodePositions` 함수를 사용**하여
"그려지는 위치 = 탭 인식 위치"를 항상 보장한다.

```dart
void _onTap(TapUpDetails details, Size canvasSize) {
  final positions = computeNodePositions(nodes, canvasSize); // Painter와 동일 함수
  for (final entry in positions.entries) {
    if ((entry.value - tapPos).distance <= hitRadius) { ... }
  }
}
```

---

## 3. 검토한 대안 (Alternatives Considered)

### 대안 A: `Row` / `Column` + `Stack` 위젯 트리

노드를 Row/Column으로 배치하고, 연결선은 Stack + Positioned로 겹치는 방식.

| 문제점 | 설명 |
|--------|------|
| **대각선 그리기 불가** | Row/Column은 수평·수직 배치만 지원한다. 대각선 경로선을 그리려면 결국 Stack 위에 Canvas를 올려야 하므로 CustomPaint 없이는 구현 불가능하다. |
| **히트 테스트 동기화 어려움** | 노드 위젯의 실제 픽셀 위치를 알려면 `GlobalKey` + `findRenderObject` 등의 우회책이 필요하다. Painter의 그리기 위치와 GestureDetector의 탭 인식 위치가 달라질 위험이 있다. |
| **z-order 제어 복잡** | 연결선이 노드 위에 올라오지 않도록 Stack 레이어를 명시적으로 관리해야 한다. 노드 수가 늘어나면 Stack 깊이도 비례해 복잡해진다. |
| **상태별 스타일링 어려움** | 각 연결선의 색·두께를 "이동 가능 / 방문 / 미도달" 상태에 따라 독립적으로 제어하려면 개별 위젯을 상태마다 재생성해야 한다. |

**결론**: Row/Column + Stack을 아무리 조합해도 **결국 CustomPaint를 써야 대각선 선을 그릴 수 있다**. 두 기술을 혼합하면 코드 복잡도만 높아지고 이점이 없다.

### 대안 B: `graphview` 등 서드파티 그래프 렌더링 패키지

오픈소스 그래프 시각화 패키지를 사용하는 방법.

| 문제점 | 설명 |
|--------|------|
| **불필요한 의존성** | 우리의 맵은 Act 1 기준 9개 노드의 고정 레이아웃이다. 일반적인 그래프 렌더링 라이브러리가 제공하는 기능의 5%도 사용하지 않는다. |
| **커스터마이징 제약** | 슬레이 더 스파이어 특유의 글로우·링 효과, 노드별 이모지 아이콘, 상태별 색상 차별화를 원하는 대로 구현하기 어렵다. |
| **pubspec 비대화** | 불필요한 외부 의존성은 빌드 복잡도를 높이고 유지보수 부담을 늘린다. |

**결론**: 오버엔지니어링. 기각.

---

## 4. 결과 (Consequences)

### 긍정적 결과

| 결과 | 설명 |
|------|------|
| **정확한 좌표 공유** | `computeNodePositions`가 단일 진실의 원천(SSOT)이 되어, Painter와 GestureDetector가 항상 동일한 좌표를 사용한다. |
| **풍부한 시각 표현** | Canvas API로 글로우, 링, 투명도, 선 두께 등을 자유롭게 제어할 수 있다. |
| **레이어 제어 명확** | 그리기 순서(비활성 선 → 활성 선 → 노드 → 아이콘)를 코드 흐름 그대로 이해할 수 있다. |
| **성능** | 9개 노드·13개 연결선은 매우 작은 데이터이므로 `shouldRepaint`가 트리거될 때만 재드로우해도 부담이 없다. |
| **테스트 독립성** | `computeNodePositions`가 순수 함수이므로 Flutter 없이 Dart 단위 테스트로 좌표 계산을 검증할 수 있다. |

### 부정적 결과 / 트레이드오프

| 결과 | 완화 방법 |
|------|-----------|
| **접근성(A11y) 미지원** | CustomPainter는 기본적으로 스크린 리더를 지원하지 않는다. 필요 시 `Semantics` 위젯으로 래핑해 보완한다. |
| **Canvas API 학습 곡선** | `Paint`, `Canvas.drawCircle`, `TextPainter` 등 위젯 트리보다 저수준 API를 다뤄야 한다. 코드 내 dartdoc 주석으로 각 단계를 명확히 설명해 보완한다. |
| **위젯 Inspector 미지원** | Canvas 내부 구조를 Flutter DevTools 위젯 Inspector로 볼 수 없다. `shouldRepaint`를 올바르게 구현해 재드로우 주기를 명확히 한다. |

---

## 5. 설계 결정 다이어그램

```
┌─────────────────────────────────────────────────────────────────┐
│                   MapScreen (ConsumerWidget)                      │
│  ref.watch(runProvider) → RunState                               │
│                          │                                        │
│         ┌────────────────▼──────────────────────┐               │
│         │              _MapCanvas                │               │
│         │                                        │               │
│         │   LayoutBuilder (실제 캔버스 크기 획득) │               │
│         │         │                              │               │
│         │         ▼                              │               │
│         │   GestureDetector                      │               │
│         │   onTapUp: _onTap()                    │               │
│         │         │                              │               │
│         │         ▼                              │               │
│         │   computeNodePositions() ◄─────── 공유 함수           │
│         │         │                              │               │
│         │         ▼                              │               │
│         │   CustomPaint                          │               │
│         │   painter: MapPainter                  │               │
│         │         │                              │               │
│         │         ▼                              │               │
│         │   computeNodePositions() ◄─────── 공유 함수           │
│         │   _drawAllPaths()                      │               │
│         │   _drawNode()                          │               │
│         └────────────────────────────────────────┘               │
│                                                                   │
│               ▼ 탭 이벤트 발생 시                                 │
│        moveToNode(id) → RunNotifier (Application 계층)           │
└─────────────────────────────────────────────────────────────────┘
```

---

*이 ADR은 "바이브 코딩" 프로젝트의 AI-Human 협업 과정에서 작성되었다.
기술적 결정의 근거를 팀과 발표 청중이 이해할 수 있도록 명문화한다.*
