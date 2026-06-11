# 007 — Co-Authored-By 트레일러: AI 기여를 추적하는 단축 컨벤션

| 항목 | 내용 |
|------|------|
| **날짜** | 2026-06-11 (지속적으로 적용된 컨벤션 정리) |
| **카테고리** | 본인만의 단축어·트리거 |
| **근거** | `git log --grep="Co-Authored-By: Claude" --oneline \| wc -l` → 86개 커밋 |

---

## 컨벤션

AI(Claude Code)가 작성하거나 함께 작성한 모든 커밋의 메시지 끝에 다음 트레일러를 포함하도록 고정했다.

```
Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

## 활용

- `git log --grep="Co-Authored-By: Claude" --oneline`로 AI가 관여한 커밋만 필터링 — 현재 86개
- 사람이 단독 작성한 docs 수정([002](002-doc-code-drift.md)의 `d24146d`처럼 `Co-authored-by: ys ...` + `Co-authored-by: Claude ...`가 함께 붙은 경우)과, AI 단독 생성 커밋을 구분 가능
- BONUS.md/LLM Wiki에서 "이 결정/코드는 AI가 제안했다"의 근거로 커밋 해시를 인용할 때, 트레일러 유무로 1차 분류

## 배운 것

> 트레일러 컨벤션처럼 **"매 커밋에 한 줄만 추가하면 되는" 규칙**은 적용 비용이 거의 없으면서, 나중에 "AI가 얼마나/어디에 기여했는가"를 `git log` 한 줄로 정량화할 수 있게 해준다.

가산점 항목(A. AI 워크플로우 활용, C. LLM Wiki)의 증빙을 모을 때 "관련 커밋을 일일이 기억해서 찾기"가 아니라 `git log --grep`으로 즉시 목록화할 수 있었던 것은 이 컨벤션을 처음부터 강제한 덕분이다. 다음 프로젝트에서도 AI 협업 컨벤션은 "사후에 정리"하지 말고 **첫 커밋부터 기계적으로 검색 가능한 형태**로 시작한다.
