import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'platform_service.dart';

/// A platform-aware app widget that uses either a [CupertinoApp]
/// or a [MaterialApp] based on the platform.
class PlatformApp extends StatelessWidget {
  /// The title of the app.
  final String title;

  /// The theme for the app.
  final ThemeData? theme;

  /// The dark theme for the app.
  final ThemeData? darkTheme;

  /// The Cupertino theme for the app.
  final CupertinoThemeData? cupertinoTheme;

  /// The home widget for the app.
  final Widget? home;

  /// The routes for the app.
  final Map<String, WidgetBuilder>? routes;

  /// The initial route for the app.
  final String? initialRoute;

  /// The route generator for the app.
  final RouteFactory? onGenerateRoute;

  /// The unknown route handler for the app.
  final RouteFactory? onUnknownRoute;

  /// The navigator observers for the app.
  final List<NavigatorObserver>? navigatorObservers;

  /// The builder for the app.
  final TransitionBuilder? builder;

  /// The color for the app.
  final Color? color;

  /// The locale for the app.
  final Locale? locale;

  /// The supported locales for the app.
  final Iterable<Locale>? supportedLocales;

  /// The locale resolution callback for the app.
  final LocaleResolutionCallback? localeResolutionCallback;

  /// The locale list resolution callback for the app.
  final LocaleListResolutionCallback? localeListResolutionCallback;

  /// The debug show material grid flag for the app.
  final bool debugShowMaterialGrid;

  /// The show performance overlay flag for the app.
  final bool showPerformanceOverlay;

  /// The checkerboard raster cache images flag for the app.
  final bool checkerboardRasterCacheImages;

  /// The checkerboard offscreen layers flag for the app.
  final bool checkerboardOffscreenLayers;

  /// The show semantics debugger flag for the app.
  final bool showSemanticsDebugger;

  /// The debug show checked mode banner flag for the app.
  final bool debugShowCheckedModeBanner;

  /// Creates a platform-aware app.
  const PlatformApp({
    Key? key,
    required this.title,
    this.theme,
    this.darkTheme,
    this.cupertinoTheme,
    this.home,
    this.routes,
    this.initialRoute,
    this.onGenerateRoute,
    this.onUnknownRoute,
    this.navigatorObservers,
    this.builder,
    this.color,
    this.locale,
    this.supportedLocales,
    this.localeResolutionCallback,
    this.localeListResolutionCallback,
    this.debugShowMaterialGrid = false,
    this.showPerformanceOverlay = false,
    this.checkerboardRasterCacheImages = false,
    this.checkerboardOffscreenLayers = false,
    this.showSemanticsDebugger = false,
    this.debugShowCheckedModeBanner = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (PlatformService.useCupertino) {
      // iOS-style app
      return CupertinoApp(
        title: title,
        theme: cupertinoTheme ?? const CupertinoThemeData(),
        home: home,
        routes: routes ?? const {},
        initialRoute: initialRoute,
        onGenerateRoute: onGenerateRoute,
        onUnknownRoute: onUnknownRoute,
        navigatorObservers: navigatorObservers ?? const [],
        builder: builder,
        color: color,
        locale: locale,
        supportedLocales: supportedLocales ?? const [Locale('en', 'US')],
        localeResolutionCallback: localeResolutionCallback,
        localeListResolutionCallback: localeListResolutionCallback,
        showPerformanceOverlay: showPerformanceOverlay,
        checkerboardRasterCacheImages: checkerboardRasterCacheImages,
        checkerboardOffscreenLayers: checkerboardOffscreenLayers,
        showSemanticsDebugger: showSemanticsDebugger,
        debugShowCheckedModeBanner: debugShowCheckedModeBanner,
      );
    } else {
      // Android-style app
      return MaterialApp(
        title: title,
        theme: theme,
        darkTheme: darkTheme,
        home: home,
        routes: routes ?? const {},
        initialRoute: initialRoute,
        onGenerateRoute: onGenerateRoute,
        onUnknownRoute: onUnknownRoute,
        navigatorObservers: navigatorObservers ?? const [],
        builder: builder,
        color: color,
        locale: locale,
        supportedLocales: supportedLocales ?? const [Locale('en', 'US')],
        localeResolutionCallback: localeResolutionCallback,
        localeListResolutionCallback: localeListResolutionCallback,
        debugShowMaterialGrid: debugShowMaterialGrid,
        showPerformanceOverlay: showPerformanceOverlay,
        checkerboardRasterCacheImages: checkerboardRasterCacheImages,
        checkerboardOffscreenLayers: checkerboardOffscreenLayers,
        showSemanticsDebugger: showSemanticsDebugger,
        debugShowCheckedModeBanner: debugShowCheckedModeBanner,
      );
    }
  }
}
