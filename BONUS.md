# BONUS.md — 가산점 트래킹 (최대 +6점)

**버전**: 2.0 | **날짜**: 2026-06-11

가산점은 자동으로 부여되지 않으므로, 발표 또는 별도 시간에 본인이 명시적으로 어필하고
검증 가능한 증빙(커밋 해시·파일 경로)을 함께 제시한다.
가산점 총합 최대 **+6점** (A+1 / B+2 / C+1 / D+2), 발표 평가(30점)에 가산.

---

## A. AI Agent / 스킬 / 워크플로우 적극 활용 (+1점)

> 단순 코드 생성이 아닌, AI를 **설계·검토·자동화 워크플로우**에 통합했음을 증명

### 사용한 워크플로우 목록과 호출 시점

| 워크플로우 | 호출 시점 | 근거 |
|------------|-----------|------|
| Claude Code(Bash/Edit/Read/Glob/Grep) 기반 반복 개발 | 기능 구현 전반 | `Co-Authored-By: Claude Sonnet 4.6` 트레일러 86개 커밋 ([docs/llm-wiki/007](docs/llm-wiki/007-co-authored-by-trailer.md)) |
| TDD 워크플로우(테스트 → 구현) | 게임 로직 추가 시 매번 | `AGENTS.md` §4 명문화, `test/`가 `lib/` Domain·Application 1:1 미러링 ([docs/llm-wiki/006](docs/llm-wiki/006-tdd-prompt-pattern.md)) |
| ADR 작성 → 직접 검토·수정 | 아키텍처/상태관리/영속성 결정 시 | `docs/decisions/ADR-0001~0005`, [docs/llm-wiki/001](docs/llm-wiki/001-architecture-naming.md) |
| 문서-코드 동기화 전수 검토 | 발표 준비·주요 마일스톤 직후 | 커밋 `d24146d` ([docs/llm-wiki/002](docs/llm-wiki/002-doc-code-drift.md)) |
| pre-commit 품질 게이트 (`flutter analyze` + `flutter test`) | 매 커밋 전 | `tools/git-hooks/pre-commit`, 설치법 `docs/setup.md` |

### 절약된 시간 / 향상된 품질 구체 사례

- **커밋 `069ecad`**: AI가 프로젝트 문서·슬라이드 전반에 잘못 사용한 아키텍처 명칭("MVVM")을 발견해
  AGENTS.md·CLAUDE.md·README.md·ADR 등 11개 파일을 한 번의 검토로 일괄 수정.
  발표 현장에서 "MVVM은 Presentation 레이어 패턴인데 왜 전체 구조를 MVVM이라 하나"라는 반박을 사전에 차단.
  ([docs/llm-wiki/001](docs/llm-wiki/001-architecture-naming.md))
- **커밋 `d24146d`**: "코드베이스 전수 검토 후 MD 파일 정확성 검증" 프롬프트 한 번으로 README 테스트 뱃지,
  CLAUDE.md 테스트 디렉토리 목록, SPECS.md 레벨업/유물 표 등 11개 파일의 누적된 불일치를 한 번에 정정.
  파일별로 수동 대조했다면 훨씬 오래 걸렸을 작업.
  ([docs/llm-wiki/002](docs/llm-wiki/002-doc-code-drift.md))

**달성 여부**: ☑ 달성

---

## B. 본인만의 기법 구성 (+2점) — 가장 큰 가산점

> 강의 내용을 넘어서 **직접 설계하거나 응용한 독창적 기법**이 코드·문서에 녹아 있음

- [x] 4-Layer + Riverpod 패턴을 로그라이크 턴제 전투에 맞게 직접 설계 (BattleProvider 구조)
  - 근거: `lib/application/battle_provider.dart` — BattleNotifier 상태 머신 설계,
    `docs/architecture.md` — 4계층 의존 방향 및 Provider 패턴 문서화,
    `docs/decisions/ADR-0002` ~ `ADR-0003` — 아키텍처·상태관리 결정 근거
- [x] 카드 효과를 `CardEffectType` 열거형으로 추상화해 확장 가능한 구조로 구현
  - 근거: `lib/domain/entities/card.dart` — `CardEffectType` 열거형(damage/block/buff/heal/draw 등) 및 `GameCard` 모델 정의,
    `lib/domain/battle_engine.dart` — 카드 타입별 효과 분기 처리
- [x] 기존 라이브러리를 사용하지 않고 덱 셔플·드로우 사이클을 순수 Dart로 구현하고 단위 테스트 작성
  - 근거: `lib/domain/deck.dart` — `shuffle()`, `draw()`, `discard()`, `discardHand()` 순수 Dart 구현,
    `test/domain/` — 덱 로직 단위 테스트
- [x] 본인이 직접 도출한 게임 공식(데미지 계산, 상태 이상 배율 등)을 상수화하고 ADR에 근거 기록
  - 근거: `lib/domain/entities/player.dart` — `Player.vulnerableMultiplier = 1.5`, `Player.weakMultiplier = 0.75` 상수 정의,
    `lib/domain/entities/monster.dart` — `Monster.vulnerableMultiplier` 상수 정의,
    `lib/domain/battle_engine.dart` — `_weakAdjusted()` 공식 적용,
    `SPECS.md` — 전체 게임 공식 명세
