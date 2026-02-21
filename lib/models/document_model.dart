class DocumentModel {
  final String id;
  final String ownerId;
  final String name;
  final String? size;
  final String? thumbnailUrl;
  final String? filePath;
  final bool isEncrypted;
  final bool isFavorite;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  DocumentModel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.size,
    this.thumbnailUrl,
    this.filePath,
    this.isEncrypted = false,
    this.isFavorite = false,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      size: json['size'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      filePath: json['file_path'] as String?,
      isEncrypted: json['is_encrypted'] as bool? ?? false,
      isFavorite: json['is_favorite'] as bool? ?? false,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'size': size,
      'thumbnail_url': thumbnailUrl,
      'file_path': filePath,
      'is_encrypted': isEncrypted,
      'is_favorite': isFavorite,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Convert to legacy format for existing UI
  Map<String, dynamic> toLegacyFormat() {
    return {
      'id': id,
      'name': name,
      'size': size ?? '0 KB',
      'modifiedDate': updatedAt,
      'thumbnail': thumbnailUrl ?? '',
      'semanticLabel': 'Document thumbnail for $name',
      'isFavorite': isFavorite,
      'isEncrypted': isEncrypted,
      'tags': tags,
      'filePath': filePath,
    };
  }
}
