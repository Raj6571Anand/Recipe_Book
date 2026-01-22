import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants.dart';
import '../../models/recipe.dart';
import '../../providers/app_providers.dart';
import '../widgets/recipe_card.dart';
import 'detail_page.dart';
import 'favorites_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(filterProvider.notifier).setQuery(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filterState = ref.watch(filterProvider);
    final recipesAsync = ref.watch(recipesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final areasAsync = ref.watch(areasProvider);

    int activeFilters = 0;
    if (filterState.category != null) activeFilters++;
    if (filterState.area != null) activeFilters++;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );
          try {
            final recipe = await ref.read(repositoryProvider).getRandomRecipe();
            if (context.mounted) {
              Navigator.pop(context); // hide loading
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RecipeDetailPage(recipeId: recipe.id, initialRecipe: recipe))
              );
            }
          } catch (e) {
            if (context.mounted) {
              Navigator.pop(context); // hide loading
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
            }
          }
        },
        label: const Text('Surprise Me'),
        icon: const Icon(Icons.shuffle),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      appBar: AppBar(
        title: const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Text('Recipe Book'),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: FloatingActionButton.small(
              heroTag: 'fav_btn',
              elevation: 0,
              backgroundColor: Colors.white,
              shape: CircleBorder(side: BorderSide(color: Colors.grey.shade300)),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritesPage()),
              ),
              child: const Icon(Icons.favorite, color: Colors.redAccent),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Search any recipe...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.search, color: kPrimaryColor),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  )
                      : null,
                ),
                onChanged: _onSearchChanged,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Filters & Sort Bar
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // Active Filter Indicator / Clear
                if (activeFilters > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      backgroundColor: kPrimaryColor,
                      label: Text('Clear ($activeFilters)', style: const TextStyle(color: Colors.white)),
                      avatar: const Icon(Icons.close, size: 16, color: Colors.white),
                      side: BorderSide.none,
                      onPressed: () => ref.read(filterProvider.notifier).clearFilters(),
                    ),
                  ),

                // Sort Toggle
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    avatar: Icon(
                        filterState.sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 16,
                        color: kPrimaryColor
                    ),
                    label: Text(filterState.sortAscending ? 'A-Z' : 'Z-A'),
                    onPressed: () => ref.read(filterProvider.notifier).toggleSort(),
                    backgroundColor: Colors.white,
                    elevation: 0,
                  ),
                ),

                // View Mode Toggle (Grid/List)
                Container(
                  margin: const EdgeInsets.only(right: 8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ViewModeBtn(
                        icon: Icons.grid_view_rounded,
                        isActive: filterState.isGridView,
                        onTap: () {
                          if (!filterState.isGridView) ref.read(filterProvider.notifier).toggleViewMode();
                        },
                      ),
                      Container(width: 1, height: 20, color: Colors.grey.shade300),
                      _ViewModeBtn(
                        icon: Icons.view_list_rounded,
                        isActive: !filterState.isGridView,
                        onTap: () {
                          if (filterState.isGridView) ref.read(filterProvider.notifier).toggleViewMode();
                        },
                      ),
                    ],
                  ),
                ),

                // Category Filter
                _buildDropdownFilter(
                  context,
                  label: 'Category',
                  value: filterState.category,
                  items: categoriesAsync.asData?.value ?? [],
                  onChanged: (val) => ref.read(filterProvider.notifier).setCategory(val),
                ),
                const SizedBox(width: 8),

                // Area Filter
                _buildDropdownFilter(
                  context,
                  label: 'Cuisine',
                  value: filterState.area,
                  items: areasAsync.asData?.value ?? [],
                  onChanged: (val) => ref.read(filterProvider.notifier).setArea(val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Recipe List
          Expanded(
            child: recipesAsync.when(
              data: (recipes) {
                if (recipes.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.no_food, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No recipes found.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  );
                }
                return filterState.isGridView
                    ? _buildGridView(recipes)
                    : _buildListView(recipes);
              },
              error: (err, stack) => Center(child: Text('Error: $err')),
              loading: () => _buildLoadingSkeleton(filterState.isGridView),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter(BuildContext context, {
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged
  }) {
    final isSelected = value != null;
    return InputChip(
      label: Text(value ?? label),
      labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500
      ),
      selected: isSelected,
      selectedColor: kPrimaryColor,
      backgroundColor: Colors.white,
      side: isSelected ? BorderSide.none : BorderSide(color: Colors.grey.shade300),
      showCheckmark: false,
      deleteIcon: Icon(Icons.close, size: 18, color: isSelected ? Colors.white : Colors.black54),
      onDeleted: isSelected ? () => onChanged(null) : null,
      onPressed: () async {
        if (items.isEmpty) return;
        final selected = await showModalBottomSheet<String>(
          context: context,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (ctx) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Select $label', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (ctx, i) => ListTile(
                    title: Text(items[i]),
                    onTap: () => Navigator.pop(ctx, items[i]),
                    trailing: value == items[i] ? const Icon(Icons.check, color: kPrimaryColor) : null,
                  ),
                ),
              ),
            ],
          ),
        );
        if (selected != null) onChanged(selected);
      },
    );
  }

  Widget _buildGridView(List<Recipe> recipes) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: recipes.length,
      itemBuilder: (context, index) => RecipeCard(recipe: recipes[index], isGrid: true),
    );
  }

  Widget _buildListView(List<Recipe> recipes) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      itemCount: recipes.length,
      itemBuilder: (context, index) => RecipeCard(recipe: recipes[index], isGrid: false),
    );
  }

  Widget _buildLoadingSkeleton(bool isGrid) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: isGrid
          ? GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 16, mainAxisSpacing: 16),
        itemCount: 6,
        itemBuilder: (_, __) => Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
      )
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        itemCount: 6,
        itemBuilder: (_, __) => Container(height: 100, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
      ),
    );
  }
}

class _ViewModeBtn extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ViewModeBtn({required this.icon, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Icon(
          icon,
          size: 20,
          color: isActive ? kPrimaryColor : Colors.grey,
        ),
      ),
    );
  }
}