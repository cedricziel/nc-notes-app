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

    testWidgets('switches between view and edit modes',
        (WidgetTester tester) async {
      const initialMarkdown = '# Heading\n\nThis is a paragraph.';

      Future<void> pumpEditor(EditorMode mode) {
        return tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UnifiedMarkdownEditor(
                initialMarkdown: initialMarkdown,
                editorMode: mode,
                onChanged: (_) {},
              ),
            ),
          ),
        );
      }

      // View mode renders the document without an editable text field
      await pumpEditor(EditorMode.view);
      expect(find.text('Heading'), findsOneWidget);
      expect(find.byType(EditableText), findsNothing);

      // Raw edit mode shows an editable text field only
      await pumpEditor(EditorMode.editRaw);
      expect(find.byType(EditableText), findsOneWidget);

      // Unified edit mode overlays the editable text field on rendered blocks
      await pumpEditor(EditorMode.editUnified);
      expect(find.text('Heading'), findsOneWidget);
      expect(find.byType(EditableText), findsOneWidget);
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
              editorMode: EditorMode.editRaw,
              onChanged: (content) {
                updatedContent = content;
              },
            ),
          ),
        ),
      );

      // Find the TextField
      final textField = find.byType(EditableText);
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
      final textField = find.byType(EditableText);
      expect(textField, findsOneWidget);

      // Set cursor position in the heading block
      await tester.tap(find.text('Heading'), warnIfMissed: false);
      await tester.pump();

      // The active block shows its raw markdown syntax
      expect(find.text('# Heading'), findsOneWidget);

      // Set cursor position in the paragraph block
      await tester.tap(find.text('This is a paragraph.'), warnIfMissed: false);
      await tester.pump();

      // Verify that the paragraph block is visible
      expect(find.text('This is a paragraph.'), findsOneWidget);
    });
  });
}
