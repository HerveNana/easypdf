import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AnnotatorsListSheet extends StatelessWidget {
  final List<Map<String, dynamic>> viewers;

  const AnnotatorsListSheet({required this.viewers, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final annotatingUsers = viewers
        .where((viewer) => viewer['is_annotating'] == true)
        .toList();
    final viewingUsers = viewers
        .where((viewer) => viewer['is_annotating'] != true)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      padding: EdgeInsets.all(4.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Utilisateurs actifs',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          if (annotatingUsers.isNotEmpty) ...[
            Text(
              'Annotent actuellement',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 1.h),
            ...annotatingUsers.map(
              (user) => _buildUserTile(context, user, isAnnotating: true),
            ),
            SizedBox(height: 2.h),
          ],
          if (viewingUsers.isNotEmpty) ...[
            Text(
              'Visualisent',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 1.h),
            ...viewingUsers.map(
              (user) => _buildUserTile(context, user, isAnnotating: false),
            ),
          ],
          if (viewers.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(4.h),
                child: Text(
                  'Aucun utilisateur actif',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildUserTile(
    BuildContext context,
    Map<String, dynamic> user, {
    required bool isAnnotating,
  }) {
    final theme = Theme.of(context);
    final avatarUrl = user['avatar_url'] as String?;
    final fullName = user['full_name'] as String? ?? 'Unknown User';
    final initials = fullName.split(' ').map((n) => n[0]).take(2).join();
    final lastActive = user['last_active'] as String?;

    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 5.w,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl == null || avatarUrl.isEmpty
                  ? Text(
                      initials,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    )
                  : null,
            ),
            if (isAnnotating)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 3.w,
                  height: 3.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFF9800),
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          fullName,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          isAnnotating ? 'Annote actuellement' : 'Visualise',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isAnnotating
                ? const Color(0xFFFF9800)
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Container(
          width: 2.w,
          height: 2.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF4CAF50),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
