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
    print('Parsing markdown into blocks, length: ${markdown.length} chars');
    final blockStrings = _splitIntoBlocks(markdown);
    print('Split into ${blockStrings.length} blocks');

    // Check for duplicate blocks in the split result
    final uniqueBlockStrings = <String>{};
    int duplicateCount = 0;
    for (final blockStr in blockStrings) {
      if (uniqueBlockStrings.contains(blockStr.trim())) {
        duplicateCount++;
        print(
            'WARNING: Duplicate block detected after splitting: "${blockStr.substring(0, blockStr.length > 30 ? 30 : blockStr.length)}..."');
      } else {
        uniqueBlockStrings.add(blockStr.trim());
      }
    }
    print(
        'Unique blocks after splitting: ${uniqueBlockStrings.length}, Duplicates: $duplicateCount');

    final blocks = blockStrings.map((blockStr) {
      final block = createBlockFromMarkdown(blockStr);
      print('Created block of type: ${block.runtimeType}');
      return block;
    }).toList();

    // Check for duplicate blocks in the final result
    final blockContents = blocks.map((block) => block.content).toList();
    final uniqueBlockContents = <String>{};
    int finalDuplicateCount = 0;
    for (final content in blockContents) {
      if (uniqueBlockContents.contains(content.trim())) {
        finalDuplicateCount++;
        print(
            'WARNING: Duplicate block content in final blocks: "${content.substring(0, content.length > 30 ? 30 : content.length)}..."');
      } else {
        uniqueBlockContents.add(content.trim());
      }
    }
    print(
        'Unique block contents in final result: ${uniqueBlockContents.length}, Duplicates: $finalDuplicateCount');

    return MarkdownDocument(blocks: blocks);
  }

  /// Convert document back to markdown.
  String toMarkdown() {
    print('Converting document to markdown, ${blocks.length} blocks');

    // Check for duplicate blocks in the document
    final blockContents = blocks.map((block) => block.content).toList();
    final uniqueBlockContents = <String>{};
    int duplicateCount = 0;
    for (int i = 0; i < blockContents.length; i++) {
      final content = blockContents[i];
      if (uniqueBlockContents.contains(content.trim())) {
        duplicateCount++;
        print(
            'WARNING: Duplicate block content at index $i: "${content.substring(0, content.length > 30 ? 30 : content.length)}..."');
      } else {
        uniqueBlockContents.add(content.trim());
      }
    }
    print(
        'Unique block contents before serialization: ${uniqueBlockContents.length}, Duplicates: $duplicateCount');

    final blockTexts = blocks.map((block) {
      final markdown = block.toMarkdown();
      print('Block ${block.runtimeType}: ${markdown.length} chars');
      return markdown;
    }).toList();

    // Check for duplicate markdown blocks in the output
    final uniqueMarkdownBlocks = <String>{};
    int duplicateMarkdownCount = 0;
    for (int i = 0; i < blockTexts.length; i++) {
      final markdown = blockTexts[i];
      if (uniqueMarkdownBlocks.contains(markdown.trim())) {
        duplicateMarkdownCount++;
        print(
            'WARNING: Duplicate markdown at index $i: "${markdown.substring(0, markdown.length > 30 ? 30 : markdown.length)}..."');
      } else {
        uniqueMarkdownBlocks.add(markdown.trim());
      }
    }
    print(
        'Unique markdown blocks: ${uniqueMarkdownBlocks.length}, Duplicates: $duplicateMarkdownCount');

    final result = blockTexts.join('\n\n');
    print('Final markdown length: ${result.length} chars');

    // Check for potential duplication in the output
    final potentialBlocks = result.split('\n\n');
    print(
        'Potential blocks in output based on double newlines: ${potentialBlocks.length}');

    // Check for duplicate blocks in the output
    final uniqueOutputBlocks = <String>{};
    int duplicateOutputCount = 0;
    for (final block in potentialBlocks) {
      if (block.trim().isNotEmpty) {
        if (uniqueOutputBlocks.contains(block.trim())) {
          duplicateOutputCount++;
          print(
              'WARNING: Duplicate block in output: "${block.substring(0, block.length > 30 ? 30 : block.length)}..."');
        } else {
          uniqueOutputBlocks.add(block.trim());
        }
      }
    }
    print(
        'Unique blocks in output: ${uniqueOutputBlocks.length}, Duplicates: $duplicateOutputCount');

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

    print('Splitting markdown into blocks, ${lines.length} lines');
    print('Input markdown length: ${markdown.length} chars');

    // Check for potential duplication in the input
    final potentialBlocks = markdown.split('\n\n');
    print(
        'Potential blocks based on double newlines: ${potentialBlocks.length}');

    // Check for duplicate blocks in the input
    final uniqueBlocks = <String>{};
    int duplicateCount = 0;
    for (final block in potentialBlocks) {
      if (block.trim().isNotEmpty) {
        if (uniqueBlocks.contains(block.trim())) {
          duplicateCount++;
          print(
              'WARNING: Duplicate block detected in input: "${block.substring(0, block.length > 30 ? 30 : block.length)}..."');
        } else {
          uniqueBlocks.add(block.trim());
        }
      }
    }
    print(
        'Unique blocks in input: ${uniqueBlocks.length}, Duplicates: $duplicateCount');

    String currentBlock = '';
    String blockType = '';

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // Handle empty lines - they typically separate blocks
      if (line.isEmpty) {
        if (blockType == 'code' || blockType == 'admonition') {
          // In code and admonition blocks, preserve empty lines
          currentBlock += '\n';
          print('Line $i: Empty line in $blockType block, preserving');
        } else if (currentBlock.isNotEmpty) {
          // End current block if not in code or admonition block
          print('Line $i: Empty line, ending block of type "$blockType"');
          blocks.add(currentBlock.trim());
          print(
              'Added block: "${currentBlock.trim().substring(0, currentBlock.length > 20 ? 20 : currentBlock.length)}..."');
          currentBlock = '';
          blockType = '';
        } else {
          print('Line $i: Skipping empty line (no current block)');
        }
        continue;
      }

      // Handle code blocks
      if (line.startsWith('```')) {
        if (blockType == 'code') {
          // End of code block
          currentBlock += line;
          print('Line $i: End of code block, adding complete block');
          blocks.add(currentBlock.trim());
          currentBlock = '';
          blockType = '';
        } else {
          // Start of code block
          if (currentBlock.isNotEmpty) {
            // End previous block if any
            print(
                'Line $i: Start of code block, ending previous block of type "$blockType"');
            blocks.add(currentBlock.trim());
            currentBlock = '';
          } else {
            print('Line $i: Start of new code block');
          }
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
        currentBlock += '\n' + line;
        print('Line $i: Adding to existing block of type "$blockType"');
      } else {
        currentBlock = line;
        if (blockType.isEmpty) {
          blockType = _determineBlockType(line);
          print('Line $i: Starting new block of type "$blockType"');
        }
      }
    }

    // Add the last block if there is one
    if (currentBlock.isNotEmpty) {
      print('Adding final block of type "$blockType"');
      blocks.add(currentBlock.trim());
      print(
          'Added block: "${currentBlock.trim().substring(0, currentBlock.length > 20 ? 20 : currentBlock.length)}..."');
    }

    return blocks;
  }

  /// Determine the type of block based on the first line.
  static String _determineBlockType(String line) {
    if (line.startsWith('#')) return 'heading';
    if (line.startsWith('>')) return 'quote';
    if (line.startsWith('- ') || line.startsWith('* ') || line.startsWith('+ '))
      return 'list';
    if (line.startsWith('1. ') || RegExp(r'^\d+\. ').hasMatch(line))
      return 'ordered_list';
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
