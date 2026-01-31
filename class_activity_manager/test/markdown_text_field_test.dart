import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:class_activity_manager/presentation/widgets/markdown_text_field.dart';

void main() {
  testWidgets('MarkdownTextField shows preview when unfocused', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownTextField(
            initialValue: '# Hello',
            hintText: 'Hint',
          ),
        ),
      ),
    );

    expect(find.byType(MarkdownTextField), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('MarkdownTextField shows TextField when focused', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 100,
            child: MarkdownTextField(
              initialValue: '**bold**',
              hintText: 'Hint',
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(MarkdownTextField));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('**bold**'), findsOneWidget);
  });

  testWidgets('MarkdownTextField calls onChanged when text is edited',
      (tester) async {
    String? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 100,
            child: MarkdownTextField(
              initialValue: 'old',
              onChanged: (v) => changed = v,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(MarkdownTextField));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextField), 'new');
    expect(changed, 'new');
  });
}
