import 'package:flutter/material.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFFFFFFFF)),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _buildNavItem(index: 0, icon: Icons.kitchen, label: '냉장고'),
              _buildNavItem(index: 1, icon: Icons.ac_unit, label: '냉동고'),
              _buildNavItem(index: 2, icon: Icons.forum, label: '소통 창구'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = selectedIndex == index;
    final color = isSelected
        ? const Color(0xFF1F222D)
        : const Color(0xFFACB1BA);

    return Expanded(
      child: Center(
        child: GestureDetector(
          onTap: () => onTap(index),
          child: Container(
            width: 125,
            height: 56,
            color: Colors.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 24,
                  width: 24,
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w500, // Pretendard Medium
                    height: 20 / 13, // line height 20px / font size 13px
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
