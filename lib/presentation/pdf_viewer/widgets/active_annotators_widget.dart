import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ActiveAnnotatorsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> activeAnnotators;
  final VoidCallback? onTap;

  const ActiveAnnotatorsWidget({
    required this.activeAnnotators,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (activeAnnotators.isEmpty) {
      return const SizedBox.shrink();
    }

    final annotatingUsers = activeAnnotators
        .where((viewer) => viewer['is_annotating'] == true)
        .toList();

    if (annotatingUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: const Color(0xFFFF9800).withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 2.w,
              height: 2.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF9800),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF9800).withValues(alpha: 0.6),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            SizedBox(width: 2.w),
            ...annotatingUsers.take(3).map((user) {
              final avatarUrl = user['avatar_url'] as String?;
              final fullName = user['full_name'] as String? ?? 'User';
              final initials = fullName
                  .split(' ')
                  .map((n) => n[0])
                  .take(2)
                  .join();

              return Padding(
                padding: EdgeInsets.only(right: 1.w),
                child: CircleAvatar(
                  radius: 2.5.w,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? Text(
                          initials,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontSize: 8.sp,
                          ),
                        )
                      : null,
                ),
              );
            }),
            SizedBox(width: 1.w),
            Text(
              annotatingUsers.length == 1
                  ? '${annotatingUsers[0]['full_name']} annote'
                  : '${annotatingUsers.length} annotent',
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (onTap != null) ...[
              SizedBox(width: 1.w),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withValues(alpha: 0.7),
                size: 16.sp,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
