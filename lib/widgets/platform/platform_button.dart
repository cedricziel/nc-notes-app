import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'platform_service.dart';

/// A platform-aware button widget that uses either a [CupertinoButton]
/// or a Material button based on the platform.
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
    final theme = Theme.of(context);

    if (PlatformService.useCupertino) {
      // iOS-style button
      return filled
          ? CupertinoButton.filled(
              onPressed: onPressed,
              padding: padding,
              child: child,
            )
          : CupertinoButton(
              onPressed: onPressed,
              padding: padding,
              color: color,
              child: child,
            );
    } else {
      // Android-style button
      return filled
          ? ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                padding: padding,
              ),
              child: child,
            )
          : TextButton(
              onPressed: onPressed,
              style: TextButton.styleFrom(
                foregroundColor: color ?? theme.primaryColor,
                padding: padding,
              ),
              child: child,
            );
    }
  }
}
