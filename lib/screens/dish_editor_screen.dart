import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/dish.dart';

/// Create or edit a dish: its name and the set of ingredients it requires.
/// Also lets you add a brand-new ingredient on the fly without leaving
/// this screen.
class DishEditorScreen extends StatefulWidget {
  final AppState appState;
  final Dish? existing;
  const DishEditorScreen({super.key, required this.appState, this.existing});

  @override
  State<DishEditorScreen> createState() => _DishEditorScreenState();
}

class _DishEditorScreenState extends State<DishEditorScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _newIngredientController;
  late final Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _newIngredientController = TextEditingController();
    _selectedIds = {...?widget.existing?.ingredientIds};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _newIngredientController.dispose();
    super.dispose();
  }

  void _addNewIngredient() {
    final name = _newIngredientController.text.trim();
    if (name.isEmpty) return;
    final added = widget.appState.addIngredient(name);
    final id = name.toLowerCase();
    final exists = widget.appState.ingredients.any((i) => i.id == id);
    setState(() {
      if (added || exists) _selectedIds.add(id);
      _newIngredientController.clear();
    });
    if (!added && exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That ingredient already exists — selected it for you')),
      );
    }
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a dish name')),
      );
      return;
    }
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one ingredient')),
      );
      return;
    }

    final appState = widget.appState;
    final existing = widget.existing;
    if (existing == null) {
      final success = appState.addDish(Dish.create(name: name, ingredientIds: _selectedIds.toList()));
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A dish with that name already exists')),
        );
        return;
      }
    } else {
      appState.updateDish(existing.copyWith(name: name, ingredientIds: _selectedIds.toList()));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'New Dish' : 'Edit Dish'),
        actions: [IconButton(icon: const Icon(Icons.check), onPressed: _save)],
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final sortedIngredients = [...appState.ingredients]..sort((a, b) => a.name.compareTo(b.name));
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Dish name', border: OutlineInputBorder()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newIngredientController,
                        decoration: const InputDecoration(
                          labelText: 'Add new ingredient',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _addNewIngredient(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(icon: const Icon(Icons.add), onPressed: _addNewIngredient),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Required ingredients', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              Expanded(
                child: sortedIngredients.isEmpty
                    ? const Center(child: Text('No ingredients yet — add one above'))
                    : ListView.builder(
                        itemCount: sortedIngredients.length,
                        itemBuilder: (context, index) {
                          final ing = sortedIngredients[index];
                          return CheckboxListTile(
                            title: Text(ing.name),
                            value: _selectedIds.contains(ing.id),
                            onChanged: (checked) {
                              setState(() {
                                if (checked ?? false) {
                                  _selectedIds.add(ing.id);
                                } else {
                                  _selectedIds.remove(ing.id);
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
