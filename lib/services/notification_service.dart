import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import '../models/user_log.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    try {
      print('알림 서비스 초기화 시작...');

      // Timezone 초기화 (에러 처리 포함)
      try {
        tz.initializeTimeZones();
        final String timeZoneName =
            await FlutterNativeTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        print('타임존 초기화 완료: $timeZoneName');
      } catch (timezoneError) {
        print('타임존 초기화 실패, 기본 타임존 사용: $timezoneError');
        // 기본 타임존 설정
        tz.setLocalLocation(tz.getLocation('UTC'));
      }

      // Android 설정
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS 설정 - 더 명확한 권한 요청
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
            requestCriticalPermission: false,
            defaultPresentAlert: true,
            defaultPresentBadge: true,
            defaultPresentSound: true,
          );

      // 초기화 설정
      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
          );

      // 알림 플러그인 초기화
      final bool? initialized = await _notifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      print('알림 플러그인 초기화 결과: $initialized');

      // 권한 요청
      await _requestPermissions();

      // 권한 상태 확인
      await _checkPermissionStatus();

      print('알림 서비스 초기화 완료');
    } catch (e) {
      print('알림 서비스 초기화 실패: $e');
      // 에러가 발생해도 앱이 계속 실행되도록 rethrow 제거
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

  void _onNotificationTapped(NotificationResponse response) {
    // 알림 탭 시 처리 (필요시 구현)
    print('알림 탭됨: ${response.payload}');
  }

  // 권한 상태 확인
  Future<void> _checkPermissionStatus() async {
    try {
      print('권한 상태 확인 중...');

      // iOS 권한 확인
      final IOSFlutterLocalNotificationsPlugin? iOSImplementation =
          _notifications
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >();

      if (iOSImplementation != null) {
        final NotificationsEnabledOptions? granted = await iOSImplementation
            .checkPermissions();
        print('iOS 알림 권한 상태: $granted');
      }
    } catch (e) {
      print('권한 상태 확인 실패: $e');
    }
  }

  // 음식 카테고리 진입 알림 예약
  Future<void> scheduleCategoryEntryNotification(UserLog userLog) async {
    final int notificationId = _generateNotificationId(
      userLog.id,
      'category_entry',
    );

    // 알림 제목과 내용
    String title = '';
    String body = '';

    if (userLog.category == '곧 상해요, 빨리 드세요' ||
        userLog.category == '오늘 먹어야 해요') {
      title = '음식 보관 상태 알림';
      body = '${userLog.foodName}이(가) ${userLog.category} 카테고리에 진입했습니다.';
    }

    if (title.isNotEmpty) {
      await _scheduleNotification(
        id: notificationId,
        title: title,
        body: body,
        scheduledDate: DateTime.now().add(
          const Duration(seconds: 5),
        ), // 5초 후 알림 (테스트용)
        payload: 'category_entry_${userLog.id}',
      );
    }
  }

  // 버려야 해요 진입 후 3일 경과 알림 예약
  Future<void> scheduleTrashExpiredNotification(UserLog userLog) async {
    final int notificationId = _generateNotificationId(
      userLog.id,
      'trash_expired',
    );

    // 버려야 해요 카테고리에 진입한 날짜 계산
    final DateTime trashEntryDate = userLog.trashEntryDate ?? userLog.startDate;
    final DateTime notificationDate = trashEntryDate.add(
      const Duration(days: 3),
    );

    // 이미 3일이 지났으면 즉시 알림, 아니면 예약
    final DateTime scheduledDate = notificationDate.isBefore(DateTime.now())
        ? DateTime.now().add(const Duration(seconds: 5)) // 테스트용
        : notificationDate;

    await _scheduleNotification(
      id: notificationId,
      title: '음식 폐기 알림',
      body: '${userLog.foodName}이(가) 버려야 해요 카테고리에 진입한 지 3일이 지났습니다.',
      scheduledDate: scheduledDate,
      payload: 'trash_expired_${userLog.id}',
    );
  }

  // 알림 예약
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'food_expiration_channel',
            '음식 보관 알림',
            channelDescription: '음식 보관 상태 및 폐기 알림',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
          );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      // 타임존 안전하게 처리
      tz.TZDateTime scheduledTZDateTime;
      try {
        scheduledTZDateTime = tz.TZDateTime.from(scheduledDate, tz.local);
      } catch (e) {
        print('타임존 변환 실패, 기본 타임존 사용: $e');
        // 기본 타임존으로 재시도
        scheduledTZDateTime = tz.TZDateTime.now(tz.local).add(
          Duration(
            milliseconds:
                scheduledDate.millisecondsSinceEpoch -
                DateTime.now().millisecondsSinceEpoch,
          ),
        );
      }

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledTZDateTime,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );

      print('알림 예약됨: $title - ${scheduledDate.toString()}');
    } catch (e) {
      print('알림 예약 실패: $e');
      // 실패 시 즉시 알림으로 대체
      await _notifications.show(
        id,
        title,
        body,
        const NotificationDetails(),
        payload: payload,
      );
    }
  }

  // 알림 ID 생성
  int _generateNotificationId(String userLogId, String type) {
    final String combined = '${userLogId}_$type';
    return combined.hashCode;
  }

  // 특정 알림 취소
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // 모든 알림 취소
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // 예약된 알림 목록 조회 (디버깅용)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // 테스트 알림 (디버깅용)
  Future<void> showTestNotification() async {
    try {
      print('테스트 알림 전송 시작...');

      // iOS/Android에 맞는 알림 설정
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'test_channel',
            '테스트 알림',
            channelDescription: '앱 테스트용 알림',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            playSound: true,
          );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _notifications.show(
        999,
        '테스트 알림',
        '알림이 정상적으로 작동합니다!',
        platformChannelSpecifics,
        payload: 'test_notification',
      );
      print('테스트 알림 전송 완료');
    } catch (e) {
      print('테스트 알림 전송 실패: $e');

      // 플러그인이 초기화되지 않은 경우 간단한 초기화 시도
      try {
        print('간단한 플러그인 초기화 시도...');

        // 최소한의 설정으로 초기화
        const InitializationSettings initializationSettings =
            InitializationSettings();

        await _notifications.initialize(
          initializationSettings,
          onDidReceiveNotificationResponse: _onNotificationTapped,
        );

        print('간단한 초기화 완료, 알림 재시도...');

        // 재시도
        await _notifications.show(
          1000,
          '테스트 알림 (재시도)',
          '알림이 정상적으로 작동합니다!',
          const NotificationDetails(),
          payload: 'test_notification_retry',
        );
        print('재시도 알림 전송 완료');
      } catch (simpleInitError) {
        print('간단한 초기화 및 재시도 실패: $simpleInitError');
      }
    }
  }

  // 플러그인 상태 확인
  Future<void> checkPluginStatus() async {
    try {
      print('플러그인 상태 확인 중...');

      // 권한 상태 재확인
      await _checkPermissionStatus();

      // 간단한 테스트 알림으로 상태 확인
      await _notifications.show(
        998,
        '상태 확인',
        '플러그인이 정상 작동 중입니다.',
        const NotificationDetails(),
        payload: 'status_check',
      );

      print('플러그인 상태 정상');
    } catch (e) {
      print('플러그인 상태 확인 실패: $e');

      // 상태가 이상하면 재초기화 시도
      try {
        print('플러그인 재초기화 시도...');
        await _reinitializePlugin();
        print('플러그인 재초기화 완료');
      } catch (reinitError) {
        print('플러그인 재초기화 실패: $reinitError');
      }
    }
  }

  // 플러그인 재초기화
  Future<void> _reinitializePlugin() async {
    try {
      // Timezone 초기화 (에러 처리 포함)
      try {
        tz.initializeTimeZones();
        final String timeZoneName =
            await FlutterNativeTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        print('타임존 재초기화 완료');
      } catch (timezoneError) {
        print('타임존 재초기화 실패, 기본 타임존 사용: $timezoneError');
        tz.setLocalLocation(tz.getLocation('UTC'));
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

      // 알림 플러그인 재초기화
      await _notifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // 권한 재요청
      await _requestPermissions();

      print('플러그인 재초기화 성공');
    } catch (e) {
      print('플러그인 재초기화 실패: $e');
      rethrow;
    }
  }
}
