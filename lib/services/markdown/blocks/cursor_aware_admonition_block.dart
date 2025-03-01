import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../widgets/cursor_aware_editor.dart';
import 'markdown_aware_block.dart';

class CursorAwareAdmonitionBlock extends MarkdownAwareBlock {
  final String type;
  final String title;

  const CursorAwareAdmonitionBlock({
    required super.content,
    required this.type,
    required this.title,
  });

  /// Create an admonition block from markdown text
  factory CursorAwareAdmonitionBlock.fromMarkdown(String markdown) {
    // Parse the admonition block
    final lines = markdown.split('\n');

    if (lines.isEmpty || !lines.first.startsWith(':::')) {
      throw ArgumentError('Invalid admonition format: $markdown');
    }

    // Extract type from first line (e.g., :::info)
    final typeMatch = RegExp(r'^:::(\w+)(?:\s+(.*))?$').firstMatch(lines.first);
    final type = typeMatch?.group(1) ?? 'note';
    final title = typeMatch?.group(2) ?? '';

    return CursorAwareAdmonitionBlock(
      content: markdown,
      type: type,
      title: title,
    );
  }

  @override
  Widget buildEditor(BuildContext context, ValueChanged<String> onChanged,
      {bool isFocused = false, ValueChanged<bool>? onFocusChanged}) {
    return CursorAwareAdmonitionEditor(
      initialContent: content,
      type: type,
      title: title,
      onChanged: onChanged,
      isFocused: isFocused,
      onFocusChanged: onFocusChanged,
    );
  }

  @override
  Widget buildPreview(BuildContext context) {
    return _buildAdmonitionPreview(context);
  }

  @override
  String toMarkdown() => content;

  @override
  CursorAwareAdmonitionBlock copyWith({String? content}) {
    return CursorAwareAdmonitionBlock(
      content: content ?? this.content,
      type: type,
      title: title,
    );
  }

  Widget _buildAdmonitionPreview(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Determine color based on type
    Color backgroundColor;
    Color borderColor;
    IconData icon;

    switch (type.toLowerCase()) {
      case 'info':
        backgroundColor = isDarkMode
            ? Colors.blue.shade900.withOpacity(0.2)
            : Colors.blue.shade50;
        borderColor = Colors.blue.shade300;
        icon = Icons.info_outline;
        break;
      case 'warning':
        backgroundColor = isDarkMode
            ? Colors.orange.shade900.withOpacity(0.2)
            : Colors.orange.shade50;
        borderColor = Colors.orange.shade300;
        icon = Icons.warning_amber_outlined;
        break;
      case 'danger':
        backgroundColor = isDarkMode
            ? Colors.red.shade900.withOpacity(0.2)
            : Colors.red.shade50;
        borderColor = Colors.red.shade300;
        icon = Icons.dangerous_outlined;
        break;
      case 'success':
        backgroundColor = isDarkMode
            ? Colors.green.shade900.withOpacity(0.2)
            : Colors.green.shade50;
        borderColor = Colors.green.shade300;
        icon = Icons.check_circle_outline;
        break;
      case 'note':
      default:
        backgroundColor = isDarkMode
            ? Colors.grey.shade800.withOpacity(0.2)
            : Colors.grey.shade100;
        borderColor = Colors.grey.shade400;
        icon = Icons.note_outlined;
        break;
    }

    // Extract content (everything after the opening marker)
    final lines = content.split('\n');
    int startIndex = 1; // Skip the first line (:::type)

    // Extract content
    final contentLines = lines.sublist(startIndex);
    final contentText = contentLines.join('\n');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          left: BorderSide(color: borderColor, width: 4),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title bar
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: borderColor),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode
                          ? borderColor
                          : borderColor.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),

          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Markdown(
              data: contentText,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
            ),
          ),
        ],
      ),
    );
  }
}

class CursorAwareAdmonitionEditor extends StatefulWidget {
  final String initialContent;
  final String type;
  final String title;
  final ValueChanged<String> onChanged;
  final bool isFocused;
  final ValueChanged<bool>? onFocusChanged;

  const CursorAwareAdmonitionEditor({
    super.key,
    required this.initialContent,
    required this.type,
    required this.title,
    required this.onChanged,
    required this.isFocused,
    this.onFocusChanged,
  });

  @override
  State<CursorAwareAdmonitionEditor> createState() =>
      _CursorAwareAdmonitionEditorState();
}

class _CursorAwareAdmonitionEditorState
    extends State<CursorAwareAdmonitionEditor> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
  }

  @override
  void didUpdateWidget(CursorAwareAdmonitionEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialContent != widget.initialContent) {
      // Update text without recreating controller to preserve cursor position
      final currentCursor = _controller.selection;
      _controller.text = widget.initialContent;
      // Restore cursor position if it was valid
      if (currentCursor.isValid &&
          currentCursor.start <= _controller.text.length) {
        _controller.selection = currentCursor;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CursorAwareEditor(
      isFocused: widget.isFocused,
      onFocusChanged: widget.onFocusChanged,
      formattedView: _buildFormattedView(context),
      markdownView: _buildMarkdownView(context),
    );
  }

  Widget _buildFormattedView(BuildContext context) {
    return TextField(
      controller: _controller,
      maxLines: null,
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        hintText: 'Enter admonition content...',
      ),
      style: Theme.of(context).textTheme.bodyMedium,
      onChanged: widget.onChanged,
      autofocus: widget.isFocused,
    );
  }

  Widget _buildMarkdownView(BuildContext context) {
    return Text(
      widget.initialContent,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}
