import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// Base abstract class for all markdown block types.
abstract class MarkdownBlock {
  final String content;

  const MarkdownBlock({required this.content});

  /// Build an editor widget for this block
  Widget buildEditor(BuildContext context, ValueChanged<String> onChanged,
      {bool isFocused = false, ValueChanged<bool>? onFocusChanged});

  /// Build a preview widget for this block
  Widget buildPreview(BuildContext context);

  /// Convert block to markdown text
  String toMarkdown();

  /// Create a copy with new content
  MarkdownBlock copyWith({String? content});

  /// Factory to create the appropriate block type from markdown content
  static MarkdownBlock fromMarkdown(String markdown) {
    // This will be implemented by the factory method in the MarkdownDocument class
    throw UnimplementedError(
        'Use MarkdownDocument.createBlockFromMarkdown instead');
  }
}
