import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';
import '../repositories/recipe_repository.dart';
import '../models/recipe.dart';

// Service & Repository Providers
final apiServiceProvider = Provider((ref) => MealApiService());
final dbHelperProvider = Provider((ref) => DatabaseHelper());
final repositoryProvider = Provider((ref) => RecipeRepository(
  apiService: ref.watch(apiServiceProvider),
  dbHelper: ref.watch(dbHelperProvider),
));

// State Classes
class RecipeFilterState {
  final String query;
  final String? category;
  final String? area;
  final bool isGridView;
  final bool sortAscending;

  RecipeFilterState({
    this.query = '',
    this.category,
    this.area,
    this.isGridView = true,
    this.sortAscending = true,
  });

  RecipeFilterState copyWith({
    String? query,
    String? category,
    String? area,
    bool? isGridView,
    bool? sortAscending,
  }) {
    return RecipeFilterState(
      query: query ?? this.query,
      category: category ?? this.category,
      area: area ?? this.area,
      isGridView: isGridView ?? this.isGridView,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  RecipeFilterState clearFilters() {
    return RecipeFilterState(
      query: '',
      category: null,
      area: null,
      isGridView: isGridView,
      sortAscending: sortAscending,
    );
  }
}

// Notifiers
class RecipeFilterNotifier extends StateNotifier<RecipeFilterState> {
  RecipeFilterNotifier() : super(RecipeFilterState());

  void setQuery(String q) => state = state.copyWith(query: q);
  void setCategory(String? c) => state = state.copyWith(category: c, area: null);
  void setArea(String? a) => state = state.copyWith(area: a, category: null);
  void toggleViewMode() => state = state.copyWith(isGridView: !state.isGridView);
  void toggleSort() => state = state.copyWith(sortAscending: !state.sortAscending);
  void clearFilters() => state = state.clearFilters();
}

class FavoritesNotifier extends StateNotifier<AsyncValue<List<Recipe>>> {
  final RecipeRepository _repo;

  FavoritesNotifier(this._repo) : super(const AsyncValue.loading()) {
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    try {
      final recipes = await _repo.getFavorites();
      state = AsyncValue.data(recipes);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleFavorite(Recipe recipe) async {
    await _repo.toggleFavorite(recipe);
    await loadFavorites();
  }

  bool isFavorite(String id) {
    return state.value?.any((r) => r.id == id) ?? false;
  }
}

// Final Providers
final filterProvider = StateNotifierProvider<RecipeFilterNotifier, RecipeFilterState>(
      (ref) => RecipeFilterNotifier(),
);

final categoriesProvider = FutureProvider((ref) => ref.read(repositoryProvider).getCategories());
final areasProvider = FutureProvider((ref) => ref.read(repositoryProvider).getAreas());

final recipesProvider = FutureProvider<List<Recipe>>((ref) async {
  final filter = ref.watch(filterProvider);
  final repository = ref.watch(repositoryProvider);

  List<Recipe> recipes = [];

  if (filter.query.isNotEmpty) {
    recipes = await repository.searchRecipes(filter.query);
    if (filter.category != null) {
      recipes = recipes.where((r) => r.category == filter.category).toList();
    }
    if (filter.area != null) {
      recipes = recipes.where((r) => r.area == filter.area).toList();
    }
  }
  else if (filter.category != null) {
    recipes = await repository.getRecipesByCategory(filter.category!);
  }
  else if (filter.area != null) {
    recipes = await repository.getRecipesByArea(filter.area!);
  }
  else {
    recipes = await repository.getRecipesByFirstLetter('c');
  }

  recipes.sort((a, b) => filter.sortAscending
      ? a.name.compareTo(b.name)
      : b.name.compareTo(a.name));

  return recipes;
});

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, AsyncValue<List<Recipe>>>(
      (ref) => FavoritesNotifier(ref.watch(repositoryProvider)),
);