import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'platform_service.dart';

/// A helper class for platform-specific theming.
class PlatformTheme {
  /// Returns the primary color for the current platform.
  static Color primaryColor(BuildContext context) {
    if (PlatformService.useCupertino) {
      return CupertinoColors.activeBlue.resolveFrom(context);
    } else {
      return Theme.of(context).colorScheme.primary;
    }
  }

  /// Returns the secondary color for the current platform.
  static Color secondaryColor(BuildContext context) {
    if (PlatformService.useCupertino) {
      return CupertinoColors.activeGreen.resolveFrom(context);
    } else {
      return Theme.of(context).colorScheme.secondary;
    }
  }

  /// Returns the background color for the current platform.
  static Color backgroundColor(BuildContext context) {
    if (PlatformService.useCupertino) {
      return CupertinoColors.systemBackground.resolveFrom(context);
    } else {
      return Theme.of(context).colorScheme.background;
    }
  }

  /// Returns the surface color for the current platform.
  static Color surfaceColor(BuildContext context) {
    if (PlatformService.useCupertino) {
      return CupertinoColors.secondarySystemBackground.resolveFrom(context);
    } else {
      return Theme.of(context).colorScheme.surface;
    }
  }

  /// Returns the error color for the current platform.
  static Color errorColor(BuildContext context) {
    if (PlatformService.useCupertino) {
      return CupertinoColors.destructiveRed.resolveFrom(context);
    } else {
      return Theme.of(context).colorScheme.error;
    }
  }

  /// Returns the text color for the current platform.
  static Color textColor(BuildContext context) {
    if (PlatformService.useCupertino) {
      return CupertinoColors.label.resolveFrom(context);
    } else {
      return Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    }
  }

  /// Returns the secondary text color for the current platform.
  static Color secondaryTextColor(BuildContext context) {
    if (PlatformService.useCupertino) {
      return CupertinoColors.secondaryLabel.resolveFrom(context);
    } else {
      return Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black54;
    }
  }

  /// Returns the divider color for the current platform.
  static Color dividerColor(BuildContext context) {
    if (PlatformService.useCupertino) {
      return CupertinoColors.separator.resolveFrom(context);
    } else {
      return Theme.of(context).dividerColor;
    }
  }

  /// Returns the card color for the current platform.
  static Color cardColor(BuildContext context) {
    if (PlatformService.useCupertino) {
      return CupertinoColors.tertiarySystemBackground.resolveFrom(context);
    } else {
      return Theme.of(context).cardColor;
    }
  }

  /// Returns the disabled color for the current platform.
  static Color disabledColor(BuildContext context) {
    if (PlatformService.useCupertino) {
      return CupertinoColors.inactiveGray.resolveFrom(context);
    } else {
      return Theme.of(context).disabledColor;
    }
  }

  /// Returns the placeholder text color for the current platform.
  static Color placeholderColor(BuildContext context) {
    if (PlatformService.useCupertino) {
      return CupertinoColors.placeholderText.resolveFrom(context);
    } else {
      return Theme.of(context).hintColor;
    }
  }

  /// Returns the text style for the current platform.
  static TextStyle textStyle(BuildContext context) {
    if (PlatformService.useCupertino) {
      return const CupertinoTextThemeData().textStyle;
    } else {
      return Theme.of(context).textTheme.bodyLarge ?? const TextStyle();
    }
  }

  /// Returns the title text style for the current platform.
  static TextStyle titleTextStyle(BuildContext context) {
    if (PlatformService.useCupertino) {
      return const CupertinoTextThemeData().navTitleTextStyle;
    } else {
      return Theme.of(context).textTheme.titleLarge ?? const TextStyle();
    }
  }

  /// Returns the subtitle text style for the current platform.
  static TextStyle subtitleTextStyle(BuildContext context) {
    if (PlatformService.useCupertino) {
      return const CupertinoTextThemeData().tabLabelTextStyle;
    } else {
      return Theme.of(context).textTheme.titleMedium ?? const TextStyle();
    }
  }

  /// Returns the caption text style for the current platform.
  static TextStyle captionTextStyle(BuildContext context) {
    if (PlatformService.useCupertino) {
      return const CupertinoTextThemeData().actionTextStyle;
    } else {
      return Theme.of(context).textTheme.bodySmall ?? const TextStyle();
    }
  }

  /// Returns the button text style for the current platform.
  static TextStyle buttonTextStyle(BuildContext context) {
    if (PlatformService.useCupertino) {
      return const CupertinoTextThemeData().actionTextStyle;
    } else {
      return Theme.of(context).textTheme.labelLarge ?? const TextStyle();
    }
  }

  /// Returns the border radius for the current platform.
  static BorderRadius borderRadius({double radius = 8.0}) {
    return BorderRadius.circular(radius);
  }

  /// Returns the edge insets for the current platform.
  static EdgeInsets padding(
      {double horizontal = 16.0, double vertical = 16.0}) {
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
  }

  /// Returns the shadow for the current platform.
  static List<BoxShadow> shadow(BuildContext context) {
    if (PlatformService.useCupertino) {
      return [
        BoxShadow(
          color:
              CupertinoColors.separator.resolveFrom(context).withOpacity(0.3),
          blurRadius: 5.0,
          offset: const Offset(0, 2),
        ),
      ];
    } else {
      return [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 5.0,
          offset: const Offset(0, 2),
        ),
      ];
    }
  }
}
