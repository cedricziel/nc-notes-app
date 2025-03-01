import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note.dart';
import '../models/folder.dart';
import '../services/auth_service.dart';
import '../services/nextcloud_notes_api.dart';
import '../utils/tag_utils.dart';

class NotesProvider with ChangeNotifier {
  List<Note> _notes = [];
  List<Folder> _folders = [];
  Note? _selectedNote;
  Folder? _selectedFolder;
  String? _selectedTag;

  final AuthService _authService = AuthService();
  NextcloudNotesApi? _api;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  // Queue for note update operations
  final Map<String, Map<String, dynamic>> _queue = {};

  bool get isAuthenticated => _api != null;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  List<Note> get notes => _notes;
  List<Folder> get folders => _folders;
  Note? get selectedNote => _selectedNote;
  Folder? get selectedFolder => _selectedFolder;
  String? get selectedTag => _selectedTag;

  // Get all unique tags from all notes
  List<String> get allTags {
    final tagSet = <String>{};
    for (final note in _notes) {
      tagSet.addAll(note.tags);
    }
    return tagSet.toList()..sort();
  }

  List<Note> get filteredNotes {
    if (_selectedFolder != null) {
      return _notes
          .where((note) => note.folder == _selectedFolder!.id)
          .toList();
    } else if (_selectedTag != null) {
      return _notes.where((note) => note.tags.contains(_selectedTag)).toList();
    }
    return _notes;
  }

  /// Get the number of notes in a specific folder
  int getNoteCountForFolder(String folderId) {
    return _notes.where((note) => note.folder == folderId).length;
  }

  NotesProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadLocalData();
    await _initializeApi();
  }

  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load folders
    final foldersJson = prefs.getStringList('folders') ?? [];
    _folders = foldersJson
        .map((folderStr) => Folder.fromJson(jsonDecode(folderStr)))
        .toList();

    // Load notes
    final notesJson = prefs.getStringList('notes') ?? [];
    _notes =
        notesJson.map((noteStr) => Note.fromJson(jsonDecode(noteStr))).toList();

    // Sort notes by updated date (newest first)
    _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    notifyListeners();
  }

  Future<void> _saveLocalData() async {
    final prefs = await SharedPreferences.getInstance();

    // Save folders
    final foldersJson =
        _folders.map((folder) => jsonEncode(folder.toJson())).toList();
    await prefs.setStringList('folders', foldersJson);

    // Save notes
    final notesJson = _notes.map((note) => jsonEncode(note.toJson())).toList();
    await prefs.setStringList('notes', notesJson);
  }

  void selectNote(Note note) {
    _selectedNote = note;
    notifyListeners();
  }

  void selectFolder(Folder? folder) {
    _selectedFolder = folder;
    _selectedTag = null;
    _selectedNote = null;
    notifyListeners();
  }

  void selectTag(String? tag) {
    _selectedTag = tag;
    _selectedFolder = null;
    _selectedNote = null;
    notifyListeners();
  }

  Future<void> addNote() async {
    final newNote = Note(
      title: 'New Note',
      content: '',
      folder: _selectedFolder?.id,
    );

    _notes.insert(0, newNote);
    _selectedNote = newNote;

    await _saveLocalData();
    notifyListeners();
  }

  /// Updates a note locally and queues it for server update
  Future<void> updateNote(String id, {String? title, String? content}) async {
    // Find the note in the local collection
    final index = _notes.indexWhere((note) => note.id == id);
    if (index == -1) {
      debugPrint('Note not found with ID: $id');
      return;
    }

    // Get the current note
    final currentNote = _notes[index];

    // Log the current ETag before update
    debugPrint('Current note ETag before update: ${currentNote.etag}');

    // Debug logging for content update
    if (content != null) {
      debugPrint('Updating note content, length: ${content.length}');
      debugPrint(
          'Content preview: "${content.substring(0, content.length > 100 ? 100 : content.length)}..."');
    }

    // Extract tags if content is updated
    List<String> tags = currentNote.tags;
    if (content != null) {
      tags = extractTags(content);
    }

    // Create updated note with reference to original state for conflict detection
    final updatedNote = currentNote.copyWith(
      title: title,
      content: content,
      updatedAt: DateTime.now(),
      unsaved: true,
      tags: tags,
      reference: currentNote.reference ?? currentNote.createReference(),
    );

    // Update note in local collection
    _notes[index] = updatedNote;

    // Re-sort notes by updated date
    _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    // Update selected note reference if needed
    if (_selectedNote?.id == id) {
      _selectedNote = updatedNote;
    }

    // Save to local storage
    await _saveLocalData();
    debugPrint('Note saved to local storage');

    // Queue the note for server update if authenticated
    if (_api != null) {
      // Queue the content update
      debugPrint('Queueing note for server update');
      queueCommand(id, 'content');
    } else {
      debugPrint('Not authenticated, note saved locally only');
    }

    // Notify listeners of changes
    notifyListeners();
  }

  /// Add a command to the queue and process it
  void queueCommand(String noteId, String type) {
    debugPrint('Queueing command: $type for note $noteId');
    _queue[noteId] = {'noteId': noteId, 'type': type};
    _processQueue();
  }

  /// Process the queue of note updates
  Future<void> _processQueue() async {
    if (_isSaving || _queue.isEmpty || _api == null) {
      return;
    }

    _isSaving = true;
    notifyListeners();

    final queueCopy = Map<String, Map<String, dynamic>>.from(_queue);
    _queue.clear();

    try {
      for (final cmd in queueCopy.values) {
        final noteId = cmd['noteId'] as String;
        final type = cmd['type'] as String;

        try {
          switch (type) {
            case 'content':
              await _saveNoteContent(noteId);
              break;
            default:
              debugPrint('Unknown queue command: $type');
          }
        } catch (e) {
          debugPrint('Command failed for note $noteId: $e');
          // Add back to queue for retry?
          // _queue[noteId] = cmd;
        }
      }
    } finally {
      _isSaving = false;
      notifyListeners();

      // Process any new queue items that were added during processing
      if (_queue.isNotEmpty) {
        _processQueue();
      }
    }
  }

  /// Save a note's content to the server
  Future<void> _saveNoteContent(String noteId) async {
    if (_api == null) {
      debugPrint('Cannot save note: API is not initialized');
      return;
    }

    // Find the note in the local collection
    final index = _notes.indexWhere((note) => note.id == noteId);
    if (index == -1) {
      debugPrint('Note not found with ID: $noteId');
      return;
    }

    final note = _notes[index];

    // Debug logging for content being saved to server
    debugPrint(
        'Preparing to save note to server, content length: ${note.content.length}');
    debugPrint(
        'Content preview: "${note.content.substring(0, note.content.length > 100 ? 100 : note.content.length)}..."');

    // Mark note as not having save error
    if (note.saveError) {
      final updatedNote = note.copyWith(saveError: false);
      _notes[index] = updatedNote;
      notifyListeners();
    }

    debugPrint('Saving note to server: ${note.title}');
    debugPrint('Using ETag: ${note.etag}');

    try {
      // Check if this is a server note (has numeric ID) or local-only note
      if (int.tryParse(noteId) != null) {
        // This is a server note, update it
        final numericNoteId = int.parse(noteId);
        await _updateExistingNote(index, numericNoteId, note);
      } else {
        // This is a local-only note, create it on server
        await _createNewNoteOnServer(index, note);
      }
    } catch (e) {
      // Mark note as having save error
      final updatedNote = note.copyWith(saveError: true);
      _notes[index] = updatedNote;

      debugPrint('Error saving note to server: $e');
      setState(error: 'Failed to save note to server: $e');
      notifyListeners();
    }
  }

  /// Update an existing note on the server
  Future<void> _updateExistingNote(int index, int noteId, Note note) async {
    try {
      // Use our custom method to update on server
      final serverNote = await _updateNoteOnServer(
        noteId,
        note.title,
        note.content,
        note.folder,
        note.favorite,
        note.etag,
      );

      // Update local note with server etag and mark as saved
      if (serverNote.etag != null) {
        debugPrint('Received new ETag from server: ${serverNote.etag}');

        // Create a new note object with the updated etag and reference
        final noteWithNewEtag = note.copyWith(
          etag: serverNote.etag,
          unsaved: false,
          reference: note.createReference(),
        );

        // Update in the notes collection
        _notes[index] = noteWithNewEtag;

        // Update selected note reference if needed
        if (_selectedNote?.id == note.id) {
          _selectedNote = noteWithNewEtag;
        }

        // Save to local storage immediately to persist the new etag
        await _saveLocalData();

        debugPrint('Updated local note with new ETag and saved to storage');
      } else {
        debugPrint('Warning: Server returned null ETag');
      }

      debugPrint('Note updated on server successfully');
    } catch (e) {
      if (e.toString().contains('conflict')) {
        // Handle conflict - this should be handled in _updateNoteOnServer
        debugPrint('Conflict detected during note update: $e');
      }
      rethrow;
    }
  }

  /// Create a new note on the server
  Future<void> _createNewNoteOnServer(int index, Note note) async {
    debugPrint('Creating new note on server');

    // Create note on server
    final serverNote = await _api!.createNote(
      title: note.title,
      content: note.content,
      category: note.folder,
      favorite: note.favorite,
    );

    debugPrint('Received ETag for new note: ${serverNote.etag}');

    // Update local note with server ID, etag, and reference
    final noteWithServerInfo = note.copyWith(
      id: serverNote.id,
      etag: serverNote.etag,
      unsaved: false,
      reference: serverNote.createReference(),
    );

    // Update in the notes collection
    _notes[index] = noteWithServerInfo;

    // Update selected note reference if needed
    if (_selectedNote?.id == note.id) {
      _selectedNote = noteWithServerInfo;
    }

    // Save updated note to local storage
    await _saveLocalData();

    debugPrint('Note created on server with ID: ${serverNote.id}');
  }

  /// Save a note manually (user-initiated save)
  Future<void> saveNoteManually(String noteId) async {
    debugPrint('Manual save requested for note: $noteId');

    // Find the note
    final index = _notes.indexWhere((note) => note.id == noteId);
    if (index == -1) {
      debugPrint('Note not found with ID: $noteId');
      return;
    }

    // Reset save error flag
    final note = _notes[index];
    final updatedNote = note.copyWith(saveError: false);
    _notes[index] = updatedNote;

    // Set manual save flag

    // Queue the save command
    queueCommand(noteId, 'content');

    notifyListeners();
  }

  /// Handle conflict resolution - use local version
  Future<void> conflictSolutionLocal(String noteId) async {
    final index = _notes.indexWhere((note) => note.id == noteId);
    if (index == -1 || _notes[index].conflict == null) {
      debugPrint('No conflict found for note: $noteId');
      return;
    }

    final note = _notes[index];
    final conflict = note.conflict!;

    // Use local content but take the server's etag
    final resolvedNote = note.copyWith(
      etag: conflict.etag,
      conflict: null,
      reference: conflict.createReference(),
    );

    _notes[index] = resolvedNote;

    // Update selected note if needed
    if (_selectedNote?.id == noteId) {
      _selectedNote = resolvedNote;
    }

    await _saveLocalData();

    // Queue for server update
    queueCommand(noteId, 'content');

    notifyListeners();
  }

  /// Handle conflict resolution - use remote version
  Future<void> conflictSolutionRemote(String noteId) async {
    final index = _notes.indexWhere((note) => note.id == noteId);
    if (index == -1 || _notes[index].conflict == null) {
      debugPrint('No conflict found for note: $noteId');
      return;
    }

    final note = _notes[index];
    final conflict = note.conflict!;

    // Use the server's version entirely
    final resolvedNote = conflict.copyWith(
      unsaved: false,
      conflict: null,
      reference: conflict.createReference(),
    );

    _notes[index] = resolvedNote;

    // Update selected note if needed
    if (_selectedNote?.id == noteId) {
      _selectedNote = resolvedNote;
    }

    await _saveLocalData();
    notifyListeners();
  }

  Future<void> deleteNote(String id) async {
    _notes.removeWhere((note) => note.id == id);

    if (_selectedNote?.id == id) {
      _selectedNote = _notes.isNotEmpty ? _notes.first : null;
    }

    await _saveLocalData();
    notifyListeners();
  }

  Future<void> addFolder(String name) async {
    final newFolder = Folder(name: name);
    _folders.add(newFolder);

    await _saveLocalData();
    notifyListeners();
  }

  Future<void> updateFolder(String id, String name) async {
    final index = _folders.indexWhere((folder) => folder.id == id);
    if (index != -1) {
      _folders[index].name = name;

      if (_selectedFolder?.id == id) {
        _selectedFolder = _folders[index];
      }

      await _saveLocalData();
      notifyListeners();
    }
  }

  Future<void> deleteFolder(String id) async {
    // Remove the folder
    _folders.removeWhere((folder) => folder.id == id);

    // Remove folder from notes or delete notes in this folder
    for (var note in _notes.where((note) => note.folder == id).toList()) {
      // Option 1: Move notes to no folder
      // note.folder = null;

      // Option 2: Delete notes in this folder
      _notes.removeWhere((n) => n.id == note.id);
    }

    if (_selectedFolder?.id == id) {
      _selectedFolder = null;
      _selectedNote = _notes.isNotEmpty ? _notes.first : null;
    }

    await _saveLocalData();
    notifyListeners();
  }

  Future<void> moveNoteToFolder(String noteId, String? folderId) async {
    final index = _notes.indexWhere((note) => note.id == noteId);
    if (index != -1) {
      _notes[index] = _notes[index].copyWith(
        folder: folderId,
        updatedAt: DateTime.now(),
      );

      if (_selectedNote?.id == noteId) {
        _selectedNote = _notes[index];
      }

      await _saveLocalData();
      notifyListeners();
    }
  }

  /// Initialize the Nextcloud API if authenticated
  Future<void> _initializeApi() async {
    final config = await _authService.getConfig();

    if (config != null) {
      _api = NextcloudNotesApi(config: config);
      await syncWithServer();
    }
  }

  /// Sync notes with the Nextcloud server
  ///
  /// This method fetches all notes from the server and updates the local collection.
  /// It ensures that ETags are properly stored for each note to prevent conflicts
  /// when saving notes back to the server.
  Future<void> syncWithServer() async {
    if (_api == null) {
      debugPrint('Cannot sync: API is not initialized');
      setState(error: 'Cannot sync: Not logged in');
      return;
    }

    setState(loading: true, error: null);
    debugPrint('Starting sync with Nextcloud server...');

    // Log the current state of local notes before sync
    debugPrint('Local notes before sync: ${_notes.length} notes');
    for (final note in _notes) {
      if (note.id.isNotEmpty) {
        debugPrint(
            'Local note ID: ${note.id}, Content length: ${note.content.length}');
        debugPrint(
            'Content preview: "${note.content.substring(0, note.content.length > 50 ? 50 : note.content.length)}..."');

        // Count blocks in the content
        final blocks = note.content.split('\n\n');
        debugPrint('Block count: ${blocks.length}');

        // Log first few blocks
        for (int i = 0; i < blocks.length && i < 3; i++) {
          final blockPreview = blocks[i].length > 30
              ? '${blocks[i].substring(0, 30)}...'
              : blocks[i];
          debugPrint('Block $i: "$blockPreview"');
        }
      }
    }

    try {
      // Fetch notes from server
      debugPrint('Fetching notes from server...');
      final serverNotes = await _api!.getNotes();
      debugPrint('Received ${serverNotes.length} notes from server');

      // Log ETags and content details for debugging
      for (final note in serverNotes) {
        debugPrint(
            'Server note ID: ${note.id}, ETag: ${note.etag}, Content length: ${note.content.length}');
        if (note.etag == null || note.etag!.isEmpty) {
          debugPrint('Warning: Note ${note.id} has no ETag from server');
        }

        // Count blocks in the server content
        final blocks = note.content.split('\n\n');
        debugPrint('Server note block count: ${blocks.length}');

        // Log first few blocks
        for (int i = 0; i < blocks.length && i < 3; i++) {
          final blockPreview = blocks[i].length > 30
              ? '${blocks[i].substring(0, 30)}...'
              : blocks[i];
          debugPrint('Server block $i: "$blockPreview"');
        }
      }

      // Check for local notes that need to be preserved
      // (notes that haven't been synced to the server yet)
      final localOnlyNotes = _notes
          .where((note) =>
                  int.tryParse(note.id) ==
                  null // Local notes have non-numeric IDs
              )
          .toList();

      if (localOnlyNotes.isNotEmpty) {
        debugPrint(
            'Found ${localOnlyNotes.length} local-only notes to preserve');
      }

      // Update local notes with server notes, ensuring each has a reference copy
      debugPrint('Processing server notes for local storage...');
      final processedServerNotes = serverNotes.map((note) {
        // Extract tags from content
        final tags = extractTags(note.content);

        // Log the processing of each note
        debugPrint('Processing server note ID: ${note.id}');

        // Count blocks in the content before processing
        final blocksBeforeProcessing = note.content.split('\n\n');
        debugPrint(
            'Blocks before processing: ${blocksBeforeProcessing.length}');

        // Create a reference copy for each server note with tags
        final processedNote = note.copyWith(
          tags: tags,
          reference: note.createReference(),
        );

        // Count blocks after processing to check for any changes
        final blocksAfterProcessing = processedNote.content.split('\n\n');
        debugPrint('Blocks after processing: ${blocksAfterProcessing.length}');

        // Check if the block count changed during processing
        if (blocksBeforeProcessing.length != blocksAfterProcessing.length) {
          debugPrint('WARNING: Block count changed during processing!');
          debugPrint(
              'Before: ${blocksBeforeProcessing.length}, After: ${blocksAfterProcessing.length}');
        }

        return processedNote;
      }).toList();

      // Log the state before updating the notes collection
      debugPrint(
          'Before updating notes collection: ${_notes.length} local notes');

      // Update the notes collection with processed server notes and local-only notes
      _notes = [...processedServerNotes, ...localOnlyNotes];

      // Log the state after updating the notes collection
      debugPrint(
          'After updating notes collection: ${_notes.length} total notes');
      debugPrint(
          'Processed server notes: ${processedServerNotes.length}, Local-only notes: ${localOnlyNotes.length}');

      // Extract folders from notes
      final folderNames = <String>{};
      for (final note in _notes) {
        if (note.folder != null && note.folder!.isNotEmpty) {
          folderNames.add(note.folder!);
        }
      }
      debugPrint('Found ${folderNames.length} folders in notes');

      // Create folder objects
      _folders = folderNames
          .map((name) => _folders.firstWhere((folder) => folder.id == name,
              orElse: () => Folder(name: name, id: name)))
          .toList();

      // Update selected note reference if needed
      if (_selectedNote != null) {
        final selectedId = _selectedNote!.id;
        final updatedNote = _notes.firstWhere((note) => note.id == selectedId,
            orElse: () => _notes.isNotEmpty ? _notes.first : _selectedNote!);

        if (updatedNote.id != selectedId) {
          debugPrint(
              'Previously selected note not found, selecting a different note');
        }

        _selectedNote = updatedNote;
      } else if (_notes.isNotEmpty) {
        debugPrint('Auto-selecting first note');
        _selectedNote = _notes.first;
      }

      // Update selected folder reference if needed
      if (_selectedFolder != null) {
        final selectedId = _selectedFolder!.id;
        final updatedFolder = _folders.firstWhere(
            (folder) => folder.id == selectedId,
            orElse: () =>
                _folders.isNotEmpty ? _folders.first : _selectedFolder!);

        if (updatedFolder.id != selectedId) {
          debugPrint(
              'Previously selected folder not found, selecting a different folder');
        }

        _selectedFolder = updatedFolder;
      } else if (_folders.isNotEmpty) {
        debugPrint('Auto-selecting first folder');
        _selectedFolder = _folders.first;
      }

      // Sort notes by updated date (newest first)
      _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      // Save to local storage
      await _saveLocalData();
      debugPrint('Sync completed successfully');

      setState(loading: false);
    } catch (e) {
      debugPrint('Sync error: $e');
      setState(loading: false, error: 'Failed to sync with server: $e');
    }
  }

  /// Login to Nextcloud and initialize the API
  Future<bool> login() async {
    debugPrint('Starting login process...');
    final config = await _authService.getConfig();

    if (config != null) {
      debugPrint('Found credentials for server: ${config.serverUrl}');
      setState(loading: true, error: null);

      try {
        debugPrint('Initializing Nextcloud Notes API...');
        _api = NextcloudNotesApi(config: config);

        // Test the connection
        debugPrint('Testing connection to server...');
        await _api!.getSettings();
        debugPrint('Connection test successful');

        // Sync notes
        debugPrint('Syncing notes from server...');
        await syncWithServer();
        debugPrint('Login and sync completed successfully');

        return true;
      } catch (e) {
        debugPrint('Login error: $e');
        _api?.dispose();
        _api = null;
        setState(loading: false, error: 'Login failed: $e');
        return false;
      }
    } else {
      debugPrint('No credentials found');
      setState(error: 'No credentials found');
      return false;
    }
  }

  /// Logout from Nextcloud
  Future<void> logout() async {
    setState(loading: true);

    try {
      _api?.dispose();
      _api = null;
      await _authService.logout();

      // Clear notes and folders
      _notes = [];
      _folders = [];
      _selectedNote = null;
      _selectedFolder = null;

      await _saveLocalData();

      setState(loading: false);
    } catch (e) {
      setState(loading: false, error: 'Logout failed: $e');
    }
  }

  /// Fetches a single note from the server by ID
  Future<Note> _fetchNoteFromServer(int noteId) async {
    if (_api == null) {
      throw Exception('Not authenticated');
    }

    try {
      return await _api!.getNote(noteId);
    } catch (e) {
      debugPrint('Error fetching note from server: $e');
      throw Exception('Failed to fetch note from server: $e');
    }
  }

  /// Helper method to update a note on the server
  ///
  /// This method handles ETag conflicts by automatically fetching the latest
  /// version from the server and implementing sophisticated conflict resolution.
  Future<Note> _updateNoteOnServer(
    int noteId,
    String title,
    String content,
    String? category,
    bool favorite,
    String? etag,
  ) async {
    if (_api == null) {
      throw Exception('Not authenticated');
    }

    debugPrint('Updating note on server - ID: $noteId, ETag: $etag');

    // Find the note in the local collection to get the reference
    final index = _notes.indexWhere((note) => note.id == noteId.toString());
    if (index == -1) {
      throw Exception('Note not found with ID: $noteId');
    }

    final note = _notes[index];
    final reference = note.reference;

    try {
      // Attempt to update with the current etag
      debugPrint('Sending update request with ETag: $etag');
      final updatedNote = await _api!.updateNote(
        id: noteId,
        title: title,
        content: content,
        category: category,
        favorite: favorite,
        etag: etag,
      );

      debugPrint('Update successful, received new ETag: ${updatedNote.etag}');

      // Update the note in the collection with the new etag
      final noteWithNewEtag = note.copyWith(
        etag: updatedNote.etag,
        unsaved: false,
        conflict: null,
        reference: note.createReference(),
      );

      _notes[index] = noteWithNewEtag;

      // Update selected note if needed
      if (_selectedNote?.id == noteId.toString()) {
        _selectedNote = noteWithNewEtag;
      }

      // Save to local storage
      await _saveLocalData();

      return updatedNote;
    } catch (e) {
      // Check if it's a precondition failed error (412)
      if (e.toString().contains('Precondition Failed') ||
          e.toString().contains('412') ||
          e.toString().contains('precondition failed')) {
        debugPrint('ETag conflict detected, attempting to resolve...');

        // Fetch the latest version of the note from the server
        final serverNote = await _fetchNoteFromServer(noteId);

        // Debug logging for conflict resolution
        debugPrint(
            'Comparing local content (${content.length} chars) with server content (${serverNote.content.length} chars)');

        // Implement TypeScript-like conflict resolution
        if (serverNote.content == content) {
          // Content is already up-to-date, just update with server's metadata
          debugPrint(
              'Content is already up-to-date on server, updating metadata');

          // Update the note with server's etag but keep our content
          final resolvedNote = note.copyWith(
            etag: serverNote.etag,
            unsaved: false,
            conflict: null,
            reference: serverNote.createReference(),
          );

          _notes[index] = resolvedNote;

          // Update selected note if needed
          if (_selectedNote?.id == noteId.toString()) {
            _selectedNote = resolvedNote;
          }

          // Save to local storage
          await _saveLocalData();

          return serverNote;
        } else if (reference != null &&
            serverNote.content == reference.content) {
          // Remote content has not changed from our reference, retry with new etag
          debugPrint(
              'Server content has not changed from reference, retrying update with new etag');
          debugPrint(
              'Reference content length: ${reference.content.length} chars');

          // Retry the update with the new etag
          debugPrint('Retrying update with new ETag: ${serverNote.etag}');
          return await _api!.updateNote(
            id: noteId,
            title: title,
            content: content,
            category: category,
            favorite: favorite,
            etag: serverNote.etag,
          );
        } else if (reference != null) {
          // Check if our local content is shorter than the reference
          // This could indicate a block deletion
          if (content.length < reference.content.length) {
            debugPrint(
                'Local content is shorter than reference, likely a block deletion');

            // Check if the server content is the same as our reference
            // This would mean the server hasn't changed since our last sync
            if (_isContentSimilarEnough(
                serverNote.content, reference.content)) {
              debugPrint(
                  'Server content is similar to reference, applying our deletion');

              // Retry the update with the new etag to apply our deletion
              debugPrint(
                  'Retrying update with new ETag to apply deletion: ${serverNote.etag}');
              return await _api!.updateNote(
                id: noteId,
                title: title,
                content: content, // Our content with the deletion
                category: category,
                favorite: favorite,
                etag: serverNote.etag,
              );
            }
          }

          // Log content differences for debugging
          debugPrint(
              'Local content length: ${content.length}, Reference content length: ${reference.content.length}, Server content length: ${serverNote.content.length}');

          // Both local and server content have changed, manual resolution required
          debugPrint('Content conflict detected, manual resolution required');
          debugPrint('Local content differs from server content and reference');

          // Store the conflict for manual resolution
          final noteWithConflict = note.copyWith(
            conflict: serverNote,
          );

          _notes[index] = noteWithConflict;

          // Update selected note if needed
          if (_selectedNote?.id == noteId.toString()) {
            _selectedNote = noteWithConflict;
          }

          // Save to local storage
          await _saveLocalData();

          throw Exception('Note update conflict. Manual resolution required.');
        } else {
          // No reference available, can't determine if this is a deletion
          // Default to manual conflict resolution
          debugPrint(
              'No reference available, defaulting to manual conflict resolution');

          // Store the conflict for manual resolution
          final noteWithConflict = note.copyWith(
            conflict: serverNote,
          );

          _notes[index] = noteWithConflict;

          // Update selected note if needed
          if (_selectedNote?.id == noteId.toString()) {
            _selectedNote = noteWithConflict;
          }

          // Save to local storage
          await _saveLocalData();

          throw Exception('Note update conflict. Manual resolution required.');
        }
      } else {
        // For other errors, log and rethrow
        debugPrint('Error updating note on server (not an ETag conflict): $e');
        throw Exception('Failed to update note: $e');
      }
    }
  }

  /// Helper to update state variables
  void setState({bool? loading, String? error}) {
    if (loading != null) {
      _isLoading = loading;
    }

    if (error != null) {
      _errorMessage = error;
    } else if (error == null && _errorMessage != null) {
      _errorMessage = null;
    }

    notifyListeners();
  }

  /// Helper method to determine if two content strings are similar enough
  ///
  /// This is used in conflict resolution to determine if the server content
  /// is similar enough to the reference content to consider them the same,
  /// which would indicate that the server hasn't changed since our last sync.
  ///
  /// We use this for handling block deletions, where the local content is
  /// shorter than the reference content.
  bool _isContentSimilarEnough(String content1, String content2) {
    // If they're exactly the same, they're similar enough
    if (content1 == content2) {
      return true;
    }

    // If one is empty and the other isn't, they're not similar
    if (content1.isEmpty || content2.isEmpty) {
      return false;
    }

    // If the length difference is too great, they're not similar
    final lengthDiff = (content1.length - content2.length).abs();
    if (lengthDiff > content1.length * 0.5) {
      // More than 50% different in length
      return false;
    }

    // Check if the content is mostly the same by comparing blocks
    final blocks1 = content1.split('\n\n');
    final blocks2 = content2.split('\n\n');

    // Count how many blocks are the same
    int sameBlockCount = 0;
    for (final block1 in blocks1) {
      if (blocks2.contains(block1)) {
        sameBlockCount++;
      }
    }

    // If more than 70% of blocks are the same, consider them similar enough
    final similarity = sameBlockCount / blocks1.length;
    debugPrint(
        'Content similarity: $similarity ($sameBlockCount/${blocks1.length} blocks)');

    return similarity >= 0.7; // 70% or more blocks are the same
  }
}
