import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart' as fpw;
import 'platform_service.dart';

/// A platform-aware list tile widget that uses either a [CupertinoListTile]
/// or a [ListTile] based on the platform.
///
/// This is a wrapper around flutter_platform_widgets' PlatformListTile that
/// adds support for additional parameters like contentPadding, minLeadingWidth,
/// dense, visualDensity, selected, selectedTileColor, and onLongPress.
class PlatformListTile extends StatelessWidget {
  /// The primary content of the list tile.
  final Widget? title;

  /// A widget to display before the title.
  final Widget? leading;

  /// A widget to display after the title.
  final Widget? trailing;

  /// Additional content displayed below the title.
  final Widget? subtitle;

  /// Called when the user taps this list tile.
  final VoidCallback? onTap;

  /// Called when the user long-presses on this list tile.
  final VoidCallback? onLongPress;

  /// Whether this list tile is selected.
  final bool? selected;

  /// The color to use for the background of this list tile when selected.
  final Color? selectedTileColor;

  /// The padding around the content of the list tile.
  final EdgeInsetsGeometry? contentPadding;

  /// Whether to use a dense layout.
  final bool? dense;

  /// Defines how compact the list tile's layout will be.
  final VisualDensity? visualDensity;

  /// The minimum width allocated for the leading widget.
  final double? minLeadingWidth;

  /// Creates a platform-aware list tile.
  const PlatformListTile({
    Key? key,
    this.title,
    this.leading,
    this.trailing,
    this.subtitle,
    this.onTap,
    this.onLongPress,
    this.selected,
    this.selectedTileColor,
    this.contentPadding,
    this.dense,
    this.visualDensity,
    this.minLeadingWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (PlatformService.useCupertino) {
      // iOS-style list tile
      return CupertinoListTile(
        title: title ?? const SizedBox.shrink(),
        leading: leading,
        trailing: trailing,
        subtitle: subtitle,
        onTap: onTap,
        padding: contentPadding,
        backgroundColor: selected == true ? selectedTileColor : null,
        additionalInfo: onLongPress != null
            ? GestureDetector(
                onLongPress: onLongPress,
                child: const SizedBox.shrink(),
              )
            : null,
      );
    } else {
      // Android-style list tile
      return ListTile(
        title: title,
        leading: leading,
        trailing: trailing,
        subtitle: subtitle,
        onTap: onTap,
        onLongPress: onLongPress,
        selected: selected ?? false,
        selectedTileColor: selectedTileColor,
        contentPadding: contentPadding,
        dense: dense,
        visualDensity: visualDensity,
        minLeadingWidth: minLeadingWidth,
      );
    }
  }
}
