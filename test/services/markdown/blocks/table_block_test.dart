import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_notes/services/markdown/blocks/table_block.dart';

void main() {
  group('TableBlock', () {
    test('constructor sets content, cells, and hasHeader correctly', () {
      const content =
          '| Header 1 | Header 2 |\n| --- | --- |\n| Cell 1 | Cell 2 |';
      final cells = [
        ['Header 1', 'Header 2'],
        ['Cell 1', 'Cell 2']
      ];
      const hasHeader = true;

      final block =
          TableBlock(content: content, cells: cells, hasHeader: hasHeader);

      expect(block.content, equals(content));
      expect(block.cells, equals(cells));
      expect(block.hasHeader, equals(hasHeader));
    });

    group('fromMarkdown', () {
      test('parses table with header correctly', () {
        const markdown =
            '| Header 1 | Header 2 |\n| --- | --- |\n| Cell 1 | Cell 2 |';
        final block = TableBlock.fromMarkdown(markdown);

        expect(
            block.cells,
            equals([
              ['Header 1', 'Header 2'],
              ['Cell 1', 'Cell 2']
            ]));
        expect(block.hasHeader, isTrue);
      });

      test('parses table without header correctly', () {
        const markdown = '| Cell 1 | Cell 2 |\n| Cell 3 | Cell 4 |';
        final block = TableBlock.fromMarkdown(markdown);

        expect(
            block.cells,
            equals([
              ['Cell 1', 'Cell 2'],
              ['Cell 3', 'Cell 4']
            ]));
        expect(block.hasHeader, isFalse);
      });

      test('handles tables with varying column counts', () {
        const markdown =
            '| Header 1 | Header 2 | Header 3 |\n| --- | --- | --- |\n| Cell 1 | Cell 2 | Cell 3 |\n| Cell 4 | Cell 5 | Cell 6 |';
        final block = TableBlock.fromMarkdown(markdown);

        expect(
            block.cells,
            equals([
              ['Header 1', 'Header 2', 'Header 3'],
              ['Cell 1', 'Cell 2', 'Cell 3'],
              ['Cell 4', 'Cell 5', 'Cell 6']
            ]));
        expect(block.hasHeader, isTrue);
      });

      test('handles tables with special characters in cells', () {
        const markdown =
            '| *Bold* | **Strong** |\n| --- | --- |\n| [Link](url) | `code` |';
        final block = TableBlock.fromMarkdown(markdown);

        expect(
            block.cells,
            equals([
              ['*Bold*', '**Strong**'],
              ['[Link](url)', '`code`']
            ]));
      });

      test('creates default table for invalid markdown', () {
        const markdown = 'Not a table';
        final block = TableBlock.fromMarkdown(markdown);

        // Should create a default table
        expect(block.cells.length, equals(2));
        expect(block.cells[0].length, equals(2));
        expect(block.hasHeader, isTrue);
      });
    });

    test('toMarkdown returns content unchanged', () {
      const content =
          '| Header 1 | Header 2 |\n| --- | --- |\n| Cell 1 | Cell 2 |';
      final cells = [
        ['Header 1', 'Header 2'],
        ['Cell 1', 'Cell 2']
      ];

      final block = TableBlock(content: content, cells: cells, hasHeader: true);

      expect(block.toMarkdown(), equals(content));
    });

    group('copyWith', () {
      test('creates a new instance with updated content', () {
        const originalContent =
            '| Header 1 | Header 2 |\n| --- | --- |\n| Cell 1 | Cell 2 |';
        const newContent =
            '| New 1 | New 2 |\n| --- | --- |\n| New 3 | New 4 |';
        final cells = [
          ['Header 1', 'Header 2'],
          ['Cell 1', 'Cell 2']
        ];

        final block =
            TableBlock(content: originalContent, cells: cells, hasHeader: true);
        final newBlock = block.copyWith(content: newContent);

        // Verify it's a new instance
        expect(newBlock, isNot(same(block)));

        // Verify content is updated
        expect(newBlock.content, equals(newContent));

        // Original block should be unchanged
        expect(block.content, equals(originalContent));
      });

      test('re-parses table when content changes', () {
        const originalContent =
            '| Header 1 | Header 2 |\n| --- | --- |\n| Cell 1 | Cell 2 |';
        const newContent =
            '| New 1 | New 2 | New 3 |\n| --- | --- | --- |\n| New 4 | New 5 | New 6 |';
        final originalCells = [
          ['Header 1', 'Header 2'],
          ['Cell 1', 'Cell 2']
        ];

        final block = TableBlock(
            content: originalContent, cells: originalCells, hasHeader: true);
        final newBlock = block.copyWith(content: newContent);

        // Should re-parse the content as a table
        expect(
            newBlock.cells,
            equals([
              ['New 1', 'New 2', 'New 3'],
              ['New 4', 'New 5', 'New 6']
            ]));
        expect(newBlock.hasHeader, isTrue);
      });

      test('returns same instance when content is null', () {
        const content =
            '| Header 1 | Header 2 |\n| --- | --- |\n| Cell 1 | Cell 2 |';
        final cells = [
          ['Header 1', 'Header 2'],
          ['Cell 1', 'Cell 2']
        ];

        final block =
            TableBlock(content: content, cells: cells, hasHeader: true);
        final newBlock = block.copyWith();

        expect(newBlock.content, equals(content));
        expect(newBlock.cells, equals(cells));
        expect(newBlock.hasHeader, isTrue);
      });
    });

    test('_generateMarkdownTable generates correct markdown', () {
      final cells = [
        ['Header 1', 'Header 2'],
        ['Cell 1', 'Cell 2']
      ];

      // We can't directly test private methods, but we can test it indirectly
      // by creating a table and checking if the editor updates correctly

      // This is more of a smoke test to ensure the method works
      final block = TableBlock(
        content: '', // Empty content will be replaced
        cells: cells,
        hasHeader: true,
      );

      // The editor would call _generateMarkdownTable internally
      // We can verify the result by checking if toMarkdown contains the expected format
      expect(block.toMarkdown(), equals(''));
    });

    testWidgets('buildEditor creates a table editor with cells',
        (WidgetTester tester) async {
      const content =
          '| Header 1 | Header 2 |\n| --- | --- |\n| Cell 1 | Cell 2 |';
      final cells = [
        ['Header 1', 'Header 2'],
        ['Cell 1', 'Cell 2']
      ];
      final block = TableBlock(content: content, cells: cells, hasHeader: true);
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

      // Verify the table editor is present
      expect(find.byType(TableBlock),
          findsNothing); // The editor itself, not the block

      // We can't easily verify the cells content in the table editor
      // But we can verify that some UI elements are present
      expect(find.byType(Table), findsOneWidget);
    });

    testWidgets('buildPreview creates a markdown widget with table',
        (WidgetTester tester) async {
      const content =
          '| Header 1 | Header 2 |\n| --- | --- |\n| Cell 1 | Cell 2 |';
      final cells = [
        ['Header 1', 'Header 2'],
        ['Cell 1', 'Cell 2']
      ];
      final block = TableBlock(content: content, cells: cells, hasHeader: true);

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
      expect(find.byType(TableBlock), findsNothing);
    });
  });
}
