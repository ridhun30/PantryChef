import 'package:flutter/material.dart';

import 'app_state.dart';
import 'screens/root_screen.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState(StorageService());
  await appState.load();
  runApp(PantryChefApp(appState: appState));
}

class PantryChefApp extends StatelessWidget {
  final AppState appState;
  const PantryChefApp({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pantry Chef',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepOrange,
        useMaterial3: true,
      ),
      home: RootScreen(appState: appState),
    );
  }
}
