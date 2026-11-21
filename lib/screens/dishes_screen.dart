import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/dish.dart';
import '../util/names.dart';
import 'dish_editor_screen.dart';

class DishesScreen extends StatelessWidget {
  final AppState appState;
  const DishesScreen({super.key, required this.appState});

  void _openEditor(BuildContext context, [Dish? dish]) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DishEditorScreen(appState: appState, existing: dish)),
    );
  }

  /// Deletes straight away and offers Undo, rather than asking first.
  void _delete(BuildContext context, Dish dish) {
    final index = appState.dishes.indexWhere((d) => d.id == dish.id);
    appState.deleteDish(dish.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Deleted "${dish.name}"'),
        action: SnackBarAction(label: 'Undo', onPressed: () => appState.restoreDish(dish, index)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final byId = {for (final i in appState.ingredients) i.id: i};
    final dishes = [...appState.dishes]..sort((a, b) => compareNames(a.name, b.name));

    return Scaffold(
      appBar: AppBar(title: Text('Dishes (${dishes.length})')),
      body: dishes.isEmpty
          ? const Center(child: Text('No dishes yet — tap + to create one'))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 88), // keep the last card clear of the + button
              itemCount: dishes.length,
              itemBuilder: (context, index) {
                final dish = dishes[index];
                final ingredientNames = dish.ingredientIds
                    .map((id) => byId[id]?.name)
                    .whereType<String>()
                    .toList()
                  ..sort(compareNames);
                return Card(
                  child: ListTile(
                    onTap: () => _openEditor(context, dish),
                    title: Text(dish.name),
                    subtitle: Text(ingredientNames.isEmpty ? 'No ingredients set' : ingredientNames.join(', ')),
                    trailing: IconButton(
                      tooltip: 'Delete ${dish.name}',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _delete(context, dish),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-dish',
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('Dish'),
      ),
    );
  }
}
