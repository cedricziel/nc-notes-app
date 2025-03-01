import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../utils/keyboard_shortcuts.dart';
import 'unified_markdown_editor.dart' show UnifiedMarkdownEditor, EditorMode;
import 'sync_indicator.dart';

class MarkdownEditor extends StatefulWidget {
  final Note note;

  const MarkdownEditor({super.key, required this.note});

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late FocusNode _contentFocusNode;
  Timer? _saveTimer;
  bool _hasUnsavedChanges = false;

  // Current editor mode
  EditorMode _editorMode = EditorMode.editRaw;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);
    _contentFocusNode = FocusNode();
  }

  @override
  void didUpdateWidget(MarkdownEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.note.id != widget.note.id) {
      _titleController.text = widget.note.title;
      _contentController.text = widget.note.content;
    }
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

  // Debounced save with 5-second delay
  void _saveNote() {
    _hasUnsavedChanges = true;

    // Debug logging for content changes

    // Cancel any pending save operation
    _saveTimer?.cancel();

    // Start a new timer
    _saveTimer = Timer(const Duration(seconds: 5), () {
      _saveNoteImmediately();
    });
  }

  // Save immediately without debounce
  void _saveNoteImmediately() {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    notesProvider.updateNote(
      widget.note.id,
      title: _titleController.text,
      content: _contentController.text,
    );
    _hasUnsavedChanges = false;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).colorScheme.surface;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    // Format date for display
    final dateFormat = DateFormat('dd. MMMM yyyy um HH:mm');
    final formattedDate = dateFormat.format(widget.note.updatedAt);

    // Wrap the Row with keyboard shortcuts
    return Shortcuts(
      shortcuts: EditorShortcuts.getShortcuts(),
      child: Actions(
        actions: {
          SaveNoteIntent: CallbackAction<SaveNoteIntent>(
            onInvoke: (SaveNoteIntent intent) {
              _saveNoteImmediately();
              // Show a snackbar to indicate the note was saved
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Note saved'),
                  duration: const Duration(seconds: 1),
                ),
              );
              return null;
            },
          ),
        },
        child: Row(
          children: [
            // Main content
            Expanded(
              child: Scaffold(
                backgroundColor: backgroundColor,
                appBar: AppBar(
                  backgroundColor: backgroundColor,
                  leading: SizedBox(
                    width: 60,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: 'New Note',
                          onPressed: () =>
                              Provider.of<NotesProvider>(context, listen: false)
                                  .addNote(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                        ),
                        // Sync indicator next to the pencil icon
                        const SyncIndicator(),
                      ],
                    ),
                  ),
                  leadingWidth: 60, // Adjust width to fit both icons
                  toolbarHeight: 36,
                  actions: [
                    // Last edited date in the app bar
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Center(
                        child: Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 11,
                            color: textColor.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                body: Column(
                  children: [
                    // Title field and editor mode toggle in the same row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          // Title field
                          Expanded(
                            child: TextField(
                              controller: _titleController,
                              decoration: InputDecoration(
                                hintText: 'Title',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                hintStyle: TextStyle(
                                    color: textColor.withOpacity(0.6)),
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

                          // Editor mode toggle
                          ToggleButtons(
                            isSelected: [
                              _editorMode == EditorMode.editRaw,
                              _editorMode == EditorMode.view,
                              _editorMode == EditorMode.editUnified,
                            ],
                            onPressed: (index) {
                              setState(() {
                                switch (index) {
                                  case 0:
                                    _editorMode = EditorMode.editRaw;
                                    break;
                                  case 1:
                                    _editorMode = EditorMode.view;
                                    break;
                                  case 2:
                                    _editorMode = EditorMode.editUnified;
                                    break;
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            constraints: const BoxConstraints(
                                minHeight: 36, minWidth: 36),
                            children: const [
                              Tooltip(
                                message: 'Edit Raw',
                                child: Icon(Icons.code, size: 18),
                              ),
                              Tooltip(
                                message: 'View',
                                child: Icon(Icons.visibility, size: 18),
                              ),
                              Tooltip(
                                message: 'Edit Unified',
                                child: Icon(Icons.edit, size: 18),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Formatting toolbar - moved from app bar to below title
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.text_format, size: 18),
                            tooltip: 'Text Formatting',
                            onPressed: () {},
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.format_list_bulleted,
                                size: 18),
                            tooltip: 'Lists',
                            onPressed: () {},
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.table_chart_outlined,
                                size: 18),
                            tooltip: 'Tables',
                            onPressed: () {},
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.image_outlined, size: 18),
                            tooltip: 'Images',
                            onPressed: () {},
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),

                    // Content area - block-based markdown editor
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: UnifiedMarkdownEditor(
                          initialMarkdown: _contentController.text,
                          onChanged: (newContent) {
                            _contentController.text = newContent;
                            _saveNote();
                          },
                          showBlockControls: true,
                          editorMode: _editorMode,
                          onEditorModeChanged: (mode) {
                            setState(() {
                              _editorMode = mode;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
