import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../widgets/hover_aware_editor.dart';
import 'markdown_aware_block.dart';

class HoverAwareAdmonitionBlock extends MarkdownAwareBlock {
  final String type;

  const HoverAwareAdmonitionBlock({
    required super.content,
    required this.type,
  });

  factory HoverAwareAdmonitionBlock.fromMarkdown(String markdown) {
    final lines = markdown.split('\n');
    String type = '';
    List<String> contentLines = [];

    if (lines.isNotEmpty && lines[0].startsWith(':::')) {
      // Extract type from the opening line
      type = lines[0].substring(3).trim();

      // Extract content between the markers
      if (lines.length > 1) {
        // Get all lines except the first one (opening marker)
        final allContentLines = lines.sublist(1);

        // Check if the last line is a closing marker
        final lastLineIndex = allContentLines.length - 1;
        if (lastLineIndex >= 0) {
          if (allContentLines[lastLineIndex].trim() == ':::') {
            // Exclude the closing marker
            contentLines = allContentLines.sublist(0, lastLineIndex);
          } else if (allContentLines[lastLineIndex].contains(':::')) {
            // Split the last line at the closing marker
            final parts = allContentLines[lastLineIndex].split(':::');
            // Replace the last line with everything before the closing marker
            allContentLines[lastLineIndex] = parts[0];
            contentLines = allContentLines;
          } else {
            contentLines = allContentLines;
          }
        }
      }
    } else {
      // If not properly formatted, just use the whole text as content
      contentLines = [markdown];
    }

    // Join the content lines preserving the original line breaks and indentation
    final content = contentLines.join('\n');
    return HoverAwareAdmonitionBlock(content: content, type: type);
  }

  @override
  Widget buildEditor(BuildContext context, ValueChanged<String> onChanged, {bool isFocused = false, ValueChanged<bool>? onFocusChanged}) {
    return HoverAwareAdmonitionEditor(
      initialContent: content,
      initialType: type,
      onChanged: onChanged,
    );
  }

  @override
  Widget buildPreview(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _getAdmonitionColor(context, type).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: _getAdmonitionColor(context, type),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Admonition header
          Row(
            children: [
              Icon(
                _getAdmonitionIcon(type),
                color: _getAdmonitionColor(context, type),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                type.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getAdmonitionColor(context, type),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Admonition content
          Markdown(
            data: content,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
          ),
        ],
      ),
    );
  }

  @override
  String toMarkdown() => ':::$type\n$content\n:::';

  @override
  HoverAwareAdmonitionBlock copyWith({String? content}) {
    if (content == null) return this;

    // If content has changed
    if (content != this.content) {
      // Check if the content looks like a markdown admonition block
      if (content.trim().startsWith(':::')) {
        // Re-parse as a markdown admonition block
        return HoverAwareAdmonitionBlock.fromMarkdown(content);
      } else {
        // Just update the content, preserving the type
        return HoverAwareAdmonitionBlock(content: content, type: this.type);
      }
    }

    return this;
  }

  // Helper method to get color based on admonition type
  Color _getAdmonitionColor(BuildContext context, String type) {
    switch (type.toLowerCase()) {
      case 'error':
      case 'danger':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'info':
        return Colors.blue;
      case 'success':
      case 'tip':
        return Colors.green;
      case 'note':
        return Colors.purple;
      default:
        return Theme.of(context).primaryColor;
    }
  }

  // Helper method to get icon based on admonition type
  IconData _getAdmonitionIcon(String type) {
    switch (type.toLowerCase()) {
      case 'error':
      case 'danger':
        return Icons.error_outline;
      case 'warning':
        return Icons.warning_amber_outlined;
      case 'info':
        return Icons.info_outline;
      case 'success':
      case 'tip':
        return Icons.check_circle_outline;
      case 'note':
        return Icons.note_outlined;
      default:
        return Icons.bookmark_border;
    }
  }
}

class HoverAwareAdmonitionEditor extends StatefulWidget {
  final String initialContent;
  final String initialType;
  final ValueChanged<String> onChanged;

  const HoverAwareAdmonitionEditor({
    super.key,
    required this.initialContent,
    required this.initialType,
    required this.onChanged,
  });

  @override
  State<HoverAwareAdmonitionEditor> createState() => _HoverAwareAdmonitionEditorState();
}

class _HoverAwareAdmonitionEditorState extends State<HoverAwareAdmonitionEditor> {
  late TextEditingController _rawMarkdownController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _rawMarkdownController = TextEditingController(
      text: ':::${widget.initialType}\n${widget.initialContent}\n:::'
    );
  }

  @override
  void didUpdateWidget(HoverAwareAdmonitionEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialContent != widget.initialContent ||
        oldWidget.initialType != widget.initialType) {
      // Only update if not currently editing to avoid overwriting user changes
      if (!_isEditing) {
        final currentCursor = _rawMarkdownController.selection;
        _rawMarkdownController.text = ':::${widget.initialType}\n${widget.initialContent}\n:::';
        // Restore cursor position if it was valid
        if (currentCursor.isValid &&
            currentCursor.start <= _rawMarkdownController.text.length) {
          _rawMarkdownController.selection = currentCursor;
        }
      }
    }
  }

  @override
  void dispose() {
    _rawMarkdownController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HoverAwareEditor(
      formattedView: _buildFormattedView(context),
      markdownView: _buildMarkdownView(context),
      onFocusChanged: (focused) {
        setState(() {
          _isEditing = focused;
        });
      },
    );
  }

  Widget _buildFormattedView(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _getAdmonitionColor(context, widget.initialType).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: _getAdmonitionColor(context, widget.initialType),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Admonition header
          Row(
            children: [
              Icon(
                _getAdmonitionIcon(widget.initialType),
                color: _getAdmonitionColor(context, widget.initialType),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                widget.initialType.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getAdmonitionColor(context, widget.initialType),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Admonition content
          Markdown(
            data: widget.initialContent,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkdownView(BuildContext context) {
    return TextField(
      controller: _rawMarkdownController,
      maxLines: null,
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        hintText: ':::type\nContent goes here\n:::',
      ),
      style: TextStyle(
        fontFamily: 'monospace',
        color: Theme.of(context).textTheme.bodyMedium?.color,
      ),
      onChanged: (value) {
        widget.onChanged(value);
      },
    );
  }

  // Helper method to get color based on admonition type
  Color _getAdmonitionColor(BuildContext context, String type) {
    switch (type.toLowerCase()) {
      case 'error':
      case 'danger':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'info':
        return Colors.blue;
      case 'success':
      case 'tip':
        return Colors.green;
      case 'note':
        return Colors.purple;
      default:
        return Theme.of(context).primaryColor;
    }
  }

  // Helper method to get icon based on admonition type
  IconData _getAdmonitionIcon(String type) {
    switch (type.toLowerCase()) {
      case 'error':
      case 'danger':
        return Icons.error_outline;
      case 'warning':
        return Icons.warning_amber_outlined;
      case 'info':
        return Icons.info_outline;
      case 'success':
      case 'tip':
        return Icons.check_circle_outline;
      case 'note':
        return Icons.note_outlined;
      default:
        return Icons.bookmark_border;
    }
  }
}
