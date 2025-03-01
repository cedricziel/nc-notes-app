import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

/// A platform-aware tag widget that uses either a Material [Chip]
/// or a Cupertino-styled tag based on the platform.
class PlatformTag extends StatelessWidget {
  /// The text to display inside the tag.
  final String label;

  /// Whether the tag is selected.
  final bool isSelected;

  /// Callback when the tag is tapped.
  final VoidCallback? onTap;

  /// Text style for the label.
  final TextStyle? labelStyle;

  /// Background color of the tag.
  final Color? backgroundColor;

  /// Padding inside the tag.
  final EdgeInsetsGeometry? padding;

  const PlatformTag({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.labelStyle,
    this.backgroundColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (!isCupertino(context)) {
      // Use Material Chip on non-iOS/macOS platforms
      // Wrap in Material to provide MaterialLocalizations
      return Material(
        // Use transparent type to not affect the visual appearance
        type: MaterialType.transparency,
        child: Chip(
          label: Text(label, style: labelStyle),
          backgroundColor: backgroundColor,
          padding: padding,
        ),
      );
    } else {
      // Use custom Cupertino-styled tag on iOS/macOS
      final isDarkMode =
          MediaQuery.platformBrightnessOf(context) == Brightness.dark;
      final defaultTextColor =
          isDarkMode ? CupertinoColors.white : CupertinoColors.black;
      final defaultBgColor = isDarkMode
          ? CupertinoColors.systemGrey6.darkColor
          : CupertinoColors.systemGrey6.color;

      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: backgroundColor ?? defaultBgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: CupertinoColors.systemGrey4,
              width: 0.5,
            ),
          ),
          child: Text(
            label,
            style: labelStyle ??
                TextStyle(
                  color: defaultTextColor,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
          ),
        ),
      );
    }
  }
}
