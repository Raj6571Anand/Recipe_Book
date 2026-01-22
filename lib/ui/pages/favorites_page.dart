import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../widgets/recipe_card.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesState = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Favorites')),
      body: favoritesState.when(
        data: (recipes) {
          if (recipes.isEmpty) {
            return const Center(child: Text('No favorites yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return Dismissible(
                key: Key(recipe.id),
                direction: DismissDirection.endToStart,
                background: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(16)),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.red)
                ),
                onDismissed: (_) => ref.read(favoritesProvider.notifier).toggleFavorite(recipe),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: RecipeCard(recipe: recipe, isGrid: false),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}