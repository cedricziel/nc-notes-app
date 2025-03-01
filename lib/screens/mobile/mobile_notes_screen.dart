import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart' as fpw;
import '../../models/note.dart';
import '../../providers/notes_provider.dart';
import '../../widgets/sync_indicator.dart';
import '../../widgets/platform/platform_app_bar.dart';
import '../../widgets/platform/platform_list_tile.dart';
import 'mobile_editor_screen.dart';

/// Mobile version of the notes list screen.
/// Shows notes filtered by folder or tag.
class MobileNotesScreen extends StatefulWidget {
  final String? folderId;
  final String? tagName;

  const MobileNotesScreen({
    super.key,
    this.folderId,
    this.tagName,
  });

  @override
  State<MobileNotesScreen> createState() => _MobileNotesScreenState();
}

class _MobileNotesScreenState extends State<MobileNotesScreen> {
  @override
  void initState() {
    super.initState();

    // Set the selected folder or tag in the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notesProvider = Provider.of<NotesProvider>(context, listen: false);

      if (widget.folderId != null) {
        final folder = notesProvider.folders.firstWhere(
          (folder) => folder.id == widget.folderId,
          orElse: () => notesProvider.folders.first,
        );
        notesProvider.selectFolder(folder);
      } else if (widget.tagName != null) {
        notesProvider.selectTag(widget.tagName);
      } else {
        notesProvider.selectFolder(null);
        notesProvider.selectTag(null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotesProvider>(
      builder: (context, notesProvider, child) {
        final notes = notesProvider.filteredNotes;
        final backgroundColor = Theme.of(context).colorScheme.surface;

        // Get title based on selected folder or tag
        String title = 'All Notes';
        if (widget.folderId != null) {
          final folder = notesProvider.folders.firstWhere(
            (folder) => folder.id == widget.folderId,
            orElse: () => notesProvider.folders.first,
          );
          title = folder.name;
        } else if (widget.tagName != null) {
          title = '#${widget.tagName}';
        }

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

        final notesListView = notes.isEmpty
            ? const Center(
                child: Text('No notes yet'),
              )
            : ListView(
                children: [
                  if (recentNotes.isNotEmpty) ...[
                    _buildSectionHeader(context, 'Last 7 Days'),
                    ...recentNotes.map((note) => _buildNoteItem(context, note)),
                  ],
                  if (olderNotes.isNotEmpty) ...[
                    _buildSectionHeader(context, 'Last 30 Days'),
                    ...olderNotes.map((note) => _buildNoteItem(context, note)),
                  ],
                  if (oldestNotes.isNotEmpty) ...[
                    _buildSectionHeader(context, 'Older'),
                    ...oldestNotes.map((note) => _buildNoteItem(context, note)),
                  ],
                ],
              );

        final fab = FloatingActionButton(
          onPressed: () async {
            // Create a new note
            await notesProvider.addNote();

            // Navigate to the editor for the new note
            if (notesProvider.selectedNote != null && mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MobileEditorScreen(
                    noteId: notesProvider.selectedNote!.id,
                  ),
                ),
              );
            }
          },
          child: const Icon(Icons.add),
        );

        final syncIndicator = Consumer<NotesProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading || provider.isSaving) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: SyncIndicator(),
              );
            }
            return const SizedBox.shrink();
          },
        );

        final platformAppBar = PlatformAppBar(
          title: Text(
            title,
            style: const TextStyle(
              inherit: true,
              fontFamily: 'SF Pro Text',
              fontSize: 17.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: backgroundColor,
          trailingActions: [syncIndicator],
          cupertino: (_, __) => fpw.CupertinoNavigationBarData(
            // Disable transitions to avoid TextStyle interpolation issues
            transitionBetweenRoutes: false,
          ),
        );

        return fpw.PlatformScaffold(
          backgroundColor: backgroundColor,
          appBar: platformAppBar,
          body: notesListView,
          material: (_, __) => fpw.MaterialScaffoldData(
            floatingActionButton: fab,
          ),
          cupertino: (_, __) => fpw.CupertinoPageScaffoldData(
              // For Cupertino, we don't need to specify the navigationBar here
              // as it's already handled by the PlatformAppBar
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
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildNoteItem(BuildContext context, Note note) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);

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
        border: Border(
          bottom: BorderSide(
            color:
                isDarkMode ? const Color(0xFF3D3D3D) : const Color(0xFFE0E0E0),
            width: 0.5,
          ),
        ),
      ),
      child: PlatformListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minLeadingWidth: 0,
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              noteIcon,
              size: 20,
              color: textColor.withOpacity(0.6),
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
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formattedDate,
              style: TextStyle(
                fontSize: 12,
                color: textColor.withOpacity(0.5),
              ),
            ),
          ],
        ),
        subtitle: note.content.isNotEmpty
            ? Text(
                note.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: textColor.withOpacity(0.7),
                ),
              )
            : null,
        onTap: () {
          // Select the note and navigate to the editor
          notesProvider.selectNote(note);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MobileEditorScreen(
                noteId: note.id,
              ),
            ),
          );
        },
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
          PlatformListTile(
            leading: const Icon(Icons.folder),
            title: const Text('Move to Folder'),
            onTap: () {
              Navigator.pop(context);
              _showMoveFolderDialog(context, note);
            },
          ),
          PlatformListTile(
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
              PlatformListTile(
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
              ...notesProvider.folders.map((folder) => PlatformListTile(
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
