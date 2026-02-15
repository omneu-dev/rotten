import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'add_recipe_screen.dart';
import 'recipe_detail_screen.dart';
import '../models/recipe.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _HomeTopBar(),
            const SizedBox(height: 32),
            // My 요리 위시리스트 섹션
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _WishlistCategoryHeader(count: 0),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => Container(
                            height: MediaQuery.of(context).size.height * 0.9,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF7F7F7),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                            ),
                            child: RecipeDetailScreen(
                              recipe: Recipe(
                                id: 'dummy',
                                menuName: '임시 레시피',
                                servingNum: 2,
                              ),
                              onBack: () => Navigator.pop(context),
                              onSave: () => Navigator.pop(context),
                            ),
                          ),
                        );
                      },
                      child: const _RecipeWishlistCard(
                        title:
                            '"오니쿡 🍋 on Instagram: \"<닭다리살 배추 우동 🍲> 겨울 내내 이 메뉴는 몇번이나 더 먹을 듯 해요.(벌써 4번 째) 이번엔 우동면 버전으로! 면발이 쫄깃해서 소바랑은 다른 매력이 있어요. 소바랑 우동면 중에 하나를 고르라면... : 못 고르겠음! 🥹  생강은 늘 가루로 쓰다가 요즘은 향을 더 내고 싶어서 3번째 사진 속 냉동 다진생강 큐브 쓰고있어요. 이 제품 편리해서 추천해요(쿠팡)  1. 닭다리살 2덩이는 껍질면이 아래로 향하게 먼저 굽다가 양면을 노릇하게 익힌다(기름이 많이 튀니 뚜껑 덮어 굽기를 추천)  2. 고인 기름은 키친타올로 닦아 제거하고 닭고기를 먹기좋게 썬다. 두툼히 채썬 배추(3장)와 육수를 더해 팔팔 끓인다.  육수 : 물 350, 쯔유 40, 맛술(미림) 40ml와 다진생강 1큰술 *저는 4배 농축 쯔유 사용했어요. 쓰는 쯔유에 따라 비율 조정  3. 육수가 끓어오르면 우동면을 넣고 면이 익으면 마무리한다. 시치미나 고춧가루를 더하면 더욱 맛있다.  #우동 #닭다리살우동 #겨울배추 #우동사리 #오니쿡_알배추 #닭다리살배추우동\""',
                        // 테스트용: 실제 로그의 썸네일 URL로 교체 가능
                        thumbnailUrl:
                            'https://scontent-iad3-2.cdninstagram.com/v/t51.82787-15/582425788_18192665599331814_4722084561622073319_n.jpg?stp=c288.0.864.864a_dst-jpg_e35_s640x640_tt6&_nc_cat=100&ccb=7-5&_nc_sid=18de74&efg=eyJlZmdfdGFnIjoiQ0FST1VTRUxfSVRFTS5iZXN0X2ltYWdlX3VybGdlbi5DMyJ9&_nc_ohc=xqdeXMKu-0MQ7kNvwGgNoHV&_nc_oc=AdmQTdaS7H1-raeqScPj68nnHybLLpEDWsyK2nO_BjCC7R0OcEQ62mkM85jTWiKLrkc&_nc_zt=23&_nc_ht=scontent-iad3-2.cdninstagram.com&_nc_gid=-g91vVuu4N8vf-ej-lW4oQ&oh=00_AftdsvHkGIPxAfn51E0cphq7v-GfScQL4vPnYpgWiZuJjg&oe=6994B6A5',
                        sourceName: 'instagram.com',
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildAddRecipeButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildAddRecipeButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const AddRecipeScreen(),
          );
        },
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF363A48),
            borderRadius: BorderRadius.circular(40),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                '요리 추가',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  letterSpacing: -0.3,
                  height: 22 / 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WishlistCategoryHeader extends StatelessWidget {
  /// 추후 Firestore 연동 시 users/{uid}/recipeLog 문서 개수를 전달받아 표시합니다.
  final int count;

  const _WishlistCategoryHeader({this.count = 0});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 냉장고 화면의 카테고리 아이콘 스타일을 참고하여 cook.svg 사용
        Transform.translate(
          offset: const Offset(0, -2),
          child: SvgPicture.asset(
            'assets/images/cook.svg',
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
              Color(0xFF686C75),
              BlendMode.srcIn,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'My 요리 위시리스트',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 22 / 14,
            letterSpacing: -0.3,
            color: Color(0xFF686C75),
          ),
        ),
        const Spacer(),
        Text(
          '$count',
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 22 / 14,
            letterSpacing: -0.3,
            color: Color(0xFF686C75),
          ),
        ),
      ],
    );
  }
}

