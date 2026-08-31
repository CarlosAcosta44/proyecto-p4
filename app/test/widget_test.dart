import 'package:flutter_test/flutter_test.dart';
import 'package:app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AppP4());
    // Solo verifica que la app arranca sin crash
    expect(find.byType(AppP4), findsOneWidget);
  });
}
