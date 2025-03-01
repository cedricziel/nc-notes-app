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
    List<String> contentLines = [];

    if (lines.isNotEmpty && lines[0].startsWith('```')) {
      // Extract language from the opening fence
      language = lines[0].substring(3).trim();

      // Extract content between the fences
      if (lines.length > 1) {
        // Get all lines except the first one (opening fence)
        final allContentLines = lines.sublist(1);

        // Check if the last line is a closing fence
        final lastLineIndex = allContentLines.length - 1;
        if (lastLineIndex >= 0) {
          if (allContentLines[lastLineIndex].trim() == '```') {
            // Exclude the closing fence
            contentLines = allContentLines.sublist(0, lastLineIndex);
          } else if (allContentLines[lastLineIndex].contains('```')) {
            // Split the last line at the closing fence
            final parts = allContentLines[lastLineIndex].split('```');
            // Replace the last line with everything before the closing fence
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
    return CodeBlock(content: content, language: language);
  }

  @override
  Widget buildEditor(BuildContext context, ValueChanged<String> onChanged,
      {bool isFocused = false, ValueChanged<bool>? onFocusChanged}) {
    return CodeEditor(
      initialContent: content,
      initialLanguage: language,
      onChanged: onChanged,
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

    // If content has changed
    if (content != this.content) {
      // Check if the content looks like a markdown code block
      if (content.trim().startsWith('```')) {
        // Re-parse as a markdown code block
        return CodeBlock.fromMarkdown(content);
      } else {
        // Just update the content, preserving the language
        return CodeBlock(content: content, language: this.language);
      }
    }

    return this;
  }
}

class CodeEditor extends StatefulWidget {
  final String initialContent;
  final String initialLanguage;
  final ValueChanged<String> onChanged;

  const CodeEditor({
    super.key,
    required this.initialContent,
    required this.initialLanguage,
    required this.onChanged,
  });

  @override
  State<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> {
  late TextEditingController _contentController;
  late TextEditingController _languageController;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.initialContent);
    _languageController = TextEditingController(text: widget.initialLanguage);
  }

  @override
  void didUpdateWidget(CodeEditor oldWidget) {
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
    if (oldWidget.initialLanguage != widget.initialLanguage) {
      _languageController.text = widget.initialLanguage;
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _languageController.dispose();
    super.dispose();
  }

  void _updateMarkdown() {
    final newMarkdown =
        '```${_languageController.text}\n${_contentController.text}\n```';
    widget.onChanged(newMarkdown);
  }

  @override
  Widget build(BuildContext context) {
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
                controller: _languageController,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(),
                  hintText: 'language',
                ),
                onChanged: (newLanguage) {
                  _updateMarkdown();
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
            controller: _contentController,
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
              _updateMarkdown();
            },
          ),
        ),
      ],
    );
  }
}
