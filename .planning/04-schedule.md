# 04-schedule.md — WBS 업데이트 및 확인 매뉴얼

**버전**: 1.0 | **날짜**: 2026-05-12

---

## 파일 구조

```
프로젝트 루트/
├── .planning/
│   ├── 00-vision.md          # 비전 & 게임 컨셉
│   ├── 01-requirements.md    # 요구사항 MoSCoW
│   ├── 02-wbs.json           # WBS 데이터 (이 파일을 편집)
│   └── 04-schedule.md        # 이 문서
└── docs/
    └── index.html            # 간트 차트 시각화 도구
```

---

## 간트 차트 열기

`index.html`은 로컬 파일을 `fetch`로 읽기 때문에 **반드시 로컬 서버** 경유로 열어야 합니다.

### 방법 A — Python (설치 없이 가능)

```bash
# 프로젝트 루트에서 실행
python -m http.server 8080
```

브라우저에서 `http://localhost:8080/docs/index.html` 접속

### 방법 B — VS Code Live Server

1. VS Code 확장에서 `Live Server` 설치
2. `docs/index.html` 파일을 열고 우클릭 → **Open with Live Server**

### 방법 C — Flutter Web Dev Server (이미 실행 중인 경우)

```bash
flutter run -d chrome
```

`lib/` 외부 파일은 서빙되지 않으므로, 별도 서버 사용 권장

---

## WBS JSON 업데이트 방법

`.planning/02-wbs.json`을 직접 편집합니다.

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
  "id": "T009",
  "name": "카드 컴포넌트 CardWidget",
  "assignee": "B",
  "start": "2026-05-26",
  "end": "2026-05-28",
  "status": "done"
}
```

`"status": "pending"` → `"status": "done"` 으로 바꾸면 됩니다.

### 예시: 새 태스크 추가

기존 밀스톤의 `"tasks"` 배열에 추가합니다. `id`는 다음 번호를 사용하세요 (현재 마지막: T034).

```json
{
  "id": "T035",
  "name": "추가 태스크명",
  "assignee": "A",
  "start": "2026-06-09",
  "end": "2026-06-10",
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
| 1주 | 05/12 ~ 05/16 | M1 기획 + M2 아키텍처 설계 | A+B |
| 2주 | 05/19 ~ 05/23 | M2 마무리 + M4 모델 구현 시작 | A+B |
| 3주 | 05/26 ~ 05/30 | M3 UI 시작 + M4 전투 로직 | B / A |
| 4주 | 06/02 ~ 06/06 | M3 UI 완성 + M4 BattleViewModel 완성 | B / A |
| 5주 | 06/09 ~ 06/13 | M4 통합 + M5 테스트 + M6 문서화 병행 | A / B |
| 6주 | 06/16 ~ 06/20 | M5 마무리 + M6 완성 + M7 발표 준비 + **최종 발표** | A+B |

---

## 주간 리뷰 프로세스

매주 월요일, 아래 체크리스트를 팀원과 함께 확인합니다.

```
[ ] 지난 주 태스크 status → "done" 으로 업데이트
[ ] 이번 주 태스크 status → "active" 로 변경
[ ] 일정 지연 태스크 있으면 end 날짜 조정
[ ] updatedAt 필드를 오늘 날짜로 갱신
[ ] 간트 차트 열어서 시각적으로 확인
```

`updatedAt` 갱신 예시:
```json
"updatedAt": "2026-05-19"
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

- WBS 데이터: `.planning/02-wbs.json`
- 시각화 도구: `docs/index.html`
- 요구사항: `.planning/01-requirements.md`
- 비전: `.planning/00-vision.md`
