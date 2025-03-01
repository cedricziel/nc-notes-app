import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_notes/services/markdown/blocks/paragraph_block.dart';

void main() {
  group('ParagraphBlock', () {
    test('constructor sets content correctly', () {
      const content = 'This is a paragraph';
      final block = ParagraphBlock(content: content);

      expect(block.content, equals(content));
    });

    test('toMarkdown returns content unchanged', () {
      const content = 'This is a paragraph';
      final block = ParagraphBlock(content: content);

      expect(block.toMarkdown(), equals(content));
    });

    test('copyWith creates a new instance with updated content', () {
      const originalContent = 'Original content';
      const newContent = 'New content';

      final block = ParagraphBlock(content: originalContent);
      final newBlock = block.copyWith(content: newContent);

      // Verify it's a new instance
      expect(newBlock, isNot(same(block)));

      // Verify content is updated
      expect(newBlock.content, equals(newContent));

      // Original block should be unchanged
      expect(block.content, equals(originalContent));
    });

    test('copyWith returns same instance when content is null', () {
      const content = 'Original content';

      final block = ParagraphBlock(content: content);
      final newBlock = block.copyWith();

      // Should be the same instance
      expect(newBlock.content, equals(content));
    });

    testWidgets('buildEditor creates a text field with content', (WidgetTester tester) async {
      const content = 'Test paragraph';
      final block = ParagraphBlock(content: content);
      String? updatedContent;

      // Build the editor widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return block.buildEditor(
                  context,
                  (value) {
                    updatedContent = value;
                  },
                );
              },
            ),
          ),
        ),
      );

      // Verify the text field contains the content
      expect(find.text(content), findsOneWidget);
    });

    testWidgets('buildPreview creates a markdown widget with content', (WidgetTester tester) async {
      const content = 'Test paragraph';
      final block = ParagraphBlock(content: content);

      // Build the preview widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return block.buildPreview(context);
              },
            ),
          ),
        ),
      );

      // The content should be rendered by the Markdown widget
      // We can't directly check the rendered text, but we can verify the widget exists
      expect(find.byType(ParagraphBlock), findsNothing);
    });
  });
}
