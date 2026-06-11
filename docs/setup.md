# 개발 환경 설정 가이드

Windows · macOS · Linux 공통 가이드입니다. 이 문서만 보고 5분 안에 앱을 실행할 수 있습니다.

---

## 필요한 도구

| 도구 | 버전 | 용도 | 확인 명령어 |
|------|------|------|-------------|
| Flutter SDK | 3.x (^3.9.2) | 앱 빌드 및 실행 (Dart 포함) | `flutter --version` |
| JDK | 17 이상 | Android 빌드 | `java -version` |
| Android Studio | 최신 | Android 에뮬레이터 및 SDK | `flutter doctor` |
| Xcode | 15 이상 | iOS 빌드 **(macOS 전용)** | `xcodebuild -version` |
| Git | 2.x 이상 | 저장소 클론 | `git --version` |

> **Dart는 별도 설치 불필요** — Flutter SDK에 번들되어 있습니다.

---

## 1단계: Flutter SDK 설치

### Windows

```powershell
# winget으로 설치 (권장)
winget install --id Google.Flutter

# 설치 확인
flutter doctor
```

> winget이 없다면 [Flutter 공식 사이트](https://docs.flutter.dev/get-started/install/windows)에서 zip을 다운로드하여
> `C:\flutter`에 압축 해제 후 `PATH`에 `C:\flutter\bin`을 추가합니다.

### macOS

```bash
# Homebrew로 설치 (권장)
brew install flutter

# 설치 확인
flutter doctor
```

### Linux

```bash
# snap으로 설치 (권장)
sudo snap install flutter --classic

# snap이 없는 경우 (수동 설치)
cd ~
git clone https://github.com/flutter/flutter.git -b stable
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
source ~/.bashrc

# 설치 확인
flutter doctor
```

---

## 2단계: JDK 17 설치

Android 에뮬레이터 또는 실기기에서 실행하려면 JDK 17이 필요합니다.

### Windows

```powershell
winget install --id Microsoft.OpenJDK.17
```

### macOS

```bash
brew install --cask temurin@17
```

### Linux

```bash
sudo apt update && sudo apt install openjdk-17-jdk   # Debian/Ubuntu
sudo dnf install java-17-openjdk                      # Fedora/RHEL
```

---

## 3단계: 저장소 클론 및 의존성 설치

```bash
git clone https://github.com/kang3019/slay-the-flutter.git
cd slay-the-flutter
flutter pub get
```

---

## 4단계: 환경 확인

```bash
flutter doctor -v
```

모든 항목에 ✓ 가 표시되어야 합니다. `flutter doctor`가 제안하는 수정 사항을 먼저 해결하세요.

연결된 디바이스 목록 확인:

```bash
flutter devices
```

---

## 5단계: 첫 실행

```bash
# 연결된 기기(에뮬레이터 또는 실기기)에서 실행
flutter run

# 기기가 여러 개라면 ID를 지정
flutter run -d <device-id>
```

> 에뮬레이터가 없다면 Android Studio → **Device Manager → Create Virtual Device**에서 먼저 생성합니다.
> macOS에서 iOS 시뮬레이터를 사용하려면: `open -a Simulator`

---

## Web(Chrome) 실행 — 세이브 슬롯 데이터 유지

현재 팀은 **Flutter Web(Chrome)** 환경에서 디버깅 모드(`flutter run`)로 개발합니다.

> ⚠️ **세이브 슬롯 데이터를 유지하려면 디버깅 모드 실행 시 반드시 아래 방법 중 하나를 사용해야 합니다.**
>
> `flutter run -d chrome` 기본 명령어는 실행할 때마다 임시 Chrome 프로필을 새로 생성하므로
> `localStorage`(세이브 슬롯·레벨·XP 데이터)가 매번 초기화됩니다.
> 배포된 프로덕션 빌드에서는 이 문제가 없습니다.

### 방법 A — VS Code F5 실행 (권장)

`.vscode/launch.json`에 **"Flutter Web (Chrome, 데이터 유지)"** 구성이 등록되어 있습니다.
VS Code에서 **F5** → 해당 구성 선택.

### 방법 B — PowerShell 스크립트

프로젝트 루트의 `run_web.ps1`을 실행합니다.

```powershell
.\run_web.ps1
```

내부적으로 고정 Chrome 프로필 디렉터리(`%LOCALAPPDATA%\flutter_chrome_dev`)를 지정해
실행 간 `localStorage` 데이터를 유지합니다.

### 방법 C — 직접 명령어 입력

```powershell
flutter run -d chrome --web-browser-flag "--user-data-dir=$env:LOCALAPPDATA\flutter_chrome_dev" --web-port=5000
```

> **왜 이렇게 해야 하나?**
> Flutter Web은 `shared_preferences`를 브라우저 `localStorage`에 저장합니다.
> `flutter run -d chrome`은 매번 새로운 임시 디렉터리로 Chrome을 열기 때문에
> `localStorage`가 초기화됩니다. `--user-data-dir`로 고정 경로를 지정하면 해결됩니다.

---

## 릴리스 빌드 (배포)

배포용 산출물은 플랫폼별로 아래 명령어로 생성합니다. 모두 프로젝트 루트에서 실행합니다.

### Android — APK / App Bundle

```bash
# 단일 APK (테스트 배포·사이드로딩용)
flutter build apk --release
# 산출물: build/app/outputs/flutter-apk/app-release.apk

# App Bundle (Google Play 등록용, 권장)
flutter build appbundle --release
# 산출물: build/app/outputs/bundle/release/app-release.aab
```

> ⚠️ 현재 release 빌드는 `android/app/build.gradle.kts`에서 **debug 서명 키**를 사용합니다
> (`signingConfig = signingConfigs.getByName("debug")`, Flutter 기본 템플릿의 TODO 미해결 상태).
> Play 스토어 정식 등록 시에는 `keytool`로 release keystore를 생성하고
> `key.properties` + `signingConfigs.release`를 추가해야 합니다
> ([Flutter 공식 가이드: Sign the app](https://docs.flutter.dev/deployment/android#sign-the-app)).
> `.planning/01-requirements.md`에서 CI/CD·앱 서명·스토어 등록은 Out of Scope로 명시했으므로,
> 이 프로젝트 범위에서는 debug 서명을 그대로 사용합니다.

### iOS — IPA (macOS + Xcode 필요)

```bash
flutter build ipa --release
# 산출물: build/ios/ipa/*.ipa
```

> Apple Developer 계정과 프로비저닝 프로파일이 필요합니다. `ios/Runner.xcworkspace`를
> Xcode로 열어 **Signing & Capabilities**에서 Team을 설정한 뒤 빌드하세요.

### Web

```bash
flutter build web --release
# 산출물: build/web/ (정적 파일 — 임의의 웹 서버/호스팅에 그대로 배포)
```

---

## Git Hook 설치 — 커밋 전 자동 검증 (pre-commit)

`tools/git-hooks/pre-commit`은 커밋 전에 `flutter analyze` → `flutter test` 순서로 실행해,
AGENTS.md의 "analyze 0 warnings·테스트 통과" 규칙을 커밋 시점에 자동으로 강제합니다.

```bash
# macOS / Linux / Git Bash
cp tools/git-hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

```powershell
# Windows PowerShell
Copy-Item tools\git-hooks\pre-commit .git\hooks\pre-commit
```

설치 후 `git commit` 시 두 검사 중 하나라도 실패하면 커밋이 중단됩니다.
의도적으로 건너뛰려면 `git commit --no-verify`를 사용할 수 있지만,
`flutter analyze` 경고 0건은 머지 전 필수 조건이므로 권장하지 않습니다.

> **참고**: `dart format --set-exit-if-changed`는 의도적으로 제외했습니다.
> 현재 Dart SDK 3.9.2의 "tall-style" 포매터 기준으로는 기존 코드 63개 파일이
> 재포맷 대상으로 표시되는데(이전 SDK의 "short-style" 포매터로 작성됨),
> 이는 이번 변경과 무관한 별도의 전체 재포맷 작업이 필요한 사항입니다.
> // TODO(kang3019): SDK 3.9.2 tall-style 기준으로 `dart format lib/ test/` 일괄 적용 후
> pre-commit에 포맷 체크를 다시 추가한다.

---

## 자주 쓰는 명령어

```bash
flutter analyze          # 정적 분석 — 0 warnings (필수)
dart format lib/ test/   # 코드 자동 포맷
flutter test             # 전체 테스트 — 431개 전량 통과
flutter test --coverage  # 커버리지 측정 → coverage/lcov.info
flutter clean && flutter pub get  # 빌드 캐시 초기화
```

> **현재 상태**: `flutter test` → **431/431 전부 통과**, `flutter analyze` → **경고 0건**

---

## 문제 해결 (FAQ)

### Q1. `flutter pub get` 실행 시 네트워크 오류가 발생합니다

```bash
# pub 캐시를 초기화한 뒤 재시도합니다
flutter pub cache repair
flutter pub get
```

중국 등 일부 국가에서는 pub.dev 접근이 차단됩니다. 아래 미러를 환경 변수로 설정하세요.

```bash
# macOS / Linux
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

# Windows PowerShell
$env:PUB_HOSTED_URL="https://pub.flutter-io.cn"
$env:FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
```

---

### Q2. `flutter run` 시 기기가 표시되지 않습니다

1. Android 에뮬레이터: Android Studio → **Device Manager**에서 에뮬레이터를 시작합니다.
2. 실기기(Android): USB 디버깅이 활성화되어 있는지 확인합니다 (설정 → 개발자 옵션).
3. iOS 시뮬레이터(macOS): `open -a Simulator` 로 시뮬레이터를 먼저 실행합니다.
4. `flutter devices` 로 인식 여부를 재확인합니다.

---

### Q3. Android 라이선스 오류 (`Android license status unknown`)가 납니다

```bash
flutter doctor --android-licenses
# 프롬프트가 나타나면 모두 y 입력
```

---

### Q4. `flutter doctor`에서 Xcode 관련 오류가 표시됩니다 (macOS)

Xcode 명령줄 도구가 설치되지 않은 경우입니다.

```bash
sudo xcode-select --install
sudo xcodebuild -license accept
```

---

### Q5. 빌드 캐시 문제로 앱이 실행되지 않거나 이상하게 동작합니다

```bash
flutter clean
flutter pub get
flutter run
```

이후에도 문제가 지속되면 Android Studio에서 **File → Invalidate Caches / Restart**를 실행합니다.
