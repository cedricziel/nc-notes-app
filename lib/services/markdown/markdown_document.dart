import 'blocks/markdown_block.dart';
import 'blocks/paragraph_block.dart';
import 'blocks/heading_block.dart';
import 'blocks/table_block.dart';
import 'blocks/code_block.dart';

/// Represents a markdown document as a collection of blocks.
class MarkdownDocument {
  final List<MarkdownBlock> blocks;

  const MarkdownDocument({required this.blocks});

  /// Parse a markdown string into a document with blocks.
  factory MarkdownDocument.fromMarkdown(String markdown) {
    final blockStrings = _splitIntoBlocks(markdown);
    final blocks = blockStrings.map((blockStr) => createBlockFromMarkdown(blockStr)).toList();
    return MarkdownDocument(blocks: blocks);
  }

  /// Convert document back to markdown.
  String toMarkdown() {
    return blocks.map((block) => block.toMarkdown()).join('\n\n');
  }

  /// Create a block of the appropriate type from markdown content.
  static MarkdownBlock createBlockFromMarkdown(String markdown) {
    final trimmedMarkdown = markdown.trim();

    // Check for code block
    if (trimmedMarkdown.startsWith('```')) {
      return CodeBlock.fromMarkdown(trimmedMarkdown);
    }

    // Check for heading
    if (trimmedMarkdown.startsWith('#')) {
      final match = RegExp(r'^(#{1,6})\s+(.+)$').firstMatch(trimmedMarkdown);
      if (match != null) {
        return HeadingBlock.fromMarkdown(trimmedMarkdown);
      }
    }

    // Check for table
    if (_isTable(trimmedMarkdown)) {
      return TableBlock.fromMarkdown(trimmedMarkdown);
    }

    // Default to paragraph
    return ParagraphBlock(content: trimmedMarkdown);
  }

  /// Split markdown into logical blocks.
  static List<String> _splitIntoBlocks(String markdown) {
    final blocks = <String>[];
    final lines = markdown.split('\n');

    String currentBlock = '';
    String blockType = '';

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // Handle empty lines - they typically separate blocks
      if (line.isEmpty) {
        if (blockType == 'code') {
          // In code blocks, preserve empty lines
          currentBlock += '\n';
        } else if (currentBlock.isNotEmpty) {
          // End current block if not in code block
          blocks.add(currentBlock.trim());
          currentBlock = '';
          blockType = '';
        }
        continue;
      }

      // Handle code blocks
      if (line.startsWith('```')) {
        if (blockType == 'code') {
          // End of code block
          currentBlock += line;
          blocks.add(currentBlock.trim());
          currentBlock = '';
          blockType = '';
        } else {
          // Start of code block
          if (currentBlock.isNotEmpty) {
            // End previous block if any
            blocks.add(currentBlock.trim());
            currentBlock = '';
          }
          currentBlock = line;
          blockType = 'code';
        }
        continue;
      }

      // Handle tables
      if (_isTableRow(line)) {
        if (blockType != 'table' && blockType != 'code') {
          // Start of table
          if (currentBlock.isNotEmpty) {
            // End previous block if any
            blocks.add(currentBlock.trim());
            currentBlock = '';
          }
          blockType = 'table';
        }
      } else if (blockType == 'table') {
        // End of table
        blocks.add(currentBlock.trim());
        currentBlock = '';
        blockType = _determineBlockType(line);
      }

      // Handle headings
      if (line.startsWith('#') && blockType != 'code') {
        if (currentBlock.isNotEmpty) {
          // End previous block if any
          blocks.add(currentBlock.trim());
          currentBlock = '';
        }
        blockType = 'heading';
      }

      // Add line to current block
      if (currentBlock.isNotEmpty) {
        currentBlock += '\n' + line;
      } else {
        currentBlock = line;
        if (blockType.isEmpty) {
          blockType = _determineBlockType(line);
        }
      }
    }

    // Add the last block if there is one
    if (currentBlock.isNotEmpty) {
      blocks.add(currentBlock.trim());
    }

    return blocks;
  }

  /// Determine the type of block based on the first line.
  static String _determineBlockType(String line) {
    if (line.startsWith('#')) return 'heading';
    if (line.startsWith('>')) return 'quote';
    if (line.startsWith('- ') || line.startsWith('* ') || line.startsWith('+ ')) return 'list';
    if (line.startsWith('1. ') || RegExp(r'^\d+\. ').hasMatch(line)) return 'ordered_list';
    if (_isTableRow(line)) return 'table';
    if (line.startsWith('```')) return 'code';
    return 'paragraph';
  }

  /// Check if a line is a table row.
  static bool _isTableRow(String line) {
    return line.startsWith('|') && line.endsWith('|');
  }

  /// Check if a block is a table.
  static bool _isTable(String block) {
    final lines = block.split('\n');
    if (lines.length < 2) return false;

    // Check if first line is a table row
    if (!_isTableRow(lines[0])) return false;

    // Check if second line is a separator row
    if (lines.length > 1) {
      final secondLine = lines[1].trim();
      if (secondLine.startsWith('|') &&
          secondLine.endsWith('|') &&
          secondLine.contains('---')) {
        return true;
      }
    }

    // If we have multiple lines with pipe characters, it's likely a table
    int pipeLineCount = 0;
    for (final line in lines) {
      if (_isTableRow(line)) pipeLineCount++;
    }

    return pipeLineCount >= 2;
  }
}
