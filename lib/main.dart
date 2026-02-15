import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/main_screen.dart';
import 'providers/food_log_provider.dart';
import 'services/notification_service.dart';
import 'services/user_service.dart';
import 'services/update_request_service.dart';

// 백그라운드 메시지 핸들러 (top-level 함수로 선언해야 함)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('백그라운드 메시지 수신: ${message.messageId}');
  print('제목: ${message.notification?.title}');
  print('내용: ${message.notification?.body}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // ← 권장 초기화 방식
  );

  // UserService 초기화 (디바이스 UID 생성 또는 복원)
  await UserService().initialize();

  // 백그라운드 메시지 핸들러 등록 (앱이 완전히 종료된 상태에서도 작동)
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const MyApp());

  // runApp 이후에 플러그인 초기화 (MissingPluginException 방지)
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      await NotificationService().initialize();

      // 소통 창구 상태 변경 리스너 시작 (앱 전체에서 상태 변경 감지)
      await UpdateRequestService().startStatusChangeListener();
    } catch (e) {
      print('서비스 초기화 실패, 앱은 계속 실행됩니다: $e');
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => FoodLogProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Rotten',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          fontFamily: 'Pretendard',
        ),
        home: const MainScreen(),
      ),
    );
  }
}
