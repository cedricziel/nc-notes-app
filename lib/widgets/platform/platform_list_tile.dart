import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'platform_service.dart';

/// A platform-aware list tile widget that uses either a [CupertinoListTile]
/// or a [ListTile] based on the platform.
class PlatformListTile extends StatelessWidget {
  /// The primary content of the list tile.
  final Widget? title;

  /// A widget to display before the title.
  final Widget? leading;

  /// A widget to display after the title.
  final Widget? trailing;

  /// Additional content displayed below the title.
  final Widget? subtitle;

  /// Whether this list tile is selected.
  final bool? selected;

  /// The tile's background color.
  final Color? backgroundColor;

  /// The tile's background color when selected.
  final Color? selectedTileColor;

  /// Called when the user taps this list tile.
  final VoidCallback? onTap;

  /// Called when the user long-presses this list tile.
  final VoidCallback? onLongPress;

  /// Whether this list tile is interactive.
  final bool enabled;

  /// Whether the list tile is dense.
  final bool? dense;

  /// The padding around the content of the list tile.
  final EdgeInsetsGeometry? contentPadding;

  /// The minimum width allocated for the leading widget.
  final double? minLeadingWidth;

  /// The visual density of the list tile.
  final VisualDensity? visualDensity;

  /// Creates a platform-aware list tile.
  const PlatformListTile({
    super.key,
    this.title,
    this.leading,
    this.trailing,
    this.subtitle,
    this.selected,
    this.backgroundColor,
    this.selectedTileColor,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.dense,
    this.contentPadding,
    this.minLeadingWidth,
    this.visualDensity,
  });

  @override
  Widget build(BuildContext context) {
    if (!PlatformService.useCupertino) {
      // Android-style list tile
      // Wrap in Material to provide MaterialLocalizations
      return Material(
        // Use transparent type to not affect the visual appearance
        type: MaterialType.transparency,
        child: ListTile(
          title: title,
          leading: leading,
          trailing: trailing,
          subtitle: subtitle,
          selected: selected ?? false,
          tileColor: backgroundColor,
          selectedTileColor: selectedTileColor,
          onTap: onTap,
          onLongPress: onLongPress,
          enabled: enabled,
          dense: dense,
          contentPadding: contentPadding,
          minLeadingWidth: minLeadingWidth,
          visualDensity: visualDensity,
        ),
      );
    } else {
      // iOS-style list tile
      // CupertinoListTile requires non-nullable title
      final Widget titleWidget = title ?? const SizedBox.shrink();

      return CupertinoListTile(
        title: titleWidget,
        leading: leading,
        trailing: trailing,
        subtitle: subtitle,
        backgroundColor: backgroundColor,
        onTap: enabled ? onTap : null,
        padding: contentPadding,
        // Note: CupertinoListTile doesn't have all the same properties as ListTile
        // We'll handle some of them manually
        additionalInfo: selected == true
            ? const Icon(CupertinoIcons.check_mark, size: 16)
            : null,
      );
    }
  }
}
