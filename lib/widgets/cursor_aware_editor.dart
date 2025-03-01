import 'package:flutter/material.dart';

/// A widget that shows different content based on cursor focus.
///
/// This widget is used to implement a text editor-like behavior where elements
/// show markdown syntax by default, and only show formatted content when
/// the cursor is in that block.
class CursorAwareEditor extends StatefulWidget {
  /// The widget to display when focused (formatted view)
  final Widget formattedView;

  /// The widget to display when not focused (markdown view)
  final Widget markdownView;

  /// Whether this block currently has the cursor
  final bool isFocused;

  /// Whether to show controls (like add/remove block buttons)
  final bool showControls;

  /// Optional callback when focus changes
  final ValueChanged<bool>? onFocusChanged;

  const CursorAwareEditor({
    super.key,
    required this.formattedView,
    required this.markdownView,
    required this.isFocused,
    this.showControls = true,
    this.onFocusChanged,
  });

  @override
  State<CursorAwareEditor> createState() => _CursorAwareEditorState();
}

class _CursorAwareEditorState extends State<CursorAwareEditor> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (widget.onFocusChanged != null) {
      widget.onFocusChanged!(_focusNode.hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDarkMode
        ? Colors.grey[700]!.withOpacity(0.3)
        : Colors.grey[300]!.withOpacity(0.5);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: widget.isFocused
            ? Border.all(
                color: borderColor,
                width: 1,
              )
            : null,
      ),
      child: Focus(
        focusNode: _focusNode,
        child: widget.isFocused
            ? widget.formattedView
            : GestureDetector(
                onTap: () => _focusNode.requestFocus(),
                child: widget.markdownView,
              ),
      ),
    );
  }
}
