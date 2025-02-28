import 'package:flutter/material.dart';
import 'nextcloud_config.dart';
import 'nextcloud_notes_api.dart';
import '../models/note.dart';

/// This file contains examples of how to use the Nextcloud Notes API client.
/// It is not meant to be used in production, but rather as a reference for
/// how to use the API client in your own code.

class NextcloudApiExample {
  /// Example of how to initialize the API client and fetch notes
  static Future<void> fetchNotesExample() async {
    // Create a configuration for the Nextcloud server
    final config = NextcloudConfig(
      serverUrl: 'https://yournextcloud.com',
      username: 'your_username',
      password: 'your_password',
    );

    // Create the API client
    final api = NextcloudNotesApi(config: config);

    try {
      // Fetch all notes
      final notes = await api.getNotes();
      debugPrint('Fetched ${notes.length} notes');

      // Fetch notes in a specific category/folder
      final workNotes = await api.getNotes(category: 'Work');
      debugPrint('Fetched ${workNotes.length} work notes');

      // Fetch a single note by ID
      if (notes.isNotEmpty) {
        final noteId = int.parse(notes.first.id);
        final note = await api.getNote(noteId);
        debugPrint('Fetched note: ${note.title}');
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      // Always dispose the API client when done
      api.dispose();
    }
  }

  /// Example of how to create, update, and delete notes
  static Future<void> crudOperationsExample() async {
    final config = NextcloudConfig(
      serverUrl: 'https://yournextcloud.com',
      username: 'your_username',
      password: 'your_password',
    );

    final api = NextcloudNotesApi(config: config);

    try {
      // Create a new note
      final newNote = await api.createNote(
        title: 'Shopping List',
        content: '- Milk\n- Eggs\n- Bread',
        category: 'Personal',
        favorite: true,
      );
      debugPrint('Created note with ID: ${newNote.id}');

      // Update the note
      final updatedNote = await api.updateNote(
        id: int.parse(newNote.id),
        content: '- Milk\n- Eggs\n- Bread\n- Cheese',
        etag: newNote.etag, // Use etag for conflict detection
      );
      debugPrint('Updated note: ${updatedNote.title}');

      // Delete the note
      await api.deleteNote(int.parse(updatedNote.id));
      debugPrint('Deleted note with ID: ${updatedNote.id}');
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      api.dispose();
    }
  }

  /// Example of how to handle pagination for large note collections
  static Future<void> paginationExample() async {
    final config = NextcloudConfig(
      serverUrl: 'https://yournextcloud.com',
      username: 'your_username',
      password: 'your_password',
    );

    final api = NextcloudNotesApi(config: config);

    try {
      // Fetch notes with pagination
      final int chunkSize = 10;
      String? chunkCursor;
      List<Note> allNotes = [];

      do {
        final notes = await api.getNotes(
          chunkSize: chunkSize,
          chunkCursor: chunkCursor,
        );

        allNotes.addAll(notes);

        // Check if there are more notes to fetch
        if (notes.length < chunkSize) {
          // No more notes
          chunkCursor = null;
        } else {
          // Get the cursor from the response headers
          // In a real app, you would get this from the X-Notes-Chunk-Cursor header
          // For this example, we'll just break the loop
          break;
        }
      } while (chunkCursor != null);

      debugPrint('Fetched ${allNotes.length} notes in total');
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      api.dispose();
    }
  }

  /// Example of how to handle server settings
  static Future<void> settingsExample() async {
    final config = NextcloudConfig(
      serverUrl: 'https://yournextcloud.com',
      username: 'your_username',
      password: 'your_password',
    );

    final api = NextcloudNotesApi(config: config);

    try {
      // Get server settings
      final settings = await api.getSettings();
      debugPrint('Notes path: ${settings['notesPath']}');
      debugPrint('File suffix: ${settings['fileSuffix']}');

      // Update server settings
      final updatedSettings = await api.updateSettings({
        'fileSuffix': '.md',
      });
      debugPrint('Updated file suffix: ${updatedSettings['fileSuffix']}');
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      api.dispose();
    }
  }
}
