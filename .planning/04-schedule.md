# 04-schedule.md — WBS 업데이트 및 확인 매뉴얼

**버전**: 1.1 | **날짜**: 2026-05-22

---

## 파일 구조

```
프로젝트 루트/
├── .planning/
│   ├── 00-vision.md          # 비전 & 게임 컨셉
│   ├── 01-requirements.md    # 요구사항 MoSCoW
│   ├── 02-wbs.json           # WBS 데이터 원본 (이 파일을 편집)
│   └── 04-schedule.md        # 이 문서
└── docs/
    ├── index.html            # 간트 차트 시각화 도구
    └── 02-wbs.json           # 시각화 도구가 읽는 WBS 사본
                              # ⚠️ .planning/02-wbs.json 수정 후 반드시 동기화
```

> **동기화 방법**: `.planning/02-wbs.json` 수정 후 아래 명령 실행
> ```bash
> cp .planning/02-wbs.json docs/02-wbs.json
> ```

---

## 간트 차트 열기

`index.html`은 로컬 파일을 `fetch`로 읽기 때문에 **반드시 로컬 서버** 경유로 열어야 합니다.

### 방법 A — Python (설치 없이 가능)

```bash
# 프로젝트 루트에서 실행
python -m http.server 8080
```

브라우저에서 `http://localhost:8080/docs/` 접속

### 방법 B — VS Code Live Server

1. VS Code 확장에서 `Live Server` 설치
2. `docs/index.html` 파일을 열고 우클릭 → **Open with Live Server**

---

## WBS JSON 업데이트 방법

`.planning/02-wbs.json`을 직접 편집한 뒤 `docs/02-wbs.json`에 복사합니다.

### 태스크 상태(status) 정의

| 값 | 의미 | 색상 |
|----|------|------|
| `"done"` | 완료된 태스크 | 회색 |
| `"active"` | 현재 진행 중 | 주황 |
| `"pending"` | 아직 시작 전 | 파랑 |
| `"milestone"` | 마일스톤 이벤트 (다이아몬드) | 보라 |

### 태스크 날짜 규칙

- `"start"` / `"end"` 모두 **작업이 포함되는 날짜** (inclusive)
- 예: 월요일~금요일 작업이면 `"start": "2026-05-19", "end": "2026-05-23"`
- 날짜 형식: `YYYY-MM-DD`

### 예시: 태스크 완료 처리

```json
{
  "id": "T013",
  "name": "BattleEngine 데미지",
  "assignee": "A",
  "start": "2026-05-22",
  "end": "2026-05-24",
  "status": "done"
}
```

`"status": "pending"` → `"status": "done"` 으로 바꾸면 됩니다.

### 예시: 새 태스크 추가

기존 마일스톤의 `"tasks"` 배열에 추가합니다. `id`는 다음 번호를 사용하세요 (현재 마지막: T042).

```json
{
  "id": "T043",
  "name": "추가 태스크명",
  "assignee": "A",
  "start": "2026-06-16",
  "end": "2026-06-17",
  "status": "pending",
  "priority": "medium"
}
```

### 담당자(assignee) 값

| 값 | 의미 |
|----|------|
| `"A"` | kang (게임 로직 / ViewModel / 테스트) |
| `"B"` | kim (UI / 모델 / 문서화) |
| `"A+B"` | 공동 작업 |

---

## 6주 마일스톤 요약

| 주차 | 기간 | 마일스톤 | 주 담당 |
|------|------|----------|---------|
| 1주 | 05/12 ~ 05/16 | M1 기획 & 환경 설정 | A+B |
| 2주 | 05/19 ~ 05/23 | M2 아키텍처 설계 마무리 | A+B |
| 3주 | 05/26 ~ 05/30 | M3 핵심 로직 시작 + M4 UI 개발 시작 | A / B |
| 4주 | 06/02 ~ 06/06 | M3 핵심 로직 완성 + M4 UI 개발 + M5 통합 시작 | A / B |
| 5주 | 06/09 ~ 06/13 | M5 통합 완성 + M6 테스트 | A+B |
| 6주 | 06/16 ~ 06/20 | M6 테스트 완성 + M7 QA & 발표 준비 + **최종 발표** | A+B |

### 마일스톤별 태스크 범위

| 마일스톤 | 태스크 | 기간 |
|----------|--------|------|
| M1 기획 & 환경 설정 | T001 ~ T006 | 05/12 ~ 05/16 |
| M2 아키텍처 설계 | T007 ~ T012 | 05/15 ~ 05/21 |
| M3 핵심 로직 구현 | T013 ~ T019 | 05/22 ~ 06/02 |
| M4 UI 개발 | T020 ~ T026 | 05/26 ~ 06/08 |
| M5 통합 & 영속성 | T027 ~ T031 | 06/02 ~ 06/12 |
| M6 테스트 | T032 ~ T036 | 06/09 ~ 06/15 |
| M7 QA & 발표 준비 | T037 ~ T042 | 06/16 ~ 06/20 |

---

## 주간 리뷰 프로세스

매주 월요일, 아래 체크리스트를 팀원과 함께 확인합니다.

```
[ ] 지난 주 태스크 status → "done" 으로 업데이트
[ ] 이번 주 태스크 status → "active" 로 변경
[ ] 일정 지연 태스크 있으면 end 날짜 조정
[ ] updatedAt 필드를 오늘 날짜로 갱신
[ ] cp .planning/02-wbs.json docs/02-wbs.json 실행
[ ] 간트 차트 열어서 시각적으로 확인
```

`updatedAt` 갱신 예시:
```json
"updatedAt": "2026-05-22"
```

---

## 우선순위(priority) 설명

| 값 | 의미 |
|----|------|
| `"high"` | 지연 시 이후 태스크에 블로킹 영향 |
| `"medium"` | 중요하지만 1~2일 여유 있음 |
| `"low"` | 시간 여유 시 구현 |

---

## 빠른 참조

- WBS 데이터 원본: `.planning/02-wbs.json`
- WBS 데이터 사본 (시각화용): `docs/02-wbs.json`
- 시각화 도구: `docs/index.html`
- 요구사항: `.planning/01-requirements.md`
- 비전: `.planning/00-vision.md`
