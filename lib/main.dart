import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/main_screen.dart';
import 'providers/food_log_provider.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // ← 권장 초기화 방식
  );
  await FirebaseAuth.instance.signInAnonymously(); // ← 익명 로그인

  runApp(const MyApp());

  // runApp 이후에 플러그인 초기화 (MissingPluginException 방지)
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      await NotificationService().initialize();
    } catch (e) {
      print('알림 서비스 초기화 실패, 앱은 계속 실행됩니다: $e');
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
