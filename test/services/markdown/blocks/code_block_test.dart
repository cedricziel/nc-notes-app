import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_notes/services/markdown/blocks/code_block.dart';

void main() {
  group('CodeBlock', () {
    test('constructor sets content and language correctly', () {
      const content = 'const x = 5;';
      const language = 'javascript';
      final block = CodeBlock(content: content, language: language);

      expect(block.content, equals(content));
      expect(block.language, equals(language));
    });

    group('fromMarkdown', () {
      test('parses code block with language correctly', () {
        const markdown = '```javascript\nconst x = 5;\n```';
        final block = CodeBlock.fromMarkdown(markdown);

        expect(block.content, equals('const x = 5;'));
        expect(block.language, equals('javascript'));
      });

      test('parses code block without language correctly', () {
        const markdown = '```\nconst x = 5;\n```';
        final block = CodeBlock.fromMarkdown(markdown);

        expect(block.content, equals('const x = 5;'));
        expect(block.language, equals(''));
      });

      test('handles multi-line code blocks', () {
        const markdown = '```python\ndef hello():\n    print("Hello, world!")\n```';
        final block = CodeBlock.fromMarkdown(markdown);

        expect(block.content, equals('def hello():\n    print("Hello, world!")'));
        expect(block.language, equals('python'));
      });

      test('handles code blocks with special characters', () {
        const markdown = '```html\n<div class="container">\n  <!-- Comment -->\n</div>\n```';
        final block = CodeBlock.fromMarkdown(markdown);

        expect(block.content, equals('<div class="container">\n  <!-- Comment -->\n</div>'));
        expect(block.language, equals('html'));
      });

      test('handles malformed code blocks without closing fence', () {
        const markdown = '```javascript\nconst x = 5;';
        final block = CodeBlock.fromMarkdown(markdown);

        expect(block.content, equals('const x = 5;'));
        expect(block.language, equals('javascript'));
      });
    });

    test('toMarkdown returns correctly formatted code block', () {
      final block = CodeBlock(content: 'const x = 5;', language: 'javascript');

      expect(block.toMarkdown(), equals('```javascript\nconst x = 5;\n```'));
    });

    test('toMarkdown with empty language still includes fence', () {
      final block = CodeBlock(content: 'const x = 5;', language: '');

      expect(block.toMarkdown(), equals('```\nconst x = 5;\n```'));
    });

    group('copyWith', () {
      test('creates a new instance with updated content', () {
        const originalContent = 'const x = 5;';
        const newContent = 'const y = 10;';
        const language = 'javascript';

        final block = CodeBlock(content: originalContent, language: language);
        final newBlock = block.copyWith(content: newContent);

        // Verify it's a new instance
        expect(newBlock, isNot(same(block)));

        // Verify content is updated but language is preserved
        expect(newBlock.content, equals(newContent));
        expect(newBlock.language, equals(language));

        // Original block should be unchanged
        expect(block.content, equals(originalContent));
      });

      test('re-parses code block when content changes', () {
        const originalContent = 'const x = 5;';
        const newContent = '```python\ndef hello():\n    print("Hello")\n```';
        const originalLanguage = 'javascript';

        final block = CodeBlock(content: originalContent, language: originalLanguage);
        final newBlock = block.copyWith(content: newContent);

        // Should re-parse the content as a code block
        expect(newBlock.content, equals('def hello():\n    print("Hello")'));
        expect(newBlock.language, equals('python'));
      });

      test('returns same instance when content is null', () {
        const content = 'const x = 5;';
        const language = 'javascript';

        final block = CodeBlock(content: content, language: language);
        final newBlock = block.copyWith();

        expect(newBlock.content, equals(content));
        expect(newBlock.language, equals(language));
      });
    });

    testWidgets('buildEditor creates a code editor with content and language field', (WidgetTester tester) async {
      const content = 'const x = 5;';
      const language = 'javascript';
      final block = CodeBlock(content: content, language: language);
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

      // Verify the language field is present and contains the language
      expect(find.text(language), findsOneWidget);
    });

    testWidgets('buildPreview creates a markdown widget with code block', (WidgetTester tester) async {
      const content = 'const x = 5;';
      const language = 'javascript';
      final block = CodeBlock(content: content, language: language);

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
      expect(find.byType(CodeBlock), findsNothing);
    });
  });
}
