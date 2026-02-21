import 'package:flutter/material.dart';
import '../presentation/settings/settings.dart';
import '../presentation/annotation_tools/annotation_tools.dart';
import '../presentation/document_editor/document_editor.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/pdf_viewer/pdf_viewer.dart';
import '../presentation/document_import/document_import.dart';
import '../presentation/authentication_setup/authentication_setup.dart';
import '../presentation/document_library/document_library.dart';
import '../presentation/share_document/share_document_screen.dart';
import '../presentation/team_management/team_management_screen.dart';
import '../presentation/authentication/login_screen.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String settings = '/settings';
  static const String annotationTools = '/annotation-tools';
  static const String documentEditor = '/document-editor';
  static const String splash = '/splash-screen';
  static const String pdfViewer = '/pdf-viewer';
  static const String documentImport = '/document-import';
  static const String authenticationSetup = '/authentication-setup';
  static const String documentLibrary = '/document-library';
  static const String shareDocument = '/share-document';
  static const String teamManagement = '/team-management';
  static const String login = '/login';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    settings: (context) => const Settings(),
    annotationTools: (context) => const AnnotationTools(),
    documentEditor: (context) => const DocumentEditor(),
    splash: (context) => const SplashScreen(),
    pdfViewer: (context) => const PdfViewer(),
    documentImport: (context) => const DocumentImport(),
    authenticationSetup: (context) => const AuthenticationSetup(),
    documentLibrary: (context) => const DocumentLibrary(),
    shareDocument: (context) => const ShareDocumentScreen(),
    teamManagement: (context) => const TeamManagementScreen(),
    login: (context) => const LoginScreen(),
    // TODO: Add your other routes here
  };
}
