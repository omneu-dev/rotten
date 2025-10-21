import 'package:flutter/material.dart';
import '../services/update_request_service.dart';

class CreateUpdateRequestScreen extends StatefulWidget {
  const CreateUpdateRequestScreen({super.key});

  @override
  State<CreateUpdateRequestScreen> createState() =>
      _CreateUpdateRequestScreenState();
}

class _CreateUpdateRequestScreenState extends State<CreateUpdateRequestScreen> {
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
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Column(
        children: [
          // 상단바
          _buildTopBar(),
          const SizedBox(height: 20),

          // 메인 콘텐츠
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 의견 내용 라벨
                  const Text(
                    '의견 내용',
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

                  // 텍스트 입력 필드
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white),
                      ),
                      child: TextField(
                        controller: _contentController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: const InputDecoration(
                          hintText:
                              '불편하신 사항이 있나요? \n더 편안한 서비스로 만들어갈게요!\n\n응원의 한 마디도 좋아요~',
                          hintStyle: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFACB1BA),
                            height: 24 / 16,
                            letterSpacing: -0.4,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(24),
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
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.only(top: 44, left: 16, right: 16, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 취소 버튼
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: const Text(
              '취소',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF686C75),
                height: 22 / 14,
                letterSpacing: -0.3,
              ),
            ),
          ),

          // 제목
          const Text(
            '의견 보내기',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF000000),
              height: 22 / 16,
              letterSpacing: -0.3,
            ),
          ),

          // 저장 버튼
          GestureDetector(
            onTap: _isLoading ? null : _saveRequest,
            child: Text(
              '저장',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _isLoading
                    ? const Color(0xFFBDBDBD)
                    : const Color(0xFF686C75),
                height: 22 / 14,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveRequest() async {
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
      await _updateRequestService.createUpdateRequest(
        title: _contentController.text.trim(),
        content: _contentController.text.trim(),
        category: '요청',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('의견이 성공적으로 전송되었습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
