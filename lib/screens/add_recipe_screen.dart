import 'package:flutter/material.dart';

class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({super.key});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final TextEditingController _linkController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _linkController.dispose();
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
          _buildHeader(),
          Expanded(
            child: GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildLinkInput(),
                    const SizedBox(height: 24),
                    _buildConfirmButton(),
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
    // 링크 입력 화면
    return Container(
      height: 56,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 12),
      child: Row(
        children: [
          // 취소 버튼
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
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
            '요리 추가',
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
          // 저장 버튼 (임시로 닫기만 수행)
          GestureDetector(
            onTap: _isSaving ? null : _onSave,
            child: Text(
              '저장',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _isSaving
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

  Widget _buildLinkInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '레시피 링크',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF686C75),
            letterSpacing: -0.3,
            height: 22 / 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white),
          ),
          child: TextField(
            controller: _linkController,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: '링크를 붙여넣어 주세요',
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

  Future<void> _onSave() async {
    setState(() {
      _isSaving = true;
    });

    // TODO: 실제 저장 로직 (예: Firestore에 링크로 레시피 추가) 연결

    // 임시로 바로 닫기
    if (mounted) {
      Navigator.of(context).pop();
    }

    setState(() {
      _isSaving = false;
    });
  }

  Widget _buildConfirmButton() {
    return GestureDetector(
      onTap: _onConfirmButtonTap,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF363A48),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            '확인',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: -0.4,
            ),
          ),
        ),
      ),
    );
  }

  void _onConfirmButtonTap() {
    // TODO: 추후 레시피 분석/매칭 결과 페이지와 연결 예정
    // 현재는 별도의 결과 화면 없이 링크 입력만 받습니다.
    FocusScope.of(context).unfocus();
  }
}
