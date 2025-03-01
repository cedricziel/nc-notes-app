import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/note.dart';
import '../../providers/notes_provider.dart';
import '../../widgets/unified_markdown_editor.dart';
import '../../widgets/sync_indicator.dart';

/// Mobile version of the note editor screen.
/// Shows the editor for a single note.
class MobileEditorScreen extends StatefulWidget {
  final String noteId;

  const MobileEditorScreen({
    super.key,
    required this.noteId,
  });

  @override
  State<MobileEditorScreen> createState() => _MobileEditorScreenState();
}

class _MobileEditorScreenState extends State<MobileEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late FocusNode _contentFocusNode;
  Timer? _saveTimer;
  bool _hasUnsavedChanges = false;
  Note? _note;

  @override
  void initState() {
    super.initState();
    _contentFocusNode = FocusNode();

    // Initialize with empty controllers
    _titleController = TextEditingController();
    _contentController = TextEditingController();

    // Load the note
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notesProvider = Provider.of<NotesProvider>(context, listen: false);
      final note = notesProvider.notes.firstWhere(
        (note) => note.id == widget.noteId,
        orElse: () => notesProvider.notes.first,
      );

      setState(() {
        _note = note;
        _titleController.text = note.title;
        _contentController.text = note.content;
      });

      // Select the note in the provider
      notesProvider.selectNote(note);
    });
  }

  @override
  void dispose() {
    // Cancel timer when widget is disposed
    _saveTimer?.cancel();

    // Save any pending changes before disposing
    if (_hasUnsavedChanges) {
      _saveNoteImmediately();
    }

    _titleController.dispose();
    _contentController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  // Debounced save with 2-second delay
  void _saveNote() {
    _hasUnsavedChanges = true;

    // Cancel any pending save operation
    _saveTimer?.cancel();

    // Start a new timer
    _saveTimer = Timer(const Duration(seconds: 2), () {
      _saveNoteImmediately();
    });
  }

  // Save immediately without debounce
  void _saveNoteImmediately() {
    if (_note == null) return;

    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    notesProvider.updateNote(
      _note!.id,
      title: _titleController.text,
      content: _contentController.text,
    );
    _hasUnsavedChanges = false;
  }

  @override
  Widget build(BuildContext context) {
    if (_note == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).colorScheme.surface;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    // Format date for display
    final dateFormat = DateFormat('dd. MMMM yyyy, HH:mm');
    final formattedDate = dateFormat.format(_note!.updatedAt);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
            _titleController.text.isEmpty ? 'Untitled' : _titleController.text),
        backgroundColor: backgroundColor,
        actions: [
          // Sync indicator
          Consumer<NotesProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading || provider.isSaving) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: SyncIndicator(),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // More options menu
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteNoteDialog(context);
              } else if (value == 'move') {
                _showMoveFolderDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'move',
                child: Row(
                  children: [
                    Icon(Icons.folder),
                    SizedBox(width: 8),
                    Text('Move to Folder'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete),
                    SizedBox(width: 8),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Last edited info
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Last edited: $formattedDate',
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),

          // Title field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Title',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintStyle: TextStyle(color: textColor.withOpacity(0.6)),
              ),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              onChanged: (_) => _saveNote(),
              onSubmitted: (_) {
                _contentFocusNode.requestFocus();
              },
            ),
          ),

          // Content area - unified markdown editor
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: UnifiedMarkdownEditor(
                initialMarkdown: _contentController.text,
                onChanged: (newContent) {
                  _contentController.text = newContent;
                  _saveNote();
                },
                showBlockControls: false, // Simplified controls for mobile
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.format_bold),
              onPressed: () {
                // Insert bold markdown
                _insertMarkdown('**', '**', 'bold text');
              },
            ),
            IconButton(
              icon: const Icon(Icons.format_italic),
              onPressed: () {
                // Insert italic markdown
                _insertMarkdown('*', '*', 'italic text');
              },
            ),
            IconButton(
              icon: const Icon(Icons.format_list_bulleted),
              onPressed: () {
                // Insert bullet list
                _insertMarkdown('- ', '', 'List item');
              },
            ),
            IconButton(
              icon: const Icon(Icons.format_list_numbered),
              onPressed: () {
                // Insert numbered list
                _insertMarkdown('1. ', '', 'List item');
              },
            ),
            IconButton(
              icon: const Icon(Icons.code),
              onPressed: () {
                // Insert code block
                _insertMarkdown('```\n', '\n```', 'code');
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to insert markdown syntax
  void _insertMarkdown(String prefix, String suffix, String placeholder) {
    // This is a simplified version - in a real app, you would need to
    // interact with the markdown editor's API to insert text at the cursor
    final currentContent = _contentController.text;
    _contentController.text = '$currentContent$prefix$placeholder$suffix';
    _saveNote();
  }

  void _showDeleteNoteDialog(BuildContext context) {
    if (_note == null) return;

    final notesProvider = Provider.of<NotesProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              notesProvider.deleteNote(_note!.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to notes list
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showMoveFolderDialog(BuildContext context) {
    if (_note == null) return;

    final notesProvider = Provider.of<NotesProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to Folder'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              // No folder option
              ListTile(
                leading: const Icon(Icons.notes),
                title: const Text('No Folder'),
                selected: _note!.folder == null,
                onTap: () {
                  notesProvider.moveNoteToFolder(_note!.id, null);
                  Navigator.pop(context);
                },
              ),

              const Divider(),

              // Folders list
              ...notesProvider.folders.map((folder) => ListTile(
                    leading: const Icon(Icons.folder),
                    title: Text(folder.name),
                    selected: _note!.folder == folder.id,
                    onTap: () {
                      notesProvider.moveNoteToFolder(_note!.id, folder.id);
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
