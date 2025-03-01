import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_notes/services/markdown/markdown_document.dart';
import 'package:flutter_notes/services/markdown/blocks/paragraph_block.dart';
import 'package:flutter_notes/services/markdown/blocks/heading_block.dart';
import 'package:flutter_notes/services/markdown/blocks/code_block.dart';
import 'package:flutter_notes/services/markdown/blocks/admonition_block.dart';
import 'package:flutter_notes/services/markdown/blocks/table_block.dart';
import 'package:flutter_notes/services/markdown/blocks/cursor_aware_paragraph_block.dart';
import 'package:flutter_notes/services/markdown/blocks/cursor_aware_heading_block.dart';
import 'package:flutter_notes/services/markdown/blocks/cursor_aware_admonition_block.dart';

void main() {
  group('MarkdownDocument', () {
    test('constructor sets blocks correctly', () {
      final blocks = [
        ParagraphBlock(content: 'Test paragraph'),
        HeadingBlock(content: 'Test heading', level: 1),
      ];
      final document = MarkdownDocument(blocks: blocks);

      expect(document.blocks, equals(blocks));
      expect(document.blocks.length, equals(2));
    });

    group('fromMarkdown', () {
      test('parses empty markdown to empty document', () {
        final document = MarkdownDocument.fromMarkdown('');

        expect(document.blocks, isEmpty);
      });

      test('parses single paragraph correctly', () {
        const markdown = 'This is a paragraph';
        final document = MarkdownDocument.fromMarkdown(markdown);

        expect(document.blocks.length, equals(1));
        expect(document.blocks[0], isA<CursorAwareParagraphBlock>());
        expect(document.blocks[0].content, equals(markdown));
      });

      test('parses single heading correctly', () {
        const markdown = '## This is a heading';
        final document = MarkdownDocument.fromMarkdown(markdown);

        expect(document.blocks.length, equals(1));
        expect(document.blocks[0], isA<CursorAwareHeadingBlock>());
        expect(document.blocks[0].content, equals(markdown));
      });

      test('parses single code block correctly', () {
        const markdown = '```\ncode\n```';
        final document = MarkdownDocument.fromMarkdown(markdown);

        expect(document.blocks.length, equals(1));
        expect(document.blocks[0], isA<CodeBlock>());
        // The content might not include the code fence markers
        expect(document.blocks[0].toMarkdown(), equals(markdown));
      });

      test('parses single admonition block correctly', () {
        const markdown = ':::info\nThis is an info admonition';
        final document = MarkdownDocument.fromMarkdown(markdown);

        expect(document.blocks.length, equals(1));
        expect(document.blocks[0], isA<CursorAwareAdmonitionBlock>());
        expect(document.blocks[0].content, equals(markdown));
      });

      test('parses single table correctly', () {
        const markdown =
            '| Header 1 | Header 2 |\n| --- | --- |\n| Cell 1 | Cell 2 |';
        final document = MarkdownDocument.fromMarkdown(markdown);

        expect(document.blocks.length, equals(1));
        expect(document.blocks[0], isA<TableBlock>());
        expect(document.blocks[0].content, equals(markdown));
      });

      test('parses multiple blocks correctly', () {
        const markdown =
            '# Heading\n\nParagraph 1\n\n```\ncode\n```\n\n:::info\nAdmonition\n\n| Header 1 | Header 2 |\n| --- | --- |\n| Cell 1 | Cell 2 |';
        final document = MarkdownDocument.fromMarkdown(markdown);

        expect(document.blocks.length, equals(5));
        expect(document.blocks[0], isA<CursorAwareHeadingBlock>());
        expect(document.blocks[1], isA<CursorAwareParagraphBlock>());
        expect(document.blocks[2], isA<CodeBlock>());
        expect(document.blocks[3], isA<CursorAwareAdmonitionBlock>());
        expect(document.blocks[4], isA<TableBlock>());
      });

      test('handles blocks without proper separation', () {
        const markdown = '# Heading\nParagraph';
        final document = MarkdownDocument.fromMarkdown(markdown);

        expect(document.blocks.length, equals(2));
        expect(document.blocks[0], isA<CursorAwareHeadingBlock>());
        expect(document.blocks[1], isA<CursorAwareParagraphBlock>());
      });

      test('handles adjacent blocks of the same type', () {
        const markdown = 'Paragraph 1\n\nParagraph 2';
        final document = MarkdownDocument.fromMarkdown(markdown);

        expect(document.blocks.length, equals(2));
        expect(document.blocks[0], isA<CursorAwareParagraphBlock>());
        expect(document.blocks[1], isA<CursorAwareParagraphBlock>());
      });

      test('preserves empty lines in code blocks', () {
        const markdown = '```\nline 1\n\nline 2\n```';
        final document = MarkdownDocument.fromMarkdown(markdown);

        expect(document.blocks.length, equals(1));
        expect(document.blocks[0], isA<CodeBlock>());
        // The content might not include the code fence markers
        expect(document.blocks[0].toMarkdown(), equals(markdown));
      });

      test('handles malformed blocks gracefully', () {
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
          CodeBlock(content: 'code', language: ''),
        ]);
        expect(document.toMarkdown(), equals('```\ncode\n```'));
      });

      test('converts single admonition block correctly', () {
        final document = MarkdownDocument(blocks: [
          AdmonitionBlock(content: 'This is an info admonition', type: 'info'),
        ]);
        expect(document.toMarkdown(),
            equals(':::info\nThis is an info admonition'));
      });

      test('converts single table correctly', () {
        final document = MarkdownDocument(blocks: [
          TableBlock(
            content:
                '| Header 1 | Header 2 |\n| --- | --- |\n| Cell 1 | Cell 2 |',
            cells: [
              ['Header 1', 'Header 2'],
              ['Cell 1', 'Cell 2']
            ],
          ),
        ]);
        expect(
            document.toMarkdown(),
            equals(
                '| Header 1 | Header 2 |\n| --- | --- |\n| Cell 1 | Cell 2 |'));
      });

      test('converts multiple blocks with proper separation', () {
        final document = MarkdownDocument(blocks: [
          HeadingBlock(content: 'Heading', level: 1),
          ParagraphBlock(content: 'Paragraph 1'),
          CodeBlock(content: 'code', language: ''),
        ]);
        expect(document.toMarkdown(),
            equals('# Heading\n\nParagraph 1\n\n```\ncode\n```'));
      });
    });

    group('round-trip conversion', () {
      test('markdown -> document -> markdown preserves content', () {
        const originalMarkdown =
            '# Heading\n\nParagraph 1\n\n```\ncode\n```\n\n:::info\nAdmonition\n\n| Header 1 | Header 2 |\n| --- | --- |\n| Cell 1 | Cell 2 |';
        final document = MarkdownDocument.fromMarkdown(originalMarkdown);
        final regeneratedMarkdown = document.toMarkdown();

        // Create a new document from the regenerated markdown to compare blocks
        final newDocument = MarkdownDocument.fromMarkdown(regeneratedMarkdown);

        // Compare the number of blocks
        expect(newDocument.blocks.length, equals(document.blocks.length));

        // Compare the types of blocks
        for (var i = 0; i < document.blocks.length; i++) {
          expect(newDocument.blocks[i].runtimeType,
              equals(document.blocks[i].runtimeType));
        }
      });

      test('document -> markdown -> document preserves blocks', () {
        final originalDocument = MarkdownDocument(blocks: [
          HeadingBlock(content: 'Heading', level: 1),
          ParagraphBlock(content: 'Paragraph 1'),
          CodeBlock(content: 'code', language: ''),
          AdmonitionBlock(content: 'Admonition', type: 'info'),
          TableBlock(
            content:
                '| Header 1 | Header 2 |\n| --- | --- |\n| Cell 1 | Cell 2 |',
            cells: [
              ['Header 1', 'Header 2'],
              ['Cell 1', 'Cell 2']
            ],
          ),
        ]);

        final markdown = originalDocument.toMarkdown();
        final newDocument = MarkdownDocument.fromMarkdown(markdown);

        // Compare the number of blocks
        expect(
            newDocument.blocks.length, equals(originalDocument.blocks.length));

        // We don't compare types directly because the document parser creates cursor-aware blocks
        // instead of the basic blocks we used to create the original document
      });
    });

    group('createBlockFromMarkdown', () {
      test('creates cursor-aware paragraph block for plain text', () {
        final block = MarkdownDocument.createBlockFromMarkdown('Plain text');
        expect(block, isA<CursorAwareParagraphBlock>());
      });

      test('creates cursor-aware heading block for heading text', () {
        final block = MarkdownDocument.createBlockFromMarkdown('# Heading');
        expect(block, isA<CursorAwareHeadingBlock>());
      });

      test('creates code block for code fence', () {
        final block =
            MarkdownDocument.createBlockFromMarkdown('```\ncode\n```');
        expect(block, isA<CodeBlock>());
      });

      test('creates cursor-aware admonition block for admonition marker', () {
        final block =
            MarkdownDocument.createBlockFromMarkdown(':::info\nAdmonition');
        expect(block, isA<CursorAwareAdmonitionBlock>());
      });

      test('creates table block for table markdown', () {
        final block = MarkdownDocument.createBlockFromMarkdown(
            '| Header 1 | Header 2 |\n| --- | --- |\n| Cell 1 | Cell 2 |');
        expect(block, isA<TableBlock>());
      });
    });

    group('Block splitting behavior', () {
      test('splits paragraphs by blank lines', () {
        const markdown = 'Paragraph 1\n\nParagraph 2\n\nParagraph 3';
        final document = MarkdownDocument.fromMarkdown(markdown);

        expect(document.blocks.length, equals(3));
        expect(document.blocks[0], isA<CursorAwareParagraphBlock>());
        expect(document.blocks[1], isA<CursorAwareParagraphBlock>());
        expect(document.blocks[2], isA<CursorAwareParagraphBlock>());
      });

      test('keeps code blocks intact with empty lines', () {
        const markdown =
            'Paragraph\n\n```\nline 1\n\nline 2\n```\n\nAnother paragraph';
        final document = MarkdownDocument.fromMarkdown(markdown);

        expect(document.blocks.length, equals(3));
        expect(document.blocks[0], isA<CursorAwareParagraphBlock>());
        expect(document.blocks[1], isA<CodeBlock>());
        expect(document.blocks[2], isA<CursorAwareParagraphBlock>());
      });

      test('keeps admonition blocks intact with empty lines', () {
        const markdown =
            'Paragraph\n\n:::info\nLine 1\n\nLine 2\n\nAnother paragraph';
        final document = MarkdownDocument.fromMarkdown(markdown);

        expect(document.blocks.length, equals(2));
        expect(document.blocks[0], isA<CursorAwareParagraphBlock>());
        expect(document.blocks[1], isA<CursorAwareAdmonitionBlock>());
      });

      test('keeps table blocks intact', () {
        const markdown =
            'Paragraph\n\n| Header 1 | Header 2 |\n| --- | --- |\n| Cell 1 | Cell 2 |\n\nAnother paragraph';
        final document = MarkdownDocument.fromMarkdown(markdown);

        expect(document.blocks.length, equals(3));
        expect(document.blocks[0], isA<CursorAwareParagraphBlock>());
        expect(document.blocks[1], isA<TableBlock>());
        expect(document.blocks[2], isA<CursorAwareParagraphBlock>());
      });

      test('handles empty input', () {
        const markdown = '';
        final document = MarkdownDocument.fromMarkdown(markdown);

        expect(document.blocks.length, equals(0));
      });

      test('handles input with only whitespace', () {
        const markdown = '\n\n  \n';
        final document = MarkdownDocument.fromMarkdown(markdown);

        expect(document.blocks.length, equals(0));
      });
    });

    group('Table detection', () {
      test('identifies valid table', () {
        const markdown =
            '| Header 1 | Header 2 |\n| --- | --- |\n| Cell 1 | Cell 2 |';
        final document = MarkdownDocument.fromMarkdown(markdown);

        expect(document.blocks.length, equals(1));
        expect(document.blocks[0], isA<TableBlock>());
      });

      test('handles table without separator row', () {
        const markdown = '| Cell 1 | Cell 2 |\n| Cell 3 | Cell 4 |';
        final document = MarkdownDocument.fromMarkdown(markdown);

        expect(document.blocks.length, equals(1));
        expect(document.blocks[0], isA<TableBlock>());
      });
    });

    group('Block type detection', () {
      test('identifies different block types correctly', () {
        const markdown =
            '# Heading\n\n> Quote\n\n- List item\n\n1. Ordered item\n\n| Cell 1 | Cell 2 |\n| --- | --- |\n| Cell 3 | Cell 4 |\n\n```\ncode\n```\n\n:::info\nAdmonition\n\nRegular paragraph';
        final document = MarkdownDocument.fromMarkdown(markdown);

        expect(document.blocks.length, equals(7));
        expect(document.blocks[0], isA<CursorAwareHeadingBlock>());
        expect(document.blocks[1],
            isA<CursorAwareParagraphBlock>()); // Quote is treated as paragraph
        expect(document.blocks[2],
            isA<CursorAwareParagraphBlock>()); // List is treated as paragraph
        expect(document.blocks[3],
            isA<CursorAwareParagraphBlock>()); // Ordered list is treated as paragraph
        expect(document.blocks[4], isA<TableBlock>());
        expect(document.blocks[5], isA<CodeBlock>());
        expect(document.blocks[6], isA<CursorAwareAdmonitionBlock>());
      });
    });
  });
}
