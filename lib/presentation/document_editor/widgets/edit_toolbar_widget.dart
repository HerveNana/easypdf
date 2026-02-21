import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Bottom toolbar widget for page editing actions
class EditToolbarWidget extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onRotate;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback onExtract;

  const EditToolbarWidget({
    super.key,
    required this.selectedCount,
    required this.onRotate,
    required this.onDuplicate,
    required this.onDelete,
    required this.onExtract,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildToolbarButton(
                context: context,
                icon: 'rotate_right',
                label: 'Rotate',
                onTap: onRotate,
                theme: theme,
              ),
              _buildToolbarButton(
                context: context,
                icon: 'content_copy',
                label: 'Duplicate',
                onTap: onDuplicate,
                theme: theme,
              ),
              _buildToolbarButton(
                context: context,
                icon: 'drive_file_move',
                label: 'Extract',
                onTap: onExtract,
                theme: theme,
              ),
              _buildToolbarButton(
                context: context,
                icon: 'delete',
                label: 'Delete',
                onTap: onDelete,
                theme: theme,
                isDestructive: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarButton({
    required BuildContext context,
    required String icon,
    required String label,
    required VoidCallback onTap,
    required ThemeData theme,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: selectedCount > 0 ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: icon,
              color: selectedCount > 0
                  ? (isDestructive
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary)
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              size: 24,
            ),
            SizedBox(height: 0.5.h),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: selectedCount > 0
                    ? (isDestructive
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurface)
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
