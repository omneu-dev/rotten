import 'package:flutter/material.dart';
import '../services/recipe_data_service.dart';
import 'ingredient_match_detail_screen.dart';

class RecipeAdminScreen extends StatefulWidget {
  const RecipeAdminScreen({super.key});

  @override
  State<RecipeAdminScreen> createState() => _RecipeAdminScreenState();
}

class _RecipeAdminScreenState extends State<RecipeAdminScreen> {
  final RecipeDataService _recipeService = RecipeDataService();
  bool _isLoading = false;
  String _statusMessage = '';
  RecipeDryRunResult? _recipeDryRunResult;
  IngredientDryRunResult? _ingredientDryRunResult;
  IngredientMatchDryRunResult? _ingredientMatchDryRunResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('레시피 관리 페이지'),
        backgroundColor: Colors.purple[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '레시피 데이터 관리',
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

            // Dry-run 결과 표시
            if (_recipeDryRunResult != null) ...[
              _buildDryRunResult('레시피', _recipeDryRunResult!),
              const SizedBox(height: 16),
            ],
            if (_ingredientDryRunResult != null) ...[
              _buildIngredientDryRunResult('재료', _ingredientDryRunResult!),
              const SizedBox(height: 16),
            ],
            if (_ingredientMatchDryRunResult != null) ...[
              _buildIngredientMatchDryRunResult(_ingredientMatchDryRunResult!),
              const SizedBox(height: 16),
            ],

            // Dry-run 버튼
            ElevatedButton(
              onPressed: _isLoading ? null : _runDryRun,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                '레시피 데이터 미리보기 (Dry-run)',
                style: TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 16),

            // 레시피 업로드 버튼
            ElevatedButton(
              onPressed: _isLoading ? null : _uploadRecipes,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[600],
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
                  : const Text(
                      '📤 레시피 업로드 (Upsert)',
                      style: TextStyle(fontSize: 16),
                    ),
            ),

            const SizedBox(height: 16),

            // 재료 업로드 버튼
            ElevatedButton(
              onPressed: _isLoading ? null : _uploadIngredients,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                '📤 재료 업로드 (Replace)',
                style: TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 16),

            // 재료 매칭 미리보기 버튼
            ElevatedButton(
              onPressed: _isLoading ? null : _runIngredientMatchDryRun,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                '재료 매칭 미리보기 (Dry-run)',
                style: TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 16),

            // 재료 매칭 적용 버튼
            ElevatedButton(
              onPressed: _isLoading ? null : _commitIngredientMatch,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                '재료 매칭 적용 (Commit)',
                style: TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 20),

            // 안내 사항
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
                        '레시피 데이터 관리 방법',
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
                    '1. assets/seed/recipes.tsv 파일을 수정\n'
                    '2. assets/seed/recipe_ingredients.tsv 파일을 수정\n'
                    '3. "미리보기 (Dry-run)" 버튼으로 변경사항 확인\n'
                    '4. "레시피 업로드" 또는 "재료 업로드" 버튼 클릭',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 버튼 기능 설명
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
                    '📊 레시피 데이터 미리보기: 업로드 전 변경사항 미리 확인\n'
                    '📤 레시피 업로드: recipe_id 기준 Upsert (있으면 업데이트, 없으면 추가)\n'
                    '📤 재료 업로드: 기존 subcollection 삭제 후 재삽입\n'
                    '🔍 재료 매칭 미리보기: rawItemName을 foodData와 매칭하는 결과 미리 확인\n'
                    '✅ 재료 매칭 적용: rawItemName을 foodData와 매칭하여 foodRef 업데이트',
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
              '• 레시피 업로드는 Upsert 방식으로 기존 데이터를 보존합니다.\n'
              '• 재료 업로드는 기존 subcollection을 삭제하고 새로 삽입합니다.\n'
              '• 업로드 과정은 몇 분 정도 소요될 수 있습니다.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),

            // 하단 여백
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDryRunResult(String title, RecipeDryRunResult result) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 $title 미리보기 결과',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green[800],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '총 레시피: ${result.totalRecipes}개\n'
            '신규 추가: ${result.newRecipes}개\n'
            '업데이트: ${result.updatedRecipes}개\n'
            '중복 메뉴명: ${result.duplicateMenuNames}개',
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientDryRunResult(
    String title,
    IngredientDryRunResult result,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 $title 미리보기 결과',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.orange[800],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '총 재료: ${result.totalIngredients}개\n'
            '레시피 수: ${result.recipeCount}개',
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientMatchDryRunResult(IngredientMatchDryRunResult result) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔍 재료 매칭 미리보기 결과',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.teal[800],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '전체 재료 수: ${result.totalIngredients}개\n'
            '매칭 성공: ${result.matchedCount}개\n'
            '매칭 비율: ${result.matchRate.toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      IngredientMatchDetailScreen(result: result),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.teal[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.teal[300]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '상세 보기',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[800],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 16, color: Colors.teal[800]),
                ],
              ),
            ),
          ),
          if (result.unmatchedTopN.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              '미매칭 TOP 10:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            ...result.unmatchedTopN
                .take(10)
                .map(
                  (name) => Padding(
                    padding: const EdgeInsets.only(left: 8, top: 2),
                    child: Text(
                      '• $name',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
          ],
          if (result.potentialMatches.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '규칙 추가 시 매칭 가능 (${result.potentialMatches.length}개):',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.orange[800],
              ),
            ),
            const SizedBox(height: 4),
            ...result.potentialMatches
                .take(5)
                .map(
                  (name) => Padding(
                    padding: const EdgeInsets.only(left: 8, top: 2),
                    child: Text(
                      '• $name',
                      style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  // Dry-run 실행
  Future<void> _runDryRun() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '미리보기를 실행하고 있습니다...';
      _recipeDryRunResult = null;
      _ingredientDryRunResult = null;
      _ingredientMatchDryRunResult = null;
    });

    try {
      final recipeResult = await _recipeService.dryRunRecipes();
      final ingredientResult = await _recipeService.dryRunIngredients();

      setState(() {
        _isLoading = false;
        _statusMessage = '✅ 미리보기 완료!';
        _recipeDryRunResult = recipeResult;
        _ingredientDryRunResult = ingredientResult;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '❌ 미리보기 중 오류가 발생했습니다: $e';
      });
    }
  }

  // 레시피 업로드
  Future<void> _uploadRecipes() async {
    // 확인 다이얼로그
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('레시피 업로드'),
        content: const Text(
          '레시피 데이터를 업로드하시겠습니까?\n'
          '(recipe_id 기준으로 Upsert: 있으면 업데이트, 없으면 추가)',
        ),
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
      _statusMessage = '레시피 데이터 업로드를 시작합니다...';
    });

    try {
      final bool success = await _recipeService.uploadRecipes();

      setState(() {
        _isLoading = false;
        _statusMessage = success
            ? '✅ 레시피 데이터 업로드가 완료되었습니다!'
            : '❌ 레시피 데이터 업로드에 실패했습니다.';
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('레시피 데이터 업로드 완료!'),
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

  // 재료 업로드
  Future<void> _uploadIngredients() async {
    // 확인 다이얼로그
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('재료 업로드'),
        content: const Text(
          '재료 데이터를 업로드하시겠습니까?\n'
          '(기존 subcollection 삭제 후 재삽입)',
        ),
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
      _statusMessage = '재료 데이터 업로드를 시작합니다...';
    });

    try {
      final bool success = await _recipeService.uploadRecipeIngredients();

      setState(() {
        _isLoading = false;
        _statusMessage = success
            ? '✅ 재료 데이터 업로드가 완료되었습니다!'
            : '❌ 재료 데이터 업로드에 실패했습니다.';
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('재료 데이터 업로드 완료!'),
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

  // 재료 매칭 미리보기
  Future<void> _runIngredientMatchDryRun() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '재료 매칭 미리보기를 실행하고 있습니다...';
      _ingredientMatchDryRunResult = null;
    });

    try {
      final result = await _recipeService.dryRunMatchIngredientsToFoodData();

      setState(() {
        _isLoading = false;
        _statusMessage = '✅ 재료 매칭 미리보기 완료!';
        _ingredientMatchDryRunResult = result;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '❌ 재료 매칭 미리보기 중 오류가 발생했습니다: $e';
      });
    }
  }

  // 재료 매칭 적용
  Future<void> _commitIngredientMatch() async {
    // 확인 다이얼로그
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('재료 매칭 적용'),
        content: const Text(
          '재료 매칭을 적용하시겠습니까?\n'
          '(foodRef == null인 재료들을 foodData와 매칭하여 foodRef를 업데이트합니다)',
        ),
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
      _statusMessage = '재료 매칭을 적용하고 있습니다...';
    });

    try {
      final bool success = await _recipeService
          .commitMatchIngredientsToFoodData();

      setState(() {
        _isLoading = false;
        _statusMessage = success
            ? '✅ 재료 매칭 적용이 완료되었습니다!'
            : '❌ 재료 매칭 적용에 실패했습니다.';
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('재료 매칭 적용 완료!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '❌ 재료 매칭 적용 중 오류가 발생했습니다: $e';
      });
    }
  }
}
