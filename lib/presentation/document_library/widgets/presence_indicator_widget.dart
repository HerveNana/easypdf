import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class PresenceIndicatorWidget extends StatelessWidget {
  final List<Map<String, dynamic>> activeViewers;
  final int maxAvatars;

  const PresenceIndicatorWidget({
    required this.activeViewers,
    this.maxAvatars = 3,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (activeViewers.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayViewers = activeViewers.take(maxAvatars).toList();
    final remainingCount = activeViewers.length - displayViewers.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...displayViewers.asMap().entries.map((entry) {
          final index = entry.key;
          final viewer = entry.value;
          final avatarUrl = viewer['avatar_url'] as String?;
          final fullName = viewer['full_name'] as String? ?? 'User';
          final initials = fullName.split(' ').map((n) => n[0]).take(2).join();

          return Transform.translate(
            offset: Offset(-index * 2.5.w, 0),
            child: Container(
              width: 6.w,
              height: 6.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.surface, width: 2),
              ),
              child: CircleAvatar(
                radius: 3.w,
                backgroundColor: theme.colorScheme.primaryContainer,
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? Text(
                        initials,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontSize: 8.sp,
                        ),
                      )
                    : null,
              ),
            ),
          );
        }),
        if (remainingCount > 0)
          Transform.translate(
            offset: Offset(-displayViewers.length * 2.5.w, 0),
            child: Container(
              width: 6.w,
              height: 6.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.secondaryContainer,
                border: Border.all(color: theme.colorScheme.surface, width: 2),
              ),
              child: Center(
                child: Text(
                  '+$remainingCount',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
