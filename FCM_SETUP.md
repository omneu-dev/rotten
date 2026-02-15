# FCM (Firebase Cloud Messaging) 설정 가이드

## 개요
앱이 완전히 종료된 상태에서도 소통 창구 요청 상태 변경 알림을 받을 수 있도록 FCM을 구현했습니다.

## 구현 내용

### 1. 클라이언트 (Flutter 앱)
- ✅ FCM 토큰 자동 수집 및 Firestore 저장 (`users/{userId}/fcmToken`)
- ✅ 포그라운드 메시지 수신 처리
- ✅ 백그라운드 메시지 수신 처리
- ✅ 알림 탭 시 앱 열기 처리
- ✅ 상태 변경 시 Cloud Functions에 알림 요청 저장

### 2. 서버 (Cloud Functions)
- ✅ `updateRequests` 컬렉션의 `status` 변경 감지
- ✅ `notification_requests` 컬렉션의 새 문서 생성 감지
- ✅ 사용자 FCM 토큰 조회 및 알림 발송

## Cloud Functions 배포 방법

### 1. Firebase CLI 설치
```bash
npm install -g firebase-tools
```

### 2. Firebase 로그인
```bash
firebase login
```

### 3. 프로젝트 초기화 (처음 한 번만)
```bash
cd /Users/hyejuyang/rotten
firebase init functions
```
- 기존 functions 폴더를 덮어쓸지 물어보면 **N** 선택
- 언어는 **JavaScript** 선택
- ESLint는 선택 사항

### 4. Functions 폴더 설정
이미 `functions/index.js`와 `functions/package.json` 파일이 생성되어 있습니다.

### 5. 의존성 설치
```bash
cd functions
npm install
```

### 6. 배포
```bash
cd ..
firebase deploy --only functions
```

## 동작 방식

### 시나리오 1: 관리자가 상태 변경
1. 관리자가 `updateRequestStatus()` 호출하여 상태 변경
2. `_requestFCMNotification()` 메서드가 `notification_requests` 컬렉션에 문서 생성
3. Cloud Functions의 `onNotificationRequest` 트리거 실행
4. 사용자의 FCM 토큰 조회 및 알림 발송
5. 사용자 디바이스에서 알림 수신 (앱이 종료되어 있어도 작동)

### 시나리오 2: Firestore에서 직접 상태 변경
1. Firestore 콘솔에서 `updateRequests` 문서의 `status` 필드 직접 수정
2. Cloud Functions의 `onUpdateRequestStatusChange` 트리거 실행
3. 사용자의 FCM 토큰 조회 및 알림 발송

## 알림 메시지

### 상태: '진행중'
- **제목**: "요청하신 사항이 진행 중이에요!"
- **내용**: "조금만 기다려주세요"

### 상태: '해결'
- **제목**: "요청하신 사항이 해결되었어요!"
- **내용**: "적용이 안 된 경우, 앱을 업데이트 해주세요 :)"

## 테스트 방법

### 1. FCM 토큰 확인
앱 실행 후 콘솔 로그에서 다음 메시지 확인:
```
FCM 토큰: [토큰 문자열]
FCM 토큰 저장 완료: [userId]
```

### 2. Firestore 확인
`users/{userId}` 문서에 `fcmToken` 필드가 저장되어 있는지 확인

### 3. 알림 테스트
1. 일반 유저로 요청 작성
2. 관리자로 상태를 '진행중' 또는 '해결'로 변경
3. 일반 유저 디바이스에서 알림 수신 확인 (앱 종료 상태에서도 작동)

## 문제 해결

### FCM 토큰이 저장되지 않는 경우
- 앱 권한 설정 확인 (Android: 알림 권한, iOS: 알림 권한)
- Firebase 프로젝트 설정 확인
- 콘솔 로그에서 에러 메시지 확인

### Cloud Functions가 작동하지 않는 경우
- Firebase 콘솔 > Functions에서 배포 상태 확인
- Functions 로그 확인: `firebase functions:log`
- `notification_requests` 컬렉션에 문서가 생성되는지 확인

### 알림이 수신되지 않는 경우
1. FCM 토큰이 Firestore에 저장되어 있는지 확인
2. Cloud Functions 로그 확인
3. 디바이스의 알림 설정 확인
4. 앱이 완전히 종료된 상태에서 테스트

## 참고 사항

- **로컬 알림**: 앱이 실행 중일 때는 로컬 알림도 함께 발송됩니다 (5초 지연)
- **FCM 알림**: 앱이 종료되어 있어도 작동합니다
- **중복 방지**: 같은 상태 변경에 대해 중복 알림이 발송되지 않도록 `_previousStatusMap`으로 관리합니다


