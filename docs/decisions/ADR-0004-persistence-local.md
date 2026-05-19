# ADR-0004: 영속성 전략 — 로컬 우선(Local-First) 선택

| 항목 | 내용 |
|------|------|
| **상태** | 승인(Accepted) |
| **결정일** | 2026-05-19 |
| **결정자** | kang3019 |

---

## 컨텍스트

Slay the Flutter는 런 종료 후 XP·레벨·카드 해금 상태를 영속 저장해야 한다. 저장 방식을 선택할 때 아래 제약이 있었다.

- 대학 과제 프로젝트로 서버 운영 비용을 쓸 수 없다.
- 1인 개발이므로 백엔드 구축·유지 비용을 최소화해야 한다.
- 인터넷 연결 없이도 게임이 완전히 동작해야 한다.
- 저장 데이터 규모가 작다 (레벨, XP, 해금 카드 ID 목록 정도).

---

## 검토된 선택지

| 옵션 | 설명 | 탈락 이유 |
|------|------|-----------|
| **Firebase Firestore** | Google 실시간 클라우드 DB | 무료 티어 제한(읽기 5만/일)이 있고, 인터넷 의존·계정 시스템 필요. 게임 규모 대비 과함 |
| **Firebase Realtime DB** | Firebase 실시간 JSON DB | 동일하게 인터넷 의존. 오프라인 플레이 요구 미충족 |
| **SQLite (drift/sqflite)** | 로컬 관계형 DB | 저장 데이터가 단순한 키-값 수준이므로 스키마 설계·마이그레이션 비용이 과도함 |
| **SharedPreferences + JSON** | OS 제공 키-값 저장소 | 단순, 오프라인, 무료, 설정 불필요 → 요구 사항에 정확히 부합 |

---

## 결정

**SharedPreferences + JSON 직렬화** 를 채택한다. 외부 서비스에 일절 의존하지 않는 **로컬 우선(Local-First)** 아키텍처로 고정한다.

저장 대상 데이터:

| 키 | 타입 | 설명 |
|----|------|------|
| `player_level` | `int` | 현재 레벨 |
| `player_xp` | `int` | 누적 XP |
| `unlocked_cards` | `List<String>` | 해금된 카드 ID 목록 |

저장 레이어는 `lib/data/local_storage.dart` 단일 파일로 캡슐화하며, Domain 계층은 저장 방식을 몰라도 된다.

```dart
// 예시: 저장소 인터페이스
abstract class LocalStorage {
  Future<int> readLevel();
  Future<void> saveLevel(int level);
  Future<List<String>> readUnlockedCards();
  Future<void> saveUnlockedCards(List<String> ids);
}
```

---

## 결과 (Consequences)

### 긍정적

- 인터넷·계정·서버 없이 완전히 오프라인 동작한다.
- 외부 서비스 장애·무료 티어 초과·API 변경에 전혀 영향을 받지 않는다.
- 테스트 시 `FakeLocalStorage` 스텁으로 쉽게 대체할 수 있다.

### 부정적 / 감수하는 트레이드오프

- 기기를 바꾸거나 앱을 삭제하면 저장 데이터가 사라진다.
- 여러 기기 간 동기화가 불가능하다 (Won't Have로 명시적 제외).

---

## 관련 문서

- [ADR-0002: 아키텍처 — MVVM](ADR-0002-architecture-mvvm.md)
- [ADR-0003: 상태관리 — Riverpod](ADR-0003-state-management-riverpod.md)
- `.planning/03-risks.md` — R-04 외부 의존 위험 대응 참고
