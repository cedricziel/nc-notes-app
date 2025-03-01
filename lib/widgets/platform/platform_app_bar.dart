import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'platform_service.dart';

/// A platform-aware app bar widget that uses either a [CupertinoNavigationBar]
/// or an [AppBar] based on the platform.
class PlatformAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// The title of the app bar.
  final Widget? title;

  /// The leading widget in the app bar.
  final Widget? leading;

  /// The list of actions to display in the app bar.
  final List<Widget>? actions;

  /// The background color of the app bar.
  final Color? backgroundColor;

  /// Whether the title should be centered.
  final bool? centerTitle;

  /// Whether the app bar should automatically add a back button when appropriate.
  final bool automaticallyImplyLeading;

  /// Creates a platform-aware app bar.
  const PlatformAppBar({
    Key? key,
    this.title,
    this.leading,
    this.actions,
    this.backgroundColor,
    this.centerTitle,
    this.automaticallyImplyLeading = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (PlatformService.useCupertino) {
      // iOS-style navigation bar
      return CupertinoNavigationBar(
        middle: title,
        leading: leading,
        trailing: actions != null && actions!.isNotEmpty
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: actions!,
              )
            : null,
        backgroundColor: backgroundColor,
        automaticallyImplyLeading: automaticallyImplyLeading,
      );
    } else {
      // Android-style app bar
      return AppBar(
        title: title,
        leading: leading,
        actions: actions,
        backgroundColor: backgroundColor,
        centerTitle: centerTitle,
        automaticallyImplyLeading: automaticallyImplyLeading,
      );
    }
  }

  @override
  Size get preferredSize {
    if (PlatformService.useCupertino) {
      return const Size.fromHeight(44.0); // iOS navigation bar height
    } else {
      return const Size.fromHeight(56.0); // Material app bar height
    }
  }
}
