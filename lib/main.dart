import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/dictionary_repository.dart';
import 'screens/add_word_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/training_overview_screen.dart';
import 'screens/training_session_screen.dart';
import 'state/dictionary_controller.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferences = await SharedPreferences.getInstance();
  final repository = DictionaryRepository(preferences);
  final controller = DictionaryController(repository);
  await controller.initialize();

  runApp(MyDictionaryApp(controller: controller));
}

class MyDictionaryApp extends StatelessWidget {
  const MyDictionaryApp({super.key, required this.controller});

  final DictionaryController controller;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DictionaryController>.value(
      value: controller,
      child: MaterialApp(
        title: 'My Personal Dictionary',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.buildDarkTheme(),
        routes: <String, WidgetBuilder>{
          HomeScreen.routeName: (_) => const HomeScreen(),
          AddWordScreen.routeName: (_) => const AddWordScreen(),
          StatisticsScreen.routeName: (_) => const StatisticsScreen(),
          TrainingOverviewScreen.routeName: (_) =>
              const TrainingOverviewScreen(),
          TrainingSessionScreen.routeName: (_) => const TrainingSessionScreen(),
          SettingsScreen.routeName: (_) => const SettingsScreen(),
        },
        initialRoute: HomeScreen.routeName,
      ),
    );
  }
}
