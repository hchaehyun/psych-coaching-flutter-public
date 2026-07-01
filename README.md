# Psych Coaching Flutter Public Snapshot

심리 코칭 서비스의 Flutter 모바일 앱입니다. 감정/수면 셀프트래킹, 저널 작성, 알림, 계정 설정처럼 사용자가 매일 기록하고 돌아볼 수 있는 모바일 경험을 제공합니다.

실제 Firebase 프로젝트 설정, 네이티브 Firebase 설정 파일, 운영 API URL은 포함하지 않습니다.

## Features
- Google 로그인 기반 인증 흐름과 사용자 세션 관리
- 사용자 프로필, 기기 단위 로그인 상태, 온보딩 상태 관리
- 감정/수면 기반 셀프트래킹 기록과 캘린더 중심 조회
- 저널 작성, 이미지 선택/업로드, 기록 상세 화면
- 알림 목록, 읽음 상태, 푸시 알림 권한 흐름
- 약관, 개인정보 처리방침, 계정 관리, 로그아웃/탈퇴 화면
- 공통 네트워크 클라이언트, 에러 처리, 테마, 라우팅 구조

## Tech Stack
- Flutter / Dart
- Riverpod, Riverpod Generator
- GoRouter
- Dio
- Firebase Auth, Cloud Firestore, Firebase Storage
- Google Sign-In
- SharedPreferences, Flutter Secure Storage
- Image Picker, Permission Handler, Device Info Plus
- Flutter Local Notifications, Timezone
- Build Runner, JSON Serializable

## Architecture
feature-first 구조로 화면, 상태, 데이터 접근을 기능 단위로 묶고, 앱 전역에서 공유되는 설정과 서비스는 `core`에 둡니다.

```text
lib/
├── core/
│   ├── constants/      # 앱 공통 상수
│   ├── network/        # Dio 클라이언트와 API 응답 처리
│   ├── router/         # GoRouter 라우트 정의
│   ├── services/       # Firebase, 알림, 기기 관련 서비스
│   ├── theme/          # 앱 테마
│   └── widgets/        # 공통 UI 위젯
│
└── features/
    ├── auth/
    │   ├── data/       # 원격/로컬 데이터 소스와 DTO
    │   ├── domain/     # 엔티티와 저장소 인터페이스
    │   ├── presentation/ # 화면과 UI 상태
    │   └── di/         # Riverpod 의존성 주입 설정
    ├── journal/
    ├── notifications/
    ├── self_tracking/
    ├── settings/
    ├── home/
    └── shell/
```

주요 기능은 `data`, `domain`, `presentation`, `di` 레이어를 기준으로 나누며, Riverpod provider와 repository를 통해 화면 로직과 데이터 접근을 분리합니다.

## Getting Started
필요한 도구는 Flutter SDK, Dart SDK, Android Studio 또는 Xcode입니다.

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=https://api.example.com
```

`API_BASE_URL`은 백엔드 API 주소를 주입하는 값입니다. 별도로 지정하지 않으면 공개용 기본값인 `https://api.example.com`을 사용합니다.

## Firebase Setup
공개 snapshot에는 실제 Firebase 프로젝트 설정이 포함되어 있지 않습니다. 로컬에서 Firebase 연동을 실행하려면 자신의 Firebase 프로젝트를 만들고 플랫폼별 설정 파일을 추가해야 합니다.

```text
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
```

`lib/firebase_options.dart`는 공개용 더미 설정입니다. 실제 앱 실행 또는 네이티브 빌드가 필요하면 FlutterFire CLI로 본인 프로젝트의 설정 파일을 생성하세요.

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

## Code Generation
Riverpod, JSON 직렬화 등 생성 파일을 갱신해야 할 때 실행합니다.

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Verification
```bash
flutter analyze
flutter test
```

실제 기기 빌드와 Firebase 인증/스토리지 플로우는 본인 Firebase 설정과 API 서버를 연결한 뒤 확인해야 합니다.
