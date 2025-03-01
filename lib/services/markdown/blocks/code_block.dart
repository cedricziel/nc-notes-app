import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'markdown_block.dart';

class CodeBlock extends MarkdownBlock {
  final String language;

  const CodeBlock({
    required super.content,
    required this.language,
  });

  factory CodeBlock.fromMarkdown(String markdown) {
    final lines = markdown.split('\n');
    String language = '';
    String content = '';

    if (lines.isNotEmpty && lines[0].startsWith('```')) {
      // Extract language from the opening fence
      language = lines[0].substring(3).trim();

      // Extract content between the fences
      if (lines.length > 1) {
        final contentLines = lines.sublist(1);

        // Check if the last line is a closing fence
        final lastLineIndex = contentLines.length - 1;
        if (lastLineIndex >= 0 && contentLines[lastLineIndex].trim() == '```') {
          content = contentLines.sublist(0, lastLineIndex).join('\n');
        } else {
          content = contentLines.join('\n');
        }
      }
    } else {
      // If not properly formatted, just use the whole text as content
      content = markdown;
    }

    return CodeBlock(content: content, language: language);
  }

  @override
  Widget buildEditor(BuildContext context, ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Language selector
        Row(
          children: [
            const Text('Language: '),
            const SizedBox(width: 8),
            SizedBox(
              width: 120,
              child: TextField(
                controller: TextEditingController(text: language),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(),
                  hintText: 'language',
                ),
                onChanged: (newLanguage) {
                  // Update with new language
                  final newMarkdown = '```$newLanguage\n$content\n```';
                  onChanged(newMarkdown);
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Code editor
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.all(8),
          child: TextField(
            controller: TextEditingController(text: content),
            maxLines: null,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
            ),
            onChanged: (newContent) {
              // Update with new content
              final newMarkdown = '```$language\n$newContent\n```';
              onChanged(newMarkdown);
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget buildPreview(BuildContext context) {
    return Markdown(
      data: toMarkdown(),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
    );
  }

  @override
  String toMarkdown() => '```$language\n$content\n```';

  @override
  CodeBlock copyWith({String? content}) {
    if (content == null) return this;

    // If content has changed, re-parse the code block
    if (content != this.content) {
      return CodeBlock.fromMarkdown(content);
    }

    return this;
  }
}