/// 홈 화면용 레시피 위시리스트 카드
/// 현재는 정적 예시 값으로 구성되어 있으며,
/// 추후 Firestore의 users/{uid}/recipeLog 데이터를 연동해 교체할 예정입니다.
class _RecipeWishlistCard extends StatelessWidget {
  final String title;
  final String? thumbnailUrl;
  final String sourceName;

  const _RecipeWishlistCard({
    required this.title,
    this.thumbnailUrl,
    required this.sourceName,
  });

  Widget _buildInstagramStyleThumbnail() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: ShapeDecoration(
        color: const Color(0xFF666666),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 좌측: title + sourceName
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: -0.4,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  sourceName,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.7),
                    letterSpacing: -0.3,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          // 우측: 썸네일 이미지 (있을 경우)
          if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty) ...[
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                thumbnailUrl!,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 64,
                  height: 64,
                  color: Colors.white24,
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SNS 링크 썸네일 영역 (인스타그램 스타일)
          _buildInstagramStyleThumbnail(),
          const SizedBox(height: 12),
          // 매칭률 + 재료 아이콘 영역
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 내 재료 매칭률 + 퍼센트
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          '내 재료 매칭률',
                          style: TextStyle(
                            color: Color(0xFF495874),
                            fontSize: 16,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w500,
                            height: 1.63,
                            letterSpacing: -1,
                          ),
                        ),
                        Text(
                          '70%',
                          style: TextStyle(
                            color: Color(0xFF495874),
                            fontSize: 16,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w600,
                            height: 1.63,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      // 대표 재료 아이콘 (이모지)
                      Container(
                        height: 36,
                        padding: const EdgeInsets.all(5.93),
                        decoration: ShapeDecoration(
                          color: const Color(0xFFD04466),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11.87),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            '🍅',
                            style: TextStyle(
                              color: Color(0xFF495874),
                              fontSize: 24,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w500,
                              height: 1.33,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // 추가 재료 개수
                      Container(
                        width: 35.6,
                        height: 35.6,
                        padding: const EdgeInsets.all(5.93),
                        decoration: ShapeDecoration(
                          color: const Color(0xFFDDE3EE),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11.87),
                          ),
                        ),
                        child: const Center(
                          child: Opacity(
                            opacity: 0.6,
                            child: Text(
                              '+ 3',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF495874),
                                fontSize: 14,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w500,
                                height: 1.29,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // 스케줄 영역
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '스케줄',
                      style: TextStyle(
                        color: Color(0xFF495874),
                        fontSize: 16,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                        height: 1.63,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 35.6,
                        height: 35.6,
                        padding: const EdgeInsets.all(5.93),
                        decoration: ShapeDecoration(
                          color: const Color(0xFF1E1E1E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11.87),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            '월',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFF5F5F5),
                              fontSize: 14,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w500,
                              height: 1.29,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 35.6,
                        height: 35.6,
                        padding: const EdgeInsets.all(5.93),
                        decoration: ShapeDecoration(
                          color: const Color(0xFFDDE3EE),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11.87),
                          ),
                        ),
                        child: const Center(
                          child: Opacity(
                            opacity: 0.6,
                            child: Text(
                              '2명',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF495874),
                                fontSize: 14,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w500,
                                height: 1.29,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: const BoxDecoration(color: Color(0xFFF7F7F7)),
      padding: const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 6),
      child: const Center(
        child: Image(
          image: AssetImage('assets/images/rotten_logo.png'),
          width: 24,
          height: 24,
        ),
      ),
    );
  }
}
