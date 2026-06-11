# 010 — 공식 문서 발췌: CLAUDE.md와 AGENTS.md를 둘 다 쓸 때의 권장 구조

| 항목 | 내용 |
|------|------|
| **날짜** | 2026-06-11 |
| **카테고리** | 최신 공식 출처 발췌·정리 |
| **출처 1** | [Claude Code 공식 문서 — How Claude remembers your project](https://code.claude.com/docs/en/memory) (2026-06-11 확인) |
| **출처 2** | [agents.md — Open format for guiding coding agents](https://agents.md/) (2026-06-11 확인) |
| **관련 파일** | `CLAUDE.md`, `AGENTS.md` |

---

## 발췌 1 — agents.md: AGENTS.md는 README와 역할이 다른 표준 포맷

> "README.md files are for humans: quick starts, project descriptions, and contribution guidelines." AGENTS.md complements this by containing detailed context agents need — build steps, testing procedures, and conventions.

AGENTS.md는 OpenAI Codex, Cursor, GitHub Copilot, JetBrains Junie 등 60,000개 이상의 오픈소스 프로젝트가 채택한 **도구 중립적 표준**이다. "anything you'd tell a new teammate belongs here too" — 신규 팀원에게 알려줄 내용은 AGENTS.md에 적으라는 것이 핵심 가이드다.

## 발췌 2 — Claude Code 공식 문서: "Claude Code reads CLAUDE.md, not AGENTS.md"

> "Claude Code reads `CLAUDE.md`, not `AGENTS.md`. If your repository already uses `AGENTS.md` for other coding agents, create a `CLAUDE.md` that imports it so both tools read the same instructions without duplicating them."

```markdown
# 공식 문서가 권장하는 형태
@AGENTS.md

## Claude Code
(Claude 전용 추가 지침이 있다면 여기에)
```

## 우리 프로젝트에 적용해보면

이 프로젝트는 **CLAUDE.md와 AGENTS.md를 별개 파일로 직접 작성**했고, 두 파일 모두 "4-Layer Layered Architecture + Riverpod" 구조와 의존성 방향을 각자의 표현으로 설명한다 (CLAUDE.md `## Architecture` 절, AGENTS.md `## 1. 아키텍처 원칙`). 실제로 [001](001-architecture-naming.md)에서 발견한 "MVVM 오표현" 버그도 두 파일에 같은 내용이 따로 적혀 있었기 때문에 **양쪽 다 수정해야** 했다 — 공식 문서가 경고하는 "duplicating them"의 정확한 사례다.

## 배운 것

> 공식 문서는 "두 파일을 따로 유지하면 한쪽만 고치고 다른 쪽을 잊는 일이 생긴다"고 명시적으로 경고한다. 이 프로젝트는 정확히 그 문제를 한 번 겪었다([001](001-architecture-naming.md)).

**권장 조치(다음 정리 작업 후보)**: `CLAUDE.md` 상단에 `@AGENTS.md`를 import하고, CLAUDE.md의 `## Architecture`·`## Code Conventions (AGENTS.md)` 절은 AGENTS.md로 일원화한다. CLAUDE.md는 Project Overview·Commands·Test Structure·Planning Docs 인덱스 등 **Claude 세션에서만 필요한 내용**으로 줄인다. 이 항목은 발견 기록이며, 실제 구조 변경은 CLAUDE.md가 세션 전반에 영향을 미치는 핵심 파일이라 별도 검토 후 진행한다.
