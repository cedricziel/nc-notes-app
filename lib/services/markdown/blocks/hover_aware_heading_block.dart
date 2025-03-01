import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../widgets/hover_aware_editor.dart';
import 'markdown_aware_block.dart';

class HoverAwareHeadingBlock extends MarkdownAwareBlock {
  final int level;

  const HoverAwareHeadingBlock({
    required super.content,
    required this.level,
  });

  factory HoverAwareHeadingBlock.fromMarkdown(String markdown) {
    // Extract heading level and content
    final match = RegExp(r'^(#{1,6})\s+(.+)$').firstMatch(markdown);
    if (match == null) {
      throw ArgumentError('Invalid heading format: $markdown');
    }

    final level = match.group(1)!.length;
    final content = match.group(2)!;

    return HoverAwareHeadingBlock(content: content, level: level);
  }

  @override
  Widget buildEditor(BuildContext context, ValueChanged<String> onChanged) {
    return HoverAwareHeadingEditor(
      initialContent: content,
      initialLevel: level,
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
  String toMarkdown() => '#' * level + ' ' + content;

  @override
  HoverAwareHeadingBlock copyWith({String? content}) {
    if (content == null) return this;

    // Check if the heading level has changed
    final match = RegExp(r'^(#{1,6})\s+(.+)$').firstMatch(content);
    if (match != null) {
      final newLevel = match.group(1)!.length;
      final newContent = match.group(2)!;
      return HoverAwareHeadingBlock(content: newContent, level: newLevel);
    }

    // If the format doesn't match a heading, keep the level but update content
    return HoverAwareHeadingBlock(content: content, level: level);
  }
}

class HoverAwareHeadingEditor extends StatefulWidget {
  final String initialContent;
  final int initialLevel;
  final ValueChanged<String> onChanged;

  const HoverAwareHeadingEditor({
    super.key,
    required this.initialContent,
    required this.initialLevel,
    required this.onChanged,
  });

  @override
  State<HoverAwareHeadingEditor> createState() => _HoverAwareHeadingEditorState();
}

class _HoverAwareHeadingEditorState extends State<HoverAwareHeadingEditor> {
  late TextEditingController _controller;
  late int _level;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
    _level = widget.initialLevel;
  }

  @override
  void didUpdateWidget(HoverAwareHeadingEditor oldWidget) {
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
    if (oldWidget.initialLevel != widget.initialLevel) {
      _level = widget.initialLevel;
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
    return Text(
      widget.initialContent,
      style: _getHeadingStyle(context, _level),
    );
  }

  Widget _buildMarkdownView(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show markdown syntax
        Text(
          '#' * _level + ' ',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),

        // Editable content
        Expanded(
          child: TextField(
            controller: _controller,
            maxLines: null,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: _getHeadingStyle(context, _level),
            onChanged: (newContent) {
              widget.onChanged('#' * _level + ' ' + newContent);
            },
          ),
        ),

        // Level selector
        DropdownButton<int>(
          value: _level,
          items: List.generate(6, (index) => index + 1)
              .map((l) => DropdownMenuItem<int>(
                    value: l,
                    child: Text('H$l'),
                  ))
              .toList(),
          onChanged: (newLevel) {
            if (newLevel != null) {
              setState(() {
                _level = newLevel;
              });
              widget.onChanged('#' * newLevel + ' ' + _controller.text);
            }
          },
        ),
      ],
    );
  }

  // Helper to get appropriate text style for heading level
  TextStyle _getHeadingStyle(BuildContext context, int level) {
    final baseStyle = Theme.of(context).textTheme.titleLarge!;

    switch (level) {
      case 1:
        return baseStyle.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        );
      case 2:
        return baseStyle.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        );
      case 3:
        return baseStyle.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        );
      case 4:
        return baseStyle.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        );
      case 5:
        return baseStyle.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        );
      case 6:
        return baseStyle.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        );
      default:
        return baseStyle;
    }
  }
}
