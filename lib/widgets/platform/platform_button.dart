import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

/// This file re-exports the PlatformElevatedButton and PlatformTextButton from flutter_platform_widgets.
///
/// We're using the package's implementation directly instead of our custom implementation.
/// For usage information, see the flutter_platform_widgets documentation.
export 'package:flutter_platform_widgets/flutter_platform_widgets.dart'
    show PlatformElevatedButton, PlatformTextButton;

/// A platform-aware button widget that uses either a [CupertinoButton]
/// or a Material button based on the platform.
///
/// This is a wrapper around flutter_platform_widgets' PlatformElevatedButton and PlatformTextButton
/// that provides a similar API to our custom PlatformButton implementation.
class PlatformButton extends StatelessWidget {
  /// The callback that is called when the button is tapped.
  final VoidCallback? onPressed;

  /// The widget to display as the button's label.
  final Widget child;

  /// The color of the button.
  final Color? color;

  /// The padding around the button's child.
  final EdgeInsetsGeometry? padding;

  /// Whether the button is filled (Material) or outlined (iOS).
  final bool filled;

  /// Creates a platform-aware button.
  const PlatformButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.color,
    this.padding,
    this.filled = true,
  }) : super(key: key);

  /// Creates a platform-aware button with text.
  factory PlatformButton.text({
    Key? key,
    required VoidCallback? onPressed,
    required String text,
    Color? color,
    EdgeInsetsGeometry? padding,
    bool filled = false,
    TextStyle? textStyle,
  }) {
    return PlatformButton(
      key: key,
      onPressed: onPressed,
      color: color,
      padding: padding,
      filled: filled,
      child: Text(
        text,
        style: textStyle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return PlatformElevatedButton(
        onPressed: onPressed,
        material: (_, __) => MaterialElevatedButtonData(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: padding,
          ),
        ),
        cupertino: (_, __) => CupertinoElevatedButtonData(
          padding: padding,
          color: color,
        ),
        child: child,
      );
    } else {
      return PlatformTextButton(
        onPressed: onPressed,
        material: (_, __) => MaterialTextButtonData(
          style: TextButton.styleFrom(
            foregroundColor: color,
            padding: padding,
          ),
        ),
        cupertino: (_, __) => CupertinoTextButtonData(
          padding: padding,
        ),
        child: child,
      );
    }
  }
}
