import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';
import 'unified_markdown_editor.dart';
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
    print(
        'Content changed, scheduling save: ${_contentController.text.length} characters');

    // Cancel any pending save operation
    _saveTimer?.cancel();

    // Start a new timer
    _saveTimer = Timer(const Duration(seconds: 5), () {
      print('Debounce timer expired, saving note');
      _saveNoteImmediately();
    });
  }

  // Save immediately without debounce
  void _saveNoteImmediately() {
    print(
        'Saving note immediately, content length: ${_contentController.text.length}');
    print(
        'Content preview: "${_contentController.text.substring(0, _contentController.text.length > 100 ? 100 : _contentController.text.length)}..."');

    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    notesProvider.updateNote(
      widget.note.id,
      title: _titleController.text,
      content: _contentController.text,
    );
    _hasUnsavedChanges = false;
    print('Note saved to provider');
  }

  // Insert markdown formatting at cursor position
  void _insertMarkdown(String markdownSyntax, {String? placeholder}) {
    final text = _contentController.text;
    final selection = _contentFocusNode.hasFocus
        ? TextSelection(
            baseOffset: _contentController.selection.baseOffset,
            extentOffset: _contentController.selection.extentOffset,
          )
        : const TextSelection.collapsed(offset: 0);

    // Get selected text or use placeholder
    final selectedText = selection.textInside(text);
    final textToInsert = selectedText.isEmpty && placeholder != null
        ? placeholder
        : selectedText;

    // Format based on markdown syntax type
    String newText;
    int newCursorPosition;

    if (markdownSyntax == '**') {
      // Bold
      newText = text.replaceRange(
          selection.start, selection.end, '**$textToInsert**');
      newCursorPosition = selection.start + 2 + textToInsert.length + 2;
    } else if (markdownSyntax == '*') {
      // Italic
      newText =
          text.replaceRange(selection.start, selection.end, '*$textToInsert*');
      newCursorPosition = selection.start + 1 + textToInsert.length + 1;
    } else if (markdownSyntax == '- ') {
      // Unordered list
      newText =
          text.replaceRange(selection.start, selection.end, '- $textToInsert');
      newCursorPosition = selection.start + 2 + textToInsert.length;
    } else if (markdownSyntax == '1. ') {
      // Ordered list
      newText =
          text.replaceRange(selection.start, selection.end, '1. $textToInsert');
      newCursorPosition = selection.start + 3 + textToInsert.length;
    } else if (markdownSyntax == '# ') {
      // Heading 1
      newText =
          text.replaceRange(selection.start, selection.end, '# $textToInsert');
      newCursorPosition = selection.start + 2 + textToInsert.length;
    } else if (markdownSyntax == '## ') {
      // Heading 2
      newText =
          text.replaceRange(selection.start, selection.end, '## $textToInsert');
      newCursorPosition = selection.start + 3 + textToInsert.length;
    } else if (markdownSyntax == '[](url)') {
      // Link
      newText = text.replaceRange(
          selection.start, selection.end, '[$textToInsert](url)');
      newCursorPosition = selection.start + 1 + textToInsert.length + 1;
    } else if (markdownSyntax == '`') {
      // Code
      newText =
          text.replaceRange(selection.start, selection.end, '`$textToInsert`');
      newCursorPosition = selection.start + 1 + textToInsert.length + 1;
    } else {
      // Default: just insert the markdown syntax
      newText = text.replaceRange(
          selection.start, selection.end, '$markdownSyntax$textToInsert');
      newCursorPosition =
          selection.start + markdownSyntax.length + textToInsert.length;
    }

    // Update text controller
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPosition),
    );

    // Trigger save
    _saveNote();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).colorScheme.background;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    // Format date for display
    final dateFormat = DateFormat('dd. MMMM yyyy um HH:mm');
    final formattedDate = dateFormat.format(widget.note.updatedAt);

    return Row(
      children: [
        // Main content
        Expanded(
          child: Scaffold(
            backgroundColor: backgroundColor,
            appBar: AppBar(
              backgroundColor: backgroundColor,
              leading: Container(
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
                // Toolbar icons
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
                  icon: const Icon(Icons.format_list_bulleted, size: 18),
                  tooltip: 'Lists',
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.table_chart_outlined, size: 18),
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
                const SizedBox(width: 16),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(24),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                  alignment: Alignment.centerRight,
                  child: Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 11,
                      color: textColor.withOpacity(0.6),
                    ),
                  ),
                ),
              ),
            ),
            body: Column(
              children: [
                // Title field
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
