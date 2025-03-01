import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import '../providers/notes_provider.dart';
import '../widgets/folders_sidebar.dart';
import '../widgets/notes_list.dart';
import '../widgets/markdown_editor.dart';
import 'login_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  // Default widths for the sidebars
  double foldersSidebarWidth = 200;
  double notesListWidth = 250;

  // Minimum and maximum widths for the sidebars
  final double minSidebarWidth = 150;
  final double maxSidebarWidth = 400;

  @override
  Widget build(BuildContext context) {
    final notesProvider = Provider.of<NotesProvider>(context);
    final bool isMacOS = Platform.isMacOS;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).colorScheme.background;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // Main content area
          Expanded(
            child: Row(
              children: [
                // Folders sidebar (left)
                SizedBox(
                  width: foldersSidebarWidth,
                  child: const FoldersSidebar(),
                ),

                // Resizable divider for folders sidebar
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      foldersSidebarWidth += details.delta.dx;
                      // Ensure the width stays within the allowed range
                      foldersSidebarWidth = foldersSidebarWidth.clamp(minSidebarWidth, maxSidebarWidth);
                    });
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeLeftRight,
                    child: Container(
                      width: 8, // Wider area for easier dragging
                      color: Colors.transparent,
                      child: Center(
                        child: Container(
                          width: 1,
                          color: isDarkMode ? const Color(0xFF3D3D3D) : const Color(0xFFE0E0E0),
                        ),
                      ),
                    ),
                  ),
                ),

                // Notes list (middle)
                SizedBox(
                  width: notesListWidth,
                  child: const NotesList(),
                ),

                // Resizable divider for notes list
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      notesListWidth += details.delta.dx;
                      // Ensure the width stays within the allowed range
                      notesListWidth = notesListWidth.clamp(minSidebarWidth, maxSidebarWidth);
                    });
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeLeftRight,
                    child: Container(
                      width: 8, // Wider area for easier dragging
                      color: Colors.transparent,
                      child: Center(
                        child: Container(
                          width: 1,
                          color: isDarkMode ? const Color(0xFF3D3D3D) : const Color(0xFFE0E0E0),
                        ),
                      ),
                    ),
                  ),
                ),

                // Note editor (right)
                Expanded(
                  child: Consumer<NotesProvider>(
                    builder: (context, notesProvider, child) {
                      final selectedNote = notesProvider.selectedNote;

                      if (selectedNote == null) {
                        return Center(
                          child: Text(
                            'Select a note or create a new one',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        );
                      }

                      return MarkdownEditor(note: selectedNote);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
