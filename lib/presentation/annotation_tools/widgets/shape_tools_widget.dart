import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Shape tools widget for drawing geometric shapes
class ShapeToolsWidget extends StatefulWidget {
  final Color selectedColor;
  final double lineThickness;

  const ShapeToolsWidget({
    super.key,
    required this.selectedColor,
    required this.lineThickness,
  });

  @override
  State<ShapeToolsWidget> createState() => _ShapeToolsWidgetState();
}

class _ShapeToolsWidgetState extends State<ShapeToolsWidget> {
  String _selectedShape = 'rectangle';
  bool _fillShape = false;
  bool _snapToGrid = true;

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
          Text(
            'Shape Type',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),

          // Shape selection
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: [
              _buildShapeOption(theme, 'rectangle', 'crop_square', 'Rectangle'),
              _buildShapeOption(theme, 'circle', 'circle', 'Circle'),
              _buildShapeOption(theme, 'arrow', 'arrow_forward', 'Arrow'),
              _buildShapeOption(theme, 'line', 'remove', 'Line'),
            ],
          ),

          SizedBox(height: 2.h),

          // Shape options
          _buildShapeOptions(theme),

          SizedBox(height: 2.h),

          // Preview
          _buildShapePreview(theme),
        ],
      ),
    );
  }

  /// Build individual shape option
  Widget _buildShapeOption(
    ThemeData theme,
    String shapeId,
    String iconName,
    String label,
  ) {
    final isSelected = _selectedShape == shapeId;

    return GestureDetector(
      onTap: () => setState(() => _selectedShape = shapeId),
      child: Container(
        width: 20.w,
        padding: EdgeInsets.symmetric(vertical: 1.5.h),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            CustomIconWidget(
              iconName: iconName,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            SizedBox(height: 0.5.h),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                fontSize: 10.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build shape options (fill, snap to grid)
  Widget _buildShapeOptions(ThemeData theme) {
    return Column(
      children: [
        // Fill shape option
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Fill Shape', style: theme.textTheme.bodyMedium),
            Switch(
              value: _fillShape,
              onChanged: (value) => setState(() => _fillShape = value),
            ),
          ],
        ),

        // Snap to grid option
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text('Snap to Grid', style: theme.textTheme.bodyMedium),
                SizedBox(width: 1.w),
                Tooltip(
                  message: 'Align shapes to grid for precise placement',
                  child: CustomIconWidget(
                    iconName: 'info_outline',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 16,
                  ),
                ),
              ],
            ),
            Switch(
              value: _snapToGrid,
              onChanged: (value) => setState(() => _snapToGrid = value),
            ),
          ],
        ),
      ],
    );
  }

  /// Build shape preview
  Widget _buildShapePreview(ThemeData theme) {
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
          height: 15.h,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Center(
            child: CustomPaint(
              size: Size(30.w, 10.h),
              painter: _ShapePreviewPainter(
                shape: _selectedShape,
                color: widget.selectedColor,
                thickness: widget.lineThickness,
                fill: _fillShape,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter for shape preview
class _ShapePreviewPainter extends CustomPainter {
  final String shape;
  final Color color;
  final double thickness;
  final bool fill;

  _ShapePreviewPainter({
    required this.shape,
    required this.color,
    required this.thickness,
    required this.fill,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = fill ? PaintingStyle.fill : PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.3;

    switch (shape) {
      case 'rectangle':
        final rect = Rect.fromCenter(
          center: center,
          width: size.width * 0.6,
          height: size.height * 0.6,
        );
        canvas.drawRect(rect, paint);
        break;

      case 'circle':
        canvas.drawCircle(center, radius, paint);
        break;

      case 'arrow':
        final path = Path()
          ..moveTo(size.width * 0.2, center.dy)
          ..lineTo(size.width * 0.7, center.dy)
          ..lineTo(size.width * 0.6, center.dy - size.height * 0.15)
          ..moveTo(size.width * 0.7, center.dy)
          ..lineTo(size.width * 0.6, center.dy + size.height * 0.15);
        paint.style = PaintingStyle.stroke;
        canvas.drawPath(path, paint);
        break;

      case 'line':
        canvas.drawLine(
          Offset(size.width * 0.2, center.dy),
          Offset(size.width * 0.8, center.dy),
          paint,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
