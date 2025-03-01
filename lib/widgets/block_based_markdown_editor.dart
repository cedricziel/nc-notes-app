import 'package:flutter/material.dart';
import '../services/markdown/markdown_document.dart';
import '../services/markdown/blocks/markdown_block.dart';
import '../services/markdown/blocks/paragraph_block.dart';

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
  State<BlockBasedMarkdownEditor> createState() => _BlockBasedMarkdownEditorState();
}

class _BlockBasedMarkdownEditorState extends State<BlockBasedMarkdownEditor> {
  late MarkdownDocument _document;
  bool _isPreviewMode = false;

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
      final updatedBlock = _document.blocks[index].copyWith(content: newContent);
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

  void _removeBlock(int index) {
    if (_document.blocks.length <= 1) return; // Don't remove the last block

    setState(() {
      final newBlocks = List<MarkdownBlock>.from(_document.blocks);
      newBlocks.removeAt(index);

      _document = MarkdownDocument(blocks: newBlocks);
      widget.onChanged(_document.toMarkdown());
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
          child: _isPreviewMode
              ? _buildPreviewMode()
              : _buildEditMode(),
        ),
      ],
    );
  }

  Widget _buildEditMode() {
    return ListView.builder(
      itemCount: _document.blocks.length,
      itemBuilder: (context, index) {
        final block = _document.blocks[index];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          elevation: 0,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[850]
              : Colors.grey[50],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Block controls
              if (widget.showBlockControls)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        block.runtimeType.toString().replaceAll('Block', ''),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add, size: 16),
                        onPressed: () => _addBlockAfter(index, ParagraphBlock(content: '')),
                        tooltip: 'Add block below',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 16),
                        onPressed: () => _removeBlock(index),
                        tooltip: 'Remove block',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),

              // Block editor
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: block.buildEditor(
                  context,
                  (newContent) => _updateBlock(index, newContent),
                ),
              ),
            ],
          ),
        );
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
}
