import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/recipe.dart';

class MealApiService {
  final http.Client client;

  MealApiService({http.Client? client}) : client = client ?? http.Client();

  Future<List<Recipe>> searchRecipes(String query) async {
    final url = query.isEmpty
        ? '$kBaseUrl/search.php?s='
        : '$kBaseUrl/search.php?s=$query';

    final response = await client.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['meals'] == null) return [];
      return (data['meals'] as List).map((e) => Recipe.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load recipes');
    }
  }

  Future<List<Recipe>> getRecipesByCategory(String category) async {
    final response = await client.get(Uri.parse('$kBaseUrl/filter.php?c=$category'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['meals'] == null) return [];

      return (data['meals'] as List).map((e) {
        final map = e as Map<String, dynamic>;
        map['strCategory'] = category;
        return Recipe.fromJson(map);
      }).toList();
    }
    return [];
  }

  Future<List<Recipe>> getRecipesByArea(String area) async {
    final response = await client.get(Uri.parse('$kBaseUrl/filter.php?a=$area'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['meals'] == null) return [];

      return (data['meals'] as List).map((e) {
        final map = e as Map<String, dynamic>;
        map['strArea'] = area;
        return Recipe.fromJson(map);
      }).toList();
    }
    return [];
  }

  Future<List<Recipe>> getRecipesByFirstLetter(String letter) async {
    final response = await client.get(Uri.parse('$kBaseUrl/search.php?f=$letter'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['meals'] == null) return [];
      return (data['meals'] as List).map((e) => Recipe.fromJson(e)).toList();
    }
    return [];
  }

  Future<Recipe> getRandomRecipe() async {
    final response = await client.get(Uri.parse('$kBaseUrl/random.php'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['meals'] == null) throw Exception('No random recipe found');
      return Recipe.fromJson(data['meals'][0]);
    } else {
      throw Exception('Failed to load random recipe');
    }
  }

  Future<Recipe> getRecipeById(String id) async {
    final response = await client.get(Uri.parse('$kBaseUrl/lookup.php?i=$id'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['meals'] == null) throw Exception('Recipe not found');
      return Recipe.fromJson(data['meals'][0]);
    } else {
      throw Exception('Failed to load recipe details');
    }
  }

  Future<List<String>> getCategories() async {
    final response = await client.get(Uri.parse('$kBaseUrl/list.php?c=list'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['meals'] as List).map((e) => e['strCategory'] as String).toList();
    }
    return [];
  }

  Future<List<String>> getAreas() async {
    final response = await client.get(Uri.parse('$kBaseUrl/list.php?a=list'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['meals'] as List).map((e) => e['strArea'] as String).toList();
    }
    return [];
  }
}