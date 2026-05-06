import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_bottom_bar.dart';
import './document_library_initial_page.dart';

class DocumentLibrary extends StatefulWidget {
  const DocumentLibrary({super.key});

  @override
  DocumentLibraryState createState() => DocumentLibraryState();
}

class DocumentLibraryState extends State<DocumentLibrary> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  int currentIndex = 0;

  final List<String> routes = [
    '/document-library',
    '/document-library',
    '/document-import',
    '/settings',
  ];

  static const _railDestinations = [
    NavigationRailDestination(
      icon: Icon(Icons.folder_outlined),
      selectedIcon: Icon(Icons.folder),
      label: Text('Bibliothèque'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.history_outlined),
      selectedIcon: Icon(Icons.history),
      label: Text('Recent'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.add_circle_outline),
      selectedIcon: Icon(Icons.add_circle),
      label: Text('Import'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: Text('Settings'),
    ),
  ];

  Widget _buildNavigator() {
    return Navigator(
      key: navigatorKey,
      initialRoute: '/document-library',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/document-library':
          case '/':
            return MaterialPageRoute(
              builder: (context) => const DocumentLibraryInitialPage(),
              settings: settings,
            );
          default:
            if (AppRoutes.routes.containsKey(settings.name)) {
              return MaterialPageRoute(
                builder: AppRoutes.routes[settings.name]!,
                settings: settings,
              );
            }
            return null;
        }
      },
    );
  }

  void _onNavTap(int index) {
    if (!AppRoutes.routes.containsKey(routes[index])) return;
    if (currentIndex != index) {
      setState(() => currentIndex = index);
      navigatorKey.currentState?.pushReplacementNamed(routes[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= 768;
    final theme = Theme.of(context);

    if (isWideScreen) {
      // Desktop / tablet layout: NavigationRail on the left
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: _onNavTap,
              labelType: NavigationRailLabelType.all,
              backgroundColor: theme.colorScheme.surface,
              destinations: _railDestinations,
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: FloatingActionButton(
                      mini: true,
                      heroTag: 'teamFab',
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.teamManagement);
                      },
                      backgroundColor: theme.colorScheme.primary,
                      tooltip: 'Team Management',
                      child: Icon(
                        Icons.group,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: _buildNavigator()),
          ],
        ),
      );
    }

    // Mobile layout: BottomNavigationBar
    return Scaffold(
      body: _buildNavigator(),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: currentIndex,
        onTap: _onNavTap,
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'teamFab',
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.teamManagement);
        },
        backgroundColor: theme.colorScheme.primary,
        child: Icon(
          Icons.group,
          color: theme.colorScheme.onPrimary,
        ),
      ),
    );
  }
}
