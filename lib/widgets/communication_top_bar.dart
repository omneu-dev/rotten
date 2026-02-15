import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';
import '../providers/food_log_provider.dart';
import '../widgets/food_card.dart';
import '../screens/write_story_screen.dart';

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
                    // 테스트 알림 버튼들 (개발 모드에서만 표시)
                    if (UserService.isDevelopmentMode) ...[
                      // 음식 알림 테스트 버튼
                      GestureDetector(
                        onTap: () async {
                          try {
                            // Provider에서 냉장고 로그 가져오기
                            final foodLogProvider =
                                Provider.of<FoodLogProvider>(
                                  context,
                                  listen: false,
                                );
                            final refrigeratorLogs =
                                foodLogProvider.refrigeratorLogs;

                            // UserLog를 FoodItem으로 변환
                            final foodItems = refrigeratorLogs.map((log) {
                              int recommendedStorageDays = 7;
                              if (log.expiryDate != null) {
                                recommendedStorageDays = log.expiryDate!
                                    .difference(log.startDate)
                                    .inDays;
                              }

                              String correctedIconPath = log.emojiPath;
                              if (correctedIconPath.isNotEmpty &&
                                  !correctedIconPath.startsWith('assets/')) {
                                correctedIconPath =
                                    'assets/images/food_images/$correctedIconPath';
                              }

                              return FoodItem(
                                id: log.id,
                                name: log.foodName,
                                iconPath: correctedIconPath,
                                startDate: log.startDate,
                                expiryDate:
                                    log.expiryDate ??
                                    log.startDate.add(
                                      Duration(days: recommendedStorageDays),
                                    ),
                                recommendedStorageDays: recommendedStorageDays,
                                storageType: log.storageType,
                              );
                            }).toList();

                            // '곧 상해요, 빨리 드세요' 카테고리 필터링
                            final urgentFoods = foodItems
                                .where(
                                  (item) => item.category == '곧 상해요, 빨리 드세요',
                                )
                                .toList();

                            // 가장 최근 추가된 음식 찾기 (startDate 기준 내림차순 정렬)
                            urgentFoods.sort(
                              (a, b) => b.startDate.compareTo(a.startDate),
                            );

                            String? foodName;
                            if (urgentFoods.isNotEmpty) {
                              foodName = urgentFoods.first.name;
                            }

                            // 5초 후 테스트 알림 전송 (Background 테스트용)
                            NotificationService().showTestNotificationDelayed(
                              foodName: foodName,
                            );

                            if (context.mounted) {
                              final message = foodName != null
                                  ? '5초 후 "$foodName" 알림이 전송됩니다. 앱을 백그라운드로 보내세요!'
                                  : '5초 후 알림이 전송됩니다. (곧 상해요 음식이 없습니다)';

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(message),
                                  duration: const Duration(seconds: 3),
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
                      // 소통 창구 알림 테스트 버튼
                      GestureDetector(
                        onTap: () {
                          try {
                            // 5초 후 소통 창구 알림 테스트 전송
                            NotificationService()
                                .showUpdateRequestTestNotification();

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '5초 후 소통 창구 알림이 전송됩니다. 앱을 백그라운드로 보내세요!',
                                  ),
                                  duration: Duration(seconds: 3),
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
                            color: const Color(0xFF363A48),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],

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
