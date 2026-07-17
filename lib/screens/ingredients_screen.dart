import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/ingredient.dart';

class IngredientsScreen extends StatelessWidget {
  final AppState appState;
  const IngredientsScreen({super.key, required this.appState});

  Future<void> _addIngredientDialog(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New ingredient'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Ingredient name'),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Add')),
        ],
      ),
    );
    if (name == null) return;
    final success = appState.addIngredient(name);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That ingredient already exists or the name is empty')),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, Ingredient ingredient) async {
    final affectedDishes = appState.dishes.where((d) => d.ingredientIds.contains(ingredient.id)).length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete ingredient?'),
        content: Text(
          affectedDishes == 0
              ? 'Remove "${ingredient.name}" from your list?'
              : 'Remove "${ingredient.name}"? It will also be removed from $affectedDishes dish(es).',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      appState.deleteIngredient(ingredient.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ingredients = [...appState.ingredients]..sort((a, b) => a.name.compareTo(b.name));
    return Scaffold(
      appBar: AppBar(title: const Text('Ingredients')),
      body: ingredients.isEmpty
          ? const Center(child: Text('No ingredients yet — tap + to add one'))
          : ListView.builder(
              itemCount: ingredients.length,
              itemBuilder: (context, index) {
                final ing = ingredients[index];
                return ListTile(
                  title: Text(ing.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDelete(context, ing),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addIngredientDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
