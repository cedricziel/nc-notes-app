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
  String? _errorMessage;

  bool get isAuthenticated => _api != null;
  bool get isLoading => _isLoading;
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

  /// Updates a note locally and on the server if authenticated
  Future<void> updateNote(String id, {String? title, String? content}) async {
    // Find the note in the local collection
    final index = _notes.indexWhere((note) => note.id == id);
    if (index == -1) {
      debugPrint('Note not found with ID: $id');
      return;
    }

    // Get the current note
    final currentNote = _notes[index];

    // Create updated note
    final updatedNote = currentNote.copyWith(
      title: title,
      content: content,
      updatedAt: DateTime.now(),
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

    // If authenticated, try to save to server
    if (_api != null) {
      try {
        debugPrint('Attempting to save note to server: ${updatedNote.title}');

        // Check if this is a server note (has numeric ID) or local-only note
        if (int.tryParse(id) != null) {
          // This is a server note, update it
          final noteId = int.parse(id);

          // Use our custom method to update on server
          final serverNote = await _updateNoteOnServer(
            noteId,
            updatedNote.title,
            updatedNote.content,
            updatedNote.folder,
            updatedNote.favorite ?? false,
            updatedNote.etag,
          );

          // Update local note with server etag
          if (serverNote.etag != null) {
            _notes[index] = updatedNote.copyWith(etag: serverNote.etag);

            if (_selectedNote?.id == id) {
              _selectedNote = _notes[index];
            }
          }

          debugPrint('Note updated on server successfully');
        } else {
          // This is a local-only note, create it on server
          debugPrint('Creating new note on server');

          // Create note on server
          final serverNote = await _api!.createNote(
            title: updatedNote.title,
            content: updatedNote.content,
            category: updatedNote.folder,
            favorite: updatedNote.favorite,
          );

          // Update local note with server ID and etag
          _notes[index] = updatedNote.copyWith(
            id: serverNote.id,
            etag: serverNote.etag,
          );

          // Update selected note reference if needed
          if (_selectedNote?.id == id) {
            _selectedNote = _notes[index];
          }

          // Save updated note to local storage
          await _saveLocalData();

          debugPrint('Note created on server with ID: ${serverNote.id}');
        }
      } catch (e) {
        debugPrint('Error saving note to server: $e');
        setState(error: 'Failed to save note to server: $e');
        // We don't rethrow the error because we want the local update to succeed
        // even if the server update fails
      }
    } else {
      debugPrint('Not authenticated, note saved locally only');
    }

    // Notify listeners of changes
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

      // Update local notes with server notes
      _notes = serverNotes;

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

      // Select first note if available and none is selected
      if (_selectedNote == null && _notes.isNotEmpty) {
        debugPrint('Auto-selecting first note');
        _selectedNote = _notes.first;
      }

      // Select first folder if available and none is selected
      if (_selectedFolder == null && _folders.isNotEmpty) {
        debugPrint('Auto-selecting first folder');
        _selectedFolder = _folders.first;
      }

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

    try {
      // First attempt: Try to update with the current etag
      try {
        return await _api!.updateNote(
          id: noteId,
          title: title,
          content: content,
          category: category,
          favorite: favorite,
          etag: etag,
        );
      } catch (e) {
        // Check if it's a precondition failed error (412)
        if (e.toString().contains('Precondition Failed') ||
            e.toString().contains('412') ||
            e.toString().contains('precondition failed')) {
          debugPrint('ETag conflict detected, fetching latest version and retrying...');

          // Fetch the latest version of the note to get the updated etag
          final serverNote = await _fetchNoteFromServer(noteId);

          // Retry the update with the new etag but our local content
          debugPrint('Retrying update with new etag: ${serverNote.etag}');
          return await _api!.updateNote(
            id: noteId,
            title: title,
            content: content,
            category: category,
            favorite: favorite,
            etag: serverNote.etag, // Use the fresh etag from the server
          );
        } else {
          // For other errors, just rethrow
          rethrow;
        }
      }
    } catch (e) {
      debugPrint('Error updating note on server: $e');
      throw Exception('Failed to update note: $e');
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
