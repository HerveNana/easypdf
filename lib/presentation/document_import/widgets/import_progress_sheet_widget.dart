import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Import Progress Sheet Widget
/// Displays import progress for multiple files with cancel options
class ImportProgressSheetWidget extends StatelessWidget {
  final List<Map<String, dynamic>> files;
  final Function(int) onCancel;

  const ImportProgressSheetWidget({
    super.key,
    required this.files,
    required this.onCancel,
  });

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(maxHeight: 70.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Importing Documents',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${files.where((f) => f['status'] == 'completed').length}/${files.length}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              itemCount: files.length,
              separatorBuilder: (context, index) => SizedBox(height: 1.5.h),
              itemBuilder: (context, index) {
                final file = files[index];
                final progress = file['progress'] as double;
                final status = file['status'] as String;

                return Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: status == 'completed'
                              ? theme.colorScheme.primaryContainer.withValues(
                                  alpha: 0.2,
                                )
                              : status == 'cancelled'
                              ? theme.colorScheme.errorContainer.withValues(
                                  alpha: 0.2,
                                )
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: status == 'completed'
                              ? CustomIconWidget(
                                  iconName: 'check_circle',
                                  color: theme.colorScheme.primary,
                                  size: 24,
                                )
                              : status == 'cancelled'
                              ? CustomIconWidget(
                                  iconName: 'cancel',
                                  color: theme.colorScheme.error,
                                  size: 24,
                                )
                              : CustomIconWidget(
                                  iconName: 'description',
                                  color: theme.colorScheme.onSurfaceVariant,
                                  size: 24,
                                ),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              file['name'] as String,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 0.5.h),
                            status == 'importing'
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      LinearProgressIndicator(
                                        value: progress,
                                        backgroundColor: theme
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              theme.colorScheme.primary,
                                            ),
                                      ),
                                      SizedBox(height: 0.5.h),
                                      Text(
                                        '${(progress * 100).toInt()}%',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    status == 'completed'
                                        ? 'Completed'
                                        : 'Cancelled',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: status == 'completed'
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.error,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                          ],
                        ),
                      ),
                      if (status == 'importing')
                        IconButton(
                          icon: CustomIconWidget(
                            iconName: 'close',
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          onPressed: () => onCancel(index),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
