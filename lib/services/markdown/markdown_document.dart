import 'blocks/markdown_block.dart';
import 'blocks/paragraph_block.dart';
import 'blocks/heading_block.dart';
import 'blocks/table_block.dart';
import 'blocks/code_block.dart';
import 'blocks/admonition_block.dart';
import 'blocks/cursor_aware_paragraph_block.dart';
import 'blocks/cursor_aware_heading_block.dart';
import 'blocks/cursor_aware_admonition_block.dart';

/// Represents a markdown document as a collection of blocks.
class MarkdownDocument {
  final List<MarkdownBlock> blocks;

  const MarkdownDocument({required this.blocks});

  /// Parse a markdown string into a document with blocks.
  factory MarkdownDocument.fromMarkdown(String markdown) {
    final blockStrings = _splitIntoBlocks(markdown);

    // Check for duplicate blocks in the split result
    final uniqueBlockStrings = <String>{};
    // ignore: unused_local_variable
    int duplicateCount = 0;
    for (final blockStr in blockStrings) {
      if (uniqueBlockStrings.contains(blockStr.trim())) {
        duplicateCount++;
      } else {
        uniqueBlockStrings.add(blockStr.trim());
      }
    }

    final blocks = blockStrings.map((blockStr) {
      final block = createBlockFromMarkdown(blockStr);
      return block;
    }).toList();

    // Check for duplicate blocks in the final result
    final blockContents = blocks.map((block) => block.content).toList();
    final uniqueBlockContents = <String>{};
    // ignore: unused_local_variable
    int finalDuplicateCount = 0;
    for (final content in blockContents) {
      if (uniqueBlockContents.contains(content.trim())) {
        finalDuplicateCount++;
      } else {
        uniqueBlockContents.add(content.trim());
      }
    }

    return MarkdownDocument(blocks: blocks);
  }

  /// Convert document back to markdown.
  String toMarkdown() {
    // Check for duplicate blocks in the document
    final blockContents = blocks.map((block) => block.content).toList();
    final uniqueBlockContents = <String>{};
    // ignore: unused_local_variable
    int duplicateCount = 0;
    for (int i = 0; i < blockContents.length; i++) {
      final content = blockContents[i];
      if (uniqueBlockContents.contains(content.trim())) {
        duplicateCount++;
      } else {
        uniqueBlockContents.add(content.trim());
      }
    }

    final blockTexts = blocks.map((block) {
      final markdown = block.toMarkdown();
      return markdown;
    }).toList();

    // Check for duplicate markdown blocks in the output
    final uniqueMarkdownBlocks = <String>{};
    // ignore: unused_local_variable
    int duplicateMarkdownCount = 0;
    for (int i = 0; i < blockTexts.length; i++) {
      final markdown = blockTexts[i];
      if (uniqueMarkdownBlocks.contains(markdown.trim())) {
        duplicateMarkdownCount++;
      } else {
        uniqueMarkdownBlocks.add(markdown.trim());
      }
    }

    final result = blockTexts.join('\n\n');

    // Check for potential duplication in the output
    final potentialBlocks = result.split('\n\n');

    // Check for duplicate blocks in the output
    final uniqueOutputBlocks = <String>{};
    int duplicateOutputCount = 0;
    for (final block in potentialBlocks) {
      if (block.trim().isNotEmpty) {
        if (uniqueOutputBlocks.contains(block.trim())) {
          duplicateOutputCount++;
        } else {
          uniqueOutputBlocks.add(block.trim());
        }
      }
    }

    return result;
  }

  /// Create a block of the appropriate type from markdown content.
  static MarkdownBlock createBlockFromMarkdown(String markdown) {
    final trimmedMarkdown = markdown.trim();

    // Check for code block
    if (trimmedMarkdown.startsWith('```')) {
      return CodeBlock.fromMarkdown(trimmedMarkdown);
    }

    // Check for admonition block
    if (trimmedMarkdown.startsWith(':::')) {
      return CursorAwareAdmonitionBlock.fromMarkdown(trimmedMarkdown);
    }

    // Check for heading
    if (trimmedMarkdown.startsWith('#')) {
      final match = RegExp(r'^(#{1,6})\s+(.+)$').firstMatch(trimmedMarkdown);
      if (match != null) {
        return CursorAwareHeadingBlock.fromMarkdown(trimmedMarkdown);
      }
    }

    // Check for table
    if (_isTable(trimmedMarkdown)) {
      return TableBlock.fromMarkdown(trimmedMarkdown);
    }

    // Default to paragraph
    return CursorAwareParagraphBlock(content: trimmedMarkdown);
  }

  /// Split markdown into logical blocks.
  static List<String> _splitIntoBlocks(String markdown) {
    final blocks = <String>[];
    final lines = markdown.split('\n');

    // Check for potential duplication in the input
    final potentialBlocks = markdown.split('\n\n');

    // Check for duplicate blocks in the input
    final uniqueBlocks = <String>{};
    // ignore: unused_local_variable
    int duplicateCount = 0;
    for (final block in potentialBlocks) {
      if (block.trim().isNotEmpty) {
        if (uniqueBlocks.contains(block.trim())) {
          duplicateCount++;
        } else {
          uniqueBlocks.add(block.trim());
        }
      }
    }

    String currentBlock = '';
    String blockType = '';

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // Handle empty lines - they typically separate blocks
      if (line.isEmpty) {
        if (blockType == 'code' || blockType == 'admonition') {
          // In code and admonition blocks, preserve empty lines
          currentBlock += '\n';
        } else if (currentBlock.isNotEmpty) {
          // End current block if not in code or admonition block
          blocks.add(currentBlock.trim());
          currentBlock = '';
          blockType = '';
        } else {}
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
          } else {}
          currentBlock = line;
          blockType = 'code';
        }
        continue;
      }

      // Handle admonition blocks
      if (line.startsWith(':::')) {
        // Start of admonition block
        if (currentBlock.isNotEmpty) {
          // End previous block if any
          blocks.add(currentBlock.trim());
          currentBlock = '';
        }
        currentBlock = line;
        blockType = 'admonition';
        continue;
      }

      // This section is now redundant since we handle empty lines in admonition blocks
      // in the main empty line handling section above

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
      if (line.startsWith('#') &&
          blockType != 'code' &&
          blockType != 'admonition') {
        if (currentBlock.isNotEmpty) {
          // End previous block if any
          blocks.add(currentBlock.trim());
          currentBlock = '';
        }
        blockType = 'heading';
      }

      // Handle paragraph after heading without blank line
      if (blockType == 'heading' &&
          !line.startsWith('#') &&
          !line.startsWith('```') &&
          !line.startsWith(':::') &&
          !_isTableRow(line)) {
        // Split the heading from the paragraph
        final headingLine = currentBlock.split('\n')[0];
        blocks.add(headingLine.trim());
        currentBlock = line;
        blockType = _determineBlockType(line);
        continue;
      }

      // Add line to current block
      if (currentBlock.isNotEmpty) {
        currentBlock += '\n$line';
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
    if (line.startsWith('- ') ||
        line.startsWith('* ') ||
        line.startsWith('+ ')) {
      return 'list';
    }
    if (line.startsWith('1. ') || RegExp(r'^\d+\. ').hasMatch(line)) {
      return 'ordered_list';
    }
    if (_isTableRow(line)) return 'table';
    if (line.startsWith('```')) return 'code';
    if (line.startsWith(':::')) return 'admonition';
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
