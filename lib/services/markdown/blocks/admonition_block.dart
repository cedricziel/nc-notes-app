import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'markdown_block.dart';

class AdmonitionBlock extends MarkdownBlock {
  final String type;

  const AdmonitionBlock({
    required super.content,
    required this.type,
  });

  factory AdmonitionBlock.fromMarkdown(String markdown) {
    final lines = markdown.split('\n');
    String type = '';
    List<String> contentLines = [];

    if (lines.isNotEmpty && lines[0].startsWith(':::')) {
      // Extract type from the opening line
      type = lines[0].substring(3).trim();

      // Extract content (all lines after the opening marker)
      if (lines.length > 1) {
        // Get all lines except the first one (opening marker)
        contentLines = lines.sublist(1);
      }
    } else {
      // If not properly formatted, just use the whole text as content
      contentLines = [markdown];
    }

    // Join the content lines preserving the original line breaks and indentation
    final content = contentLines.join('\n');
    return AdmonitionBlock(content: content, type: type);
  }

  @override
  Widget buildEditor(BuildContext context, ValueChanged<String> onChanged,
      {bool isFocused = false, ValueChanged<bool>? onFocusChanged}) {
    return AdmonitionEditor(
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
  String toMarkdown() => ':::$type\n$content';

  @override
  AdmonitionBlock copyWith({String? content}) {
    if (content == null) return this;

    // If content has changed
    if (content != this.content) {
      // Check if the content looks like a markdown admonition block
      if (content.trim().startsWith(':::')) {
        // Re-parse as a markdown admonition block
        return AdmonitionBlock.fromMarkdown(content);
      } else {
        // Just update the content, preserving the type
        return AdmonitionBlock(content: content, type: type);
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

class AdmonitionEditor extends StatefulWidget {
  final String initialContent;
  final String initialType;
  final ValueChanged<String> onChanged;

  const AdmonitionEditor({
    super.key,
    required this.initialContent,
    required this.initialType,
    required this.onChanged,
  });

  @override
  State<AdmonitionEditor> createState() => _AdmonitionEditorState();
}

class _AdmonitionEditorState extends State<AdmonitionEditor> {
  late TextEditingController _contentController;
  late TextEditingController _typeController;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.initialContent);
    _typeController = TextEditingController(text: widget.initialType);
  }

  @override
  void didUpdateWidget(AdmonitionEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialContent != widget.initialContent) {
      // Update text without recreating controller to preserve cursor position
      final currentCursor = _contentController.selection;
      _contentController.text = widget.initialContent;
      // Restore cursor position if it was valid
      if (currentCursor.isValid &&
          currentCursor.start <= _contentController.text.length) {
        _contentController.selection = currentCursor;
      }
    }
    if (oldWidget.initialType != widget.initialType) {
      _typeController.text = widget.initialType;
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  void _updateMarkdown() {
    final newMarkdown =
        ':::${_typeController.text}\n${_contentController.text}';
    widget.onChanged(newMarkdown);
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Type selector
        Row(
          children: [
            const Text('Type: '),
            const SizedBox(width: 8),
            SizedBox(
              width: 120,
              child: TextField(
                controller: _typeController,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(),
                  hintText: 'type',
                ),
                onChanged: (newType) {
                  setState(() {}); // Refresh to update the color
                  _updateMarkdown();
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Content editor
        Container(
          decoration: BoxDecoration(
            color: _getAdmonitionColor(context, _typeController.text)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _getAdmonitionColor(context, _typeController.text),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(8),
          child: TextField(
            controller: _contentController,
            maxLines: null,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
            onChanged: (newContent) {
              _updateMarkdown();
            },
          ),
        ),
      ],
    );
  }
}
