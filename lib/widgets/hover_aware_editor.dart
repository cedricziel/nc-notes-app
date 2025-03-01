import 'package:flutter/material.dart';

/// A widget that shows different content based on hover and focus states.
///
/// This widget is used to implement Obsidian-like behavior where elements
/// show formatted content when not focused, and show markdown syntax when
/// hovered or focused.
class HoverAwareEditor extends StatefulWidget {
  /// The widget to display when not hovered or focused
  final Widget formattedView;

  /// The widget to display when hovered or focused
  final Widget markdownView;

  /// Whether to show controls (like add/remove block buttons)
  final bool showControls;

  /// Optional callback when focus changes
  final ValueChanged<bool>? onFocusChanged;

  /// Optional callback when hover state changes
  final ValueChanged<bool>? onHoverChanged;

  const HoverAwareEditor({
    super.key,
    required this.formattedView,
    required this.markdownView,
    this.showControls = true,
    this.onFocusChanged,
    this.onHoverChanged,
  });

  @override
  State<HoverAwareEditor> createState() => _HoverAwareEditorState();
}

class _HoverAwareEditorState extends State<HoverAwareEditor> {
  bool _isHovering = false;
  bool _isFocused = false;
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
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    if (widget.onFocusChanged != null) {
      widget.onFocusChanged!(_isFocused);
    }
  }

  void _onHoverChanged(bool isHovering) {
    setState(() {
      _isHovering = isHovering;
    });
    if (widget.onHoverChanged != null) {
      widget.onHoverChanged!(isHovering);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showMarkdown = _isHovering || _isFocused;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final hoverColor = isDarkMode
        ? Colors.grey[800]!.withOpacity(0.3)
        : Colors.grey[200]!.withOpacity(0.5);

    return MouseRegion(
      onEnter: (_) => _onHoverChanged(true),
      onExit: (_) => _onHoverChanged(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        decoration: BoxDecoration(
          color: showMarkdown ? hoverColor : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: showMarkdown
              ? Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.3),
                  width: 1,
                )
              : null,
        ),
        child: Focus(
          focusNode: _focusNode,
          child: AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: showMarkdown
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: GestureDetector(
              onTap: () => _focusNode.requestFocus(),
              child: widget.formattedView,
            ),
            secondChild: widget.markdownView,
            layoutBuilder:
                (topChild, topChildKey, bottomChild, bottomChildKey) {
              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: <Widget>[
                  Positioned(
                    key: bottomChildKey,
                    left: 0,
                    top: 0,
                    right: 0,
                    child: bottomChild,
                  ),
                  Positioned(
                    key: topChildKey,
                    child: topChild,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
