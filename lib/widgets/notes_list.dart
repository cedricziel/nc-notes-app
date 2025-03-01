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
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final backgroundColor = Theme.of(context).colorScheme.background;
        final textColor = isDarkMode ? Colors.white : Colors.black;

        // Group notes by time periods
        final now = DateTime.now();
        final last7Days = now.subtract(const Duration(days: 7));
        final last30Days = now.subtract(const Duration(days: 30));

        final recentNotes =
            notes.where((note) => note.updatedAt.isAfter(last7Days)).toList();
        final olderNotes = notes
            .where((note) =>
                note.updatedAt.isBefore(last7Days) &&
                note.updatedAt.isAfter(last30Days))
            .toList();
        final oldestNotes =
            notes.where((note) => note.updatedAt.isBefore(last30Days)).toList();

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: backgroundColor,
            toolbarHeight: 36,
            title: null, // Explicitly set title to null to remove it
            actions: [
              // List/Grid view toggle
              IconButton(
                icon: const Icon(Icons.view_list, size: 18),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.grid_view, size: 18),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 8),
              // Note actions
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 8),
              // Removed new note button as it's moved to the right panel
            ],
          ),
          body: notes.isEmpty
              ? const Center(
                  child: Text('No notes yet'),
                )
              : ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    if (recentNotes.isNotEmpty) ...[
                      _buildSectionHeader(context, 'Letzte 7 Tage'),
                      ...recentNotes.map((note) =>
                          _buildNoteItem(context, note, selectedNote)),
                    ],
                    if (olderNotes.isNotEmpty) ...[
                      _buildSectionHeader(context, 'Letzte 30 Tage'),
                      ...olderNotes.map((note) =>
                          _buildNoteItem(context, note, selectedNote)),
                    ],
                    if (oldestNotes.isNotEmpty) ...[
                      _buildSectionHeader(context, 'Januar'),
                      ...oldestNotes.map((note) =>
                          _buildNoteItem(context, note, selectedNote)),
                    ],
                  ],
                ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white70 : Colors.black54;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildNoteItem(BuildContext context, Note note, Note? selectedNote) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final isSelected = selectedNote?.id == note.id;
    final selectedColor = Theme.of(context).colorScheme.primary;

    // Format date as DD.MM.YY
    final dateFormat = DateFormat('dd.MM.yy');
    final formattedDate = dateFormat.format(note.updatedAt);

    // Get note icon based on content
    IconData noteIcon = Icons.note_outlined;
    if (note.content.contains('```')) {
      noteIcon = Icons.code;
    } else if (note.content.contains('![')) {
      noteIcon = Icons.image_outlined;
    } else if (note.content.contains('http')) {
      noteIcon = Icons.link;
    }

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? (isDarkMode
                ? const Color(0xFF3D3D3D)
                : const Color(0xFFE5E5E5).withOpacity(0.5))
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color:
                isDarkMode ? const Color(0xFF3D3D3D) : const Color(0xFFE0E0E0),
            width: 0.5,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minLeadingWidth: 0,
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              noteIcon,
              size: 16,
              color: isSelected ? selectedColor : textColor.withOpacity(0.6),
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                note.title.isEmpty ? 'Untitled' : note.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? selectedColor : textColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formattedDate,
              style: TextStyle(
                fontSize: 11,
                color: textColor.withOpacity(0.5),
              ),
            ),
          ],
        ),
        subtitle: note.content.isNotEmpty
            ? Text(
                note.content,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: textColor.withOpacity(0.7),
                ),
              )
            : null,
        dense: true,
        visualDensity: const VisualDensity(horizontal: 0, vertical: -3),
        selected: isSelected,
        onTap: () =>
            Provider.of<NotesProvider>(context, listen: false).selectNote(note),
        onLongPress: () => _showNoteOptions(context, note),
      ),
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
