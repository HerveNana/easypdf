import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Annotation Toolbar Widget - Bottom toolbar with annotation tools
///
/// Features:
/// - Tool selection (highlighter, pen, text notes, shapes)
/// - Color picker access via long-press
/// - Auto-hiding after 3 seconds of inactivity
/// - Material ripple effects on tool selection
class AnnotationToolbarWidget extends StatelessWidget {
  final String selectedTool;
  final Color selectedColor;
  final Function(String) onToolSelected;
  final VoidCallback onColorPickerTap;

  const AnnotationToolbarWidget({
    super.key,
    required this.selectedTool,
    required this.selectedColor,
    required this.onToolSelected,
    required this.onColorPickerTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildToolButton(
            context: context,
            icon: 'highlight',
            label: 'Highlight',
            toolId: 'highlight',
            isSelected: selectedTool == 'highlight',
          ),
          _buildToolButton(
            context: context,
            icon: 'edit',
            label: 'Pen',
            toolId: 'pen',
            isSelected: selectedTool == 'pen',
          ),
          _buildToolButton(
            context: context,
            icon: 'note_add',
            label: 'Note',
            toolId: 'note',
            isSelected: selectedTool == 'note',
          ),
          _buildToolButton(
            context: context,
            icon: 'crop_square',
            label: 'Shape',
            toolId: 'shape',
            isSelected: selectedTool == 'shape',
          ),
          GestureDetector(
            onTap: onColorPickerTap,
            onLongPress: onColorPickerTap,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selectedColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'palette',
                  color: _getContrastColor(selectedColor),
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required BuildContext context,
    required String icon,
    required String label,
    required String toolId,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => onToolSelected(isSelected ? '' : toolId),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : Colors.white.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: icon,
              color: isSelected ? theme.colorScheme.primary : Colors.white,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected ? theme.colorScheme.primary : Colors.white,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
