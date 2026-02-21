import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/advanced_tools_widget.dart';
import './widgets/color_picker_widget.dart';
import './widgets/shape_tools_widget.dart';
import './widgets/text_annotation_widget.dart';
import './widgets/thickness_slider_widget.dart';
import './widgets/tool_palette_widget.dart';

/// Annotation Tools screen providing comprehensive PDF markup capabilities
/// optimized for touch interaction and mobile precision.
class AnnotationTools extends StatefulWidget {
  const AnnotationTools({super.key});

  @override
  State<AnnotationTools> createState() => _AnnotationToolsState();
}

class _AnnotationToolsState extends State<AnnotationTools>
    with SingleTickerProviderStateMixin {
  // Selected tool state
  String _selectedTool = 'highlighter';

  // Tool settings
  Color _selectedColor = const Color(0xFFFFEB3B);
  double _lineThickness = 3.0;
  double _opacity = 0.5;

  // Text annotation settings
  double _fontSize = 14.0;
  Color _textColor = Colors.black;
  Color _textBackground = Colors.transparent;

  // Bottom sheet height control
  double _sheetHeight = 0.4;
  final double _minSheetHeight = 0.3;
  final double _maxSheetHeight = 0.85;

  // Animation controller for sheet expansion
  late AnimationController _animationController;

  // Recently used tools
  List<String> _recentTools = ['highlighter', 'pen', 'text'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _loadToolSettings();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Load persisted tool settings from local storage
  Future<void> _loadToolSettings() async {
    // In production, load from SharedPreferences
    // For now, using default values
  }

  /// Save tool settings to local storage
  Future<void> _saveToolSettings() async {
    // In production, save to SharedPreferences
  }

  /// Handle tool selection
  void _onToolSelected(String tool) {
    setState(() {
      _selectedTool = tool;

      // Update recent tools
      _recentTools.remove(tool);
      _recentTools.insert(0, tool);
      if (_recentTools.length > 5) {
        _recentTools = _recentTools.sublist(0, 5);
      }
    });

    _saveToolSettings();

    // Provide haptic feedback
    // HapticFeedback.selectionClick(); // Uncomment in production
  }

  /// Handle color selection
  void _onColorSelected(Color color) {
    setState(() {
      _selectedColor = color;
    });
    _saveToolSettings();
  }

  /// Handle thickness change
  void _onThicknessChanged(double thickness) {
    setState(() {
      _lineThickness = thickness;
    });
  }

  /// Handle opacity change
  void _onOpacityChanged(double opacity) {
    setState(() {
      _opacity = opacity;
    });
  }

  /// Handle text settings change
  void _onTextSettingsChanged({
    double? fontSize,
    Color? textColor,
    Color? backgroundColor,
  }) {
    setState(() {
      if (fontSize != null) _fontSize = fontSize;
      if (textColor != null) _textColor = textColor;
      if (backgroundColor != null) _textBackground = backgroundColor;
    });
    _saveToolSettings();
  }

  /// Handle undo action (two-finger tap gesture)
  void _handleUndo() {
    // Implement undo logic
    // HapticFeedback.mediumImpact();
  }

  /// Handle redo action (three-finger tap gesture)
  void _handleRedo() {
    // Implement redo logic
    // HapticFeedback.mediumImpact();
  }

  /// Handle sheet height adjustment
  void _onSheetDrag(DragUpdateDetails details) {
    setState(() {
      _sheetHeight -=
          details.primaryDelta! / MediaQuery.of(context).size.height;
      _sheetHeight = _sheetHeight.clamp(_minSheetHeight, _maxSheetHeight);
    });
  }

  /// Dismiss bottom sheet
  void _dismissSheet() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onVerticalDragUpdate: _onSheetDrag,
      child: Container(
        height: MediaQuery.of(context).size.height * _sheetHeight,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Drag handle
            _buildDragHandle(theme),

            // Header with title and close button
            _buildHeader(theme),

            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick access toolbar for recent tools
                    if (_recentTools.isNotEmpty) ...[
                      _buildSectionTitle(theme, 'Quick Access'),
                      SizedBox(height: 1.h),
                      _buildQuickAccessToolbar(theme),
                      SizedBox(height: 3.h),
                    ],

                    // Primary tool palette
                    _buildSectionTitle(theme, 'Tools'),
                    SizedBox(height: 1.h),
                    ToolPaletteWidget(
                      selectedTool: _selectedTool,
                      onToolSelected: _onToolSelected,
                    ),
                    SizedBox(height: 3.h),

                    // Tool-specific options
                    _buildToolOptions(theme),

                    // Advanced tools section
                    SizedBox(height: 3.h),
                    _buildSectionTitle(theme, 'Advanced Tools'),
                    SizedBox(height: 1.h),
                    AdvancedToolsWidget(onToolSelected: _onToolSelected),

                    // Bottom padding for safe area
                    SizedBox(height: 2.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build drag handle for sheet adjustment
  Widget _buildDragHandle(ThemeData theme) {
    return Container(
      margin: EdgeInsets.only(top: 1.h),
      width: 12.w,
      height: 0.5.h,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  /// Build header with title and close button
  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Annotation Tools',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              // Undo button
              IconButton(
                onPressed: _handleUndo,
                icon: CustomIconWidget(
                  iconName: 'undo',
                  color: theme.colorScheme.onSurface,
                  size: 24,
                ),
                tooltip: 'Undo (Two-finger tap)',
              ),
              // Redo button
              IconButton(
                onPressed: _handleRedo,
                icon: CustomIconWidget(
                  iconName: 'redo',
                  color: theme.colorScheme.onSurface,
                  size: 24,
                ),
                tooltip: 'Redo (Three-finger tap)',
              ),
              // Close button
              IconButton(
                onPressed: _dismissSheet,
                icon: CustomIconWidget(
                  iconName: 'close',
                  color: theme.colorScheme.onSurface,
                  size: 24,
                ),
                tooltip: 'Close',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build section title
  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  /// Build quick access toolbar for recently used tools
  Widget _buildQuickAccessToolbar(ThemeData theme) {
    return Container(
      height: 8.h,
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
        padding: EdgeInsets.symmetric(horizontal: 2.w),
        itemCount: _recentTools.length,
        separatorBuilder: (context, index) => SizedBox(width: 2.w),
        itemBuilder: (context, index) {
          final tool = _recentTools[index];
          final isSelected = tool == _selectedTool;

          return GestureDetector(
            onTap: () => _onToolSelected(tool),
            child: Container(
              width: 15.w,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: _getToolIcon(tool),
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    _getToolLabel(tool),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      fontSize: 9.sp,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
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

  /// Build tool-specific options based on selected tool
  Widget _buildToolOptions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(theme, 'Tool Options'),
        SizedBox(height: 1.h),

        // Color picker for all tools except eraser
        if (_selectedTool != 'eraser') ...[
          ColorPickerWidget(
            selectedColor: _selectedColor,
            onColorSelected: _onColorSelected,
          ),
          SizedBox(height: 2.h),
        ],

        // Line thickness slider for drawing tools
        if (_selectedTool == 'pen' ||
            _selectedTool == 'highlighter' ||
            _selectedTool == 'eraser') ...[
          ThicknessSliderWidget(
            thickness: _lineThickness,
            onThicknessChanged: _onThicknessChanged,
            label: _selectedTool == 'eraser' ? 'Eraser Size' : 'Line Thickness',
          ),
          SizedBox(height: 2.h),
        ],

        // Opacity control for highlighter
        if (_selectedTool == 'highlighter') ...[
          _buildOpacityControl(theme),
          SizedBox(height: 2.h),
        ],

        // Text annotation options
        if (_selectedTool == 'text') ...[
          TextAnnotationWidget(
            fontSize: _fontSize,
            textColor: _textColor,
            backgroundColor: _textBackground,
            onSettingsChanged: _onTextSettingsChanged,
          ),
          SizedBox(height: 2.h),
        ],

        // Shape tools options
        if (_selectedTool == 'shapes') ...[
          ShapeToolsWidget(
            selectedColor: _selectedColor,
            lineThickness: _lineThickness,
          ),
        ],
      ],
    );
  }

  /// Build opacity control slider
  Widget _buildOpacityControl(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Opacity',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(_opacity * 100).toInt()}%',
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
            value: _opacity,
            min: 0.1,
            max: 1.0,
            divisions: 9,
            onChanged: _onOpacityChanged,
          ),
        ),
      ],
    );
  }

  /// Get icon name for tool
  String _getToolIcon(String tool) {
    switch (tool) {
      case 'highlighter':
        return 'highlight';
      case 'pen':
        return 'edit';
      case 'text':
        return 'text_fields';
      case 'shapes':
        return 'crop_square';
      case 'eraser':
        return 'cleaning_services';
      case 'signature':
        return 'draw';
      case 'stamp':
        return 'verified';
      case 'measure':
        return 'straighten';
      default:
        return 'edit';
    }
  }

  /// Get label for tool
  String _getToolLabel(String tool) {
    switch (tool) {
      case 'highlighter':
        return 'Highlight';
      case 'pen':
        return 'Pen';
      case 'text':
        return 'Text';
      case 'shapes':
        return 'Shapes';
      case 'eraser':
        return 'Eraser';
      case 'signature':
        return 'Sign';
      case 'stamp':
        return 'Stamp';
      case 'measure':
        return 'Measure';
      default:
        return tool;
    }
  }
}
