import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/note.dart';
import 'nextcloud_config.dart';

/// Exception thrown when an API request fails
class NextcloudApiException implements Exception {
  final String message;
  final int? statusCode;

  NextcloudApiException(this.message, {this.statusCode});

  @override
  String toString() {
    if (statusCode != null) {
      return 'NextcloudApiException: $message (Status code: $statusCode)';
    }
    return 'NextcloudApiException: $message';
  }
}

/// Client for interacting with the Nextcloud Notes API v1
class NextcloudNotesApi {
  final NextcloudConfig config;
  final http.Client _client = http.Client();

  /// Creates a new instance of the Nextcloud Notes API client
  ///
  /// [config] contains the server URL, username, and password
  NextcloudNotesApi({
    required this.config,
  });

  /// Closes the HTTP client when done
  void dispose() {
    _client.close();
  }

  /// Creates the authorization header for Basic Authentication
  String get _authHeader {
    final credentials = '${config.username}:${config.password}';
    final encodedCredentials = base64Encode(utf8.encode(credentials));
    return 'Basic $encodedCredentials';
  }

  /// Handles HTTP errors and throws appropriate exceptions
  void _handleError(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        return; // Success
      case 400:
        throw NextcloudApiException('Bad Request: Invalid ID or parameters',
            statusCode: 400);
      case 401:
        throw NextcloudApiException('Unauthorized: Invalid credentials',
            statusCode: 401);
      case 403:
        throw NextcloudApiException('Forbidden: Note is read-only',
            statusCode: 403);
      case 412:
        throw NextcloudApiException(
          'Precondition Failed: Note has been modified on the server',
          statusCode: 412,
        );
      case 507:
        throw NextcloudApiException(
          'Insufficient Storage: Not enough free storage for saving the note',
          statusCode: 507,
        );
      default:
        throw NextcloudApiException(
          'API Error: ${response.reasonPhrase}',
          statusCode: response.statusCode,
        );
    }
  }

  /// Gets all notes from the server
  ///
  /// [category] - Filter notes by category
  /// [exclude] - Fields to exclude from the response
  /// [chunkSize] - Maximum number of notes to return
  /// [chunkCursor] - Cursor for pagination
  ///
  /// Returns a list of notes with their ETags from the server.
  Future<List<Note>> getNotes({
    String? category,
    List<String>? exclude,
    int? chunkSize,
    String? chunkCursor,
  }) async {
    // Build query parameters
    final queryParams = <String, String>{};
    if (category != null) {
      queryParams['category'] = category;
    }
    if (exclude != null && exclude.isNotEmpty) {
      queryParams['exclude'] = exclude.join(',');
    }
    if (chunkSize != null) {
      queryParams['chunkSize'] = chunkSize.toString();
    }
    if (chunkCursor != null) {
      queryParams['chunkCursor'] = chunkCursor;
    }

    // Build URI with query parameters
    final uri = Uri.parse('${config.apiUrl}/notes')
        .replace(queryParameters: queryParams);

    // Make the request
    final response = await _client.get(
      uri,
      headers: {
        'Authorization': _authHeader,
        'Accept': 'application/json',
      },
    );

    // Handle errors
    _handleError(response);

    // Parse the response
    final List<dynamic> jsonList = json.decode(response.body);
    final notes =
        jsonList.map((json) => _convertApiNoteToAppNote(json)).toList();

    // Log ETags for debugging
    int notesWithEtag = notes
        .where((note) => note.etag != null && note.etag!.isNotEmpty)
        .length;

    if (notesWithEtag < notes.length) {}

    return notes;
  }

  /// Gets a single note by ID
  ///
  /// Returns the note with its current ETag from the server.
  Future<Note> getNote(int id) async {
    final response = await _client.get(
      Uri.parse('${config.apiUrl}/notes/$id'),
      headers: {
        'Authorization': _authHeader,
        'Accept': 'application/json',
      },
    );

    // Check for ETag in response headers
    final responseEtag = response.headers['etag'];
    if (responseEtag != null) {
    } else {}

    _handleError(response);

    final Map<String, dynamic> jsonMap = json.decode(response.body);

    // If the response body doesn't include an ETag but we got one in the headers,
    // add it to the JSON map before converting to a Note
    if (jsonMap['etag'] == null && responseEtag != null) {
      jsonMap['etag'] = responseEtag;
    }

    final note = _convertApiNoteToAppNote(jsonMap);

    return note;
  }

  /// Creates a new note
  ///
  /// Returns the created note with its ID and ETag from the server.
  Future<Note> createNote({
    required String title,
    required String content,
    String? category,
    bool? favorite,
  }) async {
    final Map<String, dynamic> noteData = {
      'title': title,
      'content': content,
    };

    if (category != null) {
      noteData['category'] = category;
    }

    if (favorite != null) {
      noteData['favorite'] = favorite;
    }

    final response = await _client.post(
      Uri.parse('${config.apiUrl}/notes'),
      headers: {
        'Authorization': _authHeader,
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode(noteData),
    );

    // Check for ETag in response headers
    final responseEtag = response.headers['etag'];
    if (responseEtag != null) {
    } else {}

    _handleError(response);

    final Map<String, dynamic> jsonMap = json.decode(response.body);

    // If the response body doesn't include an ETag but we got one in the headers,
    // add it to the JSON map before converting to a Note
    if (jsonMap['etag'] == null && responseEtag != null) {
      jsonMap['etag'] = responseEtag;
    }

    final createdNote = _convertApiNoteToAppNote(jsonMap);

    return createdNote;
  }

  /// Updates an existing note
  ///
  /// [etag] is used for conflict detection. If provided, the update will only
  /// succeed if the note hasn't been modified on the server since the last retrieval.
  ///
  /// Returns the updated note with the new ETag from the server.
  Future<Note> updateNote({
    required int id,
    String? title,
    String? content,
    String? category,
    bool? favorite,
    String? etag,
  }) async {
    final Map<String, dynamic> noteData = {};

    if (title != null) {
      noteData['title'] = title;
    }

    if (content != null) {
      noteData['content'] = content;
    }

    if (category != null) {
      noteData['category'] = category;
    }

    if (favorite != null) {
      noteData['favorite'] = favorite;
    }

    final headers = {
      'Authorization': _authHeader,
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    // Add If-Match header for conflict detection if etag is provided
    // Note: The ETag must be wrapped in double quotes as per the TypeScript implementation
    if (etag != null && etag.isNotEmpty) {
      // Ensure the ETag is properly quoted (add quotes if not already present)
      final quotedEtag =
          etag.startsWith('"') && etag.endsWith('"') ? etag : '"$etag"';
      headers['If-Match'] = quotedEtag;
    } else {}

    final response = await _client.put(
      Uri.parse('${config.apiUrl}/notes/$id'),
      headers: headers,
      body: json.encode(noteData),
    );

    // Check for ETag in response headers
    final responseEtag = response.headers['etag'];
    if (responseEtag != null) {
    } else {}

    _handleError(response);

    final Map<String, dynamic> jsonMap = json.decode(response.body);

    // If the response body doesn't include an ETag but we got one in the headers,
    // add it to the JSON map before converting to a Note
    if (jsonMap['etag'] == null && responseEtag != null) {
      jsonMap['etag'] = responseEtag;
    }

    final updatedNote = _convertApiNoteToAppNote(jsonMap);

    return updatedNote;
  }

  /// Deletes a note by ID
  Future<void> deleteNote(int id) async {
    final response = await _client.delete(
      Uri.parse('${config.apiUrl}/notes/$id'),
      headers: {
        'Authorization': _authHeader,
        'Accept': 'application/json',
      },
    );

    _handleError(response);
  }

  /// Gets the server settings
  Future<Map<String, dynamic>> getSettings() async {
    final response = await _client.get(
      Uri.parse('${config.apiUrl}/settings'),
      headers: {
        'Authorization': _authHeader,
        'Accept': 'application/json',
      },
    );

    _handleError(response);

    return json.decode(response.body);
  }

  /// Updates the server settings
  Future<Map<String, dynamic>> updateSettings(
      Map<String, dynamic> settings) async {
    final response = await _client.put(
      Uri.parse('${config.apiUrl}/settings'),
      headers: {
        'Authorization': _authHeader,
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode(settings),
    );

    _handleError(response);

    return json.decode(response.body);
  }

  /// Converts a note from the API format to the app's Note model
  Note _convertApiNoteToAppNote(Map<String, dynamic> apiNote) {
    // Extract the folder from the category
    String? folder;
    if (apiNote['category'] != null &&
        apiNote['category'].toString().isNotEmpty) {
      folder = apiNote['category'];
    }

    // Convert timestamps
    final DateTime createdAt =
        DateTime.now(); // API doesn't provide creation time
    final DateTime updatedAt = apiNote['modified'] != null
        ? DateTime.fromMillisecondsSinceEpoch(apiNote['modified'] * 1000)
        : DateTime.now();

    // Ensure we have a valid etag
    String? etag = apiNote['etag'];
    if (etag == null || etag.isEmpty) {}

    return Note(
      id: apiNote['id'].toString(), // Convert to string to match our model
      title: apiNote['title'] ?? '',
      content: apiNote['content'] ?? '',
      createdAt: createdAt,
      updatedAt: updatedAt,
      folder: folder,
      etag: etag, // This might be null, but that's handled in the NotesProvider
      readonly: apiNote['readonly'] ?? false,
      favorite: apiNote['favorite'] ?? false,
    );
  }
}
