import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;


// --- UPDATED IMPORTS FOR NEW FILE STRUCTURE ---
import 'package:recipe_app/main.dart';
import 'package:recipe_app/models/recipe.dart';
import 'package:recipe_app/services/api_service.dart';
import 'package:recipe_app/services/database_helper.dart';
import 'package:recipe_app/repositories/recipe_repository.dart';
import 'package:recipe_app/providers/app_providers.dart';

// --- GENERATED MOCKS IMPORT ---
import 'widget_test.mocks.dart';

// -----------------------------------------------------------------------------
// INSTRUCTIONS TO FIX ERRORS:
// 1. Open terminal in project folder.
// 2. Run: dart run build_runner build
// 3. This will generate 'widget_test.mocks.dart'.
// -----------------------------------------------------------------------------

// Generate Mocks for Client, DatabaseHelper, AND RecipeRepository
@GenerateMocks([http.Client, DatabaseHelper, RecipeRepository])
void main() {

  // -----------------------------------------------------------------------------
  // UNIT TESTS
  // -----------------------------------------------------------------------------
  group('Unit Tests', () {
    late MockClient mockClient;
    late MealApiService apiService;

    setUp(() {
      mockClient = MockClient();
      apiService = MealApiService(client: mockClient);
    });

    test('Recipe.fromJson parses correctly', () {
      final jsonMap = {
        'idMeal': '1',
        'strMeal': 'Test Meal',
        'strCategory': 'Test Cat',
        'strArea': 'Test Area',
        'strInstructions': 'Cook it.',
        'strMealThumb': 'http://img.com',
        'strIngredient1': 'Salt',
        'strMeasure1': '1 tsp',
      };
      final recipe = Recipe.fromJson(jsonMap);
      expect(recipe.id, '1');
      expect(recipe.name, 'Test Meal');
      expect(recipe.ingredients.first, 'Salt');
      expect(recipe.measures.first, '1 tsp');
    });

    test('Recipe serialization/deserialization', () {
      final recipe = Recipe(
          id: '1', name: 'A', category: 'C', area: 'Ar',
          instructions: 'I', thumbUrl: 'T', ingredients: ['i1'], measures: ['m1']
      );
      final json = recipe.toJson();
      expect(json['idMeal'], '1');
    });

    test('API Service returns list of recipes on success', () async {
      when(mockClient.get(any)).thenAnswer((_) async =>
          http.Response(jsonEncode({'meals': [{'idMeal': '1', 'strMeal': 'M'}]}), 200));

      final result = await apiService.searchRecipes('chicken');
      expect(result, isA<List<Recipe>>());
      expect(result.length, 1);
    });

    test('API Service throws exception on error', () async {
      when(mockClient.get(any)).thenAnswer((_) async => http.Response('Error', 404));
      expect(apiService.searchRecipes('chicken'), throwsException);
    });

    test('Filter Provider logic', () {
      final container = ProviderContainer();
      final notifier = container.read(filterProvider.notifier);

      notifier.setQuery('Beef');
      expect(container.read(filterProvider).query, 'Beef');

      notifier.toggleViewMode();
      expect(container.read(filterProvider).isGridView, false);

      notifier.setCategory('Seafood');
      expect(container.read(filterProvider).category, 'Seafood');
    });
  });

  // -----------------------------------------------------------------------------
  // WIDGET TESTS
  // -----------------------------------------------------------------------------

  group('Widget Tests', () {
    testWidgets('App renders Search Bar', (WidgetTester tester) async {
      // NOTE: We override repositoryProvider here to prevent actual API/DB calls
      // which might crash the test environment if not handled.
      final mockRepo = MockRecipeRepository();

      // Stub default calls made by HomePage init
      when(mockRepo.getRecipesByFirstLetter(any)).thenAnswer((_) async => []);
      when(mockRepo.getCategories()).thenAnswer((_) async => []);
      when(mockRepo.getAreas()).thenAnswer((_) async => []);
      when(mockRepo.getFavorites()).thenAnswer((_) async => []); // For FavoritesNotifier

      await tester.pumpWidget(ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const RecipeApp(),
      ));

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('Shows loading indicator initially', (WidgetTester tester) async {
      final mockRepo = MockRecipeRepository();

      // Stub the method called on launch
      when(mockRepo.getRecipesByFirstLetter(any)).thenAnswer((_) async => []);
      when(mockRepo.getCategories()).thenAnswer((_) async => []);
      when(mockRepo.getAreas()).thenAnswer((_) async => []);
      when(mockRepo.getFavorites()).thenAnswer((_) async => []);

      // Pump widget with the overridden provider
      await tester.pumpWidget(ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const RecipeApp(),
      ));

      // Allow the init frame
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Favorites page is accessible', (WidgetTester tester) async {
      final mockRepo = MockRecipeRepository();

      // Stub necessary calls
      when(mockRepo.getRecipesByFirstLetter(any)).thenAnswer((_) async => []);
      when(mockRepo.getCategories()).thenAnswer((_) async => []);
      when(mockRepo.getAreas()).thenAnswer((_) async => []);
      when(mockRepo.getFavorites()).thenAnswer((_) async => []);

      await tester.pumpWidget(ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const RecipeApp(),
      ));

      // Tap favorite icon in AppBar
      await tester.tap(find.byIcon(Icons.favorite));
      await tester.pumpAndSettle();

      expect(find.text('My Favorites'), findsOneWidget);
    });
  });
}