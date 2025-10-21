# ChatGPT Flutter 앱

Flutter로 만든 ChatGPT 채팅 앱입니다. OpenAI API를 사용하여 ChatGPT와 실시간으로 대화할 수 있습니다.

## 주요 기능

- 🤖 ChatGPT와 실시간 채팅
- 🔐 안전한 API 키 저장 (로컬 저장소)
- 📱 모던하고 직관적인 UI
- ⚙️ 간편한 설정 화면
- 💬 메시지 히스토리 관리

## 시작하기

### 1. 의존성 설치

```bash
flutter pub get
```

### 2. 앱 실행

```bash
flutter run
```

### 3. API 키 설정

1. 앱을 실행한 후 우측 상단의 설정 아이콘을 탭합니다.
2. OpenAI API 키를 입력합니다.
3. "저장" 버튼을 눌러 설정을 완료합니다.

## API 키 얻는 방법

1. [OpenAI 웹사이트](https://openai.com)에 가입하세요.
2. [API 키 페이지](https://platform.openai.com/api-keys)로 이동하세요.
3. "Create new secret key"를 클릭하여 새 API 키를 생성하세요.
4. 생성된 키를 앱의 설정에서 입력하세요.

## 주의사항

- API 키는 안전하게 로컬에 저장되며, 서버로 전송되지 않습니다.
- OpenAI API 사용에는 비용이 발생할 수 있습니다.
- API 키를 다른 사람과 공유하지 마세요.

## 기술 스택

- **Flutter**: 크로스 플랫폼 앱 개발
- **Provider**: 상태 관리
- **HTTP**: API 통신
- **SharedPreferences**: 로컬 데이터 저장

## 프로젝트 구조

```
lib/
├── main.dart              # 앱 진입점
├── models/
│   └── message.dart       # 메시지 모델
├── providers/
│   └── chat_provider.dart # 채팅 상태 관리
├── screens/
│   ├── chat_screen.dart   # 채팅 화면
│   └── settings_screen.dart # 설정 화면
└── services/
    └── chatgpt_service.dart # ChatGPT API 서비스
```

## 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다.
