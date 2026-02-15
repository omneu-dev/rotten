import 'package:flutter/material.dart';
import 'refrigerator_screen.dart';
import 'freezer_screen.dart';
// import 'cook_screen.dart'; // 요리 기능은 GNB에서 제거되었습니다.
import 'communication_screen.dart';
import 'home_screen.dart';
import '../widgets/custom_bottom_navigation_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const RefrigeratorScreen(),
    const FreezerScreen(),
    const CommunicationScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      // 요리 탭이 숨겨진 상태: 냉장고(0), 냉동고(1), 소통창구(2)
      // 요리 기능 활성화 시: 냉장고(0), 냉동고(1), 요리(2), 소통창구(3)
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: _screens[_selectedIndex],
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
