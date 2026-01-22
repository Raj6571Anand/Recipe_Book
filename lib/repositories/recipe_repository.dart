import '../models/recipe.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';

class RecipeRepository {
  final MealApiService apiService;
  final DatabaseHelper dbHelper;

  RecipeRepository({required this.apiService, required this.dbHelper});

  Future<List<Recipe>> searchRecipes(String query) => apiService.searchRecipes(query);
  Future<List<Recipe>> getRecipesByCategory(String category) => apiService.getRecipesByCategory(category);
  Future<List<Recipe>> getRecipesByArea(String area) => apiService.getRecipesByArea(area);
  Future<List<Recipe>> getRecipesByFirstLetter(String letter) => apiService.getRecipesByFirstLetter(letter);
  Future<Recipe> getRandomRecipe() => apiService.getRandomRecipe();
  Future<Recipe> getRecipeDetails(String id) => apiService.getRecipeById(id);
  Future<List<String>> getCategories() => apiService.getCategories();
  Future<List<String>> getAreas() => apiService.getAreas();

  Future<void> toggleFavorite(Recipe recipe) async {
    final isFav = await dbHelper.isFavorite(recipe.id);
    if (isFav) {
      await dbHelper.removeFavorite(recipe.id);
    } else {
      await dbHelper.insertFavorite(recipe);
    }
  }

  Future<List<Recipe>> getFavorites() => dbHelper.getFavorites();
  Future<bool> isFavorite(String id) => dbHelper.isFavorite(id);
}