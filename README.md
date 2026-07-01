# Psych Coaching Flutter Public Snapshot

심리 코칭 서비스의 Flutter 모바일 앱 공개용 snapshot입니다.

이 repo는 이력서/포트폴리오 검토를 위해 운영 repo에서 history 없이 분리한 공개본입니다. 실제 Firebase 프로젝트 설정, 네이티브 Firebase 설정 파일, 운영 API URL은 포함하지 않습니다.

## Stack

- Flutter
- Riverpod
- GoRouter
- Dio
- Firebase Auth
- Cloud Firestore
- Firebase Storage

## Features

- Google 로그인 기반 인증 흐름
- 사용자 프로필 및 기기 단위 로그인 상태 관리
- 감정/수면 기반 셀프트래킹
- 저널 작성 및 이미지 업로드 흐름
- 알림 목록, 설정, 약관/계정 관리 화면

## Local Development

```sh
flutter pub get
flutter run --dart-define=API_BASE_URL=https://api.example.com
```

`lib/firebase_options.dart`는 공개용 dummy 설정입니다. 실제 앱 실행이나 기기 빌드에는 본인 Firebase 프로젝트로 생성한 다음 파일이 필요합니다.

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

## Verification

```sh
flutter analyze
flutter test
```
