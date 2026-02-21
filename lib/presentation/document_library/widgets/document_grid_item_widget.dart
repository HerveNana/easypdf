import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class DocumentGridItemWidget extends StatelessWidget {
  final Map<String, dynamic> document;
  final bool isSelected;
  final bool isSelectionMode;
  final bool isListView;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const DocumentGridItemWidget({
    super.key,
    required this.document,
    required this.isSelected,
    required this.isSelectionMode,
    this.isListView = false,
    required this.onTap,
    required this.onLongPress,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return "Aujourd'hui ${DateFormat('HH:mm').format(date)}";
    } else if (difference.inDays == 1) {
      return 'Hier ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays < 7) {
      return DateFormat('dd/MM HH:mm').format(date);
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  void _handleTap(BuildContext context) {
    if (isSelectionMode) {
      onTap();
    } else {
      Navigator.pushNamed(
        context,
        AppRoutes.pdfViewer,
        arguments: {
          'documentId': document['id'],
          'filePath': document['filePath'],
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isListView) {
      return InkWell(
        onTap: () => _handleTap(context),
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              if (isSelectionMode)
                Padding(
                  padding: EdgeInsets.only(right: 3.w),
                  child: CustomIconWidget(
                    iconName: isSelected ? 'e86c' : 'e836',
                    size: 24,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CustomImageWidget(
                  imageUrl: document["thumbnail"] as String,
                  width: 15.w,
                  height: 10.h,
                  fit: BoxFit.cover,
                  semanticLabel: document["semanticLabel"] as String,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            document["name"] as String,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (document["isFavorite"] as bool)
                          Padding(
                            padding: EdgeInsets.only(left: 2.w),
                            child: CustomIconWidget(
                              iconName: 'e838',
                              size: 16,
                              color: Colors.amber,
                            ),
                          ),
                        if (document["isEncrypted"] as bool)
                          Padding(
                            padding: EdgeInsets.only(left: 2.w),
                            child: CustomIconWidget(
                              iconName: 'e897',
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      '${document["size"]} • ${_formatDate(document["modifiedDate"] as DateTime)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if ((document["tags"] as List).isNotEmpty) ...[
                      SizedBox(height: 0.5.h),
                      Wrap(
                        spacing: 1.w,
                        children: (document["tags"] as List).map((tag) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.w,
                              vertical: 0.3.h,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tag as String,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => _handleTap(context),
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: CustomImageWidget(
                    imageUrl: document["thumbnail"] as String,
                    width: double.infinity,
                    height: 20.h,
                    fit: BoxFit.cover,
                    semanticLabel: document["semanticLabel"] as String,
                  ),
                ),
                if (isSelectionMode)
                  Positioned(
                    top: 1.h,
                    right: 2.w,
                    child: Container(
                      padding: EdgeInsets.all(0.5.w),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        shape: BoxShape.circle,
                      ),
                      child: CustomIconWidget(
                        iconName: isSelected ? 'e86c' : 'e836',
                        size: 20,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                if (document["isFavorite"] as bool && !isSelectionMode)
                  Positioned(
                    top: 1.h,
                    right: 2.w,
                    child: Container(
                      padding: EdgeInsets.all(1.w),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: CustomIconWidget(
                        iconName: 'e838',
                        size: 16,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                if (document["isEncrypted"] as bool)
                  Positioned(
                    top: 1.h,
                    left: 2.w,
                    child: Container(
                      padding: EdgeInsets.all(1.w),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: CustomIconWidget(
                        iconName: 'e897',
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(2.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document["name"] as String,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      document["size"] as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 0.3.h),
                    Text(
                      _formatDate(document["modifiedDate"] as DateTime),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
