import 'package:flutter/material.dart';
import '../services/recipe_data_service.dart';

class SeedUploadPage extends StatelessWidget {
  const SeedUploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seed Upload')),
      body: Center(
        child: ElevatedButton(
          child: const Text('Upload Recipes TSV'),
          onPressed: () async {
            final recipeService = RecipeDataService();

            await recipeService.uploadRecipes();
            await recipeService.uploadRecipeIngredients();

            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('업로드 완료')));
          },
        ),
      ),
    );
  }
}
