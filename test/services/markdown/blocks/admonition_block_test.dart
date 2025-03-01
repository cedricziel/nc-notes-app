import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_notes/services/markdown/blocks/admonition_block.dart';

void main() {
  group('AdmonitionBlock', () {
    test('constructor sets content and type correctly', () {
      const content = 'This is an admonition';
      const type = 'info';
      final block = AdmonitionBlock(content: content, type: type);

      expect(block.content, equals(content));
      expect(block.type, equals(type));
    });

    group('fromMarkdown', () {
      test('parses admonition block with type correctly', () {
        const markdown = ':::info\nThis is an info admonition\n:::';
        final block = AdmonitionBlock.fromMarkdown(markdown);

        expect(block.content, equals('This is an info admonition'));
        expect(block.type, equals('info'));
      });

      test('parses admonition block with empty type correctly', () {
        const markdown = ':::\nThis is an admonition without type\n:::';
        final block = AdmonitionBlock.fromMarkdown(markdown);

        expect(block.content, equals('This is an admonition without type'));
        expect(block.type, equals(''));
      });

      test('handles multi-line admonition blocks', () {
        const markdown = ':::warning\nLine 1\nLine 2\nLine 3\n:::';
        final block = AdmonitionBlock.fromMarkdown(markdown);

        expect(block.content, equals('Line 1\nLine 2\nLine 3'));
        expect(block.type, equals('warning'));
      });

      test('handles admonition blocks with markdown content', () {
        const markdown = ':::note\n**Bold text** and *italic text*\n:::';
        final block = AdmonitionBlock.fromMarkdown(markdown);

        expect(block.content, equals('**Bold text** and *italic text*'));
        expect(block.type, equals('note'));
      });

      test('handles malformed admonition blocks without closing marker', () {
        const markdown = ':::info\nThis is an info admonition';
        final block = AdmonitionBlock.fromMarkdown(markdown);

        expect(block.content, equals('This is an info admonition'));
        expect(block.type, equals('info'));
      });
    });

    test('toMarkdown returns correctly formatted admonition block', () {
      final block = AdmonitionBlock(content: 'This is a warning', type: 'warning');

      expect(block.toMarkdown(), equals(':::warning\nThis is a warning\n:::'));
    });

    test('toMarkdown with empty type still includes markers', () {
      final block = AdmonitionBlock(content: 'This is an admonition', type: '');

      expect(block.toMarkdown(), equals(':::\nThis is an admonition\n:::'));
    });

    group('copyWith', () {
      test('creates a new instance with updated content', () {
        const originalContent = 'Original admonition';
        const newContent = 'New admonition';
        const type = 'info';

        final block = AdmonitionBlock(content: originalContent, type: type);
        final newBlock = block.copyWith(content: newContent);

        // Verify it's a new instance
        expect(newBlock, isNot(same(block)));

        // Verify content is updated but type is preserved
        expect(newBlock.content, equals(newContent));
        expect(newBlock.type, equals(type));

        // Original block should be unchanged
        expect(block.content, equals(originalContent));
      });

      test('re-parses admonition block when content changes', () {
        const originalContent = 'Original admonition';
        const newContent = ':::warning\nThis is a warning\n:::';
        const originalType = 'info';

        final block = AdmonitionBlock(content: originalContent, type: originalType);
        final newBlock = block.copyWith(content: newContent);

        // Should re-parse the content as an admonition block
        expect(newBlock.content, equals('This is a warning'));
        expect(newBlock.type, equals('warning'));
      });

      test('returns same instance when content is null', () {
        const content = 'This is an admonition';
        const type = 'info';

        final block = AdmonitionBlock(content: content, type: type);
        final newBlock = block.copyWith();

        expect(newBlock.content, equals(content));
        expect(newBlock.type, equals(type));
      });
    });

    testWidgets('buildEditor creates an admonition editor with content and type field', (WidgetTester tester) async {
      const content = 'This is an admonition';
      const type = 'info';
      final block = AdmonitionBlock(content: content, type: type);
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

      // Verify the type field is present and contains the type
      expect(find.text(type), findsOneWidget);
    });

    testWidgets('buildPreview creates a styled container with admonition content', (WidgetTester tester) async {
      const content = 'This is an admonition';
      const type = 'info';
      final block = AdmonitionBlock(content: content, type: type);

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

      // Verify the container is present
      expect(find.byType(Container), findsWidgets);

      // Verify the type label is displayed
      expect(find.text(type.toUpperCase()), findsOneWidget);
    });

    test('_getAdmonitionColor returns appropriate color for different types', () {
      final BuildContext context = _MockBuildContext();

      final infoBlock = AdmonitionBlock(content: 'Info', type: 'info');
      final warningBlock = AdmonitionBlock(content: 'Warning', type: 'warning');
      final errorBlock = AdmonitionBlock(content: 'Error', type: 'error');
      final successBlock = AdmonitionBlock(content: 'Success', type: 'success');
      final noteBlock = AdmonitionBlock(content: 'Note', type: 'note');

      // We can't directly test private methods, but we can indirectly verify
      // the behavior through the buildPreview method which uses these colors

      // This is more of a smoke test to ensure the method doesn't crash
      infoBlock.buildPreview(context);
      warningBlock.buildPreview(context);
      errorBlock.buildPreview(context);
      successBlock.buildPreview(context);
      noteBlock.buildPreview(context);
    });
  });
}

// Mock BuildContext for testing
class _MockBuildContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
