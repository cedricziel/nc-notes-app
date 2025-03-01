import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../editors/table_editor.dart';
import 'markdown_block.dart';

class TableBlock extends MarkdownBlock {
  final List<List<String>> cells;
  final bool hasHeader;

  const TableBlock({
    required super.content,
    required this.cells,
    this.hasHeader = true,
  });

  // Parse markdown table into cells
  factory TableBlock.fromMarkdown(String markdown) {
    final lines = markdown.split('\n');
    final cells = <List<String>>[];
    bool hasHeader = false;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // Skip separator line but note that we have a header
      if (i == 1 && line.contains('---')) {
        hasHeader = true;
        continue;
      }

      if (line.startsWith('|') && line.endsWith('|')) {
        // Remove outer pipes and split by pipe
        final rowContent = line.substring(1, line.length - 1);
        final rowCells =
            rowContent.split('|').map((cell) => cell.trim()).toList();
        cells.add(rowCells);
      }
    }

    // If we have an empty table or parsing failed, create a default table
    if (cells.isEmpty) {
      cells.add(['Header 1', 'Header 2']);
      cells.add(['Cell 1', 'Cell 2']);
      hasHeader = true;
    }

    return TableBlock(
      content: markdown,
      cells: cells,
      hasHeader: hasHeader,
    );
  }

  @override
  Widget buildEditor(BuildContext context, ValueChanged<String> onChanged,
      {bool isFocused = false, ValueChanged<bool>? onFocusChanged}) {
    return TableEditor(
      initialCells: cells,
      initialHasHeader: hasHeader,
      onChanged: (newCells, newHasHeader) {
        final newContent = _generateMarkdownTable(newCells, newHasHeader);
        onChanged(newContent);
      },
    );
  }

  @override
  Widget buildPreview(BuildContext context) {
    return Markdown(
      data: content,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
    );
  }

  @override
  String toMarkdown() => content;

  @override
  TableBlock copyWith({String? content}) {
    if (content == null) return this;

    // If content has changed
    if (content != this.content) {
      // Check if the content looks like a markdown table
      if (content.trim().startsWith('|') && content.contains('|')) {
        // Re-parse as a markdown table
        return TableBlock.fromMarkdown(content);
      } else {
        // Just update the content, preserving the cells and hasHeader
        return TableBlock(content: content, cells: cells, hasHeader: hasHeader);
      }
    }

    return this;
  }

  // Generate markdown table from cells
  String _generateMarkdownTable(List<List<String>> cells, bool hasHeader) {
    if (cells.isEmpty) return '';

    final buffer = StringBuffer();

    // Add header row
    buffer.writeln('| ${cells[0].join(' | ')} |');

    // Add separator row if has header
    if (hasHeader) {
      final separators = cells[0].map((_) => '---').join(' | ');
      buffer.writeln('| $separators |');

      // Add data rows (skip the header row)
      for (var i = 1; i < cells.length; i++) {
        buffer.writeln('| ${cells[i].join(' | ')} |');
      }
    } else {
      // Add all rows as data rows
      for (var i = 1; i < cells.length; i++) {
        buffer.writeln('| ${cells[i].join(' | ')} |');
      }
    }

    return buffer.toString().trim();
  }
}
