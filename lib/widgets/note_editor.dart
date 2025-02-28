import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';

class NoteEditor extends StatefulWidget {
  final Note note;

  const NoteEditor({super.key, required this.note});

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
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
  void didUpdateWidget(NoteEditor oldWidget) {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Note'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveNoteImmediately,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Title field
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Title',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              onChanged: (_) => _saveNote(),
              onSubmitted: (_) {
                _contentFocusNode.requestFocus();
              },
            ),

            const Divider(),

            // Content field
            Expanded(
              child: TextField(
                controller: _contentController,
                focusNode: _contentFocusNode,
                decoration: const InputDecoration(
                  hintText: 'Note content',
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 16),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                onChanged: (_) => _saveNote(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
