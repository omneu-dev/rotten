import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'user_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initialize() async {
    try {
      print('알림 서비스 초기화 시작...');

      // Timezone 초기화
      try {
        tz.initializeTimeZones();
        final String timeZoneName =
            await FlutterNativeTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        print('타임존 초기화 완료: $timeZoneName');
      } catch (timezoneError) {
        print('타임존 초기화 실패, 기본 타임존 사용: $timezoneError');
        tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
      }

      // Android 설정
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS 설정
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      // 초기화 설정
      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
          );

      // 알림 플러그인 초기화
      await _notifications.initialize(initializationSettings);

      // 권한 요청
      await _requestPermissions();

      // FCM 초기화 및 토큰 저장
      await _initializeFCM();

      print('알림 서비스 초기화 완료');
    } catch (e) {
      print('알림 서비스 초기화 실패: $e');
    }
  }

  Future<void> _requestPermissions() async {
    // Android 13+ 권한 요청
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    // iOS 권한 요청
    final IOSFlutterLocalNotificationsPlugin? iOSImplementation = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    if (iOSImplementation != null) {
      await iOSImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  /// FCM 초기화 및 토큰 관리
  Future<void> _initializeFCM() async {
    try {
      // FCM 권한 요청
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('FCM 권한 승인됨');
      } else {
        print('FCM 권한 거부됨: ${settings.authorizationStatus}');
        return;
      }

      // FCM 토큰 가져오기
      String? token = await _fcm.getToken();
      if (token != null) {
        print('FCM 토큰: $token');
        await _saveFCMToken(token);
      }

      // 토큰 갱신 리스너
      _fcm.onTokenRefresh.listen((newToken) {
        print('FCM 토큰 갱신: $newToken');
        _saveFCMToken(newToken);
      });

      // 포그라운드 메시지 핸들러
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 백그라운드에서 앱이 열릴 때 메시지 핸들러
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // 앱이 종료된 상태에서 알림을 탭하여 열린 경우
      RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }

      print('FCM 초기화 완료');
    } catch (e) {
      print('FCM 초기화 실패: $e');
    }
  }

  /// FCM 토큰을 Firestore에 저장
  Future<void> _saveFCMToken(String token) async {
    try {
      final userService = UserService();
      final userId = await userService.getUserId();

      await _firestore.collection('users').doc(userId).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('FCM 토큰 저장 완료: $userId');
    } catch (e) {
      print('FCM 토큰 저장 실패: $e');
    }
  }

  /// 포그라운드 메시지 핸들러 (앱이 실행 중일 때)
  void _handleForegroundMessage(RemoteMessage message) {
    print('포그라운드 메시지 수신: ${message.messageId}');
    print('제목: ${message.notification?.title}');
    print('내용: ${message.notification?.body}');

    // 로컬 알림으로 표시
    if (message.notification != null) {
      _showLocalNotificationFromFCM(message);
    }
  }

  /// 메시지 탭 핸들러 (알림을 탭하여 앱이 열릴 때)
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('알림 탭으로 앱 열림: ${message.messageId}');
    // 필요시 특정 화면으로 이동하는 로직 추가 가능
  }

  /// FCM 메시지를 로컬 알림으로 표시
  Future<void> _showLocalNotificationFromFCM(RemoteMessage message) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'update_request_channel',
            '소통 창구 알림',
            channelDescription: '소통 창구 요청 상태 변경 알림',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/ic_stat_ic_notification',
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        message.hashCode,
        message.notification?.title ?? '알림',
        message.notification?.body ?? '',
        notificationDetails,
      );
    } catch (e) {
      print('로컬 알림 표시 실패: $e');
    }
  }

  // ============================================
  // 1️⃣ 음식 알림 발송 관련 메서드들
  // ============================================

  /// [테스트용] 5초 후 테스트 알림 발송
  ///
  /// 목적: 개발자가 알림 기능을 테스트하기 위한 메서드
  /// 사용 위치: communication_top_bar.dart (개발 모드에서만 사용)
  /// 동작: 5초 후 "알림이 정상적으로 작동합니다!" 메시지 발송
  void showTestNotificationDelayed({String? foodName}) {
    final String title = foodName ?? '테스트 알림';
    print('5초 후 테스트 알림 예약... (제목: $title)');

    // 비동기로 실행 (메서드는 즉시 반환)
    Future.delayed(const Duration(seconds: 5)).then((_) async {
      try {
        const AndroidNotificationDetails androidDetails =
            AndroidNotificationDetails(
              'test_channel',
              '테스트 알림',
              channelDescription: '테스트용 알림 채널',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@drawable/ic_stat_ic_notification',
            );

        const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

        const NotificationDetails notificationDetails = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        await _notifications.show(
          0,
          title,
          '알림이 정상적으로 작동합니다!',
          notificationDetails,
        );

        print('지연 테스트 알림 전송 완료 (제목: $title)');
      } catch (e) {
        print('지연 테스트 알림 전송 실패: $e');
      }
    });
  }

  /// 알림 ID 생성 (내부 헬퍼 메서드)
  ///
  /// 목적: 음식명과 카테고리를 조합하여 고유한 알림 ID 생성
  /// 사용 위치: scheduleFoodNotifications, cancelFoodNotifications 내부에서 사용
  int _generateNotificationId(String foodName, String category) {
    // 음식명 + 카테고리를 조합하여 고유 ID 생성
    final String combined = '${foodName}_$category';
    return combined.hashCode;
  }

  /// 음식의 예약 알림 설정 (권장폐기일 기반)
  ///
  /// 목적: 음식이 추가되거나 권장폐기일이 수정될 때, 미래에 알림을 예약하는 메서드
  /// 사용 위치: food_log_provider.dart (음식 추가/수정 시, D-3일 이상인 경우)
  ///
  /// 동작 방식:
  /// - D-2일: "곧 상해요, 빨리 드세요" 알림 예약 (오전 9시)
  /// - D-day: "오늘 먹어야 해요" 알림 예약 (오전 9시)
  /// - D+3일: "3일째 상해가는 중" 알림 예약 (오전 9시)
  /// - D+31일: "한 달째 상해가는 중" 알림 예약 (오전 9시)
  ///
  /// 참고: D-0일, D-1일, D-2일은 이미 위험 상태이므로 즉시 알림을 보냅니다.
  ///       이 메서드는 D-3일 이상인 경우에만 사용됩니다.
  Future<void> scheduleFoodNotifications({
    required String foodName,
    required DateTime expiryDate,
  }) async {
    try {
      print('알림 예약 시작: $foodName, 권장폐기일: $expiryDate');

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final expiry = DateTime(
        expiryDate.year,
        expiryDate.month,
        expiryDate.day,
      );
      final daysUntilExpiry = expiry.difference(today).inDays;

      print('$foodName의 남은 일수: $daysUntilExpiry일');

      // '곧 상해요, 빨리 드세요' 알림 (D-2일 오전 9시)
      // D-1일, D-0일은 즉시 알림으로 처리되므로 예약하지 않음
      if (daysUntilExpiry >= 2) {
        // D-2일 오전 9시에 알림
        final urgentDate = expiry.subtract(const Duration(days: 2));
        final urgentDateTime = DateTime(
          urgentDate.year,
          urgentDate.month,
          urgentDate.day,
          9,
          0,
        );

        if (urgentDateTime.isAfter(now)) {
          await _scheduleNotification(
            id: _generateNotificationId(foodName, 'urgent'),
            title: foodName,
            body: '곧 상해요, 빨리 드세요',
            scheduledDate: urgentDateTime,
          );
          print('예약 완료: $foodName - 곧 상해요 알림 ($urgentDateTime)');
        }
      }

      // '오늘 먹어야 해요' 알림 (D-day 오전 9시)
      // D-0일은 즉시 알림으로 처리되므로 D-1일 이상만 예약
      if (daysUntilExpiry >= 1) {
        final todayEatDate = expiry;
        final todayEatDateTime = DateTime(
          todayEatDate.year,
          todayEatDate.month,
          todayEatDate.day,
          9,
          0,
        );

        if (todayEatDateTime.isAfter(now)) {
          await _scheduleNotification(
            id: _generateNotificationId(foodName, 'today'),
            title: foodName,
            body: '오늘 먹어야 해요',
            scheduledDate: todayEatDateTime,
          );
          print('예약 완료: $foodName - 오늘 먹어야 해요 알림 ($todayEatDateTime)');
        }
      }

      // D+3일 알림 (권장폐기일 3일 후 오전 9시)
      final d3Date = expiry.add(const Duration(days: 3));
      final d3DateTime = DateTime(d3Date.year, d3Date.month, d3Date.day, 9, 0);

      if (d3DateTime.isAfter(now)) {
        await _scheduleNotification(
          id: _generateNotificationId(foodName, 'd+3'),
          title: foodName,
          body: '3 일째 상해가는 중..! 버려야 해요..!!',
          scheduledDate: d3DateTime,
        );
        print('예약 완료: $foodName - D+3 알림 ($d3DateTime)');
      }

      // D+31일 알림 (권장폐기일 31일 후 오전 9시)
      final d31Date = expiry.add(const Duration(days: 31));
      final d31DateTime = DateTime(
        d31Date.year,
        d31Date.month,
        d31Date.day,
        9,
        0,
      );

      if (d31DateTime.isAfter(now)) {
        await _scheduleNotification(
          id: _generateNotificationId(foodName, 'd+31'),
          title: foodName,
          body: '한 달째 상해가는 중..! 버려야 해요..!!!',
          scheduledDate: d31DateTime,
        );
        print('예약 완료: $foodName - D+31 알림 ($d31DateTime)');
      }

      print('알림 예약 완료: $foodName');
    } catch (e) {
      print('알림 예약 실패: $e');
    }
  }

  /// 알림 예약 실행 (내부 헬퍼 메서드)
  ///
  /// 목적: scheduleFoodNotifications에서 호출하여 실제로 알림을 예약하는 메서드
  /// 차이점:
  ///   - scheduleFoodNotifications: 어떤 알림을 언제 보낼지 결정 (비즈니스 로직)
  ///   - _scheduleNotification: 실제로 시스템에 알림 예약 요청 (기술적 실행)
  ///
  /// 예시: scheduleFoodNotifications가 "D-2일 오전 9시에 알림 보내"라고 결정하면,
  ///       이 메서드가 실제로 시스템에 "2024년 1월 15일 오전 9시에 알림 보내"라고 등록합니다.
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'food_expiry_channel',
            '음식 보관 알림',
            channelDescription: '음식 보관 상태 알림',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/ic_stat_ic_notification',
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final tz.TZDateTime scheduledTZDateTime = tz.TZDateTime.from(
        scheduledDate,
        tz.local,
      );

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledTZDateTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      print('알림 예약 실패: $e');
    }
  }

  /// 특정 음식의 모든 예약된 알림 취소
  ///
  /// 목적: 음식이 삭제되거나 권장폐기일이 수정될 때, 기존에 예약된 알림들을 모두 취소
  /// 사용 위치: food_log_provider.dart (음식 삭제/수정 시)
  ///
  /// 취소하는 알림:
  /// - "곧 상해요, 빨리 드세요" 알림
  /// - "오늘 먹어야 해요" 알림
  /// - "3일째 상해가는 중" 알림
  /// - "한 달째 상해가는 중" 알림
  Future<void> cancelFoodNotifications(String foodName) async {
    try {
      // '곧 상해요, 빨리 드세요' 알림 취소
      await _notifications.cancel(_generateNotificationId(foodName, 'urgent'));
      // '오늘 먹어야 해요' 알림 취소
      await _notifications.cancel(_generateNotificationId(foodName, 'today'));
      // 'D+3' 알림 취소
      await _notifications.cancel(_generateNotificationId(foodName, 'd+3'));
      // 'D+31' 알림 취소
      await _notifications.cancel(_generateNotificationId(foodName, 'd+31'));
      print('알림 취소 완료: $foodName');
    } catch (e) {
      print('알림 취소 실패: $e');
    }
  }

  /// 5초 후 즉시 알림 발송 (위험 상태 음식 추가/수정 시 사용)
  ///
  /// 목적: 음식이 추가되거나 권장폐기일이 수정되어 D-0일, D-1일, D-2일 상태가 되었을 때,
  ///       5초 후에 즉시 알림을 보내는 메서드
  /// 사용 위치: food_log_provider.dart (음식 추가/수정 시, D-0~D-2일인 경우)
  ///
  /// 왜 5초 후인가?
  /// - 앱을 백그라운드로 보낸 상태에서도 알림이 작동하는지 테스트하기 위함
  /// - 사용자가 앱을 닫아도 알림이 정상적으로 발송되는지 확인
  ///
  /// 차이점:
  /// - scheduleFoodNotifications: 미래의 특정 날짜/시간에 알림 예약 (예: 3일 후 오전 9시)
  /// - showCategoryNotificationDelayed: 지금부터 5초 후에 알림 발송 (즉시 알림)
  void showCategoryNotificationDelayed({
    required String foodName,
    required String category,
  }) {
    print('5초 후 즉시 알림 예약: $foodName - $category');

    // 비동기로 실행 (메서드는 즉시 반환)
    Future.delayed(const Duration(seconds: 5)).then((_) async {
      try {
        // 알림 내용: 카테고리명
        final String body = category;

        const AndroidNotificationDetails androidDetails =
            AndroidNotificationDetails(
              'food_expiry_channel',
              '음식 보관 알림',
              channelDescription: '음식 보관 상태 알림',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@drawable/ic_stat_ic_notification',
            );

        const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

        const NotificationDetails notificationDetails = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        await _notifications.show(
          foodName.hashCode + 5000, // 즉시 알림 전용 ID
          foodName,
          body,
          notificationDetails,
        );

        print('즉시 알림 전송 완료: $foodName - $category');
      } catch (e) {
        print('즉시 알림 전송 실패: $e');
      }
    });
  }

  // ============================================
  // 2️⃣ 소통 창구 알림 관련 메서드들
  // ============================================

  /// 소통 창구 요청 상태 변경 알림 발송 (5초 후)
  ///
  /// 목적: 요청 게시글의 status가 변경되었을 때 5초 후에 알림을 발송
  /// 사용 위치: update_request_service.dart (상태 변경 시)
  ///
  /// 동작: status가 변경되면 5초 후에 "요청 상태가 변경되었습니다" 알림 발송
  void showUpdateRequestStatusChangeNotification({required String status}) {
    print('5초 후 소통 창구 상태 변경 알림 예약: $status');

    // 비동기로 실행 (메서드는 즉시 반환)
    Future.delayed(const Duration(seconds: 5)).then((_) async {
      try {
        String title;
        String body;

        if (status == '진행중') {
          title = '요청하신 사항이 진행 중이에요!';
          body = '조금만 기다려주세요';
        } else if (status == '해결') {
          title = '요청하신 사항이 해결되었어요!';
          body = '적용이 안 된 경우, 앱을 업데이트 해주세요 :)';
        } else {
          // 다른 상태는 기본 메시지
          title = '요청 상태가 변경되었습니다';
          body = '상태: $status';
        }

        const AndroidNotificationDetails androidDetails =
            AndroidNotificationDetails(
              'update_request_channel',
              '소통 창구 알림',
              channelDescription: '소통 창구 요청 상태 변경 알림',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@drawable/ic_stat_ic_notification',
            );

        const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

        const NotificationDetails notificationDetails = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        // 요청 ID를 해시하여 고유 ID 생성
        final notificationId = 'update_request_status_$status'.hashCode;

        await _notifications.show(
          notificationId,
          title,
          body,
          notificationDetails,
        );

        print('소통 창구 상태 변경 알림 전송 완료: $status');
      } catch (e) {
        print('소통 창구 상태 변경 알림 전송 실패: $e');
      }
    });
  }

  /// [테스트용] 소통 창구 알림 테스트 (5초 후)
  ///
  /// 목적: 개발자가 소통 창구 알림 기능을 테스트하기 위한 메서드
  /// 사용 위치: communication_top_bar.dart (개발 모드에서만 사용)
  /// 동작: 5초 후 현재 유저의 최근 요청 문서의 content를 알림 내용으로 발송
  void showUpdateRequestTestNotification() {
    print('5초 후 소통 창구 알림 테스트 예약');

    // 비동기로 실행 (메서드는 즉시 반환)
    Future.delayed(const Duration(seconds: 5)).then((_) async {
      try {
        // 현재 유저 ID 가져오기
        final userService = UserService();
        final currentUserId = await userService.getUserId();

        // Firestore에서 현재 유저의 최근 요청 문서 가져오기
        // 인덱스 없이 작동하도록 where만 사용하고 메모리에서 정렬
        final firestore = FirebaseFirestore.instance;
        final querySnapshot = await firestore
            .collection('updateRequests')
            .where('userId', isEqualTo: currentUserId)
            .get();

        String notificationTitle = '소통 창구 알림 테스트';
        String notificationBody;

        if (querySnapshot.docs.isNotEmpty) {
          // createdAt 기준으로 정렬하여 가장 최근 문서 선택
          final sortedDocs = querySnapshot.docs.toList()
            ..sort((a, b) {
              final aCreatedAt = a.data()['createdAt'] as Timestamp?;
              final bCreatedAt = b.data()['createdAt'] as Timestamp?;
              if (aCreatedAt == null && bCreatedAt == null) return 0;
              if (aCreatedAt == null) return 1;
              if (bCreatedAt == null) return -1;
              return bCreatedAt.compareTo(aCreatedAt); // 내림차순
            });

          final doc = sortedDocs.first;
          final data = doc.data();
          final content = data['content'] as String? ?? '';

          if (content.isNotEmpty) {
            notificationBody = content;
            print('최근 요청 문서의 content 사용: $content');
          } else {
            notificationBody = '최근 요청 문서의 content가 비어있습니다.';
            print('최근 요청 문서의 content가 비어있음');
          }
        } else {
          notificationBody = '현재 유저의 요청 문서를 찾을 수 없습니다.';
          print('현재 유저의 요청 문서를 찾을 수 없음');
        }

        const AndroidNotificationDetails androidDetails =
            AndroidNotificationDetails(
              'update_request_channel',
              '소통 창구 알림',
              channelDescription: '소통 창구 요청 상태 변경 알림',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@drawable/ic_stat_ic_notification',
            );

        const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

        const NotificationDetails notificationDetails = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        await _notifications.show(
          9999, // 테스트 알림 전용 ID
          notificationTitle,
          notificationBody,
          notificationDetails,
        );

        print('소통 창구 알림 테스트 전송 완료');
      } catch (e) {
        print('소통 창구 알림 테스트 전송 실패: $e');
      }
    });
  }
}
