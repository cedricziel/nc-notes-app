import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'platform_service.dart';

/// This file re-exports the PlatformAlertDialog and related classes from flutter_platform_widgets.
///
/// We're using the package's implementation directly instead of our custom implementation.
/// For usage information, see the flutter_platform_widgets documentation.
export 'package:flutter_platform_widgets/flutter_platform_widgets.dart'
    show PlatformAlertDialog, PlatformDialogAction, showPlatformDialog;

/// Shows a platform-aware confirmation dialog.
/// This is a convenience wrapper around PlatformAlertDialog.
Future<bool?> showPlatformConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String? cancelText,
  String? confirmText,
  bool isDestructive = false,
}) {
  final isCupertino = PlatformService.useCupertino;

  return showPlatformDialog<bool>(
    context: context,
    builder: (context) => PlatformAlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        PlatformDialogAction(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText ?? (isCupertino ? 'Cancel' : 'CANCEL')),
        ),
        PlatformDialogAction(
          onPressed: () => Navigator.of(context).pop(true),
          cupertino: (_, __) => CupertinoDialogActionData(
            isDestructiveAction: isDestructive,
            isDefaultAction: !isDestructive,
          ),
          material: (_, __) => MaterialDialogActionData(
            style: TextButton.styleFrom(
              foregroundColor: isDestructive ? Colors.red : null,
            ),
          ),
          child: Text(confirmText ?? (isCupertino ? 'OK' : 'OK')),
        ),
      ],
    ),
  );
}
