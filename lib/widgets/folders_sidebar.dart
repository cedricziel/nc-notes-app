import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/folder.dart';
import '../providers/notes_provider.dart';

class FoldersSidebar extends StatelessWidget {
  const FoldersSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotesProvider>(
      builder: (context, notesProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Folders'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showAddFolderDialog(context),
              ),
            ],
          ),
          body: Column(
            children: [
              // All Notes option
              ListTile(
                leading: const Icon(Icons.notes),
                title: const Text('All Notes'),
                selected: notesProvider.selectedFolder == null,
                onTap: () => notesProvider.selectFolder(null),
              ),

              const Divider(),

              // Folders list
              Expanded(
                child: ListView.builder(
                  itemCount: notesProvider.folders.length,
                  itemBuilder: (context, index) {
                    final folder = notesProvider.folders[index];
                    return ListTile(
                      leading: const Icon(Icons.folder),
                      title: Text(folder.name),
                      selected: notesProvider.selectedFolder?.id == folder.id,
                      onTap: () => notesProvider.selectFolder(folder),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () => _showFolderOptions(context, folder),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddFolderDialog(BuildContext context) {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Folder name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = textController.text.trim();
              if (name.isNotEmpty) {
                Provider.of<NotesProvider>(context, listen: false)
                    .addFolder(name);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showFolderOptions(BuildContext context, Folder folder) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Rename'),
            onTap: () {
              Navigator.pop(context);
              _showRenameFolderDialog(context, folder);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete'),
            onTap: () {
              Navigator.pop(context);
              _showDeleteFolderDialog(context, folder);
            },
          ),
        ],
      ),
    );
  }

  void _showRenameFolderDialog(BuildContext context, Folder folder) {
    final textController = TextEditingController(text: folder.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Folder'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Folder name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = textController.text.trim();
              if (name.isNotEmpty) {
                Provider.of<NotesProvider>(context, listen: false)
                    .updateFolder(folder.id, name);
                Navigator.pop(context);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showDeleteFolderDialog(BuildContext context, Folder folder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder'),
        content: Text(
          'Are you sure you want to delete "${folder.name}"? All notes in this folder will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<NotesProvider>(context, listen: false)
                  .deleteFolder(folder.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
