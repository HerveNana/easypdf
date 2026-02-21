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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Navigator(
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
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (!AppRoutes.routes.containsKey(routes[index])) {
            return;
          }
          if (currentIndex != index) {
            setState(() => currentIndex = index);
            navigatorKey.currentState?.pushReplacementNamed(routes[index]);
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.teamManagement);
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(
          Icons.group,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }
}
