import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/recipe.dart';
import '../pages/detail_page.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final bool isGrid;

  const RecipeCard({super.key, required this.recipe, required this.isGrid});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RecipeDetailPage(recipeId: recipe.id, initialRecipe: recipe)),
        );
      },
      child: Card(
        child: isGrid
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Hero(
                tag: 'image_${recipe.id}',
                child: CachedNetworkImage(
                  imageUrl: recipe.thumbUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey[100]),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis
                  ),
                  const SizedBox(height: 4),
                  Text('${recipe.category} • ${recipe.area}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])
                  ),
                ],
              ),
            ),
          ],
        )
            : Row(
          children: [
            SizedBox(
              width: 110,
              height: 110,
              child: Hero(
                tag: 'image_${recipe.id}',
                child: CachedNetworkImage(
                  imageUrl: recipe.thumbUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey[100]),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(recipe.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                          child: Text(recipe.category, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                        ),
                        const SizedBox(width: 8),
                        Text('•', style: TextStyle(color: Colors.grey[400])),
                        const SizedBox(width: 8),
                        Text(recipe.area, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}