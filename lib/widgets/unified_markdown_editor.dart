import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/markdown/markdown_document.dart';
import '../services/markdown/blocks/markdown_block.dart';

/// A unified markdown editor that allows seamless cursor navigation
/// while maintaining the block-based document model.
class UnifiedMarkdownEditor extends StatefulWidget {
  /// The initial markdown content
  final String initialMarkdown;

  /// Callback when content changes
  final ValueChanged<String> onChanged;

  /// Whether to show block controls
  final bool showBlockControls;

  const UnifiedMarkdownEditor({
    super.key,
    required this.initialMarkdown,
    required this.onChanged,
    this.showBlockControls = true,
  });

  @override
  State<UnifiedMarkdownEditor> createState() => _UnifiedMarkdownEditorState();
}

class _UnifiedMarkdownEditorState extends State<UnifiedMarkdownEditor> {
  late TextEditingController _controller;
  late MarkdownDocument _document;
  late FocusNode _focusNode;

  // Track which block contains the cursor
  int _cursorBlockIndex = -1;

  // Track cursor position within the document
  TextPosition? _cursorPosition;

  // Map of block indices to their text ranges in the document
  late List<_BlockRange> _blockRanges;

  // Whether we're in preview mode
  bool _isPreviewMode = false;

  @override
  void initState() {
    super.initState();
    _document = MarkdownDocument.fromMarkdown(widget.initialMarkdown);
    _controller = TextEditingController(text: widget.initialMarkdown);
    _focusNode = FocusNode();

    // Initialize block ranges
    _updateBlockRanges();

    // Listen for cursor position changes
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(UnifiedMarkdownEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialMarkdown != widget.initialMarkdown) {
      // Preserve cursor position when updating content
      final cursorPosition = _controller.selection.start;

      _document = MarkdownDocument.fromMarkdown(widget.initialMarkdown);
      _controller.text = widget.initialMarkdown;

      // Restore cursor position if valid
      if (cursorPosition <= _controller.text.length) {
        _controller.selection = TextSelection.collapsed(offset: cursorPosition);
      }

      _updateBlockRanges();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Updates the mapping of block indices to text ranges
  void _updateBlockRanges() {
    _blockRanges = [];

    // Convert document to markdown to ensure consistent formatting
    final markdown = _document.toMarkdown();

    // Re-parse to get blocks with consistent formatting
    _document = MarkdownDocument.fromMarkdown(markdown);

    // Build the block ranges
    int offset = 0;
    for (int i = 0; i < _document.blocks.length; i++) {
      final block = _document.blocks[i];
      final blockText = block.toMarkdown();
      final length = blockText.length;

      _blockRanges.add(_BlockRange(
        start: offset,
        end: offset + length,
        blockIndex: i,
      ));

      // Add 2 for the newline characters between blocks
      offset += length + 2;
    }

    // Update cursor block index based on new ranges
    _updateCursorBlockIndex();
  }

  /// Called when text changes or cursor position changes
  void _onTextChanged() {
    // Get current cursor position
    _cursorPosition = _controller.selection.start == _controller.selection.end
        ? TextPosition(offset: _controller.selection.start)
        : null;

    // Update which block contains the cursor
    _updateCursorBlockIndex();

    // Notify parent of changes
    widget.onChanged(_controller.text);

    // Update document model and block ranges
    _document = MarkdownDocument.fromMarkdown(_controller.text);
    _updateBlockRanges();
  }

  /// Updates which block contains the cursor
  void _updateCursorBlockIndex() {
    if (_cursorPosition == null) {
      setState(() {
        _cursorBlockIndex = -1;
      });
      return;
    }

    final cursorOffset = _cursorPosition!.offset;

    // Find which block contains the cursor
    for (final blockRange in _blockRanges) {
      if (cursorOffset >= blockRange.start && cursorOffset <= blockRange.end) {
        if (_cursorBlockIndex != blockRange.blockIndex) {
          setState(() {
            _cursorBlockIndex = blockRange.blockIndex;
          });
        }
        return;
      }
    }

    // If cursor is at the end of the document
    if (cursorOffset >= _controller.text.length && _blockRanges.isNotEmpty) {
      setState(() {
        _cursorBlockIndex = _blockRanges.last.blockIndex;
      });
      return;
    }

    // If no block contains the cursor
    setState(() {
      _cursorBlockIndex = -1;
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

        // Editor or preview
        Expanded(
          child: _isPreviewMode ? _buildPreviewMode() : _buildEditMode(),
        ),
      ],
    );
  }

  Widget _buildEditMode() {
    return Stack(
      children: [
        // The actual editable text field (invisible layer for editing)
        Positioned.fill(
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            maxLines: null,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: const TextStyle(
              color: Colors.transparent, // Make text invisible
              height: 1.5, // Match line height with rendered blocks
            ),
            // Ensure cursor is visible even though text is transparent
            cursorColor:
                Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black,
          ),
        ),

        // Rendered blocks (visible layer)
        Positioned.fill(
          child: _buildRenderedBlocks(),
        ),
      ],
    );
  }

  Widget _buildRenderedBlocks() {
    return ListView.builder(
      itemCount: _document.blocks.length,
      itemBuilder: (context, index) {
        final block = _document.blocks[index];
        final isActive = index == _cursorBlockIndex;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: _buildBlockWithActiveState(block, isActive, index),
        );
      },
    );
  }

  Widget _buildBlockWithActiveState(
      MarkdownBlock block, bool isActive, int index) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDarkMode
        ? Colors.grey[700]!.withOpacity(0.3)
        : Colors.grey[300]!.withOpacity(0.5);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: isActive
            ? Border.all(
                color: borderColor,
                width: 1,
              )
            : null,
      ),
      child: isActive ? _buildMarkdownView(block) : _buildFormattedView(block),
    );
  }

  Widget _buildMarkdownView(MarkdownBlock block) {
    return Text(
      block.content,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  Widget _buildFormattedView(MarkdownBlock block) {
    return block.buildPreview(context);
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

/// Helper class to track the text range of each block
class _BlockRange {
  final int start;
  final int end;
  final int blockIndex;

  _BlockRange({
    required this.start,
    required this.end,
    required this.blockIndex,
  });
}
