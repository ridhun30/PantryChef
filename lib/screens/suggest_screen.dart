import 'package:flutter/material.dart';

import '../app_state.dart';
import '../services/updater.dart';
import '../util/names.dart';
import 'update_ui.dart';

class SuggestScreen extends StatefulWidget {
  final AppState appState;
  final Updater updater;
  const SuggestScreen({super.key, required this.appState, required this.updater});

  @override
  State<SuggestScreen> createState() => _SuggestScreenState();
}

class _SuggestScreenState extends State<SuggestScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    final scheme = Theme.of(context).colorScheme;
    final query = _query.trim().toLowerCase();
    final filteredIngredients = appState.ingredients.where((i) => i.name.toLowerCase().contains(query)).toList()
      ..sort((a, b) => compareNames(a.name, b.name));
    final selectedCount = appState.selectedIngredientIds.length;
    final matches = appState.suggestions;
    final makeableCount = matches.where((m) => m.canMake).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('What can I make?'),
        actions: [
          if (selectedCount > 0)
            TextButton.icon(
              onPressed: appState.clearSelected,
              icon: const Icon(Icons.clear_all),
              label: Text('Clear ($selectedCount)'),
            ),
          IconButton(
            tooltip: 'About & updates',
            icon: Badge(isLabelVisible: widget.updater.hasUpdate, child: const Icon(Icons.info_outline)),
            onPressed: () => showAboutSheet(context, widget.updater),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search ingredients',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() {
                          _searchController.clear();
                          _query = '';
                        }),
                      ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          // Chips wrap onto several lines (scrollable when there are many) so
          // every ingredient is visible instead of hidden off to the side.
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.3),
            child: appState.ingredients.isEmpty
                ? const _Message('No ingredients yet — add some in the Ingredients tab')
                : filteredIngredients.isEmpty
                    ? _Message('No ingredient matches "${_query.trim()}"')
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            for (final ing in filteredIngredients)
                              FilterChip(
                                label: Text(ing.name),
                                selected: appState.selectedIngredientIds.contains(ing.id),
                                onSelected: (_) => appState.toggleSelected(ing.id),
                              ),
                          ],
                        ),
                      ),
          ),
          const Divider(height: 1),
          if (matches.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  selectedCount == 0
                      ? 'Tap the ingredients you have to see what you can cook'
                      : makeableCount == 0
                          ? 'Nothing complete yet — closest matches first'
                          : 'You can make $makeableCount ${makeableCount == 1 ? 'dish' : 'dishes'}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            ),
          Expanded(
            child: matches.isEmpty
                ? const _Message('Add some dishes in the Dishes tab to see suggestions')
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: matches.length,
                    itemBuilder: (context, index) => _MatchCard(match: matches[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final DishMatch match;
  const _MatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final String subtitle;
    if (match.hasNoIngredients) {
      subtitle = 'No ingredients set — edit it in the Dishes tab';
    } else if (match.canMake) {
      subtitle = 'You have everything!';
    } else {
      subtitle = 'Missing: ${match.missing.map((i) => i.name).join(', ')}';
    }
    return Card(
      child: ListTile(
        leading: SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: match.canMake ? 1 : match.ratio,
                strokeWidth: 4,
                color: match.canMake ? scheme.primary : scheme.tertiary,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
              if (match.canMake) Icon(Icons.check, size: 20, color: scheme.primary),
            ],
          ),
        ),
        title: Text(match.dish.name),
        subtitle: Text(subtitle),
        trailing: match.hasNoIngredients ? null : Text('${match.haveCount}/${match.totalCount}'),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  const _Message(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Center(child: Text(text, textAlign: TextAlign.center)),
      );
}
