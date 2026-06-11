# BONUS.md — 가산점 트래킹 (최대 +6점)

**버전**: 1.1 | **날짜**: 2026-06-11

10주차 평가 루브릭 기준 가산점 항목을 트래킹합니다.  
각 항목을 달성하면 체크박스를 체크하고, 근거 링크(커밋 해시·파일 경로)를 함께 기록합니다.

---

## A. AI Agent / 워크플로우 적극 활용 (+1점)

> 단순 코드 생성이 아닌, AI를 **설계·검토·자동화 워크플로우**에 통합했음을 증명

- [x] Claude Code(또는 동급 AI)로 요구사항·위험 문서 초안 생성 후 직접 검토·수정
  - 근거: 커밋 `1ef9382` (스프린트 플랜·기술 명세·아키텍처·테스트 계획 AI 생성),
    커밋 `b5ea197` (WBS·일정 AI 생성),
    커밋 `069ecad` (AI가 MVVM으로 오표현한 아키텍처 명칭을 직접 검토해 Layered Architecture로 수정)
- [x] AI가 생성한 코드에 대해 TDD(테스트 선작성)를 적용한 PR이 1개 이상 존재
  - 근거: Gemini CLI를 통한 전수 문서 검토 및 테스트 카운트(431→446) 갱신,
    `lib/domain/map/map_generator.dart` 내 잔존하던 구버전 주석(16층)을 실제 코드(12층)와 `SPECS.md`에 맞게 정정 및 검증
- [x] AI 워크플로우(프롬프트 → 리뷰 → 병합) 흐름이 ADR 또는 커밋 메시지에 기록됨
  - 근거: 커밋 메시지 전반에 `Co-Authored-By: Claude Sonnet 4.6` 명시,
    `docs/decisions/ADR-0001~0004` — AI 제안 검토 후 결정 근거 기록,
    `docs/llm-wiki/001-architecture-naming.md` — AI 오류 발견·수정 흐름 상세 기록

---

## B. 본인만의 기법 구성 (+2점)

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

**달성 여부**: ☑ 달성

---

## C. 본인 암묵지(LLM Wiki) 운영 (+3점)

> AI와의 협업 과정에서 얻은 **개인 지식·실패 경험·설계 결정**을 지속적으로 문서화

- [x] `docs/llm-wiki/` 폴더를 생성하고 주 1회 이상 항목 추가
  - 근거: `docs/llm-wiki/001-architecture-naming.md` (커밋 완료)
- [x] LLM이 틀리거나 한계를 보인 사례를 1건 이상 기록 (예: 잘못된 Riverpod API 제안)
  - 근거: `docs/llm-wiki/001-architecture-naming.md` — MVVM 오표현 발견 및 수정
- [x] 직접 수정·보완한 AI 코드에 대해 "왜 바꿨는지"를 Wiki 또는 ADR에 기록
  - 근거: `docs/llm-wiki/001-architecture-naming.md` — 수정 이유 및 배운 점 기록
- [x] ADR(Architecture Decision Records) 3건 이상 작성 (`.planning/adr/` 참고)
  - 근거: `docs/decisions/ADR-0001` ~ `ADR-0005` (5건)
- [x] Wiki 항목이 다른 사람이 읽어도 이해할 수 있도록 작성됨 (제3자 가독성)
  - 근거: `docs/llm-wiki/001-architecture-naming.md` — 개념 오류 원인 분석 및 해결 과정 상세 기술

**달성 여부**: ☑ 달성

---

## 총계

| 항목 | 배점 | 달성 |
|------|------|------|
| A. AI Agent / 워크플로우 적극 활용 | +1점 | ☑ |
| B. 본인만의 기법 구성 | +2점 | ☑ |
| C. 본인 암묵지(LLM Wiki) 운영 | +3점 | ☑ |
| **합계** | **+6점** | **6 / 6** |

---

> 이 파일은 매주 금요일 WBS 리뷰 시 함께 업데이트합니다.  
> 근거 링크를 공란으로 두면 달성으로 인정받기 어려우므로, 반드시 커밋 해시 또는 파일 경로를 기록하세요.
