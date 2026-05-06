import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Color picker widget with preset colors and custom color option
class ColorPickerWidget extends StatefulWidget {
  final Color selectedColor;
  final Function(Color) onColorSelected;

  const ColorPickerWidget({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  State<ColorPickerWidget> createState() => _ColorPickerWidgetState();
}

class _ColorPickerWidgetState extends State<ColorPickerWidget> {
  // Preset colors for quick selection
  final List<Color> _presetColors = [
    const Color(0xFFFFEB3B), // Yellow
    const Color(0xFF4CAF50), // Green
    const Color(0xFF2196F3), // Blue
    const Color(0xFFFF5722), // Red
    const Color(0xFF9C27B0), // Purple
    const Color(0xFFFF9800), // Orange
    const Color(0xFF00BCD4), // Cyan
    const Color(0xFF795548), // Brown
  ];

  bool _showCustomPicker = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Color',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 1.h),

        // Preset colors grid
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: [
            ..._presetColors.map((color) => _buildColorOption(theme, color)),
            _buildCustomColorOption(theme),
          ],
        ),

        // Custom color picker (if shown)
        if (_showCustomPicker) ...[
          SizedBox(height: 2.h),
          _buildCustomColorPicker(theme),
        ],
      ],
    );
  }

  /// Build individual color option
  Widget _buildColorOption(ThemeData theme, Color color) {
    final isSelected = widget.selectedColor.toARGB32() == color.toARGB32();

    return GestureDetector(
      onTap: () {
        setState(() => _showCustomPicker = false);
        widget.onColorSelected(color);
      },
      child: Container(
        width: 12.w,
        height: 6.h,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: isSelected
            ? Center(
                child: CustomIconWidget(
                  iconName: 'check',
                  color: _getContrastColor(color),
                  size: 20,
                ),
              )
            : null,
      ),
    );
  }

  /// Build custom color option button
  Widget _buildCustomColorOption(ThemeData theme) {
    final isCustomSelected = !_presetColors.any(
      (color) => color.toARGB32() == widget.selectedColor.toARGB32(),
    );

    return GestureDetector(
      onTap: () {
        setState(() => _showCustomPicker = !_showCustomPicker);
      },
      child: Container(
        width: 12.w,
        height: 6.h,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFF0000),
              Color(0xFFFFFF00),
              Color(0xFF00FF00),
              Color(0xFF00FFFF),
              Color(0xFF0000FF),
              Color(0xFFFF00FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCustomSelected || _showCustomPicker
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: isCustomSelected || _showCustomPicker ? 3 : 1,
          ),
        ),
        child: Center(
          child: CustomIconWidget(
            iconName: _showCustomPicker ? 'expand_less' : 'add',
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  /// Build custom color picker with RGB sliders
  Widget _buildCustomColorPicker(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Custom Color',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),

          // Color preview
          Container(
            width: double.infinity,
            height: 6.h,
            decoration: BoxDecoration(
              color: widget.selectedColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          SizedBox(height: 2.h),

          // RGB sliders
          _buildColorSlider(
            theme,
            'Red',
            (widget.selectedColor.r * 255.0).round().clamp(0, 255).toDouble(),
            (value) {
              widget.onColorSelected(
                Color.fromARGB(
                  255,
                  value.toInt(),
                  (widget.selectedColor.g * 255.0).round().clamp(0, 255),
                  (widget.selectedColor.b * 255.0).round().clamp(0, 255),
                ),
              );
            },
          ),
          SizedBox(height: 1.h),
          _buildColorSlider(
            theme,
            'Green',
            (widget.selectedColor.g * 255.0).round().clamp(0, 255).toDouble(),
            (value) {
              widget.onColorSelected(
                Color.fromARGB(
                  255,
                  (widget.selectedColor.r * 255.0).round().clamp(0, 255),
                  value.toInt(),
                  (widget.selectedColor.b * 255.0).round().clamp(0, 255),
                ),
              );
            },
          ),
          SizedBox(height: 1.h),
          _buildColorSlider(
            theme,
            'Blue',
            (widget.selectedColor.b * 255.0).round().clamp(0, 255).toDouble(),
            (value) {
              widget.onColorSelected(
                Color.fromARGB(
                  255,
                  (widget.selectedColor.r * 255.0).round().clamp(0, 255),
                  (widget.selectedColor.g * 255.0).round().clamp(0, 255),
                  value.toInt(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Build individual color slider
  Widget _buildColorSlider(
    ThemeData theme,
    String label,
    double value,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.bodySmall),
            Text(
              value.toInt().toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: theme.colorScheme.primary,
            inactiveTrackColor: theme.colorScheme.outline.withValues(
              alpha: 0.2,
            ),
            thumbColor: theme.colorScheme.primary,
            overlayColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            trackHeight: 3,
          ),
          child: Slider(value: value, min: 0, max: 255, onChanged: onChanged),
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
