import 'package:flutter/material.dart';
import 'markdown_block.dart';

/// Base abstract class for markdown blocks that are aware of hover and focus states.
///
/// This class extends the basic [MarkdownBlock] to add functionality for
/// Obsidian-like behavior where blocks show formatted content when not focused,
/// and show markdown syntax when hovered or focused.
abstract class MarkdownAwareBlock extends MarkdownBlock {
  const MarkdownAwareBlock({required super.content});

  /// Build an editor widget for this block that is aware of cursor focus
  @override
  Widget buildEditor(BuildContext context, ValueChanged<String> onChanged,
      {bool isFocused = false, ValueChanged<bool>? onFocusChanged});

  /// Build a preview widget for this block
  @override
  Widget buildPreview(BuildContext context);

  /// Convert block to markdown text
  @override
  String toMarkdown();

  /// Create a copy with new content
  @override
  MarkdownBlock copyWith({String? content});
}
