# 09-current-status.md — 현재 구현 상태

**기준일**: 2026-06-09 | **스프린트**: Sprint 5 (06/09 ~ 06/13)

---

## 전체 진행률

| 구분 | 상태 |
|------|------|
| 테스트 | ✅ 421개 전부 통과 |
| 린트 | ✅ `flutter analyze` 경고 0건 |
| 핵심 게임 루프 | ✅ 전투 → 보상 → 맵 이동 동작 |
| 미구현 화면 | ⚠️ ShopScreen / RunEndScreen / MetaProgressScreen |

---

## 구현 완료

### Domain
- `BattleEngine` — 전투 규칙, 카드 효과, 유물 효과, 상태이상
- `Deck` — 셔플, 드로우, 버림, 소각(exhaust)
- `GameCard` / `Cards` — 26종 + 강화(upgraded) 버전
- `Monster` — 5종 (StickySlime, IronScavenger, VenomSentinel, CaveGuardian, IronGolem), AI 의도 패턴
- `Player` — HP, 방어도, 힘, 상태이상
- `StatusEffect` — Vulnerable, Weak, Poison
- `Relic` / `GameRelics` — 20종 이상 패시브 효과
- `GameEvent` / `GameEvents` — 텍스트 이벤트 + 선택지
- `MapNode` / `MapGenerator` — 절차적 생성 5층 맵
- `MetaProgress` — XP 레벨 1~10, 카드 해금 시스템
- `SaveSlot` — 3슬롯 JSON 직렬화

### Application
- `BattleProvider` — 전투 상태 머신
- `RunProvider` — 런 진행 (6가지 RunPhase)
- `MetaProgressProvider` — XP/레벨 영속 저장
- `SaveSlotProvider` — 슬롯 저장/로드

### Presentation
- `BattleScreen` — 공격 모션, 피격 그라데이션, 사망 애니메이션, 화면 흔들림
- `MapScreen` — 절차적 맵, 덱 뷰어 시트
- `RewardScreen` — 카드 3장 중 1장 선택
- `EventScreen` — 텍스트 이벤트 선택지
- `TreasureScreen` — 유물 획득/건너뛰기
- `RestScreen` — HP 회복 / 카드 강화 선택
- `SaveSlotScreen` — 슬롯 선택·저장·로드
- `SettingsScreen`

---

## 미구현 항목

### ⬜ ShopScreen (T043)
- `NodeType.shop` 도메인에 존재, `RunPhase`에 없음
- 필요 작업:
  1. `RunPhase.shop` 추가
  2. `RunNotifier.enterShop()` / `buyCard()` / `removeCard()` 메서드
  3. `ShopScreen` 위젯 — 골드 표시, 카드 구매(50G), 카드 제거(75G), 유물 구매
  4. `AppRouter`에 `RunPhase.shop` 케이스 추가

### ⬜ RunEndScreen (T044)
- `isRunOver = true` 시 AppRouter가 MapScreen을 그대로 띄움
- 필요 작업:
  1. `RunPhase.runEnd` 추가 (또는 별도 오버레이 처리)
  2. 승리/패배 구분 표시
  3. 클리어 스테이지, 획득 골드 요약
  4. XP 지급 → 레벨업 연출 (현재 BattleScreen 내부에 일부 로직 있음)
  5. "새 런 시작" 버튼 → `RunNotifier.startNewRun()`

### ⚠️ MetaProgressScreen (T045)
- `MetaProgressProvider` 완성됨, 화면 접근 경로 없음
- 필요 작업:
  1. SaveSlotScreen 또는 타이틀에서 레벨·XP 바 노출
  2. 해금 카드 목록 그리드 뷰
  3. 현재 레벨 진행률 시각화

---

## Sprint 6 예정 작업 (06/16 ~ 06/20)

| ID | 태스크 |
|----|--------|
| T037 | 버그 수정 & QA (QA 체크리스트 기준) |
| T038 | README 업데이트 (설치·실행 가이드) |
| T039 | 발표 슬라이드 |
| T040 | 데모 시나리오 |
| T041 | 전체 리허설 |
| T042 | 최종 발표 |

---

## QA 체크리스트 (Sprint 6 시작 전 완료 목표)

```
[x] 카드 사용 → 데미지 정상 적용
[x] 방어도 턴 종료 시 소멸
[x] 취약/약화 배율 공식 정확
[x] 몬스터 HP 0 → 승리 처리
[x] 플레이어 HP 0 → 패배 처리
[x] XP 저장 → 앱 재시작 후 유지
[x] 레벨업 시 카드 해금 정상 등록
[x] 보스전 패턴 정상 동작
[x] 메모리 누수 없음 (ProviderContainer dispose)
[ ] ShopScreen 골드 소비 정상 동작
[ ] RunEndScreen XP 지급 및 레벨업 연출
[ ] 세이브 슬롯 저장/로드 전체 흐름
```
