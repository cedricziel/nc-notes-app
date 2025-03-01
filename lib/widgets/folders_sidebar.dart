import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/folder.dart';
import '../providers/notes_provider.dart';
import '../screens/login_screen.dart';
import 'sync_indicator.dart';

class FoldersSidebar extends StatelessWidget {
  const FoldersSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotesProvider>(
      builder: (context, notesProvider, child) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final backgroundColor = Theme.of(context).colorScheme.surface;

        return Scaffold(
          backgroundColor: backgroundColor,
          body: Stack(
            children: [
              // Main scrollable content
              Padding(
                padding: const EdgeInsets.only(
                    bottom: 50), // Add padding for the bottom controls
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // Nextcloud Section with dynamic folders
                    if (notesProvider.isAuthenticated) ...[
                      _buildSectionHeader(context, 'Nextcloud'),
                      // All Nextcloud Notes
                      _buildFolderItem(
                        context,
                        icon: Icons.cloud_outlined,
                        title: 'All Notes',
                        count: notesProvider.notes.length.toString(),
                        isSelected: notesProvider.selectedFolder == null &&
                            notesProvider.selectedTag == null,
                        onTap: () => notesProvider.selectFolder(null),
                      ),
                      // Dynamic folders from provider
                      if (notesProvider.folders.isNotEmpty) ...[
                        ...notesProvider.folders.map((folder) =>
                            _buildFolderItem(
                              context,
                              icon: Icons.folder_outlined,
                              title: folder.name,
                              count: notesProvider
                                  .getNoteCountForFolder(folder.id)
                                  .toString(),
                              isSelected:
                                  notesProvider.selectedFolder?.id == folder.id,
                              onTap: () => notesProvider.selectFolder(folder),
                              onLongPress: () =>
                                  _showFolderOptions(context, folder),
                            )),
                      ],
                    ],

                    // Tags Section
                    _buildSectionHeader(context, 'Tags'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Wrap(
                        spacing: 8.0, // horizontal space between chips
                        runSpacing: 8.0, // vertical space between lines
                        children: [
                          _buildTagItem(
                            context,
                            'Alle Tags',
                            isSelected: notesProvider.selectedTag == null,
                            onTap: () => notesProvider.selectTag(null),
                          ),
                          ...notesProvider.allTags.map((tag) => _buildTagItem(
                                context,
                                tag,
                                isSelected: notesProvider.selectedTag == tag,
                                onTap: () => notesProvider.selectTag(tag),
                              )),
                        ],
                      ),
                    ),

                    // Add extra padding at the bottom to ensure content is visible above the sticky controls
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // Sticky bottom controls
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    border: Border(
                      top: BorderSide(
                        color: isDarkMode
                            ? const Color(0xFF3D3D3D)
                            : const Color(0xFFE0E0E0),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Sync button with animated indicator
                      Consumer<NotesProvider>(
                        builder: (context, provider, child) {
                          // If syncing, show the animated indicator
                          if (provider.isLoading || provider.isSaving) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: SyncIndicator(),
                            );
                          }

                          // Otherwise show the regular sync button
                          return IconButton(
                            icon: const Icon(Icons.refresh, size: 18),
                            tooltip: 'Sync with server',
                            onPressed: provider.isAuthenticated
                                ? () => provider.syncWithServer()
                                : null,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            visualDensity: VisualDensity.compact,
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          notesProvider.isAuthenticated
                              ? Icons.logout
                              : Icons.login,
                          size: 18,
                        ),
                        tooltip: notesProvider.isAuthenticated
                            ? 'Logout'
                            : 'Login to Nextcloud',
                        onPressed: () async {
                          if (notesProvider.isAuthenticated) {
                            // Logout
                            await notesProvider.logout();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Logged out successfully')),
                            );
                          } else {
                            // Navigate to login screen
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );

                            if (result == true) {
                              // Login successful, initialize API
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Initializing connection to Nextcloud...')),
                              );

                              // Show loading indicator
                              notesProvider.setState(loading: true);

                              try {
                                final success = await notesProvider.login();
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Connected to Nextcloud successfully!')),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Error: ${notesProvider.errorMessage ?? "Unknown error"}')),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Error connecting to Nextcloud: $e')),
                                );
                                notesProvider.setState(loading: false);
                              }
                            }
                          }
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        onPressed: () {},
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () => _showAddFolderDialog(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white70 : Colors.black54;

    return Padding(
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

  Widget _buildFolderItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String count,
    required bool isSelected,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final selectedColor = Theme.of(context).colorScheme.primary;

    return ListTile(
      leading: Icon(
        icon,
        size: 18,
        color: isSelected ? selectedColor : textColor.withOpacity(0.7),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? selectedColor : textColor,
        ),
      ),
      trailing: Text(
        count,
        style: TextStyle(
          fontSize: 12,
          color: textColor.withOpacity(0.5),
        ),
      ),
      dense: true,
      visualDensity: const VisualDensity(horizontal: 0, vertical: -3),
      selected: isSelected,
      selectedTileColor: isDarkMode
          ? const Color(0xFF3D3D3D)
          : const Color(0xFFE5E5E5).withOpacity(0.5),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  Widget _buildTagItem(BuildContext context, String tag,
      {bool isSelected = false, VoidCallback? onTap}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final selectedColor = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Text(
          tag,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? selectedColor : textColor,
          ),
        ),
        backgroundColor: isDarkMode
            ? (isSelected
                ? const Color(0xFF3D3D3D).withOpacity(0.7)
                : const Color(0xFF3D3D3D))
            : (isSelected
                ? const Color(0xFFE5E5E5).withOpacity(0.7)
                : const Color(0xFFE5E5E5)),
        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
        padding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: -2),
      ),
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
