import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/food_data_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final FoodDataService _foodDataService = FoodDataService();
  bool _isLoading = false;
  String _statusMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('관리자 페이지'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '음식 데이터 관리',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // 상태 메시지
            if (_statusMessage.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  _statusMessage,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 업로드 버튼
            ElevatedButton(
              onPressed: _isLoading ? null : _uploadFoodData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('업로드 중...'),
                      ],
                    )
                  : const Text('음식 데이터 업로드', style: TextStyle(fontSize: 16)),
            ),

            const SizedBox(height: 16),

            // 재업로드 버튼
            ElevatedButton(
              onPressed: _isLoading ? null : _reuploadFoodData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                '음식 데이터 재업로드 (기존 데이터 삭제 후)',
                style: TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 16),

            // 조회 버튼
            ElevatedButton(
              onPressed: _isLoading ? null : _checkFoodData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Firestore 데이터 확인',
                style: TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 16),

            // JSON 출력 버튼
            ElevatedButton(
              onPressed: _isLoading ? null : _exportFoodsToJson,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('고추장, oyster_sauce JSON 출력', style: TextStyle(fontSize: 16)),
            ),

            const SizedBox(height: 16),

            // 삭제 버튼
            ElevatedButton(
              onPressed: _isLoading ? null : _clearFoodData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('모든 음식 데이터 삭제', style: TextStyle(fontSize: 16)),
            ),

            const SizedBox(height: 20),

            // 음식 데이터 추가 방법 안내
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '음식 데이터 추가/수정 방법',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '1. assets/seed/food_data_ko_251215.json 파일을 수정\n'
                    '2. 새로운 음식 데이터 추가 또는 기존 데이터 수정\n'
                    '3. "음식 데이터 재업로드" 버튼 클릭 (권장)\n'
                    '4. "Firestore 데이터 확인"으로 결과 확인',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: const Text(
                      '💡 "재업로드"는 기존 데이터를 모두 삭제 후 새로 업로드하므로 데이터 일관성이 보장됩니다.',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 버튼별 기능 설명
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.help_outline,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '버튼 기능 설명',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '🔄 음식 데이터 업로드: 새로운 데이터만 추가 (기존 데이터 유지)\n'
                    '🔄 음식 데이터 재업로드: 기존 데이터 삭제 후 완전히 새로 업로드\n'
                    '📊 Firestore 데이터 확인: 현재 저장된 데이터 개수 및 통계 확인\n'
                    '🗑️ 모든 음식 데이터 삭제: Firestore의 모든 데이터 삭제',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              '주의사항:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• 업로드 전에 Firebase 연결 상태를 확인하세요.\n'
              '• 재업로드는 기존 데이터를 모두 삭제하고 다시 업로드합니다.\n'
              '• 업로드 과정은 몇 분 정도 소요될 수 있습니다.\n'
              '• 음식 이미지 추가 시 assets/images/food_images/ 폴더에 PNG 파일 추가 필요\n'
              '• food.dart 모델 파일은 데이터 구조 정의용이므로 직접 수정하지 마세요.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),

            // 하단 여백 추가 (스크롤 여유 공간)
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // 음식 데이터 업로드
  Future<void> _uploadFoodData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '음식 데이터 업로드를 시작합니다...';
    });

    try {
      final bool success = await _foodDataService.uploadFoodDataToFirestore();

      setState(() {
        _isLoading = false;
        _statusMessage = success
            ? '✅ 음식 데이터 업로드가 완료되었습니다!'
            : '❌ 음식 데이터 업로드에 실패했습니다.';
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('음식 데이터 업로드 완료!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '❌ 업로드 중 오류가 발생했습니다: $e';
      });
    }
  }

  // 음식 데이터 재업로드
  Future<void> _reuploadFoodData() async {
    // 확인 다이얼로그
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('데이터 재업로드'),
        content: const Text('기존 데이터를 모두 삭제하고 새로 업로드하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _statusMessage = '기존 데이터 삭제 및 새 데이터 업로드를 시작합니다...';
    });

    try {
      final bool success = await _foodDataService.reuploadAllFoodData();

      setState(() {
        _isLoading = false;
        _statusMessage = success
            ? '✅ 음식 데이터 재업로드가 완료되었습니다!'
            : '❌ 음식 데이터 재업로드에 실패했습니다.';
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('음식 데이터 재업로드 완료!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '❌ 재업로드 중 오류가 발생했습니다: $e';
      });
    }
  }

  // Firestore 데이터 확인
  Future<void> _checkFoodData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Firestore 데이터를 확인하고 있습니다...';
    });

    try {
      final foods = await _foodDataService.getAllFoodsFromFirestore();

      setState(() {
        _isLoading = false;
        _statusMessage =
            '📊 Firestore에 저장된 음식 데이터: ${foods.length}개\n'
            '카테고리별 개수:\n${_getCategoryCounts(foods)}';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '❌ 데이터 확인 중 오류가 발생했습니다: $e';
      });
    }
  }

  // 음식 데이터 삭제
  Future<void> _clearFoodData() async {
    // 확인 다이얼로그
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('데이터 삭제'),
        content: const Text('모든 음식 데이터를 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _statusMessage = '음식 데이터를 삭제하고 있습니다...';
    });

    try {
      final bool success = await _foodDataService.clearFoodDataCollection();

      setState(() {
        _isLoading = false;
        _statusMessage = success
            ? '✅ 모든 음식 데이터가 삭제되었습니다.'
            : '❌ 음식 데이터 삭제에 실패했습니다.';
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('음식 데이터 삭제 완료!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '❌ 삭제 중 오류가 발생했습니다: $e';
      });
    }
  }

  // 고추장, oyster_sauce JSON 출력
  Future<void> _exportFoodsToJson() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Firestore에서 데이터를 가져오는 중...';
    });

    try {
      final foodDataService = FoodDataService();
      
      // '고추장'과 'oyster_sauce' 조회
      final gochujangJson = await foodDataService.getFoodJsonByName('고추장');
      final oysterSauceJson = await foodDataService.getFoodJsonById('oyster_sauce');

      if (gochujangJson == null && oysterSauceJson == null) {
        setState(() {
          _isLoading = false;
          _statusMessage = '❌ 데이터를 찾을 수 없습니다.';
        });
        return;
      }

      String jsonOutput = '';
      if (gochujangJson != null) {
        jsonOutput += '// 고추장\n$gochujangJson,\n\n';
      }
      if (oysterSauceJson != null) {
        jsonOutput += '// 굴소스 (oyster_sauce)\n$oysterSauceJson,\n';
      }

      // 다이얼로그로 표시
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('JSON 형식'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '아래 내용을 food_data_ko_251215.json 파일의 배열 끝에 추가하세요:',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: SelectableText(
                      jsonOutput,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: jsonOutput));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('JSON이 클립보드에 복사되었습니다'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: const Text('복사'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '❌ JSON 출력 실패: $e';
      });
    }
  }

  // 카테고리별 개수 계산
  String _getCategoryCounts(List foods) {
    final Map<String, int> counts = {};
    for (final food in foods) {
      final category = food.category as String;
      counts[category] = (counts[category] ?? 0) + 1;
    }

    return counts.entries
        .map((entry) => '  ${entry.key}: ${entry.value}개')
        .join('\n');
  }
}
