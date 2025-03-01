import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/note.dart';
import '../../providers/notes_provider.dart';
import '../../widgets/unified_markdown_editor.dart';
import '../../widgets/sync_indicator.dart';
import '../../widgets/platform/platform_scaffold.dart';
import '../../widgets/platform/platform_app_bar.dart';
import '../../widgets/platform/platform_bottom_app_bar.dart';
import '../../widgets/platform/platform_service.dart';
import '../../widgets/platform/platform_list_tile.dart';
import '../../widgets/platform/platform_text_field.dart';

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

  // Helper method to check if we're running on iOS
  bool get isIOS {
    return PlatformService.isIOS;
  }

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

  // Helper method to insert markdown syntax
  void _insertMarkdown(String prefix, String suffix, String placeholder) {
    // This is a simplified version - in a real app, you would need to
    // interact with the markdown editor's API to insert text at the cursor
    final currentContent = _contentController.text;
    _contentController.text = '$currentContent$prefix$placeholder$suffix';
    _saveNote();
  }

  // Show iOS-style action sheet
  void _showCupertinoActionSheet(BuildContext context) {
    if (_note == null) return;

    final notesProvider = Provider.of<NotesProvider>(context, listen: false);

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showCupertinoMoveDialog(context);
            },
            child: const Text('Move to Folder'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _showCupertinoDeleteDialog(context);
            },
            child: const Text('Delete Note'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  // Show iOS-style delete confirmation dialog
  void _showCupertinoDeleteDialog(BuildContext context) {
    if (_note == null) return;

    final notesProvider = Provider.of<NotesProvider>(context, listen: false);

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
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

  // Show iOS-style move folder dialog
  void _showCupertinoMoveDialog(BuildContext context) {
    if (_note == null) return;

    final notesProvider = Provider.of<NotesProvider>(context, listen: false);

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                alignment: Alignment.centerLeft,
                child: const Text(
                  'Move to Folder',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  children: [
                    // No folder option
                    CupertinoListTile(
                      leading: const Icon(CupertinoIcons.doc),
                      title: const Text('No Folder'),
                      trailing: _note!.folder == null
                          ? const Icon(CupertinoIcons.check_mark)
                          : null,
                      onTap: () {
                        notesProvider.moveNoteToFolder(_note!.id, null);
                        Navigator.pop(context);
                      },
                    ),
                    // Folders list
                    ...notesProvider.folders.map((folder) => CupertinoListTile(
                          leading: const Icon(CupertinoIcons.folder),
                          title: Text(folder.name),
                          trailing: _note!.folder == folder.id
                              ? const Icon(CupertinoIcons.check_mark)
                              : null,
                          onTap: () {
                            notesProvider.moveNoteToFolder(
                                _note!.id, folder.id);
                            Navigator.pop(context);
                          },
                        )),
                  ],
                ),
              ),
              const Divider(height: 1),
              CupertinoButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Show Material delete dialog
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

  // Show Material move folder dialog
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
              PlatformListTile(
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
              ...notesProvider.folders.map((folder) => PlatformListTile(
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

  @override
  Widget build(BuildContext context) {
    if (_note == null) {
      // Loading state
      return PlatformScaffold(
        appBar: const PlatformAppBar(
          title: Text('Loading...'),
        ),
        body: Center(
          child: PlatformService.useCupertino
              ? const CupertinoActivityIndicator()
              : const CircularProgressIndicator(),
        ),
      );
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).colorScheme.surface;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Format date for display
    final dateFormat = DateFormat('dd. MMMM yyyy, HH:mm');
    final formattedDate = dateFormat.format(_note!.updatedAt);

    // Title for the app bar
    final title =
        _titleController.text.isEmpty ? 'Untitled' : _titleController.text;

    // Build the editor content (shared between iOS and Android)
    final editorContent = Column(
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
          child: PlatformTextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: 'Title',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintStyle: TextStyle(color: textColor.withOpacity(0.6)),
            ),
            placeholder: 'Title',
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
    );

    // Build the formatting toolbar (shared between iOS and Android)
    final formattingToolbar = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Icon(isIOS ? CupertinoIcons.bold : Icons.format_bold),
          onPressed: () => _insertMarkdown('**', '**', 'bold text'),
        ),
        IconButton(
          icon: Icon(isIOS ? CupertinoIcons.italic : Icons.format_italic),
          onPressed: () => _insertMarkdown('*', '*', 'italic text'),
        ),
        IconButton(
          icon: Icon(
              isIOS ? CupertinoIcons.list_bullet : Icons.format_list_bulleted),
          onPressed: () => _insertMarkdown('- ', '', 'List item'),
        ),
        IconButton(
          icon: Icon(
              isIOS ? CupertinoIcons.list_number : Icons.format_list_numbered),
          onPressed: () => _insertMarkdown('1. ', '', 'List item'),
        ),
        IconButton(
          icon: Icon(isIOS
              ? CupertinoIcons.chevron_left_slash_chevron_right
              : Icons.code),
          onPressed: () => _insertMarkdown('```\n', '\n```', 'code'),
        ),
      ],
    );

    // Build platform-specific actions
    List<Widget> appBarActions = [
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
    ];

    // Add platform-specific more options button
    if (PlatformService.useCupertino) {
      appBarActions.add(
        GestureDetector(
          onTap: () => _showCupertinoActionSheet(context),
          child: const Icon(CupertinoIcons.ellipsis),
        ),
      );
    } else {
      appBarActions.add(
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
      );
    }

    return PlatformScaffold(
      backgroundColor: backgroundColor,
      appBar: PlatformAppBar(
        title: Text(title),
        backgroundColor: backgroundColor,
        actions: appBarActions,
      ),
      body: editorContent,
      bottomNavigationBar: PlatformBottomAppBar(
        backgroundColor: backgroundColor,
        child: formattingToolbar,
      ),
    );
  }
}
