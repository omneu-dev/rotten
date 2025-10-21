import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/notification_service.dart';

class CommunicationTopBar extends StatelessWidget {
  const CommunicationTopBar({super.key});

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
              // 중앙 로고 (절대 중앙 정렬)
              Center(
                child: Image.asset(
                  'assets/images/rotten_logo.png',
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
                    // 테스트 알림 버튼
                    GestureDetector(
                      onTap: () async {
                        try {
                          // 먼저 플러그인 상태 확인
                          await NotificationService().checkPluginStatus();

                          // 테스트 알림 전송
                          await NotificationService().showTestNotification();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('테스트 알림이 전송되었습니다.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('알림 전송 실패: $e'),
                                duration: const Duration(seconds: 2),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFF814083),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.notifications,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // 글쓰기 버튼
                    GestureDetector(
                      onTap: () {
                        // TODO: 글쓰기 기능 구현
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('글쓰기 기능이 준비 중입니다.'),
                            duration: Duration(seconds: 2),
                          ),
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
