import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_notes/widgets/cursor_aware_editor.dart';

void main() {
  group('CursorAwareEditor', () {
    testWidgets('shows markdown view by default', (WidgetTester tester) async {
      final formattedView = Container(
        key: const Key('formatted'),
        child: const Text('Formatted View'),
      );

      final markdownView = Container(
        key: const Key('markdown'),
        child: const Text('Markdown View'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CursorAwareEditor(
              formattedView: formattedView,
              markdownView: markdownView,
              isFocused: false,
            ),
          ),
        ),
      );

      // Verify the markdown view is shown by default
      expect(find.text('Markdown View'), findsOneWidget);
      expect(find.text('Formatted View'), findsNothing);
    });

    testWidgets('shows formatted view when focused', (WidgetTester tester) async {
      final formattedView = Container(
        key: const Key('formatted'),
        child: const Text('Formatted View'),
      );

      final markdownView = Container(
        key: const Key('markdown'),
        child: const Text('Markdown View'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CursorAwareEditor(
              formattedView: formattedView,
              markdownView: markdownView,
              isFocused: true,
            ),
          ),
        ),
      );

      // Verify the formatted view is shown when focused
      expect(find.text('Formatted View'), findsOneWidget);
      expect(find.text('Markdown View'), findsNothing);
    });

    testWidgets('calls onFocusChanged when focus changes', (WidgetTester tester) async {
      bool? focusState;

      final formattedView = Container(
        key: const Key('formatted'),
        child: const Text('Formatted View'),
      );

      final markdownView = Container(
        key: const Key('markdown'),
        child: const Text('Markdown View'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CursorAwareEditor(
              formattedView: formattedView,
              markdownView: markdownView,
              isFocused: false,
              onFocusChanged: (focused) {
                focusState = focused;
              },
            ),
          ),
        ),
      );

      // Tap on the markdown view to focus
      await tester.tap(find.text('Markdown View'));
      await tester.pump();

      // Verify onFocusChanged was called with true
      expect(focusState, isTrue);
    });

    testWidgets('applies border styling when focused', (WidgetTester tester) async {
      final formattedView = Container(
        key: const Key('formatted'),
        child: const Text('Formatted View'),
      );

      final markdownView = Container(
        key: const Key('markdown'),
        child: const Text('Markdown View'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CursorAwareEditor(
              formattedView: formattedView,
              markdownView: markdownView,
              isFocused: true,
            ),
          ),
        ),
      );

      // Verify the focused container has a border
      final container = tester.widget<Container>(
        find.byType(Container).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
    });
  });
}
