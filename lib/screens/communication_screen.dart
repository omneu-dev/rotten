import 'package:flutter/material.dart';
import '../widgets/communication_top_bar.dart';
import '../services/update_request_service.dart';
import '../models/update_request.dart';
import 'update_request_detail_screen.dart';
import 'webview_screen.dart';

class CommunicationScreen extends StatefulWidget {
  const CommunicationScreen({super.key});

  @override
  State<CommunicationScreen> createState() => _CommunicationScreenState();
}

class _CommunicationScreenState extends State<CommunicationScreen> {
  final UpdateRequestService _updateRequestService = UpdateRequestService();

  @override
  void initState() {
    super.initState();
    // Firebase 연결 테스트
    _updateRequestService.testConnection();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Column(
        children: [
          // 상단바
          const CommunicationTopBar(),
          const SizedBox(height: 20),

          // 메인 콘텐츠
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 업데이트 요청 현황 카드
          _buildUpdateRequestCard(),
          const SizedBox(height: 24),

          // 로튼 이야기 섹션
          _buildRottenStorySection(),
        ],
      ),
    );
  }

  Widget _buildUpdateRequestCard() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const UpdateRequestDetailScreen(),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFFEAECF0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 아이콘
              Image.asset('assets/images/request.png', width: 24, height: 24),
              const SizedBox(width: 12),

              // 텍스트
              const Expanded(
                child: Text(
                  '업데이트 요청 현황',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF363A48),
                    height: 32 / 16,
                    letterSpacing: -1,
                  ),
                ),
              ),

              // 화살표 아이콘
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFF686C75),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRottenStorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '로튼 이야기',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF686C75),
            height: 22 / 14,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),

        // Firebase에서 로튼 이야기 데이터 가져오기
        StreamBuilder<List<UpdateRequest>>(
          stream: _updateRequestService.getUpdateRequests(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF363A48)),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 32,
                      color: Color(0xFFBDBDBD),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '로딩 중 오류가 발생했습니다',
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 12,
                        color: Color(0xFFBDBDBD),
                      ),
                    ),
                  ],
                ),
              );
            }

            final allPosts = snapshot.data ?? [];
            print('전체 게시글 수: ${allPosts.length}');
            for (var post in allPosts) {
              print(
                '게시글: ${post.title}, status: ${post.status}, url: ${post.url}',
              );
            }

            // status가 '로튼 이야기'인 문서들만 필터링
            final rottenStories = allPosts
                .where((post) => post.status == '로튼 이야기')
                .toList();
            print('로튼 이야기 개수: ${rottenStories.length}');

            if (rottenStories.isEmpty) {
              return Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.article_outlined,
                      size: 32,
                      color: Color(0xFFBDBDBD),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '아직 로튼 이야기가 없어요',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 12,
                        color: Color(0xFFBDBDBD),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: rottenStories.asMap().entries.map((entry) {
                final index = entry.key;
                final story = entry.value;
                return Column(
                  children: [
                    _buildRottenStoryCard(
                      title: story.title,
                      date: _formatDate(story.createdAt),
                      story: story,
                    ),
                    if (index < rottenStories.length - 1)
                      const SizedBox(height: 12),
                  ],
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '오늘';
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${date.month}/${date.day}';
    }
  }

  Widget _buildRottenStoryCard({
    required String title,
    required String date,
    required UpdateRequest story,
  }) {
    return GestureDetector(
      onTap: () {
        print('로튼 이야기 탭: ${story.title}, URL: ${story.url}');

        if (story.url != null && story.url!.isNotEmpty) {
          try {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    WebViewScreen(title: story.title, url: story.url!),
              ),
            );
          } catch (e) {
            print('WebView 네비게이션 오류: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('페이지를 열 수 없습니다: $e'),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('URL이 설정되지 않은 이야기입니다.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        width: double.infinity,
        height: 82,
        decoration: BoxDecoration(
          color: const Color(0xFFEAECF0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF363A48),
                        height: 32 / 16,
                        letterSpacing: -1,
                      ),
                    ),
                    //const SizedBox(height: 4),
                    Text(
                      date,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF495874),
                        height: 18 / 14,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),

              // 화살표 아이콘
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFF686C75),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
