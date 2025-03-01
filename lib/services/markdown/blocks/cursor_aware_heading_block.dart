import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../widgets/cursor_aware_editor.dart';
import 'markdown_aware_block.dart';

class CursorAwareHeadingBlock extends MarkdownAwareBlock {
  final int level;

  const CursorAwareHeadingBlock({
    required super.content,
    required this.level,
  });

  /// Create a heading block from markdown text
  factory CursorAwareHeadingBlock.fromMarkdown(String markdown) {
    final match = RegExp(r'^(#{1,6})\s+(.+)$').firstMatch(markdown);
    if (match == null) {
      throw ArgumentError('Invalid heading format: $markdown');
    }

    final level = match.group(1)!.length;
    final content = markdown;

    return CursorAwareHeadingBlock(
      content: content,
      level: level,
    );
  }

  @override
  Widget buildEditor(BuildContext context, ValueChanged<String> onChanged,
      {bool isFocused = false, ValueChanged<bool>? onFocusChanged}) {
    return CursorAwareHeadingEditor(
      initialContent: content,
      level: level,
      onChanged: onChanged,
      isFocused: isFocused,
      onFocusChanged: onFocusChanged,
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
  CursorAwareHeadingBlock copyWith({String? content}) {
    return CursorAwareHeadingBlock(
      content: content ?? this.content,
      level: level,
    );
  }
}

class CursorAwareHeadingEditor extends StatefulWidget {
  final String initialContent;
  final int level;
  final ValueChanged<String> onChanged;
  final bool isFocused;
  final ValueChanged<bool>? onFocusChanged;

  const CursorAwareHeadingEditor({
    super.key,
    required this.initialContent,
    required this.level,
    required this.onChanged,
    required this.isFocused,
    this.onFocusChanged,
  });

  @override
  State<CursorAwareHeadingEditor> createState() =>
      _CursorAwareHeadingEditorState();
}

class _CursorAwareHeadingEditorState extends State<CursorAwareHeadingEditor> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
  }

  @override
  void didUpdateWidget(CursorAwareHeadingEditor oldWidget) {
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
        hintText: 'Enter heading text...',
      ),
      style: _getHeadingStyle(context),
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

  TextStyle _getHeadingStyle(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    switch (widget.level) {
      case 1:
        return textTheme.headlineLarge ??
            const TextStyle(fontSize: 28, fontWeight: FontWeight.bold);
      case 2:
        return textTheme.headlineMedium ??
            const TextStyle(fontSize: 24, fontWeight: FontWeight.bold);
      case 3:
        return textTheme.headlineSmall ??
            const TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
      case 4:
        return textTheme.titleLarge ??
            const TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
      case 5:
        return textTheme.titleMedium ??
            const TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
      case 6:
        return textTheme.titleSmall ??
            const TextStyle(fontSize: 14, fontWeight: FontWeight.bold);
      default:
        return textTheme.titleMedium ??
            const TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
    }
  }
}
