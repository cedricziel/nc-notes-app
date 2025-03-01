import 'package:uuid/uuid.dart';

class Note {
  final String id;
  String title;
  String content;
  DateTime createdAt;
  DateTime updatedAt;
  String? folder;
  String? etag;
  bool readonly;
  bool favorite;
  bool unsaved;
  bool saveError;
  List<String> tags;
  Note?
      reference; // Reference to the original server state for conflict detection
  Note? conflict; // Stores the server version when a conflict is detected

  Note({
    String? id,
    this.title = '',
    this.content = '',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.folder,
    this.etag,
    this.readonly = false,
    this.favorite = false,
    this.unsaved = false,
    this.saveError = false,
    this.tags = const [],
    this.reference,
    this.conflict,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Note copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? updatedAt,
    String? folder,
    String? etag,
    bool? readonly,
    bool? favorite,
    bool? unsaved,
    bool? saveError,
    List<String>? tags,
    Note? reference,
    Note? conflict,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      folder: folder ?? this.folder,
      etag: etag ?? this.etag,
      readonly: readonly ?? this.readonly,
      favorite: favorite ?? this.favorite,
      unsaved: unsaved ?? this.unsaved,
      saveError: saveError ?? this.saveError,
      tags: tags ?? this.tags,
      reference: reference ?? this.reference,
      conflict: conflict ?? this.conflict,
    );
  }

  /// Creates a reference copy of this note for conflict detection
  Note createReference() {
    return Note(
      id: this.id,
      title: this.title,
      content: this.content,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
      folder: this.folder,
      etag: this.etag,
      readonly: this.readonly,
      favorite: this.favorite,
      tags: this.tags,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'folder': folder,
      'etag': etag,
      'readonly': readonly,
      'favorite': favorite,
      'unsaved': unsaved,
      'saveError': saveError,
      'tags': tags,
    };

    // Add reference if it exists
    if (reference != null) {
      data['reference'] = reference!.toJson();
    }

    // Add conflict if it exists
    if (conflict != null) {
      data['conflict'] = conflict!.toJson();
    }

    return data;
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    // Parse reference if it exists
    Note? referenceNote;
    if (json['reference'] != null) {
      referenceNote = Note.fromJson(json['reference']);
    }

    // Parse conflict if it exists
    Note? conflictNote;
    if (json['conflict'] != null) {
      conflictNote = Note.fromJson(json['conflict']);
    }

    return Note(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      folder: json['folder'],
      etag: json['etag'],
      readonly: json['readonly'] ?? false,
      favorite: json['favorite'] ?? false,
      unsaved: json['unsaved'] ?? false,
      saveError: json['saveError'] ?? false,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      reference: referenceNote,
      conflict: conflictNote,
    );
  }
}
