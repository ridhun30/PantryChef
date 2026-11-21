import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/ingredient.dart';
import '../util/names.dart';

class IngredientsScreen extends StatelessWidget {
  final AppState appState;
  const IngredientsScreen({super.key, required this.appState});

  Future<void> _addIngredientDialog(BuildContext context) async {
    final name = await showDialog<String>(context: context, builder: (_) => const _NameDialog());
    if (name == null || !context.mounted) return;
    final existing = appState.ingredientByName(name);
    final String message;
    if (tidyName(name).isEmpty) {
      message = 'Please enter a name';
    } else if (existing != null) {
      message = '"${existing.name}" is already in your list';
    } else {
      appState.addIngredient(name);
      message = 'Added "${tidyName(name)}"';
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
              : 'Remove "${ingredient.name}"? It will also be removed from '
                  '$affectedDishes ${affectedDishes == 1 ? 'dish' : 'dishes'}.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      appState.deleteIngredient(ingredient.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ingredients = [...appState.ingredients]..sort((a, b) => compareNames(a.name, b.name));
    final usage = <String, int>{};
    for (final d in appState.dishes) {
      for (final id in d.ingredientIds) {
        usage[id] = (usage[id] ?? 0) + 1;
      }
    }
    return Scaffold(
      appBar: AppBar(title: Text('Ingredients (${ingredients.length})')),
      body: ingredients.isEmpty
          ? const Center(child: Text('No ingredients yet — tap + to add one'))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 88), // keep the last row clear of the + button
              itemCount: ingredients.length,
              itemBuilder: (context, index) {
                final ing = ingredients[index];
                final used = usage[ing.id] ?? 0;
                return ListTile(
                  title: Text(ing.name),
                  subtitle: Text(used == 0 ? 'Not used in any dish' : 'Used in $used ${used == 1 ? 'dish' : 'dishes'}'),
                  trailing: IconButton(
                    tooltip: 'Delete ${ing.name}',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDelete(context, ing),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-ingredient',
        onPressed: () => _addIngredientDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Ingredient'),
      ),
    );
  }
}

/// Asks for an ingredient name. Owns (and disposes) its text controller.
class _NameDialog extends StatefulWidget {
  const _NameDialog();

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New ingredient'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(labelText: 'Ingredient name'),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, _controller.text), child: const Text('Add')),
      ],
    );
  }
}
