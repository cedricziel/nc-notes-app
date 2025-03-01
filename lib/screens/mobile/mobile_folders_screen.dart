import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart' as fpw;
import '../../providers/notes_provider.dart';
import '../../models/folder.dart';
import '../responsive_notes_layout.dart';
import '../login_screen.dart';
import '../../widgets/sync_indicator.dart';
import '../../widgets/platform/platform_tag.dart';
import '../../widgets/platform/platform_scaffold.dart';
import '../../widgets/platform/platform_app_bar.dart';
import '../../widgets/platform/platform_list_tile.dart';
import '../../widgets/platform/platform_text_field.dart';
import '../../widgets/platform/platform_button.dart';
import 'mobile_notes_screen.dart';

/// Mobile version of the folders screen.
/// This is the first screen shown on mobile devices.
class MobileFoldersScreen extends StatelessWidget {
  const MobileFoldersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotesProvider>(
      builder: (context, notesProvider, child) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final backgroundColor = Theme.of(context).colorScheme.surface;

        return PlatformScaffold(
          backgroundColor: backgroundColor,
          appBar: PlatformAppBar(
            title: const Text('Nextcloud Notes'),
            backgroundColor: backgroundColor,
            trailingActions: [
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
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Sync with server',
                    onPressed: provider.isAuthenticated
                        ? () => provider.syncWithServer()
                        : null,
                  );
                },
              ),
            ],
          ),
          body: ListView(
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
                  onTap: () {
                    // Navigate to notes screen with no folder selected
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MobileNotesScreen(
                          folderId: null,
                          tagName: null,
                        ),
                      ),
                    );
                  },
                ),
                // Dynamic folders from provider
                if (notesProvider.folders.isNotEmpty) ...[
                  ...notesProvider.folders.map((folder) => _buildFolderItem(
                        context,
                        icon: Icons.folder_outlined,
                        title: folder.name,
                        count: notesProvider
                            .getNoteCountForFolder(folder.id)
                            .toString(),
                        isSelected:
                            notesProvider.selectedFolder?.id == folder.id,
                        onTap: () {
                          // Navigate to notes screen with selected folder
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MobileNotesScreen(
                                folderId: folder.id,
                                tagName: null,
                              ),
                            ),
                          );
                        },
                        onLongPress: () => _showFolderOptions(context, folder),
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
                      'All Tags',
                      isSelected: notesProvider.selectedTag == null,
                      onTap: () {
                        // Navigate to notes screen with no tag selected
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MobileNotesScreen(
                              folderId: null,
                              tagName: null,
                            ),
                          ),
                        );
                      },
                    ),
                    ...notesProvider.allTags.map((tag) => _buildTagItem(
                          context,
                          tag,
                          isSelected: notesProvider.selectedTag == tag,
                          onTap: () {
                            // Navigate to notes screen with selected tag
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MobileNotesScreen(
                                  folderId: null,
                                  tagName: tag,
                                ),
                              ),
                            );
                          },
                        )),
                  ],
                ),
              ),

              // Add extra padding at the bottom
              const SizedBox(height: 20),
            ],
          ),
          material: (_, __) => fpw.MaterialScaffoldData(
            bottomNavBar: Material(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(
                      notesProvider.isAuthenticated
                          ? Icons.logout
                          : Icons.login,
                    ),
                    tooltip: notesProvider.isAuthenticated
                        ? 'Logout'
                        : 'Login to Nextcloud',
                    onPressed: () async {
                      if (notesProvider.isAuthenticated) {
                        // Logout
                        await notesProvider.logout();

                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Logged out successfully')),
                        );

                        // Navigate to login screen, replacing the current screen
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()),
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
                  ),
                  IconButton(
                    icon: const Icon(Icons.create_new_folder_outlined),
                    tooltip: 'Add Folder',
                    onPressed: () => _showAddFolderDialog(context),
                  ),
                ],
              ),
            ),
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
          fontSize: 14,
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

    return PlatformListTile(
      leading: Icon(
        icon,
        color: isSelected ? selectedColor : textColor.withOpacity(0.7),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? selectedColor : textColor,
        ),
      ),
      trailing: Text(
        count,
        style: TextStyle(
          fontSize: 14,
          color: textColor.withOpacity(0.5),
        ),
      ),
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

    return PlatformTag(
      label: tag,
      isSelected: isSelected,
      onTap: onTap,
      labelStyle: TextStyle(
        fontSize: 14,
        color: isSelected ? selectedColor : textColor,
      ),
      backgroundColor: isDarkMode
          ? (isSelected
              ? const Color(0xFF3D3D3D).withOpacity(0.7)
              : const Color(0xFF3D3D3D))
          : (isSelected
              ? const Color(0xFFE5E5E5).withOpacity(0.7)
              : const Color(0xFFE5E5E5)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    );
  }

  void _showAddFolderDialog(BuildContext context) {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Folder'),
        content: PlatformTextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Folder name',
          ),
          placeholder: 'Folder name',
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
          PlatformListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Rename'),
            onTap: () {
              Navigator.pop(context);
              _showRenameFolderDialog(context, folder);
            },
          ),
          PlatformListTile(
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
        content: PlatformTextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Folder name',
          ),
          placeholder: 'Folder name',
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
