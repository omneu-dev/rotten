import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/communication_detail_top_bar.dart';
import '../models/update_request.dart';
import '../services/update_request_service.dart';

class UpdateRequestDetailScreen extends StatefulWidget {
  const UpdateRequestDetailScreen({super.key});

  @override
  State<UpdateRequestDetailScreen> createState() =>
      _UpdateRequestDetailScreenState();
}

class _UpdateRequestDetailScreenState extends State<UpdateRequestDetailScreen> {
  int _selectedTabIndex = 0;
  final UpdateRequestService _updateRequestService = UpdateRequestService();

  final List<String> _tabs = ['전체', '요청', '진행중', '보류', '해결'];

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
          const CommunicationDetailTopBar(),
          const SizedBox(height: 20),

          // 상단 탭
          _buildTabBar(),
          const SizedBox(height: 32),

          // 메인 콘텐츠
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return SizedBox(
      height: 34,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _tabs.length,
        itemBuilder: (context, index) {
          final tab = _tabs[index];
          final isSelected = index == _selectedTabIndex;

          return Container(
            margin: EdgeInsets.only(right: index < _tabs.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF363A48)
                      : const Color(0xFFEAECF0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tab,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF686C75),
                    height: 22 / 14,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0: // 전체
        return _buildAllContent();
      case 1: // 요청
        return _buildRequestContent();
      case 2: // 진행중
        return _buildInProgressContent();
      case 3: // 보류
        return _buildPendingContent();
      case 4: // 해결
        return _buildResolvedContent();
      default:
        return _buildAllContent();
    }
  }

  Widget _buildAllContent() {
    return _buildPostList();
  }

  Widget _buildRequestContent() {
    return _buildPostList(filterStatus: '요청');
  }

  Widget _buildInProgressContent() {
    return _buildPostList(filterStatus: '진행중');
  }

  Widget _buildPendingContent() {
    return _buildPostList(filterStatus: '보류');
  }

  Widget _buildResolvedContent() {
    return _buildPostList(filterStatus: '해결');
  }

  Widget _buildPostList({String? filterCategory, String? filterStatus}) {
    return StreamBuilder<List<UpdateRequest>>(
      stream: _updateRequestService.getUpdateRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF363A48)),
          );
        }

        if (snapshot.hasError) {
          print('Firebase 오류: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Color(0xFFBDBDBD),
                ),
                const SizedBox(height: 16),
                const Text(
                  '오류가 발생했습니다',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF676C74),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 12,
                    color: Color(0xFFBDBDBD),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      // 상태를 다시 빌드하여 재시도
                    });
                  },
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          );
        }

        final allPosts = snapshot.data ?? [];

        // 필터링 적용
        // 전체 탭에서는 '로튼 이야기'를 제외
        List<UpdateRequest> filteredPosts = (filterStatus == null)
            ? allPosts.where((p) => p.status != '로튼 이야기').toList()
            : allPosts;

        if (filterCategory != null) {
          filteredPosts = filteredPosts
              .where((post) => post.category == filterCategory)
              .toList();
        }
        if (filterStatus != null) {
          filteredPosts = filteredPosts
              .where((post) => post.status == filterStatus)
              .toList();
        }

        if (filteredPosts.isEmpty) {
          String emptyMessage = '게시글이 없습니다.';
          if (filterCategory != null) {
            emptyMessage = '${filterCategory} 게시글이 없습니다.';
          } else if (filterStatus != null) {
            emptyMessage = '${filterStatus} 게시글이 없습니다.';
          }
          return _buildEmptyContent(emptyMessage);
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filteredPosts.length,
          itemBuilder: (context, index) {
            final post = filteredPosts[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildUpdateRequestCard(
                title: post.content,
                date: _formatDate(post.createdAt),
                userNickname: post.userNickname,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyContent(String message) {
    return SizedBox.expand(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/empty.svg',
            width: 28,
            height: 28,
            color: const Color(0xFF686C75),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF686C75),
              height: 22 / 14,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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

  Widget _buildUpdateRequestCard({
    required String title,
    required String date,
    required String userNickname,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFEAECF0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF363A48),
                height: 24 / 16,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  userNickname,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF495874),
                    height: 18 / 14,
                    letterSpacing: -0.2,
                  ),
                ),
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
          ],
        ),
      ),
    );
  }
}
