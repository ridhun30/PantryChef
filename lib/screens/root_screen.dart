import 'package:flutter/material.dart';

import '../app_state.dart';
import '../services/updater.dart';
import 'dishes_screen.dart';
import 'ingredients_screen.dart';
import 'suggest_screen.dart';
import 'update_ui.dart';

class RootScreen extends StatefulWidget {
  final AppState appState;
  final Updater updater;
  const RootScreen({super.key, required this.appState, required this.updater});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> with WidgetsBindingObserver {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.updater.check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Look for a new build whenever the app comes back to the foreground
    // (the updater itself skips checks made less than an hour apart).
    if (state == AppLifecycleState.resumed) widget.updater.check();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.appState, widget.updater]),
      builder: (context, _) {
        // The screens are built here, inside the builder, so they get rebuilt
        // every time the app state changes. An IndexedStack keeps each tab
        // alive (search text, scroll position) while you switch between them.
        return Scaffold(
          body: Column(
            children: [
              UpdateBanner(updater: widget.updater),
              Expanded(
                child: IndexedStack(
                  index: _index,
                  children: [
                    SuggestScreen(appState: widget.appState, updater: widget.updater),
                    IngredientsScreen(appState: widget.appState),
                    DishesScreen(appState: widget.appState),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.restaurant_menu_outlined),
                selectedIcon: Icon(Icons.restaurant_menu),
                label: 'Suggest',
              ),
              NavigationDestination(
                icon: Icon(Icons.egg_alt_outlined),
                selectedIcon: Icon(Icons.egg_alt),
                label: 'Ingredients',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book),
                label: 'Dishes',
              ),
            ],
          ),
        );
      },
    );
  }
}
