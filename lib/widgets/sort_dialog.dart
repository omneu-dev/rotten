import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/sort_preference_service.dart';

/// 정렬 다이얼로그를 표시하는 함수
void showSortDialog(
  BuildContext context,
  SortType currentSortType,
  Function(SortType) onSortTypeChanged,
) {
  // 우측 상단 위치 계산 (정렬 아이콘 위치)
  final screenWidth = MediaQuery.of(context).size.width;
  final topBarHeight = 0.0; // CommonTopBar 높이
  final rightPadding = 16.0;

  // 정렬 아이콘의 오른쪽 끝 위치
  final iconRight = screenWidth - rightPadding;

  // 다이얼로그 위치 (아이콘 아래, 우측 정렬)
  final dialogWidth = 215.0;
  final dialogLeft = iconRight - dialogWidth;
  final dialogTop =
      MediaQuery.of(context).padding.top + topBarHeight + 4; // 아이콘 아래 4px 간격

  showDialog(
    context: context,
    barrierColor: Colors.transparent, // 배경 어둡게 하지 않음
    builder: (context) => Stack(
      children: [
        // 배경을 클릭하면 닫히도록
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(color: Colors.transparent),
          ),
        ),
        // 다이얼로그
        Positioned(
          left: dialogLeft,
          top: dialogTop,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 215,
              height: 110,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color.fromARGB(236, 245, 245, 245),
                border: Border.all(
                  color: const Color.fromARGB(255, 233, 233, 233),
                ),
                borderRadius: BorderRadius.circular(34),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 추가된 순서 옵션
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () async {
                            await SortPreferenceService.saveSortType(
                              SortType.createdAt,
                            );
                            onSortTypeChanged(SortType.createdAt);
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 0,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 24,
                                  height: 16,
                                  clipBehavior: Clip.antiAlias,
                                  decoration: const BoxDecoration(),
                                  child: currentSortType == SortType.createdAt
                                      ? SvgPicture.asset(
                                          'assets/images/si_check-line.svg',
                                          width: 24,
                                          height: 24,
                                          colorFilter: const ColorFilter.mode(
                                            Color(0xFF686C75),
                                            BlendMode.srcIn,
                                          ),
                                        )
                                      : const SizedBox(),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          '추가된 순서',
                                          style: TextStyle(
                                            color: Color(0xFF686C75),
                                            fontSize: 15,
                                            fontFamily: 'Pretendard',
                                            fontWeight: FontWeight.w500,
                                            height: 1.33,
                                            letterSpacing: -0.43,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // 구분선
                        Container(
                          width: double.infinity,
                          height: 15,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: double.infinity,
                                height: 1,
                                decoration: const BoxDecoration(
                                  color: Color.fromARGB(160, 212, 212, 212),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 남은 보관 기간 옵션
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () async {
                            await SortPreferenceService.saveSortType(
                              SortType.remainingDays,
                            );
                            onSortTypeChanged(SortType.remainingDays);
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 0,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 28,
                                  child:
                                      currentSortType == SortType.remainingDays
                                      ? SvgPicture.asset(
                                          'assets/images/si_check-line.svg',
                                          width: 24,
                                          height: 24,
                                          colorFilter: const ColorFilter.mode(
                                            Color(0xFF686C75),
                                            BlendMode.srcIn,
                                          ),
                                        )
                                      : const SizedBox(width: 24, height: 24),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          '남은 보관 기간',
                                          style: TextStyle(
                                            color: Color(0xFF686C75),
                                            fontSize: 15,
                                            fontFamily: 'Pretendard',
                                            fontWeight: FontWeight.w500,
                                            height: 1.33,
                                            letterSpacing: -0.43,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
