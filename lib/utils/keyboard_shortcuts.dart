import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/platform/platform_service.dart';

/// Intent for saving a note
class SaveNoteIntent extends Intent {
  const SaveNoteIntent();
}

/// A class that provides keyboard shortcuts for the editor
class EditorShortcuts {
  /// Returns a map of keyboard shortcuts for the editor
  static Map<ShortcutActivator, Intent> getShortcuts() {
    // Use Command on macOS, Control on other platforms
    final LogicalKeyboardKey modifierKey = PlatformService.isMacOS
        ? LogicalKeyboardKey.meta
        : LogicalKeyboardKey.control;

    return {
      // Save shortcut (Command+S or Ctrl+S)
      SingleActivator(LogicalKeyboardKey.keyS,
          meta: PlatformService.isMacOS,
          control: !PlatformService.isMacOS): const SaveNoteIntent(),
    };
  }
}
