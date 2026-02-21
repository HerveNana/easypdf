import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A custom app bar widget for the PDF management application.
/// Implements clean professional appearance with contextual actions.
///
/// This widget provides a reusable app bar with consistent styling,
/// search functionality, and customizable actions.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// The title text to display in the app bar
  final String title;

  /// Optional subtitle text
  final String? subtitle;

  /// Whether to show the back button
  final bool showBackButton;

  /// Whether to show the search icon
  final bool showSearch;

  /// Custom leading widget (overrides showBackButton)
  final Widget? leading;

  /// List of action widgets to display
  final List<Widget>? actions;

  /// Callback when search icon is tapped
  final VoidCallback? onSearchTap;

  /// Callback when back button is tapped
  final VoidCallback? onBackTap;

  /// Background color override
  final Color? backgroundColor;

  /// Foreground color override
  final Color? foregroundColor;

  /// Elevation override
  final double? elevation;

  /// Whether to center the title
  final bool centerTitle;

  /// Custom bottom widget (e.g., TabBar)
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showBackButton = false,
    this.showSearch = false,
    this.leading,
    this.actions,
    this.onSearchTap,
    this.onBackTap,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.centerTitle = false,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine leading widget
    Widget? leadingWidget;
    if (leading != null) {
      leadingWidget = leading;
    } else if (showBackButton) {
      leadingWidget = IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBackTap ?? () => Navigator.of(context).pop(),
        tooltip: 'Back',
        iconSize: 24,
      );
    }

    // Build actions list
    List<Widget> actionWidgets = [];
    if (showSearch) {
      actionWidgets.add(
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: onSearchTap,
          tooltip: 'Search',
          iconSize: 24,
        ),
      );
    }
    if (actions != null) {
      actionWidgets.addAll(actions!);
    }

    return AppBar(
      leading: leadingWidget,
      title: subtitle != null
          ? Column(
              crossAxisAlignment: centerTitle
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: foregroundColor ?? colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: (foregroundColor ?? colorScheme.onSurface)
                        .withValues(alpha: 0.7),
                  ),
                ),
              ],
            )
          : Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: foregroundColor ?? colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? colorScheme.surface,
      foregroundColor: foregroundColor ?? colorScheme.onSurface,
      elevation: elevation ?? 0,
      scrolledUnderElevation: 2,
      actions: actionWidgets.isNotEmpty ? actionWidgets : null,
      bottom: bottom,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: theme.brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
        statusBarBrightness: theme.brightness,
      ),
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}

/// A custom search app bar with animated search field
class CustomSearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  /// Callback when search query changes
  final ValueChanged<String>? onSearchChanged;

  /// Callback when search is submitted
  final ValueChanged<String>? onSearchSubmitted;

  /// Callback when search is cancelled
  final VoidCallback? onSearchCancelled;

  /// Initial search query
  final String? initialQuery;

  /// Hint text for search field
  final String hintText;

  /// Whether to auto-focus the search field
  final bool autoFocus;

  /// Background color override
  final Color? backgroundColor;

  const CustomSearchAppBar({
    super.key,
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.onSearchCancelled,
    this.initialQuery,
    this.hintText = 'Search documents...',
    this.autoFocus = true,
    this.backgroundColor,
  });

  @override
  State<CustomSearchAppBar> createState() => _CustomSearchAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomSearchAppBarState extends State<CustomSearchAppBar> {
  late TextEditingController _searchController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _focusNode = FocusNode();

    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleCancel() {
    _searchController.clear();
    _focusNode.unfocus();
    widget.onSearchCancelled?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppBar(
      backgroundColor: widget.backgroundColor ?? colorScheme.surface,
      elevation: 0,
      scrolledUnderElevation: 2,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _handleCancel,
        tooltip: 'Cancel',
      ),
      title: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        style: theme.textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: widget.hintText,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding: EdgeInsets.zero,
        ),
        textInputAction: TextInputAction.search,
        onChanged: widget.onSearchChanged,
        onSubmitted: widget.onSearchSubmitted,
      ),
      actions: [
        if (_searchController.text.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              widget.onSearchChanged?.call('');
            },
            tooltip: 'Clear',
          ),
      ],
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: theme.brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
        statusBarBrightness: theme.brightness,
      ),
    );
  }
}
