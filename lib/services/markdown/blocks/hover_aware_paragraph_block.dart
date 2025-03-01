import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../widgets/hover_aware_editor.dart';
import 'markdown_aware_block.dart';

class HoverAwareParagraphBlock extends MarkdownAwareBlock {
  const HoverAwareParagraphBlock({required super.content});

  @override
  Widget buildEditor(BuildContext context, ValueChanged<String> onChanged,
      {bool isFocused = false, ValueChanged<bool>? onFocusChanged}) {
    return HoverAwareParagraphEditor(
      initialContent: content,
      onChanged: onChanged,
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
  HoverAwareParagraphBlock copyWith({String? content}) {
    return HoverAwareParagraphBlock(content: content ?? this.content);
  }
}

class HoverAwareParagraphEditor extends StatefulWidget {
  final String initialContent;
  final ValueChanged<String> onChanged;

  const HoverAwareParagraphEditor({
    super.key,
    required this.initialContent,
    required this.onChanged,
  });

  @override
  State<HoverAwareParagraphEditor> createState() =>
      _HoverAwareParagraphEditorState();
}

class _HoverAwareParagraphEditorState extends State<HoverAwareParagraphEditor> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
  }

  @override
  void didUpdateWidget(HoverAwareParagraphEditor oldWidget) {
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
    return HoverAwareEditor(
      formattedView: _buildFormattedView(context),
      markdownView: _buildMarkdownView(context),
    );
  }

  Widget _buildFormattedView(BuildContext context) {
    // For paragraphs, we use Markdown to render the formatted view
    // This allows inline formatting like bold, italic, links, etc. to be displayed
    return Markdown(
      data: widget.initialContent,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
    );
  }

  Widget _buildMarkdownView(BuildContext context) {
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
    );
  }
}
