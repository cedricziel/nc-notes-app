import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'platform_service.dart';

/// A platform-aware scaffold widget that uses either a [CupertinoPageScaffold]
/// or a [Scaffold] based on the platform.
class PlatformScaffold extends StatelessWidget {
  /// The body of the scaffold.
  final Widget body;

  /// The app bar to display at the top of the scaffold.
  final PreferredSizeWidget? appBar;

  /// The navigation bar to display at the top of the scaffold (iOS only).
  final ObstructingPreferredSizeWidget? navigationBar;

  /// The background color of the scaffold.
  final Color? backgroundColor;

  /// The bottom navigation bar to display at the bottom of the scaffold.
  final Widget? bottomNavigationBar;

  /// The floating action button to display (Android only).
  final Widget? floatingActionButton;

  /// The drawer to display (Android only).
  final Widget? drawer;

  /// Creates a platform-aware scaffold.
  ///
  /// For iOS, provide [navigationBar] instead of [appBar].
  /// For Android, provide [appBar] instead of [navigationBar].
  const PlatformScaffold({
    Key? key,
    required this.body,
    this.appBar,
    this.navigationBar,
    this.backgroundColor,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.drawer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (PlatformService.useCupertino) {
      // iOS-style scaffold
      return CupertinoPageScaffold(
        navigationBar: navigationBar as ObstructingPreferredSizeWidget?,
        backgroundColor: backgroundColor,
        child: SafeArea(
          bottom: bottomNavigationBar != null,
          child: Column(
            children: [
              Expanded(child: body),
              if (bottomNavigationBar != null) bottomNavigationBar!,
            ],
          ),
        ),
      );
    } else {
      // Android-style scaffold
      return Scaffold(
        appBar: appBar,
        backgroundColor: backgroundColor,
        body: body,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
        drawer: drawer,
      );
    }
  }
}
