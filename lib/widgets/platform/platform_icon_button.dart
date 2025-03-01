import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

/// This file re-exports the PlatformIconButton from flutter_platform_widgets.
///
/// We're using the package's implementation directly instead of our custom implementation.
/// For usage information, see the flutter_platform_widgets documentation.
export 'package:flutter_platform_widgets/flutter_platform_widgets.dart'
    show PlatformIconButton;

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
    final isCupertinoPlatform = isCupertino(context);
    return PlatformIconButton(
      icon: Icon(
        isCupertinoPlatform ? Icons.arrow_back_ios : Icons.arrow_back,
        color: color,
      ),
      onPressed: onPressed ?? () => Navigator.of(context).pop(),
      cupertino: (_, __) => CupertinoIconButtonData(
        padding: EdgeInsets.zero,
      ),
      material: (_, __) => MaterialIconButtonData(
        tooltip: 'Back',
      ),
    );
  }
}
