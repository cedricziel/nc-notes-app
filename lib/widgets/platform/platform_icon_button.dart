import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'platform_service.dart';

/// A platform-aware icon button widget that uses either a [CupertinoButton]
/// or an [IconButton] based on the platform.
class PlatformIconButton extends StatelessWidget {
  /// The callback that is called when the button is tapped.
  final VoidCallback? onPressed;

  /// The icon to display.
  final IconData icon;

  /// The size of the icon.
  final double? iconSize;

  /// The color of the icon.
  final Color? color;

  /// The tooltip for the button.
  final String? tooltip;

  /// Creates a platform-aware icon button.
  const PlatformIconButton({
    Key? key,
    required this.onPressed,
    required this.icon,
    this.iconSize,
    this.color,
    this.tooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = color ??
        (PlatformService.useCupertino
            ? CupertinoColors.activeBlue.resolveFrom(context)
            : theme.iconTheme.color);

    if (PlatformService.useCupertino) {
      // iOS-style icon button
      return CupertinoButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        child: Tooltip(
          message: tooltip ?? '',
          child: Icon(
            icon,
            size: iconSize ?? 24.0,
            color: iconColor,
          ),
        ),
      );
    } else {
      // Android-style icon button
      return IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        iconSize: iconSize ?? 24.0,
        color: iconColor,
        tooltip: tooltip,
      );
    }
  }
}

/// A platform-aware back button widget that uses either a [CupertinoNavigationBarBackButton]
/// or an [IconButton] with a back icon based on the platform.
class PlatformBackButton extends StatelessWidget {
  /// The callback that is called when the button is tapped.
  final VoidCallback? onPressed;

  /// The color of the button.
  final Color? color;

  /// Creates a platform-aware back button.
  const PlatformBackButton({
    Key? key,
    this.onPressed,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (PlatformService.useCupertino) {
      // iOS-style back button
      return CupertinoNavigationBarBackButton(
        onPressed: onPressed ?? () => Navigator.of(context).pop(),
        color: color,
      );
    } else {
      // Android-style back button
      return IconButton(
        icon: const Icon(Icons.arrow_back),
        color: color,
        onPressed: onPressed ?? () => Navigator.of(context).pop(),
      );
    }
  }
}
