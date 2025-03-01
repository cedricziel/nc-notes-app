import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_notes/services/markdown/markdown_document.dart';
import 'package:flutter_notes/services/markdown/blocks/paragraph_block.dart';
import 'package:flutter_notes/services/markdown/blocks/heading_block.dart';
import 'package:flutter_notes/services/markdown/blocks/code_block.dart';
import 'package:flutter_notes/services/markdown/blocks/admonition_block.dart';
import 'package:flutter_notes/services/markdown/blocks/table_block.dart';

void main() {
  group('MarkdownDocument', () {
    test('constructor sets blocks correctly', () {
      final blocks = [
        ParagraphBlock(content: 'Paragraph 1'),
        HeadingBlock(content: 'Heading', level: 2),
      ];

      final document = MarkdownDocument(blocks: blocks);

      expect(document.blocks, equals(blocks));
    });

    group('fromMarkdown', () {
      test('parses empty markdown to empty document', () {
        const markdown = '';
        final document = MarkdownDocument.fromMarkdown(markdown);

        expect(document.blocks, isEmpty);
      });

      test('parses single paragraph correctly', () {
        const markdown = 'This is a paragraph';
        final document = MarkdownDocument.fromMarkdown(markdown);

        expect(document.blocks.length, equals(1));
        expect(document.blocks[0], isA<ParagraphBlock>());
        expect(document.blocks[0].content, equals('This is a paragraph'));
      });

      test('parses single heading correctly', () {
        const markdown = '## This is a heading';
        final document = MarkdownDocument.fromMarkdown(markdown);

        expect(document.blocks.length, equals(1));
        expect(document.blocks[0], isA<HeadingBlock>());
        expect((document.blocks[0] as HeadingBlock).level, equals(2));
        expect(document.blocks[0].content, equals('This is a heading'));
      });

      test('parses single code block correctly', () {
        const markdown = '```javascript\nconst x = 5;\n```';
        final document = MarkdownDocument.fromMarkdown(markdown);

        expect(document.blocks.length, equals(1));
        expect(document.blocks[0], isA<CodeBlock>());
        expect((document.blocks[0] as CodeBlock).language, equals('javascript'));
        expect(document.blocks[0].content, equals('const x = 5;'));
      });

      test('parses single admonition block correctly', () {
        const markdown = ':::info\nThis is an info admonition\n:::';
        final document = MarkdownDocument.fromMarkdown(markdown);

        expect(document.blocks.length, equals(1));
        expect(document.blocks[0], isA<AdmonitionBlock>());
        expect((document.blocks[0] as AdmonitionBlock).type, equals('info'));
        expect(document.blocks[0].content, equals('This is an info admonition'));
      });

      test('parses single table correctly', () {
        const markdown = '| Header 1 | Header 2 |\n| --- | --- |\n| Cell 1 | Cell 2 |';
        final document = MarkdownDocument.fromMarkdown(markdown);

        expect(document.blocks.length, equals(1));
        expect(document.blocks[0], isA<TableBlock>());
        expect((document.blocks[0] as TableBlock).cells, equals([
          ['Header 1', 'Header 2'],
          ['Cell 1', 'Cell 2']
        ]));
      });

      test('parses multiple blocks correctly', () {
        const markdown = '# Heading\n\nParagraph 1\n\n```javascript\nconst x = 5;\n```\n\n:::info\nInfo block\n:::\n\n| Header 1 | Header 2 |\n| --- | --- |\n| Cell 1 | Cell 2 |';
        final document = MarkdownDocument.fromMarkdown(markdown);

        expect(document.blocks.length, equals(5));
        expect(document.blocks[0], isA<HeadingBlock>());
        expect(document.blocks[1], isA<ParagraphBlock>());
        expect(document.blocks[2], isA<CodeBlock>());
        expect(document.blocks[3], isA<AdmonitionBlock>());
        expect(document.blocks[4], isA<TableBlock>());
      });

      test('handles blocks without proper separation', () {
        // No blank line between heading and paragraph
        const markdown = '# Heading\nParagraph';
        final document = MarkdownDocument.fromMarkdown(markdown);

        // Should still be parsed as two separate blocks
        expect(document.blocks.length, equals(2));
        expect(document.blocks[0], isA<HeadingBlock>());
        expect(document.blocks[1], isA<ParagraphBlock>());
      });

      test('handles adjacent blocks of the same type', () {
        // Two paragraphs with proper separation
        const markdown = 'Paragraph 1\n\nParagraph 2';
        final document = MarkdownDocument.fromMarkdown(markdown);

        expect(document.blocks.length, equals(2));
        expect(document.blocks[0], isA<ParagraphBlock>());
        expect(document.blocks[0].content, equals('Paragraph 1'));
        expect(document.blocks[1], isA<ParagraphBlock>());
        expect(document.blocks[1].content, equals('Paragraph 2'));
      });

      test('preserves empty lines in code blocks', () {
        const markdown = '```python\ndef hello():\n\nprint("Hello")\n```';
        final document = MarkdownDocument.fromMarkdown(markdown);

        expect(document.blocks.length, equals(1));
        expect(document.blocks[0], isA<CodeBlock>());
        expect(document.blocks[0].content, equals('def hello():\n\nprint("Hello")'));
      });

      test('handles malformed blocks gracefully', () {
        // Malformed table without separator row
        const markdown = '| Header 1 | Header 2 |\n| Cell 1 | Cell 2 |';
        final document = MarkdownDocument.fromMarkdown(markdown);

        expect(document.blocks.length, equals(1));
        expect(document.blocks[0], isA<TableBlock>());
      });
    });

    group('toMarkdown', () {
      test('converts empty document to empty string', () {
        final document = MarkdownDocument(blocks: []);

        expect(document.toMarkdown(), equals(''));
      });

      test('converts single paragraph correctly', () {
        final document = MarkdownDocument(blocks: [
          ParagraphBlock(content: 'This is a paragraph'),
        ]);

        expect(document.toMarkdown(), equals('This is a paragraph'));
      });

      test('converts single heading correctly', () {
        final document = MarkdownDocument(blocks: [
          HeadingBlock(content: 'This is a heading', level: 2),
        ]);

        expect(document.toMarkdown(), equals('## This is a heading'));
      });

      test('converts single code block correctly', () {
        final document = MarkdownDocument(blocks: [
          CodeBlock(content: 'const x = 5;', language: 'javascript'),
        ]);

        expect(document.toMarkdown(), equals('```javascript\nconst x = 5;\n```'));
      });

      test('converts single admonition block correctly', () {
        final document = MarkdownDocument(blocks: [
          AdmonitionBlock(content: 'This is an info admonition', type: 'info'),
        ]);

        expect(document.toMarkdown(), equals(':::info\nThis is an info admonition\n:::'));
      });

      test('converts single table correctly', () {
        final cells = [
          ['Header 1', 'Header 2'],
          ['Cell 1', 'Cell 2']
        ];
        const content = '| Header 1 | Header 2 |\n| --- | --- |\n| Cell 1 | Cell 2 |';

        final document = MarkdownDocument(blocks: [
          TableBlock(content: content, cells: cells, hasHeader: true),
        ]);

        expect(document.toMarkdown(), equals(content));
      });

      test('converts multiple blocks with proper separation', () {
        final document = MarkdownDocument(blocks: [
          HeadingBlock(content: 'Heading', level: 1),
          ParagraphBlock(content: 'Paragraph 1'),
          CodeBlock(content: 'const x = 5;', language: 'javascript'),
        ]);

        expect(document.toMarkdown(), equals('# Heading\n\nParagraph 1\n\n```javascript\nconst x = 5;\n```'));
      });
    });

    group('round-trip conversion', () {
      test('markdown -> document -> markdown preserves content', () {
        const originalMarkdown = '# Heading\n\nParagraph 1\n\n```javascript\nconst x = 5;\n```\n\n:::info\nInfo block\n:::\n\n| Header 1 | Header 2 |\n| --- | --- |\n| Cell 1 | Cell 2 |';

        final document = MarkdownDocument.fromMarkdown(originalMarkdown);
        final regeneratedMarkdown = document.toMarkdown();

        // The regenerated markdown might have slight formatting differences
        // but should contain all the same blocks with the same content

        // To verify, we'll parse it again and check the blocks
        final reparsedDocument = MarkdownDocument.fromMarkdown(regeneratedMarkdown);

        expect(reparsedDocument.blocks.length, equals(document.blocks.length));

        for (var i = 0; i < document.blocks.length; i++) {
          expect(reparsedDocument.blocks[i].runtimeType, equals(document.blocks[i].runtimeType));
          expect(reparsedDocument.blocks[i].content, equals(document.blocks[i].content));
        }
      });

      test('document -> markdown -> document preserves blocks', () {
        final originalDocument = MarkdownDocument(blocks: [
          HeadingBlock(content: 'Heading', level: 1),
          ParagraphBlock(content: 'Paragraph 1'),
          CodeBlock(content: 'const x = 5;', language: 'javascript'),
          AdmonitionBlock(content: 'Info block', type: 'info'),
          TableBlock(
            content: '| Header 1 | Header 2 |\n| --- | --- |\n| Cell 1 | Cell 2 |',
            cells: [
              ['Header 1', 'Header 2'],
              ['Cell 1', 'Cell 2']
            ],
            hasHeader: true,
          ),
        ]);

        final markdown = originalDocument.toMarkdown();
        final reparsedDocument = MarkdownDocument.fromMarkdown(markdown);

        expect(reparsedDocument.blocks.length, equals(originalDocument.blocks.length));

        for (var i = 0; i < originalDocument.blocks.length; i++) {
          expect(reparsedDocument.blocks[i].runtimeType, equals(originalDocument.blocks[i].runtimeType));
          expect(reparsedDocument.blocks[i].content, equals(originalDocument.blocks[i].content));
        }
      });
    });

    group('createBlockFromMarkdown', () {
      test('creates paragraph block for plain text', () {
        const markdown = 'This is a paragraph';
        final block = MarkdownDocument.createBlockFromMarkdown(markdown);

        expect(block, isA<ParagraphBlock>());
        expect(block.content, equals(markdown));
      });

      test('creates heading block for heading text', () {
        const markdown = '## This is a heading';
        final block = MarkdownDocument.createBlockFromMarkdown(markdown);

        expect(block, isA<HeadingBlock>());
        expect(block.content, equals('This is a heading'));
        expect((block as HeadingBlock).level, equals(2));
      });

      test('creates code block for code fence', () {
        const markdown = '```javascript\nconst x = 5;\n```';
        final block = MarkdownDocument.createBlockFromMarkdown(markdown);

        expect(block, isA<CodeBlock>());
        expect(block.content, equals('const x = 5;'));
        expect((block as CodeBlock).language, equals('javascript'));
      });

      test('creates admonition block for admonition marker', () {
        const markdown = ':::info\nThis is an info admonition\n:::';
        final block = MarkdownDocument.createBlockFromMarkdown(markdown);

        expect(block, isA<AdmonitionBlock>());
        expect(block.content, equals('This is an info admonition'));
        expect((block as AdmonitionBlock).type, equals('info'));
      });

      test('creates table block for table markdown', () {
        const markdown = '| Header 1 | Header 2 |\n| --- | --- |\n| Cell 1 | Cell 2 |';
        final block = MarkdownDocument.createBlockFromMarkdown(markdown);

        expect(block, isA<TableBlock>());
        expect((block as TableBlock).cells, equals([
          ['Header 1', 'Header 2'],
          ['Cell 1', 'Cell 2']
        ]));
      });
    });

    group('Block splitting behavior', () {
      test('splits paragraphs by blank lines', () {
        const markdown = 'Paragraph 1\n\nParagraph 2\n\nParagraph 3';
        final document = MarkdownDocument.fromMarkdown(markdown);

        expect(document.blocks.length, equals(3));
        expect(document.blocks[0].content, equals('Paragraph 1'));
        expect(document.blocks[1].content, equals('Paragraph 2'));
        expect(document.blocks[2].content, equals('Paragraph 3'));
      });

      test('keeps code blocks intact with empty lines', () {
        const markdown = 'Paragraph\n\n```javascript\nconst x = 5;\n\nconst y = 10;\n```\n\nAnother paragraph';
        final document = MarkdownDocument.fromMarkdown(markdown);

        expect(document.blocks.length, equals(3));
        expect(document.blocks[0].content, equals('Paragraph'));
        expect(document.blocks[1], isA<CodeBlock>());
        expect(document.blocks[1].content, equals('const x = 5;\n\nconst y = 10;'));
        expect(document.blocks[2].content, equals('Another paragraph'));
      });

      test('keeps admonition blocks intact with empty lines', () {
        const markdown = 'Paragraph\n\n:::info\nLine 1\n\nLine 2\n:::\n\nAnother paragraph';
        final document = MarkdownDocument.fromMarkdown(markdown);

        // Print the actual blocks for debugging
        for (var i = 0; i < document.blocks.length; i++) {
          print('Block $i: ${document.blocks[i].runtimeType} - "${document.blocks[i].content}"');
        }

        expect(document.blocks.length, equals(3));
        expect(document.blocks[0].content, equals('Paragraph'));
        expect(document.blocks[1], isA<AdmonitionBlock>());
        expect(document.blocks[1].content, equals('Line 1\n\nLine 2'));
        expect(document.blocks[2].content, equals('Another paragraph'));
      });

      test('keeps table blocks intact', () {
        const markdown = 'Paragraph\n\n| Header 1 | Header 2 |\n| --- | --- |\n| Cell 1 | Cell 2 |\n\nAnother paragraph';
        final document = MarkdownDocument.fromMarkdown(markdown);

        expect(document.blocks.length, equals(3));
        expect(document.blocks[0].content, equals('Paragraph'));
        expect(document.blocks[1], isA<TableBlock>());
        expect(document.blocks[2].content, equals('Another paragraph'));
      });

      test('handles empty input', () {
        const markdown = '';
        final document = MarkdownDocument.fromMarkdown(markdown);

        expect(document.blocks, isEmpty);
      });

      test('handles input with only whitespace', () {
        const markdown = '   \n\n   ';
        final document = MarkdownDocument.fromMarkdown(markdown);

        expect(document.blocks, isEmpty);
      });
    });

    group('Table detection', () {
      test('identifies valid table', () {
        const markdown = '| Header 1 | Header 2 |\n| --- | --- |\n| Cell 1 | Cell 2 |';
        final document = MarkdownDocument.fromMarkdown(markdown);

        expect(document.blocks.length, equals(1));
        expect(document.blocks[0], isA<TableBlock>());
      });

      test('handles table without separator row', () {
        const markdown = '| Cell 1 | Cell 2 |\n| Cell 3 | Cell 4 |';
        final document = MarkdownDocument.fromMarkdown(markdown);

        expect(document.blocks.length, equals(1));
        expect(document.blocks[0], isA<TableBlock>());
        expect((document.blocks[0] as TableBlock).hasHeader, isFalse);
      });
    });

    group('Block type detection', () {
      test('identifies different block types correctly', () {
        const markdown = '# Heading\n\n> Quote\n\n- List item\n\n1. Ordered item\n\n| Cell 1 | Cell 2 |\n| --- | --- |\n| Data 1 | Data 2 |\n\n```javascript\nconst x = 5;\n```\n\n:::info\nInfo block\n:::\n\nRegular paragraph';
        final document = MarkdownDocument.fromMarkdown(markdown);

        expect(document.blocks.length, equals(8));
        expect(document.blocks[0], isA<HeadingBlock>());
        expect(document.blocks[1], isA<ParagraphBlock>()); // Quote is treated as paragraph
        expect(document.blocks[2], isA<ParagraphBlock>()); // List is treated as paragraph
        expect(document.blocks[3], isA<ParagraphBlock>()); // Ordered list is treated as paragraph
        expect(document.blocks[4], isA<TableBlock>());
        expect(document.blocks[5], isA<CodeBlock>());
        expect(document.blocks[6], isA<AdmonitionBlock>());
        expect(document.blocks[7], isA<ParagraphBlock>()); // Regular paragraph
      });
    });
  });
}
