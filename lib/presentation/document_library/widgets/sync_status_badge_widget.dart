import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class SyncStatusBadgeWidget extends StatelessWidget {
  final String status;
  final bool showLabel;

  const SyncStatusBadgeWidget({
    required this.status,
    this.showLabel = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (status) {
      case 'connected':
        statusColor = const Color(0xFF4CAF50);
        statusIcon = Icons.cloud_done;
        statusLabel = 'Connecté';
        break;
      case 'syncing':
        statusColor = const Color(0xFFFF9800);
        statusIcon = Icons.sync;
        statusLabel = 'Synchronisation';
        break;
      case 'disconnected':
        statusColor = const Color(0xFFE57373);
        statusIcon = Icons.cloud_off;
        statusLabel = 'Déconnecté';
        break;
      default:
        statusColor = theme.colorScheme.onSurfaceVariant;
        statusIcon = Icons.help_outline;
        statusLabel = 'Inconnu';
    }

    if (showLabel) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(statusIcon, size: 14.sp, color: statusColor),
            SizedBox(width: 1.w),
            Text(
              statusLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: 2.w,
      height: 2.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: statusColor,
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.4),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
