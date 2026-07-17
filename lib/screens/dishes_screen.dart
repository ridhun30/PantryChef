import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/dish.dart';
import 'dish_editor_screen.dart';

class DishesScreen extends StatelessWidget {
  final AppState appState;
  const DishesScreen({super.key, required this.appState});

  Future<void> _confirmDelete(BuildContext context, Dish dish) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete dish?'),
        content: Text('Remove "${dish.name}" from your dishes?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      appState.deleteDish(dish.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final byId = {for (final i in appState.ingredients) i.id: i};
    final dishes = [...appState.dishes]..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      appBar: AppBar(title: const Text('Dishes')),
      body: dishes.isEmpty
          ? const Center(child: Text('No dishes yet — tap + to create one'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: dishes.length,
              itemBuilder: (context, index) {
                final dish = dishes[index];
                final ingredientNames =
                    dish.ingredientIds.map((id) => byId[id]?.name).whereType<String>().join(', ');
                return Card(
                  child: ListTile(
                    title: Text(dish.name),
                    subtitle: Text(ingredientNames.isEmpty ? 'No ingredients set' : ingredientNames),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DishEditorScreen(appState: appState, existing: dish),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _confirmDelete(context, dish),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DishEditorScreen(appState: appState)),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
