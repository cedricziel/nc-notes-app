import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

/// A service to detect the current platform and provide platform-specific utilities.
/// This is a thin wrapper around flutter_platform_widgets' platform detection.
class PlatformService {
  /// Returns true if the app is running on iOS.
  static bool get isIOS {
    return !kIsWeb && Platform.isIOS;
  }

  /// Returns true if the app is running on Android.
  static bool get isAndroid {
    return !kIsWeb && Platform.isAndroid;
  }

  /// Returns true if the app is running on macOS.
  static bool get isMacOS {
    return !kIsWeb && Platform.isMacOS;
  }

  /// Returns true if the app is running on the web.
  static bool get isWeb {
    return kIsWeb;
  }

  /// Returns true if the app should use Cupertino (iOS-style) widgets.
  ///
  /// This returns true for iOS and macOS platforms.
  static bool get useCupertino {
    return isIOS || isMacOS;
  }
}
