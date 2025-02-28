import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note.dart';
import '../models/folder.dart';
import '../services/auth_service.dart';
import '../services/nextcloud_notes_api.dart';

class NotesProvider with ChangeNotifier {
  List<Note> _notes = [];
  List<Folder> _folders = [];
  Note? _selectedNote;
  Folder? _selectedFolder;

  final AuthService _authService = AuthService();
  NextcloudNotesApi? _api;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _manualSave = false;
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

  List<Note> get filteredNotes {
    if (_selectedFolder == null) {
      return _notes;
    }
    return _notes.where((note) => note.folder == _selectedFolder!.id).toList();
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
    _notes = notesJson
        .map((noteStr) => Note.fromJson(jsonDecode(noteStr)))
        .toList();

    // Sort notes by updated date (newest first)
    _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    notifyListeners();
  }

  Future<void> _saveLocalData() async {
    final prefs = await SharedPreferences.getInstance();

    // Save folders
    final foldersJson = _folders
        .map((folder) => jsonEncode(folder.toJson()))
        .toList();
    await prefs.setStringList('folders', foldersJson);

    // Save notes
    final notesJson = _notes
        .map((note) => jsonEncode(note.toJson()))
        .toList();
    await prefs.setStringList('notes', notesJson);
  }

  void selectNote(Note note) {
    _selectedNote = note;
    notifyListeners();
  }

  void selectFolder(Folder? folder) {
    _selectedFolder = folder;
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

    // Create updated note with reference to original state for conflict detection
    final updatedNote = currentNote.copyWith(
      title: title,
      content: content,
      updatedAt: DateTime.now(),
      unsaved: true,
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

    // Queue the note for server update if authenticated
    if (_api != null) {
      // Queue the content update
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
      _manualSave = false;
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
    _manualSave = true;

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

    try {
      // Fetch notes from server
      debugPrint('Fetching notes from server...');
      final serverNotes = await _api!.getNotes();
      debugPrint('Received ${serverNotes.length} notes from server');

      // Log ETags for debugging
      for (final note in serverNotes) {
        debugPrint('Server note ID: ${note.id}, ETag: ${note.etag}');
        if (note.etag == null || note.etag!.isEmpty) {
          debugPrint('Warning: Note ${note.id} has no ETag from server');
        }
      }

      // Check for local notes that need to be preserved
      // (notes that haven't been synced to the server yet)
      final localOnlyNotes = _notes.where((note) =>
        int.tryParse(note.id) == null // Local notes have non-numeric IDs
      ).toList();

      if (localOnlyNotes.isNotEmpty) {
        debugPrint('Found ${localOnlyNotes.length} local-only notes to preserve');
      }

      // Update local notes with server notes, ensuring each has a reference copy
      final processedServerNotes = serverNotes.map((note) {
        // Create a reference copy for each server note
        return note.copyWith(reference: note.createReference());
      }).toList();

      _notes = [...processedServerNotes, ...localOnlyNotes];

      // Extract folders from notes
      final folderNames = <String>{};
      for (final note in _notes) {
        if (note.folder != null && note.folder!.isNotEmpty) {
          folderNames.add(note.folder!);
        }
      }
      debugPrint('Found ${folderNames.length} folders in notes');

      // Create folder objects
      _folders = folderNames.map((name) =>
        _folders.firstWhere(
          (folder) => folder.id == name,
          orElse: () => Folder(name: name, id: name)
        )
      ).toList();

      // Update selected note reference if needed
      if (_selectedNote != null) {
        final selectedId = _selectedNote!.id;
        final updatedNote = _notes.firstWhere(
          (note) => note.id == selectedId,
          orElse: () => _notes.isNotEmpty ? _notes.first : _selectedNote!
        );

        if (updatedNote.id != selectedId) {
          debugPrint('Previously selected note not found, selecting a different note');
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
          orElse: () => _folders.isNotEmpty ? _folders.first : _selectedFolder!
        );

        if (updatedFolder.id != selectedId) {
          debugPrint('Previously selected folder not found, selecting a different folder');
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

        // Implement TypeScript-like conflict resolution
        if (serverNote.content == content) {
          // Content is already up-to-date, just update with server's metadata
          debugPrint('Content is already up-to-date on server, updating metadata');

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
        } else if (reference != null && serverNote.content == reference.content) {
          // Remote content has not changed from our reference, retry with new etag
          debugPrint('Server content has not changed, retrying update with new etag');

          // Retry the update with the new etag
          return await _api!.updateNote(
            id: noteId,
            title: title,
            content: content,
            category: category,
            favorite: favorite,
            etag: serverNote.etag,
          );
        } else {
          // Both local and server content have changed, manual resolution required
          debugPrint('Content conflict detected, manual resolution required');

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
}
