import 'package:cloud_firestore/cloud_firestore.dart';

class Recipe {
  final String id;
  final String menuName;
  final double servingNum;
  final String? youtubeUrl;
  final String? recipeText;
  final DateTime? updatedAt;
  final List<RecipeIngredient> ingredients;

  Recipe({
    required this.id,
    required this.menuName,
    required this.servingNum,
    this.youtubeUrl,
    this.recipeText,
    this.updatedAt,
    this.ingredients = const [],
  });

  factory Recipe.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Recipe(
      id: doc.id,
      menuName: data['menuName'] as String? ?? '',
      servingNum: (data['servingNum'] as num?)?.toDouble() ?? 0.0,
      youtubeUrl: data['youtubeUrl'] as String?,
      recipeText: data['recipeText'] as String?,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Firestore 문서 + `recipe_ingredients` 서브컬렉션까지 함께 불러오기
  static Future<Recipe> fromFirestoreWithIngredients(
    DocumentSnapshot doc,
  ) async {
    final base = Recipe.fromFirestore(doc);

    final ingredientsSnap = await doc.reference
        .collection('recipe_ingredients')
        .orderBy('order')
        .get();

    final ingredients = ingredientsSnap.docs
        .map((d) => RecipeIngredient.fromFirestore(d))
        .toList();

    return base.copyWith(ingredients: ingredients);
  }

  Recipe copyWith({
    String? id,
    String? menuName,
    double? servingNum,
    String? youtubeUrl,
    String? recipeText,
    DateTime? updatedAt,
    List<RecipeIngredient>? ingredients,
  }) {
    return Recipe(
      id: id ?? this.id,
      menuName: menuName ?? this.menuName,
      servingNum: servingNum ?? this.servingNum,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      recipeText: recipeText ?? this.recipeText,
      updatedAt: updatedAt ?? this.updatedAt,
      ingredients: ingredients ?? this.ingredients,
    );
  }
}

class RecipeIngredient {
  final String id;
  final String rawItemName;
  final double? amount;
  final String unit;
  final String type; // 'ingredient' or 'sauce'

  RecipeIngredient({
    required this.id,
    required this.rawItemName,
    this.amount,
    required this.unit,
    required this.type,
  });

  factory RecipeIngredient.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final amountValue = data['amount'];

    double? parsedAmount;
    if (amountValue is num) {
      parsedAmount = amountValue.toDouble();
    }

    return RecipeIngredient(
      id: doc.id,
      rawItemName: (data['rawItemName'] as String?) ?? '',
      amount: parsedAmount,
      unit: (data['unit'] as String?) ?? '',
      type: (data['type'] as String?) ?? 'ingredient',
    );
  }
}