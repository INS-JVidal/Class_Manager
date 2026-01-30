import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:class_activity_manager/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ClassActivityManagerApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Class Activity Manager'), findsOneWidget);
  });
}
