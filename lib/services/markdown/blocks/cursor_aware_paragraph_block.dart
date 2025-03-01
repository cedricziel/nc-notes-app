import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../widgets/cursor_aware_editor.dart';
import 'markdown_aware_block.dart';

class CursorAwareParagraphBlock extends MarkdownAwareBlock {
  const CursorAwareParagraphBlock({required super.content});

  @override
  Widget buildEditor(BuildContext context, ValueChanged<String> onChanged,
      {bool isFocused = false, ValueChanged<bool>? onFocusChanged}) {
    return CursorAwareParagraphEditor(
      initialContent: content,
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
  CursorAwareParagraphBlock copyWith({String? content}) {
    return CursorAwareParagraphBlock(content: content ?? this.content);
  }
}

class CursorAwareParagraphEditor extends StatefulWidget {
  final String initialContent;
  final ValueChanged<String> onChanged;
  final bool isFocused;
  final ValueChanged<bool>? onFocusChanged;

  const CursorAwareParagraphEditor({
    super.key,
    required this.initialContent,
    required this.onChanged,
    required this.isFocused,
    this.onFocusChanged,
  });

  @override
  State<CursorAwareParagraphEditor> createState() =>
      _CursorAwareParagraphEditorState();
}

class _CursorAwareParagraphEditorState
    extends State<CursorAwareParagraphEditor> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
  }

  @override
  void didUpdateWidget(CursorAwareParagraphEditor oldWidget) {
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
    // For paragraphs, we use Markdown to render the formatted view
    // This allows inline formatting like bold, italic, links, etc. to be displayed
    return TextField(
      controller: _controller,
      maxLines: null,
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        hintText: 'Enter text here...',
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
