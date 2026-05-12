# docs/setup.md — 개발 환경 설정 및 실행 가이드

---

## 사전 요구사항

| 도구 | 최소 버전 | 확인 명령어 |
|------|-----------|-------------|
| Flutter SDK | 3.9.2 이상 | `flutter --version` |
| Dart SDK | 3.9.2 이상 | `dart --version` |
| Android Studio / VS Code | 최신 권장 | — |
| Android SDK | API 23 (Android 6.0) 이상 | `flutter doctor` |
| Xcode (iOS 빌드 시) | 15 이상 | `xcodebuild -version` |

---

## 1. Flutter SDK 설치

공식 Flutter 설치 가이드: https://docs.flutter.dev/get-started/install

### Windows

1. [Flutter 공식 사이트](https://docs.flutter.dev/get-started/install/windows)에서 SDK zip 다운로드
2. `C:\flutter` 등 원하는 경로에 압축 해제
3. 환경 변수 `PATH`에 `C:\flutter\bin` 추가
4. PowerShell에서 확인:
   ```powershell
   flutter doctor
   ```

### macOS / Linux

```bash
# Homebrew 사용 시 (macOS)
brew install flutter

# 또는 공식 설치 스크립트
# https://docs.flutter.dev/get-started/install/macos
```

---

## 2. 프로젝트 클론 및 의존성 설치

```bash
# 저장소 클론
git clone <repository-url>
cd slay-the-flutter

# 패키지 의존성 설치
flutter pub get
```

---

## 3. 환경 확인

```bash
# Flutter 환경 전체 점검
flutter doctor -v

# 연결된 디바이스 목록 확인
flutter devices
```

모든 항목에 체크(✓)가 표시되어야 합니다. 미해결 이슈가 있으면 출력된 안내에 따라 해결합니다.

---

## 4. 앱 실행 명령어

### 에뮬레이터 / 시뮬레이터 실행

```bash
# Android 에뮬레이터 (AVD Manager에서 먼저 기기 생성 필요)
flutter emulators --launch <emulator-id>

# iOS 시뮬레이터 (macOS 전용)
open -a Simulator
```

### 앱 빌드 및 실행

```bash
# 연결된 기기(에뮬레이터 또는 실기기)에서 디버그 모드 실행
flutter run

# 특정 기기 지정 실행
flutter run -d <device-id>

# 릴리즈 모드로 실행 (성능 테스트용)
flutter run --release

# 웹 브라우저에서 실행 (기능 제한 있음)
flutter run -d chrome
```

### 빌드 산출물 생성

```bash
# Android APK 빌드
flutter build apk --release

# Android App Bundle (Play Store 배포용)
flutter build appbundle --release

# iOS 빌드 (macOS + Xcode 필요)
flutter build ios --release
```

---

## 5. 코드 분석

```bash
# 정적 분석 실행 (경고 0건 유지 필수)
flutter analyze

# 코드 자동 포맷
dart format lib/ test/
```

---

## 6. 주요 파일 구조

```
slay-the-flutter/
├── lib/
│   ├── main.dart              # 앱 진입점
│   ├── models/                # 데이터 모델 (Card, Character, Monster, Quest)
│   ├── viewmodels/            # 상태 관리 (Riverpod Providers)
│   └── views/                 # UI 위젯 (Battle, Quest, Reward 화면)
├── test/                      # 단위 테스트
├── pubspec.yaml               # 의존성 정의
├── AGENTS.md                  # AI 개발 원칙
├── SPECS.md                   # 게임 규칙 명세
├── .planning/                 # 기획 문서
└── docs/                      # 개발 가이드
```

---

## 7. 개발 시 권장 VS Code 확장

- **Flutter** (Dart Code): Flutter/Dart 통합 지원
- **Dart** (Dart Code): Dart 언어 지원
- **Riverpod Snippets**: Riverpod 코드 스니펫

---

## 8. 트러블슈팅

### `flutter pub get` 실패 시

```bash
# pub 캐시 초기화
flutter pub cache repair
flutter pub get
```

### 빌드 캐시 문제

```bash
flutter clean
flutter pub get
flutter run
```

### Android 라이선스 미동의 오류

```bash
flutter doctor --android-licenses
# 모든 라이선스에 'y' 입력
```
