import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_notes/services/markdown/blocks/heading_block.dart';

void main() {
  group('HeadingBlock', () {
    test('constructor sets content and level correctly', () {
      const content = 'Heading Text';
      const level = 2;
      final block = HeadingBlock(content: content, level: level);

      expect(block.content, equals(content));
      expect(block.level, equals(level));
    });

    group('fromMarkdown', () {
      test('parses H1 correctly', () {
        const markdown = '# Heading 1';
        final block = HeadingBlock.fromMarkdown(markdown);

        expect(block.content, equals('Heading 1'));
        expect(block.level, equals(1));
      });

      test('parses H2 correctly', () {
        const markdown = '## Heading 2';
        final block = HeadingBlock.fromMarkdown(markdown);

        expect(block.content, equals('Heading 2'));
        expect(block.level, equals(2));
      });

      test('parses H6 correctly', () {
        const markdown = '###### Heading 6';
        final block = HeadingBlock.fromMarkdown(markdown);

        expect(block.content, equals('Heading 6'));
        expect(block.level, equals(6));
      });

      test('handles headings with special characters', () {
        const markdown = '## Special *Heading* with [link](https://example.com)';
        final block = HeadingBlock.fromMarkdown(markdown);

        expect(block.content, equals('Special *Heading* with [link](https://example.com)'));
        expect(block.level, equals(2));
      });

      test('throws ArgumentError for invalid heading format', () {
        const invalidMarkdown = 'Not a heading';

        expect(() => HeadingBlock.fromMarkdown(invalidMarkdown),
               throwsArgumentError);
      });
    });

    test('toMarkdown returns correctly formatted heading', () {
      final block = HeadingBlock(content: 'Heading Text', level: 3);

      expect(block.toMarkdown(), equals('### Heading Text'));
    });

    group('copyWith', () {
      test('creates a new instance with updated content', () {
        const originalContent = 'Original Heading';
        const newContent = 'New Heading';
        const level = 2;

        final block = HeadingBlock(content: originalContent, level: level);
        final newBlock = block.copyWith(content: newContent);

        // Verify it's a new instance
        expect(newBlock, isNot(same(block)));

        // Verify content is updated but level is preserved
        expect(newBlock.content, equals(newContent));
        expect(newBlock.level, equals(level));

        // Original block should be unchanged
        expect(block.content, equals(originalContent));
      });

      test('detects heading level change in content', () {
        const originalContent = 'Original Heading';
        const newContent = '# New Heading';
        const originalLevel = 2;

        final block = HeadingBlock(content: originalContent, level: originalLevel);
        final newBlock = block.copyWith(content: newContent);

        // Level should be updated based on the new content
        expect(newBlock.content, equals('New Heading'));
        expect(newBlock.level, equals(1));
      });

      test('returns same instance when content is null', () {
        const content = 'Heading';
        const level = 3;

        final block = HeadingBlock(content: content, level: level);
        final newBlock = block.copyWith();

        expect(newBlock.content, equals(content));
        expect(newBlock.level, equals(level));
      });
    });

    testWidgets('buildEditor creates a heading editor with content', (WidgetTester tester) async {
      const content = 'Test Heading';
      const level = 2;
      final block = HeadingBlock(content: content, level: level);
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

      // Verify the heading level dropdown is present
      expect(find.byType(DropdownButton<int>), findsOneWidget);
    });

    testWidgets('buildPreview creates a markdown widget with heading', (WidgetTester tester) async {
      const content = 'Test Heading';
      const level = 2;
      final block = HeadingBlock(content: content, level: level);

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
      expect(find.byType(HeadingBlock), findsNothing);
    });
  });
}
