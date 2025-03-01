import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'markdown_block.dart';

class ParagraphBlock extends MarkdownBlock {
  const ParagraphBlock({required super.content});

  @override
  Widget buildEditor(BuildContext context, ValueChanged<String> onChanged) {
    return TextField(
      controller: TextEditingController(text: content),
      maxLines: null,
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      style: Theme.of(context).textTheme.bodyMedium,
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
