/**
 * Firebase Cloud Functions for FCM Notifications
 * 
 * 설치 방법:
 * 1. Firebase CLI 설치: npm install -g firebase-tools
 * 2. Firebase 로그인: firebase login
 * 3. 프로젝트 초기화: firebase init functions
 * 4. functions 폴더에 이 파일 복사
 * 5. 배포: firebase deploy --only functions
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * updateRequests 컬렉션의 status 필드가 변경될 때 FCM 알림 발송
 */
exports.onUpdateRequestStatusChange = functions.firestore
  .document('updateRequests/{requestId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const requestId = context.params.requestId;

    // status가 변경되지 않았으면 종료
    if (before.status === after.status) {
      return null;
    }

    // '진행중' 또는 '해결' 상태로 변경된 경우만 알림 발송
    if (after.status !== '진행중' && after.status !== '해결') {
      return null;
    }

    const userId = after.userId || after.authorID; // 구버전 호환성
    if (!userId) {
      console.log('userId가 없어 알림을 발송할 수 없습니다.');
      return null;
    }

    // 사용자의 FCM 토큰 가져오기
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    if (!userDoc.exists) {
      console.log(`사용자 문서를 찾을 수 없습니다: ${userId}`);
      return null;
    }

    const fcmToken = userDoc.data()?.fcmToken;
    if (!fcmToken) {
      console.log(`FCM 토큰을 찾을 수 없습니다: ${userId}`);
      return null;
    }

    // 알림 메시지 구성
    let title = '';
    let body = '';

    if (after.status === '진행중') {
      title = '요청하신 사항이 진행 중이에요!';
      body = '조금만 기다려주세요';
    } else if (after.status === '해결') {
      title = '요청하신 사항이 해결되었어요!';
      body = '적용이 안 된 경우, 앱을 업데이트 해주세요 :)';
    }

    // FCM 메시지 구성
    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        type: 'update_request_status_change',
        requestId: requestId,
        status: after.status,
      },
      token: fcmToken,
      android: {
        priority: 'high',
        notification: {
          channelId: 'update_request_channel',
          sound: 'default',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    try {
      // FCM 발송
      const response = await admin.messaging().send(message);
      console.log(`FCM 알림 발송 성공: ${response} (사용자: ${userId}, 요청: ${requestId})`);
      return null;
    } catch (error) {
      console.error(`FCM 알림 발송 실패: ${error} (사용자: ${userId}, 요청: ${requestId})`);
      return null;
    }
  });

/**
 * notification_requests 컬렉션에 새 문서가 추가될 때 FCM 알림 발송
 * (클라이언트에서 알림 요청을 저장하는 방식)
 */
exports.onNotificationRequest = functions.firestore
  .document('notification_requests/{requestId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();

    // 이미 처리된 요청이면 종료
    if (data.processed) {
      return null;
    }

    // update_request_status_change 타입만 처리
    if (data.type !== 'update_request_status_change') {
      return null;
    }

    const userId = data.userId;
    const status = data.status;

    if (!userId || !status) {
      console.log('필수 필드가 없습니다.');
      return null;
    }

    // 사용자의 FCM 토큰 가져오기
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    if (!userDoc.exists) {
      console.log(`사용자 문서를 찾을 수 없습니다: ${userId}`);
      return null;
    }

    const fcmToken = userDoc.data()?.fcmToken;
    if (!fcmToken) {
      console.log(`FCM 토큰을 찾을 수 없습니다: ${userId}`);
      return null;
    }

    // 알림 메시지 구성
    let title = '';
    let body = '';

    if (status === '진행중') {
      title = '요청하신 사항이 진행 중이에요!';
      body = '조금만 기다려주세요';
    } else if (status === '해결') {
      title = '요청하신 사항이 해결되었어요!';
      body = '적용이 안 된 경우, 앱을 업데이트 해주세요 :)';
    } else {
      // 다른 상태는 알림 발송하지 않음
      return null;
    }

    // FCM 메시지 구성
    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        type: 'update_request_status_change',
        requestId: data.requestId || '',
        status: status,
      },
      token: fcmToken,
      android: {
        priority: 'high',
        notification: {
          channelId: 'update_request_channel',
          sound: 'default',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    try {
      // FCM 발송
      const response = await admin.messaging().send(message);
      console.log(`FCM 알림 발송 성공: ${response} (사용자: ${userId})`);

      // 요청 문서를 처리됨으로 표시
      await snap.ref.update({ processed: true, processedAt: admin.firestore.FieldValue.serverTimestamp() });
      return null;
    } catch (error) {
      console.error(`FCM 알림 발송 실패: ${error} (사용자: ${userId})`);
      return null;
    }
  });


