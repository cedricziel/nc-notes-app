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
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Note copyWith({
    String? title,
    String? content,
    DateTime? updatedAt,
    String? folder,
    String? etag,
    bool? readonly,
    bool? favorite,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      folder: folder ?? this.folder,
      etag: etag ?? this.etag,
      readonly: readonly ?? this.readonly,
      favorite: favorite ?? this.favorite,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'folder': folder,
      'etag': etag,
      'readonly': readonly,
      'favorite': favorite,
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
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
    );
  }
}
