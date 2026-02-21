import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/annotation_model.dart';
import '../models/document_model.dart';
import '../models/user_profile_model.dart';
import './supabase_service.dart';

class CollaborationService {
  static CollaborationService? _instance;
  static CollaborationService get instance =>
      _instance ??= CollaborationService._();

  CollaborationService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  // Get current user profile
  Future<UserProfileModel?> getCurrentUserProfile() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      return UserProfileModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch user profile: $e');
    }
  }

  // Get all documents (owned + shared)
  Future<List<DocumentModel>> getAllDocuments() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('documents')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((doc) => DocumentModel.fromJson(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch documents: $e');
    }
  }

  // Get annotations for a document
  Future<List<AnnotationModel>> getDocumentAnnotations(
    String documentId,
  ) async {
    try {
      final response = await _client
          .from('annotations')
          .select(
            '*, user_profiles!annotations_user_id_fkey(full_name, avatar_url)',
          )
          .eq('document_id', documentId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((annotation) => AnnotationModel.fromJson(annotation))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch annotations: $e');
    }
  }

  // Create annotation
  Future<AnnotationModel> createAnnotation({
    required String documentId,
    required String annotationType,
    required int pageNumber,
    String? color,
    double? thickness,
    String? content,
    Map<String, dynamic>? positionData,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _client
          .from('annotations')
          .insert({
            'document_id': documentId,
            'user_id': userId,
            'annotation_type': annotationType,
            'page_number': pageNumber,
            'color': color,
            'thickness': thickness,
            'content': content,
            'position_data': positionData,
          })
          .select(
            '*, user_profiles!annotations_user_id_fkey(full_name, avatar_url)',
          )
          .single();

      return AnnotationModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create annotation: $e');
    }
  }

  // Update annotation
  Future<void> updateAnnotation(
    String annotationId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _client.from('annotations').update(updates).eq('id', annotationId);
    } catch (e) {
      throw Exception('Failed to update annotation: $e');
    }
  }

  // Delete annotation
  Future<void> deleteAnnotation(String annotationId) async {
    try {
      await _client.from('annotations').delete().eq('id', annotationId);
    } catch (e) {
      throw Exception('Failed to delete annotation: $e');
    }
  }

  // Share document with user
  Future<void> shareDocument({
    required String documentId,
    required String userEmail,
    required String permission,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Find user by email
      final userResponse = await _client
          .from('user_profiles')
          .select('id')
          .eq('email', userEmail)
          .maybeSingle();

      if (userResponse == null) {
        throw Exception('User not found with email: $userEmail');
      }

      final sharedWithUserId = userResponse['id'];

      await _client.from('document_shares').insert({
        'document_id': documentId,
        'shared_with_user_id': sharedWithUserId,
        'shared_by_user_id': userId,
        'permission': permission,
      });
    } catch (e) {
      throw Exception('Failed to share document: $e');
    }
  }

  // Get document shares
  Future<List<Map<String, dynamic>>> getDocumentShares(
    String documentId,
  ) async {
    try {
      final response = await _client
          .from('document_shares')
          .select(
            '*, user_profiles!document_shares_shared_with_user_id_fkey(full_name, email, avatar_url)',
          )
          .eq('document_id', documentId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch document shares: $e');
    }
  }

  // Remove document share
  Future<void> removeDocumentShare(String shareId) async {
    try {
      await _client.from('document_shares').delete().eq('id', shareId);
    } catch (e) {
      throw Exception('Failed to remove share: $e');
    }
  }

  // Subscribe to annotation changes
  RealtimeChannel subscribeToAnnotations({
    required String documentId,
    required Function(AnnotationModel) onInsert,
    required Function(AnnotationModel) onUpdate,
    required Function(String) onDelete,
  }) {
    final channel = _client
        .channel('annotations_$documentId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'annotations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'document_id',
            value: documentId,
          ),
          callback: (payload) {
            final annotation = AnnotationModel.fromJson(payload.newRecord);
            onInsert(annotation);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'annotations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'document_id',
            value: documentId,
          ),
          callback: (payload) {
            final annotation = AnnotationModel.fromJson(payload.newRecord);
            onUpdate(annotation);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'annotations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'document_id',
            value: documentId,
          ),
          callback: (payload) {
            final annotationId = payload.oldRecord['id'] as String;
            onDelete(annotationId);
          },
        )
        .subscribe();

    return channel;
  }

  // Get teams
  Future<List<Map<String, dynamic>>> getTeams() async {
    try {
      final response = await _client
          .from('teams')
          .select('*, team_members(count)')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch teams: $e');
    }
  }

  // Create team
  Future<Map<String, dynamic>> createTeam(String teamName) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _client
          .from('teams')
          .insert({'name': teamName, 'owner_id': userId})
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to create team: $e');
    }
  }

  // Add team member
  Future<void> addTeamMember({
    required String teamId,
    required String userEmail,
  }) async {
    try {
      // Find user by email
      final userResponse = await _client
          .from('user_profiles')
          .select('id')
          .eq('email', userEmail)
          .maybeSingle();

      if (userResponse == null) {
        throw Exception('User not found with email: $userEmail');
      }

      final userId = userResponse['id'];

      await _client.from('team_members').insert({
        'team_id': teamId,
        'user_id': userId,
        'role': 'member',
      });
    } catch (e) {
      throw Exception('Failed to add team member: $e');
    }
  }

  // Share document with team
  Future<void> shareDocumentWithTeam({
    required String documentId,
    required String teamId,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _client.from('team_documents').insert({
        'team_id': teamId,
        'document_id': documentId,
        'shared_by_user_id': userId,
      });
    } catch (e) {
      throw Exception('Failed to share document with team: $e');
    }
  }

  // Create document
  Future<DocumentModel> createDocument({
    required String name,
    required String size,
    String? thumbnailUrl,
    String? filePath,
    bool isEncrypted = false,
    List<String> tags = const [],
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _client
          .from('documents')
          .insert({
            'owner_id': userId,
            'name': name,
            'size': size,
            'thumbnail_url': thumbnailUrl,
            'file_path': filePath,
            'is_encrypted': isEncrypted,
            'is_favorite': false,
            'tags': tags,
          })
          .select()
          .single();

      return DocumentModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create document: $e');
    }
  }
}
