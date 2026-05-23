# 001 — 아키텍처 명칭 오류: MVVM vs Layered Architecture

| 항목 | 내용 |
|------|------|
| **날짜** | 2026-05-23 |
| **발견 경위** | 발표 슬라이드 작성 중 아키텍처 설명 검토 |
| **수정 파일** | AGENTS.md, CLAUDE.md, README.md, ADR-0001~0004 등 11개 파일 |
| **커밋** | `069ecad` |

---

## AI가 한 것

프로젝트 문서와 슬라이드 전반에 걸쳐 이 프로젝트의 아키텍처를 **"MVVM"** 또는 **"4-Layer MVVM"** 으로 표현했다.

예시:
```
# AGENTS.md (수정 전)
모든 코드는 4계층 MVVM 패턴을 따른다.

# README.md (수정 전)
4-Layer MVVM + Riverpod 아키텍처.
```

---

## 무엇이 틀렸는가

**MVVM은 Presentation 계층 내부 패턴이다.**

- `View` = 화면 위젯
- `ViewModel` = UI 상태 소유, View와 Model을 연결
- `Model` = 데이터/비즈니스 로직

MVVM은 Presentation 레이어 안에서 View와 로직을 분리하는 패턴이지,  
앱 전체의 4계층 구조(Presentation / Application / Domain / Data)를 설명하는 용어가 아니다.

**이 프로젝트의 실제 구조는:**

```
Presentation → Application → Domain ← Data
```

- 전체 구조: **Layered Architecture** (계층 아키텍처)
- Use Case 레이어 없음 → Application 계층이 ViewModel + Use Case 겸임
- 정확한 이름: **4-Layer Layered Architecture + Riverpod**

---

## 왜 AI가 이렇게 표현했는가

Flutter/Riverpod 커뮤니티에서 Riverpod `Notifier`를 관례적으로 "ViewModel"이라고 부르는 경우가 많다. AI는 이 관례적 표현을 그대로 가져와 전체 아키텍처를 "MVVM"으로 뭉뚱그려 표현했다.

틀린 말은 아니지만 **정확하지 않은 표현**이다. 발표 자리에서 "MVVM입니다"라고 하면 "MVVM은 Presentation 레이어 패턴인데 왜 전체 구조를 MVVM이라고 하나요?"라는 반박을 받을 수 있다.

---

## 내가 수정한 것

1. 아키텍처 명칭을 **"4-Layer Layered Architecture + Riverpod"** 으로 통일
2. ADR-0002 결정 섹션을 실제 구조(Use Case 생략 경량 구조)로 갱신
3. CLAUDE.md의 구 3계층 디렉토리(models/viewmodels/views)를 실제 4계층(presentation/application/domain/data)으로 정정
4. 발표 슬라이드 ADR 요약 슬라이드 표현 수정

---

## 배운 것

> AI가 생성한 **용어와 개념**은 코드보다 더 주의 깊게 검토해야 한다.  
> 코드 버그는 테스트가 잡아주지만, 잘못된 개념 정의는 발표장에서 드러난다.

AI는 커뮤니티의 관례적 표현을 그대로 사용하는 경향이 있다.  
공식 발표나 문서에 쓸 용어는 직접 정의를 확인하고 검토해야 한다.
