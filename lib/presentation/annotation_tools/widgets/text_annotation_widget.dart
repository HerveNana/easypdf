import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Text annotation settings widget with font size, color, and background options
class TextAnnotationWidget extends StatelessWidget {
  final double fontSize;
  final Color textColor;
  final Color backgroundColor;
  final Function({double? fontSize, Color? textColor, Color? backgroundColor})
  onSettingsChanged;

  const TextAnnotationWidget({
    super.key,
    required this.fontSize,
    required this.textColor,
    required this.backgroundColor,
    required this.onSettingsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Font size control
          _buildFontSizeControl(theme),
          SizedBox(height: 2.h),

          // Text color picker
          _buildColorSection(
            theme,
            'Text Color',
            textColor,
            (color) => onSettingsChanged(textColor: color),
          ),
          SizedBox(height: 2.h),

          // Background color picker
          _buildColorSection(
            theme,
            'Background',
            backgroundColor,
            (color) => onSettingsChanged(backgroundColor: color),
          ),
          SizedBox(height: 2.h),

          // Preview
          _buildPreview(theme),
        ],
      ),
    );
  }

  /// Build font size control
  Widget _buildFontSizeControl(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Font Size',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${fontSize.toInt()}pt',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: theme.colorScheme.primary,
            inactiveTrackColor: theme.colorScheme.outline.withValues(
              alpha: 0.2,
            ),
            thumbColor: theme.colorScheme.primary,
            overlayColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            trackHeight: 4,
          ),
          child: Slider(
            value: fontSize,
            min: 8,
            max: 32,
            divisions: 24,
            onChanged: (value) => onSettingsChanged(fontSize: value),
          ),
        ),
      ],
    );
  }

  /// Build color section with preset colors
  Widget _buildColorSection(
    ThemeData theme,
    String label,
    Color currentColor,
    Function(Color) onColorSelected,
  ) {
    final colors = [
      Colors.black,
      Colors.white,
      const Color(0xFF2196F3),
      const Color(0xFF4CAF50),
      const Color(0xFFFF5722),
      const Color(0xFF9C27B0),
      Colors.transparent,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: colors.map((color) {
            final isSelected = currentColor.value == color.value;
            final isTransparent = color == Colors.transparent;

            return GestureDetector(
              onTap: () => onColorSelected(color),
              child: Container(
                width: 10.w,
                height: 5.h,
                decoration: BoxDecoration(
                  color: isTransparent ? Colors.white : color,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withValues(alpha: 0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: isTransparent
                    ? Center(
                        child: CustomIconWidget(
                          iconName: 'block',
                          color: Colors.red,
                          size: 16,
                        ),
                      )
                    : isSelected
                    ? Center(
                        child: CustomIconWidget(
                          iconName: 'check',
                          color: _getContrastColor(color),
                          size: 16,
                        ),
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Build text preview
  Widget _buildPreview(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preview',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Sample Text',
              style: TextStyle(
                fontSize: fontSize,
                color: textColor,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Get contrasting color for text on colored background
  Color _getContrastColor(Color background) {
    final luminance = background.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
