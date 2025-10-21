import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../screens/write_story_screen.dart';

class CommunicationDetailTopBar extends StatelessWidget {
  const CommunicationDetailTopBar({super.key});

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
              // 중앙 텍스트 (절대 중앙 정렬)
              Center(
                child: const Text(
                  '요청 현황',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF363A48),
                    letterSpacing: -0.3,
                    height: 22 / 16,
                  ),
                ),
              ),

              // 좌측 뒤로가기 버튼
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  // 선택 화살표 (표시용)
                  child: Container(
                    width: 32,
                    height: 32,
                    padding: const EdgeInsets.all(4),
                    child: Transform.rotate(
                      angle: 1.5708, // -90도 (라디안)
                      child: SvgPicture.asset(
                        'assets/images/arrow_dropdown.svg',
                        width: 24,
                        height: 24,
                        color: const Color(0xFF686C75),
                      ),
                    ),
                  ),
                ),
              ),

              // 우측 버튼들
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Row(
                  children: [
                    // 글쓰기 버튼
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const WriteStoryScreen(),
                        );
                      },
                      child: SvgPicture.asset(
                        'assets/images/write.svg',
                        width: 24,
                        height: 24,
                        color: const Color(0xFF686C75),
                      ),
                    ),
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
