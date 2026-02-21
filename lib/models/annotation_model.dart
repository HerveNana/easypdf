import 'package:flutter/material.dart';

class AnnotationModel {
  final String id;
  final String documentId;
  final String userId;
  final String annotationType;
  final int pageNumber;
  final String? color;
  final double? thickness;
  final String? content;
  final Map<String, dynamic>? positionData;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? userFullName;
  final String? userAvatarUrl;

  AnnotationModel({
    required this.id,
    required this.documentId,
    required this.userId,
    required this.annotationType,
    required this.pageNumber,
    this.color,
    this.thickness,
    this.content,
    this.positionData,
    required this.createdAt,
    required this.updatedAt,
    this.userFullName,
    this.userAvatarUrl,
  });

  factory AnnotationModel.fromJson(Map<String, dynamic> json) {
    final userProfiles = json['user_profiles'] as Map<String, dynamic>?;

    return AnnotationModel(
      id: json['id'] as String,
      documentId: json['document_id'] as String,
      userId: json['user_id'] as String,
      annotationType: json['annotation_type'] as String,
      pageNumber: json['page_number'] as int,
      color: json['color'] as String?,
      thickness: (json['thickness'] as num?)?.toDouble(),
      content: json['content'] as String?,
      positionData: json['position_data'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      userFullName: userProfiles?['full_name'] as String?,
      userAvatarUrl: userProfiles?['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'document_id': documentId,
      'user_id': userId,
      'annotation_type': annotationType,
      'page_number': pageNumber,
      'color': color,
      'thickness': thickness,
      'content': content,
      'position_data': positionData,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Convert to legacy format for existing UI
  Map<String, dynamic> toLegacyFormat() {
    return {
      'type': annotationType,
      'page': pageNumber,
      'color': color != null ? _hexToColor(color!) : null,
      'text': content,
      'content': content,
      'timestamp': createdAt,
      'userId': userId,
      'userName': userFullName,
    };
  }

  Color? _hexToColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return null;
    }
  }
}
