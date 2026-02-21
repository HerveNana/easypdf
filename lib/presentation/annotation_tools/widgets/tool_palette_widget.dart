import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Primary tool palette widget displaying horizontally-scrolling tool icons
class ToolPaletteWidget extends StatelessWidget {
  final String selectedTool;
  final Function(String) onToolSelected;

  const ToolPaletteWidget({
    super.key,
    required this.selectedTool,
    required this.onToolSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final tools = [
      {'id': 'highlighter', 'icon': 'highlight', 'label': 'Highlighter'},
      {'id': 'pen', 'icon': 'edit', 'label': 'Pen'},
      {'id': 'text', 'icon': 'text_fields', 'label': 'Text Box'},
      {'id': 'shapes', 'icon': 'crop_square', 'label': 'Shapes'},
      {'id': 'eraser', 'icon': 'cleaning_services', 'label': 'Eraser'},
    ];

    return Container(
      height: 12.h,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        itemCount: tools.length,
        separatorBuilder: (context, index) => SizedBox(width: 3.w),
        itemBuilder: (context, index) {
          final tool = tools[index];
          final isSelected = tool['id'] == selectedTool;

          return GestureDetector(
            onTap: () => onToolSelected(tool['id'] as String),
            child: Container(
              width: 18.w,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: theme.colorScheme.primary, width: 2)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomIconWidget(
                      iconName: tool['icon'] as String,
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    tool['label'] as String,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      fontSize: 10.sp,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
