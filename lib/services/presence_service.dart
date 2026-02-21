import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile_model.dart';
import './supabase_service.dart';

class PresenceService {
  static PresenceService? _instance;
  static PresenceService get instance => _instance ??= PresenceService._();

  PresenceService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  Timer? _heartbeatTimer;
  final Map<String, RealtimeChannel> _presenceChannels = {};

  // Start presence tracking for current user
  Future<void> startPresenceTracking() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _updatePresence('online', null);

      // Start heartbeat to keep presence alive
      _heartbeatTimer?.cancel();
      _heartbeatTimer = Timer.periodic(
        const Duration(minutes: 2),
        (_) => _updatePresence('online', null),
      );
    } catch (e) {
      throw Exception('Failed to start presence tracking: $e');
    }
  }

  // Stop presence tracking
  Future<void> stopPresenceTracking() async {
    try {
      _heartbeatTimer?.cancel();
      await _updatePresence('offline', null);
    } catch (e) {
      throw Exception('Failed to stop presence tracking: $e');
    }
  }

  // Update user presence status
  Future<void> _updatePresence(String status, String? documentId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client.rpc(
        'update_user_presence',
        params: {
          'p_user_id': userId,
          'p_status': status,
          'p_document_id': documentId,
        },
      );
    } catch (e) {
      throw Exception('Failed to update presence: $e');
    }
  }

  // Join document viewing session
  Future<void> joinDocumentViewing(String documentId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client.rpc(
        'join_document_viewing',
        params: {'p_document_id': documentId, 'p_user_id': userId},
      );

      await logSyncStatus(documentId, 'connected');
    } catch (e) {
      throw Exception('Failed to join document viewing: $e');
    }
  }

  // Leave document viewing session
  Future<void> leaveDocumentViewing(String documentId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client.rpc(
        'leave_document_viewing',
        params: {'p_document_id': documentId, 'p_user_id': userId},
      );
    } catch (e) {
      throw Exception('Failed to leave document viewing: $e');
    }
  }

  // Update annotating status
  Future<void> updateAnnotatingStatus(
    String documentId,
    bool isAnnotating,
  ) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client.rpc(
        'update_annotating_status',
        params: {
          'p_document_id': documentId,
          'p_user_id': userId,
          'p_is_annotating': isAnnotating,
        },
      );

      if (isAnnotating) {
        await logSyncStatus(documentId, 'syncing');
      }
    } catch (e) {
      throw Exception('Failed to update annotating status: $e');
    }
  }

  // Get active viewers for a document
  Future<List<Map<String, dynamic>>> getActiveViewers(String documentId) async {
    try {
      final response = await _client.rpc(
        'get_active_viewers',
        params: {'p_document_id': documentId},
      );

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      throw Exception('Failed to get active viewers: $e');
    }
  }

  // Log sync status
  Future<void> logSyncStatus(String documentId, String status) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client.rpc(
        'log_sync_status',
        params: {
          'p_user_id': userId,
          'p_document_id': documentId,
          'p_status': status,
        },
      );
    } catch (e) {
      throw Exception('Failed to log sync status: $e');
    }
  }

  // Get users viewing a specific document
  Future<List<UserProfileModel>> getDocumentViewers(String documentId) async {
    try {
      final viewers = await getActiveViewers(documentId);
      return viewers
          .map(
            (viewer) => UserProfileModel(
              id: viewer['user_id'] as String,
              email: '',
              fullName: viewer['full_name'] as String? ?? 'Unknown',
              avatarUrl: viewer['avatar_url'] as String?,
              role: 'member',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to get document viewers: $e');
    }
  }

  // Subscribe to document viewers changes
  RealtimeChannel subscribeToDocumentViewers({
    required String documentId,
    required Function(List<Map<String, dynamic>>) onViewersChanged,
  }) {
    final channelName = 'document_viewers_$documentId';

    // Remove existing channel if present
    _presenceChannels[channelName]?.unsubscribe();

    final channel = _client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'document_viewers',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'document_id',
            value: documentId,
          ),
          callback: (_) async {
            final viewers = await getActiveViewers(documentId);
            onViewersChanged(viewers);
          },
        )
        .subscribe();

    _presenceChannels[channelName] = channel;
    return channel;
  }

  // Subscribe to user presence changes
  RealtimeChannel subscribeToPresence({
    required Function(Map<String, dynamic>) onPresenceChanged,
  }) {
    const channelName = 'user_presence_all';

    // Remove existing channel if present
    _presenceChannels[channelName]?.unsubscribe();

    final channel = _client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'user_presence',
          callback: (payload) {
            onPresenceChanged(payload.newRecord);
          },
        )
        .subscribe();

    _presenceChannels[channelName] = channel;
    return channel;
  }

  // Unsubscribe from a specific channel
  Future<void> unsubscribeFromChannel(String channelName) async {
    await _presenceChannels[channelName]?.unsubscribe();
    _presenceChannels.remove(channelName);
  }

  // Unsubscribe from all channels
  Future<void> unsubscribeAll() async {
    for (final channel in _presenceChannels.values) {
      await channel.unsubscribe();
    }
    _presenceChannels.clear();
  }

  // Cleanup
  void dispose() {
    _heartbeatTimer?.cancel();
    unsubscribeAll();
  }
}
