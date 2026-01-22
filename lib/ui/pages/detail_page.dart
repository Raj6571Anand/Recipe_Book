import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:photo_view/photo_view.dart';

import '../../core/constants.dart';
import '../../models/recipe.dart';
import '../../providers/app_providers.dart';

class RecipeDetailPage extends ConsumerStatefulWidget {
  final String recipeId;
  final Recipe? initialRecipe;

  const RecipeDetailPage({super.key, required this.recipeId, this.initialRecipe});

  @override
  ConsumerState<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends ConsumerState<RecipeDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Recipe? _fullRecipe;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      if (widget.initialRecipe != null && widget.initialRecipe!.instructions.isNotEmpty) {
        setState(() { _fullRecipe = widget.initialRecipe; _isLoading = false; });
      } else {
        final details = await ref.read(repositoryProvider).getRecipeDetails(widget.recipeId);
        setState(() { _fullRecipe = details; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context as BuildContext).showSnackBar(SnackBar(content: Text('Error loading details: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipe = _fullRecipe ?? widget.initialRecipe;
    final favState = ref.watch(favoritesProvider);
    final isFav = favState.value?.any((r) => r.id == widget.recipeId) ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: Colors.white,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.9),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: recipe != null ? GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ImageViewerPage(imageUrl: recipe.thumbUrl))),
                child: Hero(
                  tag: 'image_${widget.recipeId}',
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(imageUrl: recipe.thumbUrl, fit: BoxFit.cover),
                      const DecoratedBox(
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                  colors: [Colors.black26, Colors.transparent, Colors.black54]
                              )
                          )
                      ),
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Text(
                          recipe.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              shadows: [Shadow(blurRadius: 10, color: Colors.black45)]
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ) : Container(color: Colors.grey[200]),
            ),
            actions: [
              if (recipe != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.9),
                    child: IconButton(
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Icon(isFav ? Icons.favorite : Icons.favorite_border, key: ValueKey(isFav), color: isFav ? Colors.red : Colors.grey),
                      ),
                      onPressed: () => ref.read(favoritesProvider.notifier).toggleFavorite(recipe),
                    ),
                  ),
                )
            ],
          ),
          SliverPersistentHeader(
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: kPrimaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: kPrimaryColor,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Ingredients'),
                  Tab(text: 'Instructions'),
                ],
              ),
            ),
            pinned: true,
          ),
        ],
        body: _isLoading && recipe == null
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
          controller: _tabController,
          children: [
            _buildOverview(recipe!),
            _buildIngredients(recipe),
            _buildInstructions(recipe),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview(Recipe recipe) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _OverviewChip(label: recipe.category, icon: Icons.category),
              const SizedBox(width: 12),
              _OverviewChip(label: recipe.area, icon: Icons.public),
            ],
          ),
          const SizedBox(height: 30),
          if (recipe.videoUrl != null && recipe.videoUrl!.isNotEmpty)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => launchUrl(Uri.parse(recipe.videoUrl!)),
                icon: const Icon(Icons.play_circle_fill, color: Colors.white),
                label: const Text('Watch Tutorial', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIngredients(Recipe recipe) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: recipe.ingredients.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: kPrimaryColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Text('${index + 1}', style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
            ),
            title: Text(recipe.ingredients[index], style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: Text(recipe.measures[index], style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Widget _buildInstructions(Recipe recipe) {
    final steps = recipe.instructions.split(RegExp(r'\r\n|\n|\r')).where((s) => s.trim().isNotEmpty).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: steps.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(steps[index], style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OverviewChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _OverviewChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: kBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class ImageViewerPage extends StatelessWidget {
  final String imageUrl;
  const ImageViewerPage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
      body: PhotoView(imageProvider: NetworkImage(imageUrl)),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.black12)),
        ),
        child: _tabBar
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}