- [x] Claude Code 공식 메모리 문서의 `@import` 규칙을 적용해 `CLAUDE.md` ↔ `AGENTS.md` 중복 제거
  - 저희는 `docs/llm-wiki/010`에서 발췌한 "CLAUDE.md는 AGENTS.md를 `@import`하고, 중복 규칙은 AGENTS.md로 일원화하라"는 공식 권장 패턴을 그대로 적용해, `CLAUDE.md`의 `## Architecture`·`## Code Conventions` 중복 절을 제거하고 `@AGENTS.md` import로 연결했습니다.
  - 근거: `CLAUDE.md`(상단 `@AGENTS.md` import, `## Architecture` 절 축약), `AGENTS.md`(규칙의 단일 진실 공급원), `docs/llm-wiki/010-claude-md-agents-md-overlap.md` — 공식 문서 발췌 및 적용 기록

**발표 시 설명(2~3분)**: "왜 4-Layer + Riverpod을 카드게임 전투 상태 머신에 맞게 변형했는가"를
`docs/decisions/ADR-0002`·`ADR-0003`의 결정 근거를 바탕으로 설명하고,
CLAUDE.md/AGENTS.md 중복 제거는 한 문장으로 짧게 언급한다.

**달성 여부**: ☑ 달성

---

## C. LLM Wiki 기반 본인 암묵지 운영 (+1점)

> AI와의 협업 과정에서 얻은 **개인 지식·실패 경험·설계 결정**을 지속적으로 문서화

- [x] 위치: [`docs/llm-wiki/`](docs/llm-wiki/) (본 공개 리포지토리 내, 인덱스: `docs/llm-wiki/README.md`)
- [x] 최소 10개 항목: 001~010 (10개) — [docs/llm-wiki/README.md](docs/llm-wiki/README.md) 인덱스 참고
- [x] 최신 LLM 공식 출처에서 발췌·정리한 흔적
  - 근거: [010](docs/llm-wiki/010-claude-md-agents-md-overlap.md) — Claude Code 공식 문서(`code.claude.com/docs/en/memory`) 및
    `agents.md` 스펙 사이트를 발췌, 이 프로젝트의 CLAUDE.md/AGENTS.md 중복 문제와 직접 연결
- [x] 권장 카테고리 커버
  - 잘 동작한 프롬프트 패턴: [006](docs/llm-wiki/006-tdd-prompt-pattern.md)
  - 실패 사례와 원인: [001](docs/llm-wiki/001-architecture-naming.md), [002](docs/llm-wiki/002-doc-code-drift.md), [003](docs/llm-wiki/003-visual-bug-iteration.md), [004](docs/llm-wiki/004-reward-wiring-bug.md), [008](docs/llm-wiki/008-web-platform-gap.md), [009](docs/llm-wiki/009-procedural-map-validation.md)
  - 모델/도구별 차이점: [005](docs/llm-wiki/005-adr-example-vs-implementation.md), [008](docs/llm-wiki/008-web-platform-gap.md)
  - 본인만의 단축어·트리거: [007](docs/llm-wiki/007-co-authored-by-trailer.md)
- [x] 직접 수정·보완한 AI 코드/문서에 대해 "왜 바꿨는지"를 Wiki에 기록 (전 항목 공통 — "내가 수정한 것" 절)

**달성 여부**: ☑ 달성

---

## D. 최신 AI Agent 리포트 발표 (+2점)

> 본인 프로젝트 발표와 **별도 시간**에 신청·진행하는 10분 이상 발표

- [ ] 10분 이상 발표 시간 별도 신청 (정확히 측정)
- [ ] 주제: 최근 6개월 이내 출시·업데이트된 AI Agent 도구/기법
      (예: Claude Code Skills/Subagent 생태계, MCP 최신 변화, 신규 코드 생성 모델 비교, 기업 AI Agent 도입 사례)
- [ ] 출처(블로그·공식 문서·논문) 명시
- [ ] 본인 프로젝트 발표와 분리된 일정으로 진행

**상태**: 미신청 — 발표 일정 확정 시 본 항목 갱신

---

## 총계

| 항목 | 배점 | 달성 |
|------|------|------|
| A. AI Agent / 스킬 / 워크플로우 적극 활용 | +1점 | ☑ |
| B. 본인만의 기법 구성 | +2점 | ☑ |
| C. LLM Wiki 기반 본인 암묵지 운영 | +1점 | ☑ |
| D. 최신 AI Agent 리포트 발표 | +2점 | ☐ (별도 신청 필요) |
| **합계 (확보)** | **+4점** | A+B+C 달성 |
| **합계 (D 포함 시 최대)** | **+6점** | D는 별도 발표 신청 필요 |

---

> 이 파일은 주요 마일스톤마다 함께 갱신한다.
> 근거 링크를 공란으로 두면 달성으로 인정받기 어려우므로, 반드시 커밋 해시 또는 파일 경로를 기록한다.
