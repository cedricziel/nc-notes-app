import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import '../providers/notes_provider.dart';
import '../widgets/folders_sidebar.dart';
import '../widgets/notes_list.dart';
import '../widgets/note_editor.dart';
import 'login_screen.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notesProvider = Provider.of<NotesProvider>(context);

    // Determine if we're running on macOS
    final bool isMacOS = Platform.isMacOS;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nextcloud Notes'),
        // Use macOS-style window controls if on macOS
        toolbarHeight: isMacOS ? 38 : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Sync with server',
            onPressed: notesProvider.isAuthenticated
                ? () => notesProvider.syncWithServer()
                : null,
          ),
          IconButton(
            icon: Icon(notesProvider.isAuthenticated
                ? Icons.logout
                : Icons.login),
            tooltip: notesProvider.isAuthenticated
                ? 'Logout'
                : 'Login to Nextcloud',
            onPressed: () async {
              if (notesProvider.isAuthenticated) {
                // Logout
                await notesProvider.logout();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logged out successfully')),
                );
              } else {
                // Navigate to login screen
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );

                if (result == true) {
                  // Login successful, initialize API
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Initializing connection to Nextcloud...')),
                  );

                  // Show loading indicator
                  notesProvider.setState(loading: true);

                  try {
                    final success = await notesProvider.login();
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Connected to Nextcloud successfully!')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${notesProvider.errorMessage ?? "Unknown error"}')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error connecting to Nextcloud: $e')),
                    );
                    notesProvider.setState(loading: false);
                  }
                }
              }
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Add a small left padding on macOS for better aesthetics
          if (isMacOS) const SizedBox(width: 8),
          // Folders sidebar (left)
          SizedBox(
            width: isMacOS ? 220 : 200,
            child: const FoldersSidebar(),
          ),

          // Vertical divider
          const VerticalDivider(width: 1, thickness: 1),

          // Notes list (middle)
          SizedBox(
            width: isMacOS ? 280 : 250,
            child: const NotesList(),
          ),

          // Vertical divider
          const VerticalDivider(width: 1, thickness: 1),

          // Note editor (right)
          Expanded(
            child: Consumer<NotesProvider>(
              builder: (context, notesProvider, child) {
                final selectedNote = notesProvider.selectedNote;

                if (selectedNote == null) {
                  return const Center(
                    child: Text('Select a note or create a new one'),
                  );
                }

                // Add some padding for macOS
                return Padding(
                  padding: isMacOS
                      ? const EdgeInsets.fromLTRB(0, 8, 8, 8)
                      : EdgeInsets.zero,
                  child: NoteEditor(note: selectedNote),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
