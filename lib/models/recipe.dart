import 'dart:convert';

class Recipe {
  final String id;
  final String name;
  final String category;
  final String area;
  final String instructions;
  final String thumbUrl;
  final String? videoUrl;
  final List<String> ingredients;
  final List<String> measures;

  Recipe({
    required this.id,
    required this.name,
    required this.category,
    required this.area,
    required this.instructions,
    required this.thumbUrl,
    this.videoUrl,
    required this.ingredients,
    required this.measures,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    List<String> ingredients = [];
    List<String> measures = [];

    for (int i = 1; i <= 20; i++) {
      final ingredient = json['strIngredient$i'];
      final measure = json['strMeasure$i'];
      if (ingredient != null && ingredient.toString().trim().isNotEmpty) {
        ingredients.add(ingredient.toString());
        measures.add(measure?.toString() ?? '');
      }
    }

    return Recipe(
      id: json['idMeal'] ?? '',
      name: json['strMeal'] ?? 'Unknown Meal',
      category: json['strCategory'] ?? 'Unknown',
      area: json['strArea'] ?? 'Unknown',
      instructions: json['strInstructions'] ?? '',
      thumbUrl: json['strMealThumb'] ?? '',
      videoUrl: json['strYoutube'],
      ingredients: ingredients,
      measures: measures,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idMeal': id,
      'strMeal': name,
      'strCategory': category,
      'strArea': area,
      'strInstructions': instructions,
      'strMealThumb': thumbUrl,
      'strYoutube': videoUrl,
    };
  }

  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'area': area,
      'instructions': instructions,
      'thumbUrl': thumbUrl,
      'videoUrl': videoUrl,
      'ingredients': jsonEncode(ingredients),
      'measures': jsonEncode(measures),
    };
  }

  factory Recipe.fromDbMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      area: map['area'],
      instructions: map['instructions'],
      thumbUrl: map['thumbUrl'],
      videoUrl: map['videoUrl'],
      ingredients: List<String>.from(jsonDecode(map['ingredients'])),
      measures: List<String>.from(jsonDecode(map['measures'])),
    );
  }
}