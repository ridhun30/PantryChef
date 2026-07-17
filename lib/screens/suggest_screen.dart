import 'package:flutter/material.dart';

import '../app_state.dart';

class SuggestScreen extends StatefulWidget {
  final AppState appState;
  const SuggestScreen({super.key, required this.appState});

  @override
  State<SuggestScreen> createState() => _SuggestScreenState();
}

class _SuggestScreenState extends State<SuggestScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    final filteredIngredients = appState.ingredients
        .where((i) => i.name.toLowerCase().contains(_query.toLowerCase()))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final matches = appState.suggestions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('What can I make?'),
        actions: [
          if (appState.selectedIngredientIds.isNotEmpty)
            IconButton(
              tooltip: 'Clear selection',
              icon: const Icon(Icons.clear_all),
              onPressed: appState.clearSelected,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search ingredients',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          SizedBox(
            height: 56,
            child: filteredIngredients.isEmpty
                ? const Center(
                    child: Text('No ingredients yet — add some in the Ingredients tab'),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: filteredIngredients.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final ing = filteredIngredients[index];
                      final selected = appState.selectedIngredientIds.contains(ing.id);
                      return FilterChip(
                        label: Text(ing.name),
                        selected: selected,
                        onSelected: (_) => appState.toggleSelected(ing.id),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          Expanded(
            child: matches.isEmpty
                ? const Center(child: Text('Add some dishes in the Dishes tab to see suggestions'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      final match = matches[index];
                      return Card(
                        child: ListTile(
                          leading: Icon(
                            match.canMake ? Icons.check_circle : Icons.circle_outlined,
                            color: match.canMake ? Colors.green : Colors.grey,
                          ),
                          title: Text(match.dish.name),
                          subtitle: match.canMake
                              ? const Text('You have everything!')
                              : Text('Missing: ${match.missing.map((i) => i.name).join(', ')}'),
                          trailing: Text('${match.haveCount}/${match.totalCount}'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
