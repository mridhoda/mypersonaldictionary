// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mypersonaldictionary/data/dictionary_repository.dart';
import 'package:mypersonaldictionary/main.dart';
import 'package:mypersonaldictionary/services/speech_service.dart';
import 'package:mypersonaldictionary/state/dictionary_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Home screen shows seeded language', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final repository = DictionaryRepository(preferences);
    final controller = DictionaryController(repository);
    await controller.initialize();

    final speechService = SpeechService();
    addTearDown(speechService.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DictionaryController>.value(value: controller),
          Provider<SpeechService>.value(value: speechService),
        ],
        child: const MyDictionaryApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('English'), findsOneWidget);
  });
}
