import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'platform_service.dart';

/// A platform-aware bottom app bar widget that uses either a Material [BottomAppBar]
/// or a Cupertino-styled container based on the platform.
class PlatformBottomAppBar extends StatelessWidget {
  /// The child widget to display in the bottom app bar.
  final Widget child;

  /// The background color of the bottom app bar.
  final Color? backgroundColor;

  /// The height of the bottom app bar.
  final double? height;

  /// Creates a platform-aware bottom app bar.
  const PlatformBottomAppBar({
    super.key,
    required this.child,
    this.backgroundColor,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final defaultBgColor = isDarkMode
        ? const Color(0xFF2D2D2D)
        : const Color(0xFFF5F5F5);

    if (!PlatformService.useCupertino) {
      // Android-style bottom app bar
      return BottomAppBar(
        color: backgroundColor ?? defaultBgColor,
        height: height,
        child: child,
      );
    } else {
      // iOS-style bottom container
      return Container(
        height: height ?? 56.0,
        decoration: BoxDecoration(
          color: backgroundColor ?? defaultBgColor,
          border: Border(
            top: BorderSide(
              color: isDarkMode ? const Color(0xFF3D3D3D) : const Color(0xFFE0E0E0),
              width: 0.5,
            ),
          ),
        ),
        child: child,
      );
    }
  }
}
