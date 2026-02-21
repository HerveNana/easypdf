import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Line thickness slider widget for drawing tools
class ThicknessSliderWidget extends StatelessWidget {
  final double thickness;
  final Function(double) onThicknessChanged;
  final String label;

  const ThicknessSliderWidget({
    super.key,
    required this.thickness,
    required this.onThicknessChanged,
    this.label = 'Line Thickness',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${thickness.toInt()}pt',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),

        // Thickness slider
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
            value: thickness,
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: onThicknessChanged,
          ),
        ),

        // Visual thickness preview
        SizedBox(height: 1.h),
        Container(
          width: double.infinity,
          height: 6.h,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Container(
              width: 60.w,
              height: thickness,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(thickness / 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
