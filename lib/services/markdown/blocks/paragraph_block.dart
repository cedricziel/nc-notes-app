import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'markdown_block.dart';

class ParagraphBlock extends MarkdownBlock {
  const ParagraphBlock({required super.content});

  @override
  Widget buildEditor(BuildContext context, ValueChanged<String> onChanged) {
    return ParagraphEditor(
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
  ParagraphBlock copyWith({String? content}) {
    return ParagraphBlock(content: content ?? this.content);
  }
}

class ParagraphEditor extends StatefulWidget {
  final String initialContent;
  final ValueChanged<String> onChanged;

  const ParagraphEditor({
    super.key,
    required this.initialContent,
    required this.onChanged,
  });

  @override
  State<ParagraphEditor> createState() => _ParagraphEditorState();
}

class _ParagraphEditorState extends State<ParagraphEditor> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
  }

  @override
  void didUpdateWidget(ParagraphEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialContent != widget.initialContent) {
      // Update text without recreating controller to preserve cursor position
      final currentCursor = _controller.selection;
      _controller.text = widget.initialContent;
      // Restore cursor position if it was valid
      if (currentCursor.isValid && currentCursor.start <= _controller.text.length) {
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
    return TextField(
      controller: _controller,
      maxLines: null,
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      style: Theme.of(context).textTheme.bodyMedium,
      onChanged: widget.onChanged,
    );
  }
}
