import 'package:flutter/material.dart';
import 'refrigerator_screen.dart';
import 'freezer_screen.dart';
import 'communication_screen.dart';
import '../widgets/custom_bottom_navigation_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const RefrigeratorScreen(),
    const FreezerScreen(),
    const CommunicationScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
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
