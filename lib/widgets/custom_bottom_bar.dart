import 'package:flutter/material.dart';

/// A custom bottom navigation bar widget for the PDF management application.
/// Implements touch-optimized navigation with minimum 44pt touch targets.
///
/// This widget is parameterized and reusable - it does NOT contain hardcoded
/// navigation logic. The parent widget controls navigation through callbacks.
class CustomBottomBar extends StatelessWidget {
  /// The currently selected navigation index
  final int currentIndex;

  /// Callback function when a navigation item is tapped
  final Function(int) onTap;

  /// Optional background color override
  final Color? backgroundColor;

  /// Optional selected item color override
  final Color? selectedItemColor;

  /// Optional unselected item color override
  final Color? unselectedItemColor;

  /// Optional elevation override
  final double? elevation;

  const CustomBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: backgroundColor ?? colorScheme.surface,
          selectedItemColor: selectedItemColor ?? colorScheme.primary,
          unselectedItemColor:
              unselectedItemColor ??
              (theme.brightness == Brightness.light
                  ? const Color(0xFF6B7280)
                  : const Color(0xFF94A3B8)),
          elevation: elevation ?? 0,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: [
            // Library/Home - Primary workspace for document browsing
            BottomNavigationBarItem(
              icon: const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.folder_outlined, size: 24),
              ),
              activeIcon: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (selectedItemColor ?? colorScheme.primary)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.folder,
                    size: 24,
                    color: selectedItemColor ?? colorScheme.primary,
                  ),
                ),
              ),
              label: 'Bibliothèque',
              tooltip: 'Document Library',
            ),

            // Recent - Quick access to frequently used PDFs
            BottomNavigationBarItem(
              icon: const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.history_outlined, size: 24),
              ),
              activeIcon: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (selectedItemColor ?? colorScheme.primary)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.history,
                    size: 24,
                    color: selectedItemColor ?? colorScheme.primary,
                  ),
                ),
              ),
              label: 'Recent',
              tooltip: 'Recent Documents',
            ),

            // Import - Document capture and cloud integration
            BottomNavigationBarItem(
              icon: const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.add_circle_outline, size: 24),
              ),
              activeIcon: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (selectedItemColor ?? colorScheme.primary)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.add_circle,
                    size: 24,
                    color: selectedItemColor ?? colorScheme.primary,
                  ),
                ),
              ),
              label: 'Import',
              tooltip: 'Import Document',
            ),

            // Profile/Settings - Security configuration and customization
            BottomNavigationBarItem(
              icon: const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.settings_outlined, size: 24),
              ),
              activeIcon: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (selectedItemColor ?? colorScheme.primary)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.settings,
                    size: 24,
                    color: selectedItemColor ?? colorScheme.primary,
                  ),
                ),
              ),
              label: 'Settings',
              tooltip: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

/// Navigation item data model for CustomBottomBar
class BottomBarItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
  final String? tooltip;

  const BottomBarItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
    this.tooltip,
  });
}

/// Predefined navigation items matching the Mobile Navigation Hierarchy
class BottomBarItems {
  BottomBarItems._();

  static const List<BottomBarItem> items = [
    BottomBarItem(
      label: 'Library',
      icon: Icons.folder_outlined,
      activeIcon: Icons.folder,
      route: '/document-library',
      tooltip: 'Document Library',
    ),
    BottomBarItem(
      label: 'Recent',
      icon: Icons.history_outlined,
      activeIcon: Icons.history,
      route: '/document-library', // Recent view within library
      tooltip: 'Recent Documents',
    ),
    BottomBarItem(
      label: 'Import',
      icon: Icons.add_circle_outline,
      activeIcon: Icons.add_circle,
      route: '/document-import',
      tooltip: 'Import Document',
    ),
    BottomBarItem(
      label: 'Settings',
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      route: '/settings',
      tooltip: 'Settings',
    ),
  ];
}
