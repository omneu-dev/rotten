import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../screens/admin_screen.dart';
import '../screens/recipe_admin_screen.dart';
import '../screens/add_food_screen.dart';
import '../services/user_service.dart';

class AddIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF686C75)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // 수평선 (6, 12) to (18, 12)
    canvas.drawLine(
      Offset(size.width * 0.25, size.height * 0.5), // 6/24, 12/24
      Offset(size.width * 0.75, size.height * 0.5), // 18/24, 12/24
      paint,
    );

    // 수직선 (12, 6) to (12, 18)
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.25), // 12/24, 6/24
      Offset(size.width * 0.5, size.height * 0.75), // 12/24, 18/24
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class CommonTopBar extends StatelessWidget {
  final bool isEditMode;
  final Set<String> selectedCards;
  final VoidCallback onEditToggle;
  final VoidCallback onDeleteSelected;
  final bool isEmpty; // 빈 상태 여부
  final String defaultLocation; // '냉장' 또는 '냉동'
  final VoidCallback? onSortTap; // 정렬 버튼 콜백

  const CommonTopBar({
    super.key,
    required this.isEditMode,
    required this.selectedCards,
    required this.onEditToggle,
    required this.onDeleteSelected,
    this.isEmpty = false,
    this.defaultLocation = '냉장',
    this.onSortTap,
  });


  void _navigateToAddFood(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddFoodScreen(defaultLocation: defaultLocation),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: const BoxDecoration(color: Color(0xFFF7F7F7)),
        child: Padding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 10,
            bottom: 6,
          ),
          child: Stack(
            children: [
              // 좌측 버튼들
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Row(
                  children: [
                    // 정리/완료 버튼
                    GestureDetector(
                      onTap: isEmpty ? null : onEditToggle,
                      child: Text(
                        isEditMode ? '완료' : '정리',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 22 / 14,
                          letterSpacing: -0.3,
                          color: isEmpty ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 중앙 로고 (절대 중앙 정렬)
              Center(
                child: Image(
                  image: AssetImage('assets/images/rotten_logo.png'),
                  width: 24,
                  height: 24,
                ),
              ),

              // 우측 버튼들
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Row(
                  children: [
                    if (isEditMode) ...[
                      // 정리 모드: 버리기 버튼
                      GestureDetector(
                        onTap: onDeleteSelected,
                        child: Text(
                          '버리기',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 22 / 14,
                            letterSpacing: -0.3,
                            color: selectedCards.isNotEmpty
                                ? const Color(0xFF814083)
                                : Colors.grey[400],
                          ),
                        ),
                      ),
                    ] else ...[
                      // 일반 모드: 레시피 관리 + 음식 데이터 관리 + 추가 버튼
                      // 개발 모드에서만 표시
                      if (UserService.isDevelopmentMode) ...[
                        // 레시피 관리 버튼
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RecipeAdminScreen(),
                              ),
                            );
                          },
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.purple[600],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.restaurant_menu,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 음식 데이터 관리 버튼
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AdminScreen(),
                              ),
                            );
                          },
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.green[600],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      // 정렬 버튼
                      if (onSortTap != null) ...[
                        Builder(
                          key: const ValueKey('sort_icon'),
                          builder: (context) {
                            return GestureDetector(
                              onTap: () {
                                final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
                                if (renderBox != null && onSortTap != null) {
                                  final position = renderBox.localToGlobal(Offset.zero);
                                  final size = renderBox.size;
                                  // 위치 정보를 콜백에 전달
                                  onSortTap?.call();
                                } else {
                                  onSortTap?.call();
                                }
                              },
                              child: SvgPicture.asset(
                                'assets/images/system-uicons_sort.svg',
                                width: 24,
                                height: 24,
                                colorFilter: const ColorFilter.mode(
                                  Color(0xFF686C75),
                                  BlendMode.srcIn,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                      ],
                      // + 버튼
                      GestureDetector(
                        onTap: () => _navigateToAddFood(context),
                        child: CustomPaint(
                          size: const Size(24, 24),
                          painter: AddIconPainter(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
