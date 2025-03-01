import 'package:flutter/material.dart';
import 'notes_screen.dart';
import 'mobile/mobile_folders_screen.dart';

/// A responsive layout that shows either a multi-pane layout on large screens
/// or a single-screen layout with navigation on small screens (like mobile devices).
class ResponsiveNotesLayout extends StatelessWidget {
  const ResponsiveNotesLayout({super.key});

  // Breakpoint for switching between layouts
  static const double _breakpoint = 600;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use screen width to determine which layout to show
        if (constraints.maxWidth > _breakpoint) {
          // Large screen: show multi-pane layout
          return const NotesScreen();
        } else {
          // Small screen: show mobile layout with navigation
          return const MobileFoldersScreen();
        }
      },
    );
  }
}

/// Enum to track which screen is currently active in the mobile layout
enum MobileScreen {
  folders,
  notes,
  editor,
}

/// Provider to manage the current screen in the mobile layout
class MobileNavigationProvider with ChangeNotifier {
  MobileScreen _currentScreen = MobileScreen.folders;
  MobileScreen get currentScreen => _currentScreen;

  // Navigation state
  String? _selectedFolderId;
  String? _selectedTagName;
  String? _selectedNoteId;

  String? get selectedFolderId => _selectedFolderId;
  String? get selectedTagName => _selectedTagName;
  String? get selectedNoteId => _selectedNoteId;

  // Navigate to the notes screen
  void navigateToNotes({String? folderId, String? tagName}) {
    _selectedFolderId = folderId;
    _selectedTagName = tagName;
    _currentScreen = MobileScreen.notes;
    notifyListeners();
  }

  // Navigate to the editor screen
  void navigateToEditor(String noteId) {
    _selectedNoteId = noteId;
    _currentScreen = MobileScreen.editor;
    notifyListeners();
  }

  // Navigate back to the folders screen
  void navigateToFolders() {
    _currentScreen = MobileScreen.folders;
    notifyListeners();
  }

  // Navigate back to the notes screen from the editor
  void navigateBackToNotes() {
    _currentScreen = MobileScreen.notes;
    notifyListeners();
  }
}
