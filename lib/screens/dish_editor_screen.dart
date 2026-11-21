import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/dish.dart';
import '../util/names.dart';

/// Create or edit a dish: its name and the set of ingredients it requires.
/// One field both filters the ingredient list and adds a brand-new
/// ingredient without leaving this screen.
class DishEditorScreen extends StatefulWidget {
  final AppState appState;
  final Dish? existing;
  const DishEditorScreen({super.key, required this.appState, this.existing});

  @override
  State<DishEditorScreen> createState() => _DishEditorScreenState();
}

class _DishEditorScreenState extends State<DishEditorScreen> {
  late final TextEditingController _nameController;
  final _searchController = TextEditingController();
  late final Set<String> _selectedIds;
  late final String _initialName;
  late final Set<String> _initialIds;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _initialName = widget.existing?.name ?? '';
    _initialIds = {...?widget.existing?.ingredientIds};
    _nameController = TextEditingController(text: _initialName);
    _selectedIds = {..._initialIds};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasChanges =>
      tidyName(_nameController.text) != _initialName ||
      _selectedIds.length != _initialIds.length ||
      !_selectedIds.containsAll(_initialIds);

  void _showSnack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  /// Selects the ingredient typed in the search field, creating it first if
  /// it doesn't exist yet.
  void _addOrSelectTyped() {
    final name = tidyName(_searchController.text);
    if (name.isEmpty) return;
    final appState = widget.appState;
    final existing = appState.ingredientByName(name);
    if (existing == null) appState.addIngredient(name);
    final id = nameKey(name);
    setState(() {
      _selectedIds.add(id);
      _searchController.clear();
    });
    _showSnack(existing == null ? 'Added "$name" and selected it' : 'Selected "${existing.name}"');
  }

  void _save() {
    final name = tidyName(_nameController.text);
    if (name.isEmpty) {
      setState(() => _nameError = 'Please enter a dish name');
      return;
    }
    // Ignore ids whose ingredient was deleted meanwhile.
    final known = widget.appState.ingredients.map((i) => i.id).toSet();
    final ids = _selectedIds.where(known.contains).toList();
    if (ids.isEmpty) {
      _showSnack('Select at least one ingredient');
      return;
    }

    final appState = widget.appState;
    final existing = widget.existing;
    final result = existing == null
        ? appState.addDish(Dish.create(name: name, ingredientIds: ids))
        : appState.updateDish(existing.copyWith(name: name, ingredientIds: ids));
    switch (result) {
      case DishSaveResult.saved:
        Navigator.of(context).pop();
      case DishSaveResult.emptyName:
        setState(() => _nameError = 'Please enter a dish name');
      case DishSaveResult.duplicateName:
        setState(() => _nameError = 'A dish with that name already exists');
    }
  }

  Future<bool> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your changes to this dish haven\'t been saved.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep editing')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Discard')),
        ],
      ),
    );
    return discard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.existing == null ? 'New dish' : 'Edit dish'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton(onPressed: _save, child: const Text('Save')),
            ),
          ],
        ),
        body: ListenableBuilder(
          listenable: appState,
          builder: (context, _) {
            final query = _searchController.text.trim().toLowerCase();
            final sortedIngredients = appState.ingredients.where((i) => i.name.toLowerCase().contains(query)).toList()
              // Selected ingredients first, then alphabetical.
              ..sort((a, b) {
                final sa = _selectedIds.contains(a.id), sb = _selectedIds.contains(b.id);
                if (sa != sb) return sa ? -1 : 1;
                return compareNames(a.name, b.name);
              });
            final typed = tidyName(_searchController.text);
            final canAddTyped = typed.isNotEmpty && appState.ingredientByName(typed) == null;
            final selectedCount = _selectedIds.where((id) => appState.ingredients.any((i) => i.id == id)).length;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: _nameController,
                    autofocus: widget.existing == null,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Dish name',
                      border: const OutlineInputBorder(),
                      errorText: _nameError,
                    ),
                    onChanged: (_) => setState(() => _nameError = null),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Find or add an ingredient',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      isDense: true,
                      suffixIcon: typed.isEmpty
                          ? null
                          : IconButton(
                              tooltip: canAddTyped ? 'Add "$typed"' : 'Select "$typed"',
                              icon: Icon(canAddTyped ? Icons.add : Icons.check),
                              onPressed: _addOrSelectTyped,
                            ),
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _addOrSelectTyped(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Required ingredients ($selectedCount selected)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      if (canAddTyped)
                        ListTile(
                          leading: const Icon(Icons.add_circle_outline),
                          title: Text('Add "$typed" as a new ingredient'),
                          onTap: _addOrSelectTyped,
                        ),
                      if (sortedIngredients.isEmpty && !canAddTyped)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: Text('No ingredients yet — type one above to add it')),
                        ),
                      for (final ing in sortedIngredients)
                        CheckboxListTile(
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
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
