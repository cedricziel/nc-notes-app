import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_notes/services/markdown/blocks/hover_aware_admonition_block.dart';
import 'package:flutter_notes/widgets/hover_aware_editor.dart';

void main() {
  group('HoverAwareAdmonitionBlock', () {
    test('constructor sets content and type correctly', () {
      const content = 'This is an admonition';
      const type = 'info';
      final block = HoverAwareAdmonitionBlock(content: content, type: type);

      expect(block.content, equals(content));
      expect(block.type, equals(type));
    });

    group('fromMarkdown', () {
      test('parses admonition block with type correctly', () {
        const markdown = ':::info\nThis is an info admonition';
        final block = HoverAwareAdmonitionBlock.fromMarkdown(markdown);

        expect(block.content, equals('This is an info admonition'));
        expect(block.type, equals('info'));
      });

      test('parses admonition block with empty type correctly', () {
        const markdown = ':::\nThis is an admonition without type';
        final block = HoverAwareAdmonitionBlock.fromMarkdown(markdown);

        expect(block.content, equals('This is an admonition without type'));
        expect(block.type, equals(''));
      });

      test('handles multi-line admonition blocks', () {
        const markdown = ':::warning\nLine 1\nLine 2\nLine 3';
        final block = HoverAwareAdmonitionBlock.fromMarkdown(markdown);

        expect(block.content, equals('Line 1\nLine 2\nLine 3'));
        expect(block.type, equals('warning'));
      });

      test('handles admonition blocks with markdown content', () {
        const markdown = ':::note\n**Bold text** and *italic text*';
        final block = HoverAwareAdmonitionBlock.fromMarkdown(markdown);

        expect(block.content, equals('**Bold text** and *italic text*'));
        expect(block.type, equals('note'));
      });
    });

    test('toMarkdown returns correctly formatted admonition block', () {
      final block = HoverAwareAdmonitionBlock(
          content: 'This is a warning', type: 'warning');

      expect(block.toMarkdown(), equals(':::warning\nThis is a warning'));
    });

    test('toMarkdown with empty type still includes opening marker', () {
      final block =
          HoverAwareAdmonitionBlock(content: 'This is an admonition', type: '');

      expect(block.toMarkdown(), equals(':::\nThis is an admonition'));
    });

    group('copyWith', () {
      test('creates a new instance with updated content', () {
        const originalContent = 'Original admonition';
        const newContent = 'New admonition';
        const type = 'info';

        final block =
            HoverAwareAdmonitionBlock(content: originalContent, type: type);
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
        const newContent = ':::warning\nThis is a warning';
        const originalType = 'info';

        final block = HoverAwareAdmonitionBlock(
            content: originalContent, type: originalType);
        final newBlock = block.copyWith(content: newContent);

        // Should re-parse the content as an admonition block
        expect(newBlock.content, equals('This is a warning'));
        expect(newBlock.type, equals('warning'));
      });

      test('returns same instance when content is null', () {
        const content = 'This is an admonition';
        const type = 'info';

        final block = HoverAwareAdmonitionBlock(content: content, type: type);
        final newBlock = block.copyWith();

        expect(newBlock.content, equals(content));
        expect(newBlock.type, equals(type));
      });
    });

    testWidgets(
        'buildEditor creates a HoverAwareEditor with formatted and markdown views',
        (WidgetTester tester) async {
      const content = 'This is an admonition';
      const type = 'info';
      final block = HoverAwareAdmonitionBlock(content: content, type: type);

      // Build the editor widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return block.buildEditor(
                  context,
                  (value) {},
                );
              },
            ),
          ),
        ),
      );

      // Verify the HoverAwareEditor is created
      expect(find.byType(HoverAwareEditor), findsOneWidget);

      // Verify the formatted view contains the content
      expect(find.text(type.toUpperCase()), findsOneWidget);

      // We can't directly test the markdown view since it's not visible by default
      // but we can verify the editor exists
      expect(find.byType(HoverAwareAdmonitionEditor), findsOneWidget);
    });

    testWidgets(
        'buildPreview creates a styled container with admonition content',
        (WidgetTester tester) async {
      const content = 'This is an admonition';
      const type = 'info';
      final block = HoverAwareAdmonitionBlock(content: content, type: type);

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

    test('_getAdmonitionColor returns appropriate color for different types',
        () {
      final BuildContext context = _MockBuildContext();

      final infoBlock =
          HoverAwareAdmonitionBlock(content: 'Info', type: 'info');
      final warningBlock =
          HoverAwareAdmonitionBlock(content: 'Warning', type: 'warning');
      final errorBlock =
          HoverAwareAdmonitionBlock(content: 'Error', type: 'error');
      final successBlock =
          HoverAwareAdmonitionBlock(content: 'Success', type: 'success');
      final noteBlock =
          HoverAwareAdmonitionBlock(content: 'Note', type: 'note');

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
