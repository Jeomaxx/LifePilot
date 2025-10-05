import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/database_service.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

final recipesProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return DatabaseService().streamQuery('recipes');
});

class RecipesScreen extends ConsumerWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(recipesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Recipe Collection')),
      body: recipesAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(message: error.toString()),
        data: (recipes) {
          if (recipes.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.restaurant_menu,
              subtitle: 'No recipes saved',
              actionLabel: 'Add Recipe',
              onAction: () => _showAddDialog(context, ref),
            );
          }

          final recipesByCategory = <String, List<Map<String, dynamic>>>{};
          for (final recipe in recipes) {
            final category = recipe['category']?.toString() ?? 'Other';
            if (!recipesByCategory.containsKey(category)) {
              recipesByCategory[category] = [];
            }
            recipesByCategory[category]!.add(recipe);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: recipesByCategory.entries.map((entry) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.key, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...entry.value.map((recipe) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.restaurant)),
                    title: Text(recipe['name']?.toString() ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: recipe['prep_time'] != null ? Text('${recipe['prep_time']} min') : null,
                    onTap: () => _showRecipeDetails(context, ref, recipe),
                    onLongPress: () async {
                      await DatabaseService().delete('recipes', recipe['id']?.toString() ?? '');
                    ),
                  ),
                )),
                const SizedBox(height: 16),
              ],
            )).toList(),
          );
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final ingredientsController = TextEditingController();
    final instructionsController = TextEditingController();
    final prepTimeController = TextEditingController();
    String category = 'Breakfast';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Recipe'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Recipe Name')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  items: const [
                    DropdownMenuItem(value: 'Breakfast', child: Text('Breakfast')),
                    DropdownMenuItem(value: 'Lunch', child: Text('Lunch')),
                    DropdownMenuItem(value: 'Dinner', child: Text('Dinner')),
                    DropdownMenuItem(value: 'Dessert', child: Text('Dessert')),
                    DropdownMenuItem(value: 'Snack', child: Text('Snack')),
                  ],
                  onChanged: (v) => setState(() => category = v ?? 'Breakfast'),
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                const SizedBox(height: 12),
                TextField(controller: prepTimeController, decoration: const InputDecoration(labelText: 'Prep Time (min)'), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                TextField(controller: ingredientsController, decoration: const InputDecoration(labelText: 'Ingredients'), maxLines: 3),
                const SizedBox(height: 12),
                TextField(controller: instructionsController, decoration: const InputDecoration(labelText: 'Instructions'), maxLines: 4),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;
                await DatabaseService().insert('recipes', {
                  'name': nameController.text,
                  'category': category,
                  'prep_time': int.tryParse(prepTimeController.text),
                  'ingredients': ingredientsController.text,
                  'instructions': instructionsController.text,
                });
                if (context.mounted) Navigator.pop(context);
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecipeDetails(BuildContext context, WidgetRef ref, Map<String, dynamic> recipe) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(recipe['name']?.toString() ?? ''),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (recipe['prep_time'] != null) Text('Prep Time: ${recipe['prep_time']} minutes', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Ingredients:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(recipe['ingredients']?.toString() ?? ''),
              const SizedBox(height: 16),
              const Text('Instructions:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(recipe['instructions']?.toString() ?? ''),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}
