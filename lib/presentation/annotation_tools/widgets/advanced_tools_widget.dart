import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Advanced tools widget for signature, stamps, and measurements
class AdvancedToolsWidget extends StatelessWidget {
  final Function(String) onToolSelected;

  const AdvancedToolsWidget({super.key, required this.onToolSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final advancedTools = [
      {
        'id': 'signature',
        'icon': 'draw',
        'label': 'Signature',
        'description': 'Add digital signature',
      },
      {
        'id': 'stamp',
        'icon': 'verified',
        'label': 'Stamp',
        'description': 'Apply document stamps',
      },
      {
        'id': 'measure',
        'icon': 'straighten',
        'label': 'Measure',
        'description': 'Measurement tools',
      },
    ];

    return Column(
      children: advancedTools.map((tool) {
        return Container(
          margin: EdgeInsets.only(bottom: 1.h),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onToolSelected(tool['id'] as String),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomIconWidget(
                        iconName: tool['icon'] as String,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tool['label'] as String,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            tool['description'] as String,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CustomIconWidget(
                      iconName: 'chevron_right',
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
