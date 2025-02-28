import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';

class NotesList extends StatelessWidget {
  const NotesList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotesProvider>(
      builder: (context, notesProvider, child) {
        final notes = notesProvider.filteredNotes;
        final selectedNote = notesProvider.selectedNote;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              notesProvider.selectedFolder?.name ?? 'All Notes',
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => notesProvider.addNote(),
              ),
            ],
          ),
          body: notes.isEmpty
              ? const Center(
                  child: Text('No notes yet'),
                )
              : ListView.builder(
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    final isSelected = selectedNote?.id == note.id;

                    return ListTile(
                      title: Text(
                        note.title.isEmpty ? 'Untitled' : note.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM d, yyyy').format(note.updatedAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      selected: isSelected,
                      onTap: () => notesProvider.selectNote(note),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () => _showNoteOptions(context, note),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  void _showNoteOptions(BuildContext context, Note note) {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text('Move to Folder'),
            onTap: () {
              Navigator.pop(context);
              _showMoveFolderDialog(context, note);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete'),
            onTap: () {
              Navigator.pop(context);
              notesProvider.deleteNote(note.id);
            },
          ),
        ],
      ),
    );
  }

  void _showMoveFolderDialog(BuildContext context, Note note) {
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
                selected: note.folder == null,
                onTap: () {
                  notesProvider.moveNoteToFolder(note.id, null);
                  Navigator.pop(context);
                },
              ),

              const Divider(),

              // Folders list
              ...notesProvider.folders.map((folder) => ListTile(
                    leading: const Icon(Icons.folder),
                    title: Text(folder.name),
                    selected: note.folder == folder.id,
                    onTap: () {
                      notesProvider.moveNoteToFolder(note.id, folder.id);
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
