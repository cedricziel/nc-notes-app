import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'platform_service.dart';
import 'platform_button.dart';

/// A platform-aware dialog widget that uses either a [CupertinoAlertDialog]
/// or an [AlertDialog] based on the platform.
class PlatformDialog extends StatelessWidget {
  /// The title of the dialog.
  final Widget? title;

  /// The content of the dialog.
  final Widget? content;

  /// The actions at the bottom of the dialog.
  final List<Widget>? actions;

  /// Creates a platform-aware dialog.
  const PlatformDialog({
    Key? key,
    this.title,
    this.content,
    this.actions,
  }) : super(key: key);

  /// Shows a platform-aware dialog.
  static Future<T?> show<T>({
    required BuildContext context,
    Widget? title,
    Widget? content,
    List<Widget>? actions,
    bool barrierDismissible = true,
  }) {
    if (PlatformService.useCupertino) {
      // iOS-style dialog
      return showCupertinoDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: (context) => PlatformDialog(
          title: title,
          content: content,
          actions: actions,
        ),
      );
    } else {
      // Android-style dialog
      return showDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: (context) => PlatformDialog(
          title: title,
          content: content,
          actions: actions,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (PlatformService.useCupertino) {
      // iOS-style dialog
      return CupertinoAlertDialog(
        title: title,
        content: content,
        actions: actions ?? [],
      );
    } else {
      // Android-style dialog
      return AlertDialog(
        title: title,
        content: content,
        actions: actions,
      );
    }
  }
}

/// A platform-aware dialog action widget that uses either a [CupertinoDialogAction]
/// or a [TextButton] based on the platform.
class PlatformDialogAction extends StatelessWidget {
  /// The callback that is called when the action is tapped.
  final VoidCallback? onPressed;

  /// The child widget of the action.
  final Widget child;

  /// Whether the action is destructive.
  final bool isDestructiveAction;

  /// Whether the action is the default action.
  final bool isDefaultAction;

  /// Creates a platform-aware dialog action.
  const PlatformDialogAction({
    Key? key,
    required this.onPressed,
    required this.child,
    this.isDestructiveAction = false,
    this.isDefaultAction = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (PlatformService.useCupertino) {
      // iOS-style dialog action
      return CupertinoDialogAction(
        onPressed: onPressed,
        isDestructiveAction: isDestructiveAction,
        isDefaultAction: isDefaultAction,
        child: child,
      );
    } else {
      // Android-style dialog action
      final theme = Theme.of(context);
      final textColor = isDestructiveAction
          ? Colors.red
          : isDefaultAction
              ? theme.colorScheme.primary
              : theme.textTheme.labelLarge?.color;

      return TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: textColor,
        ),
        child: child,
      );
    }
  }
}

/// Shows a platform-aware confirmation dialog.
Future<bool?> showPlatformConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String? cancelText,
  String? confirmText,
  bool isDestructive = false,
}) {
  return PlatformDialog.show<bool>(
    context: context,
    title: Text(title),
    content: Text(message),
    actions: [
      PlatformDialogAction(
        onPressed: () => Navigator.of(context).pop(false),
        child: Text(
            cancelText ?? (PlatformService.useCupertino ? 'Cancel' : 'CANCEL')),
      ),
      PlatformDialogAction(
        onPressed: () => Navigator.of(context).pop(true),
        isDestructiveAction: isDestructive,
        isDefaultAction: !isDestructive,
        child:
            Text(confirmText ?? (PlatformService.useCupertino ? 'OK' : 'OK')),
      ),
    ],
  );
}
