import 'package:flutter/material.dart';
import '../services/update_request_service.dart';

class WriteStoryScreen extends StatefulWidget {
  const WriteStoryScreen({super.key});

  @override
  State<WriteStoryScreen> createState() => _WriteStoryScreenState();
}

class _WriteStoryScreenState extends State<WriteStoryScreen> {
  final TextEditingController _contentController = TextEditingController();
  final UpdateRequestService _updateRequestService = UpdateRequestService();
  bool _isLoading = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFFF7F7F7),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Column(
        children: [
          // 헤더
          _buildHeader(),

          // 메인 콘텐츠
          Expanded(
            child: GestureDetector(
              onTap: () {
                // 키보드 포커스 해제
                FocusScope.of(context).unfocus();
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    // 내용 입력
                    _buildContentSection(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 56,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 12),
      child: Row(
        children: [
          // 취소 버튼
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Text(
              '취소',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF686C75),
                letterSpacing: -0.3,
                height: 22 / 14,
              ),
            ),
          ),
          const Spacer(),
          // 제목
          const Text(
            '의견 보내기',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF000000),
              letterSpacing: -0.3,
              height: 22 / 16,
            ),
          ),
          const Spacer(),
          // 저장 버튼
          GestureDetector(
            onTap: _isLoading ? null : _saveStory,
            child: Text(
              '저장',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _isLoading
                    ? const Color(0xFFBDBDBD)
                    : const Color(0xFF686C75),
                letterSpacing: -0.3,
                height: 22 / 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 0),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white),
          ),
          child: TextField(
            controller: _contentController,
            minLines: 5,
            maxLines: null,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(
              hintText: '불편하신 사항이 있나요? \n더 편안한 서비스로 만들어갈게요!\n\n응원의 한 마디도 좋아요~',
              hintStyle: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFFACB1BA),
                height: 24 / 16,
                letterSpacing: -0.4,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(
                top: 18,
                bottom: 18,
                left: 24,
                right: 24,
              ),
            ),
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF363A48),
              height: 24 / 16,
              letterSpacing: -0.4,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveStory() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('의견 내용을 입력해주세요.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _updateRequestService.createUpdateRequest(
        title: '',
        content: _contentController.text.trim(),
        category: '로튼 이야기',
      );

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('의견이 저장되었습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('저장에 실패했습니다. 다시 시도해주세요.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('의견 저장 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류가 발생했습니다: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
