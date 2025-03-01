import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_notes/widgets/unified_markdown_editor.dart';

void main() {
  group('UnifiedMarkdownEditor', () {
    testWidgets('renders initial markdown content',
        (WidgetTester tester) async {
      const initialMarkdown = '# Heading\n\nThis is a paragraph.';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnifiedMarkdownEditor(
              initialMarkdown: initialMarkdown,
              onChanged: (content) {},
            ),
          ),
        ),
      );

      // Verify that the editor renders the initial content
      expect(find.text('Heading'), findsOneWidget);
      expect(find.text('This is a paragraph.'), findsOneWidget);
    });

    testWidgets('switches between preview and edit mode',
        (WidgetTester tester) async {
      const initialMarkdown = '# Heading\n\nThis is a paragraph.';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnifiedMarkdownEditor(
              initialMarkdown: initialMarkdown,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // Initially in edit mode
      expect(find.text('Preview'), findsOneWidget);

      // Tap the preview button
      await tester.tap(find.text('Preview'));
      await tester.pump();

      // Now in preview mode
      expect(find.text('Edit'), findsOneWidget);

      // Tap the edit button
      await tester.tap(find.text('Edit'));
      await tester.pump();

      // Back to edit mode
      expect(find.text('Preview'), findsOneWidget);
    });

    testWidgets('updates content when text changes',
        (WidgetTester tester) async {
      const initialMarkdown = '# Heading\n\nThis is a paragraph.';
      String? updatedContent;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnifiedMarkdownEditor(
              initialMarkdown: initialMarkdown,
              onChanged: (content) {
                updatedContent = content;
              },
            ),
          ),
        ),
      );

      // Find the TextField
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // Enter text in the TextField
      await tester.enterText(textField, '# New Heading\n\nNew paragraph.');
      await tester.pump();

      // Verify that onChanged was called with the updated content
      expect(updatedContent, '# New Heading\n\nNew paragraph.');
    });

    testWidgets('shows markdown syntax when cursor is in a block',
        (WidgetTester tester) async {
      const initialMarkdown = '# Heading\n\nThis is a paragraph.';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnifiedMarkdownEditor(
              initialMarkdown: initialMarkdown,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // Find the TextField
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // Set cursor position in the heading block
      await tester.tap(find.text('Heading'));
      await tester.pump();

      // Verify that the heading block is visible
      expect(find.text('Heading'), findsOneWidget);

      // Set cursor position in the paragraph block
      await tester.tap(find.text('This is a paragraph.'));
      await tester.pump();

      // Verify that the paragraph block is visible
      expect(find.text('This is a paragraph.'), findsOneWidget);
    });
  });
}
