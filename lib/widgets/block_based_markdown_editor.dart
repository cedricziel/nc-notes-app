import 'package:flutter/material.dart';
import '../services/markdown/markdown_document.dart';
import '../services/markdown/blocks/markdown_block.dart';
import '../services/markdown/blocks/cursor_aware_paragraph_block.dart';

class BlockBasedMarkdownEditor extends StatefulWidget {
  final String initialMarkdown;
  final ValueChanged<String> onChanged;
  final bool showBlockControls;

  const BlockBasedMarkdownEditor({
    super.key,
    required this.initialMarkdown,
    required this.onChanged,
    this.showBlockControls = true,
  });

  @override
  State<BlockBasedMarkdownEditor> createState() =>
      _BlockBasedMarkdownEditorState();
}

class _BlockBasedMarkdownEditorState extends State<BlockBasedMarkdownEditor> {
  late MarkdownDocument _document;
  bool _isPreviewMode = false;
  int _focusedBlockIndex = -1; // No block focused initially

  @override
  void initState() {
    super.initState();
    _document = MarkdownDocument.fromMarkdown(widget.initialMarkdown);
  }

  @override
  void didUpdateWidget(BlockBasedMarkdownEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialMarkdown != widget.initialMarkdown) {
      _document = MarkdownDocument.fromMarkdown(widget.initialMarkdown);
    }
  }

  void _updateBlock(int index, String newContent) {
    setState(() {
      final currentBlock = _document.blocks[index];
      MarkdownBlock updatedBlock;

      // Check if the block type should change based on content
      final trimmedContent = newContent.trim();

      // If content starts with #, convert to heading
      if (trimmedContent.startsWith('#')) {
        final match = RegExp(r'^(#{1,6})\s+(.+)$').firstMatch(trimmedContent);
        if (match != null) {
          print('Converting block to heading: $trimmedContent');
          updatedBlock =
              MarkdownDocument.createBlockFromMarkdown(trimmedContent);
        } else {
          // If it doesn't match heading pattern, just update content
          updatedBlock = currentBlock.copyWith(content: newContent);
        }
      }
      // If content starts with :::, convert to admonition
      else if (trimmedContent.startsWith(':::')) {
        print('Converting block to admonition: $trimmedContent');
        updatedBlock = MarkdownDocument.createBlockFromMarkdown(trimmedContent);
      }
      // Otherwise, if it was an admonition or heading, convert to paragraph
      else if (currentBlock.runtimeType.toString().contains('Admonition') ||
          currentBlock.runtimeType.toString().contains('Heading')) {
        print('Converting block to paragraph: $trimmedContent');
        updatedBlock = MarkdownDocument.createBlockFromMarkdown(trimmedContent);
      }
      // Otherwise, just update content
      else {
        updatedBlock = currentBlock.copyWith(content: newContent);
      }

      final newBlocks = List<MarkdownBlock>.from(_document.blocks);
      newBlocks[index] = updatedBlock;

      _document = MarkdownDocument(blocks: newBlocks);
      widget.onChanged(_document.toMarkdown());
    });
  }

  void _addBlockAfter(int index, MarkdownBlock block) {
    setState(() {
      final newBlocks = List<MarkdownBlock>.from(_document.blocks);
      newBlocks.insert(index + 1, block);

      _document = MarkdownDocument(blocks: newBlocks);
      widget.onChanged(_document.toMarkdown());
    });
  }

  // Helper method to create a new empty block
  MarkdownBlock _createEmptyBlock() {
    return CursorAwareParagraphBlock(content: '');
  }

  void _removeBlock(int index) {
    if (_document.blocks.length <= 1) return; // Don't remove the last block

    setState(() {
      final newBlocks = List<MarkdownBlock>.from(_document.blocks);
      final removedBlock = newBlocks[index];
      print('Removing block at index $index: ${removedBlock.runtimeType}');
      print('Block content before removal: "${removedBlock.content}"');

      newBlocks.removeAt(index);

      _document = MarkdownDocument(blocks: newBlocks);
      final newMarkdown = _document.toMarkdown();
      print('Markdown after block removal: "$newMarkdown"');
      widget.onChanged(newMarkdown);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Preview mode toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              icon: Icon(_isPreviewMode ? Icons.edit : Icons.visibility),
              label: Text(_isPreviewMode ? 'Edit' : 'Preview'),
              onPressed: () {
                setState(() {
                  _isPreviewMode = !_isPreviewMode;
                });
              },
            ),
          ],
        ),

        // Blocks
        Expanded(
          child: _isPreviewMode ? _buildPreviewMode() : _buildEditMode(),
        ),
      ],
    );
  }

  Widget _buildEditMode() {
    return ListView.builder(
      itemCount: _document.blocks.length,
      itemBuilder: (context, index) {
        final block = _document.blocks[index];

        return _buildBlockCard(context, block, index);
      },
    );
  }

  Widget _buildPreviewMode() {
    return ListView.builder(
      itemCount: _document.blocks.length,
      itemBuilder: (context, index) {
        final block = _document.blocks[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: block.buildPreview(context),
        );
      },
    );
  }

  // Build a card for a block with cursor-aware controls
  Widget _buildBlockCard(BuildContext context, MarkdownBlock block, int index) {
    final isFocused = index == _focusedBlockIndex;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Block controls
          if (widget.showBlockControls)
            _BlockControls(
              blockType: block.runtimeType.toString().replaceAll('Block', ''),
              onAddBlock: () => _addBlockAfter(index, _createEmptyBlock()),
              onRemoveBlock: () => _removeBlock(index),
            ),

          // Block editor
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: block.buildEditor(
              context,
              (newContent) => _updateBlock(index, newContent),
              isFocused: isFocused,
              onFocusChanged: (focused) {
                if (focused) {
                  setState(() {
                    _focusedBlockIndex = index;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Widget for block controls
class _BlockControls extends StatelessWidget {
  final String blockType;
  final VoidCallback onAddBlock;
  final VoidCallback onRemoveBlock;

  const _BlockControls({
    required this.blockType,
    required this.onAddBlock,
    required this.onRemoveBlock,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            blockType,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.add, size: 16),
            onPressed: onAddBlock,
            tooltip: 'Add block below',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete, size: 16),
            onPressed: onRemoveBlock,
            tooltip: 'Remove block',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
