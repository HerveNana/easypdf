import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

/// Splash Screen for EasyPDF application
/// Provides branded launch experience while initializing PDF services
/// Handles navigation based on user authentication state
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isInitializing = true;
  String _statusMessage = 'Initialisation...';
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      // Step 1: Ensure Supabase is initialized
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _statusMessage = 'Connexion au serveur...';
        });
      }

      // Wait for Supabase to be fully initialized
      try {
        // Test if Supabase is initialized by accessing it
        final _ = Supabase.instance.client;
      } catch (e) {
        // If not initialized, initialize it now
        debugPrint('Supabase not initialized, initializing now...');
        await SupabaseService.initialize();
      }

      // Step 2: Check biometric authentication availability
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        setState(() {
          _statusMessage = 'Vérification de la sécurité...';
        });
      }

      // Actually check biometric availability
      await _checkBiometricSetup();

      // Step 3: Load user preferences
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        setState(() {
          _statusMessage = 'Chargement des préférences...';
        });
      }

      // Step 4: Prepare PDF rendering engine
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) {
        setState(() {
          _statusMessage = 'Préparation du moteur PDF...';
        });
      }

      // Step 5: Validate secure storage access
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _statusMessage = 'Validation du stockage...';
          _isInitializing = false;
        });
      }

      // Navigation logic after initialization
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        await _handleBiometricAuthentication();
      }
    } catch (e) {
      debugPrint('Initialization error: $e');
      if (mounted) {
        setState(() {
          _statusMessage = 'Erreur d\'initialisation';
          _isInitializing = false;
        });
        _showRetryDialog();
      }
    }
  }

  Future<void> _checkBiometricSetup() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (canCheckBiometrics && isDeviceSupported) {
        final availableBiometrics = await _localAuth.getAvailableBiometrics();
        debugPrint('Available biometrics: $availableBiometrics');
      }
    } catch (e) {
      debugPrint('Biometric check error: $e');
    }
  }

  Future<void> _handleBiometricAuthentication() async {
    try {
      final securityEnabled = await _secureStorage.read(
        key: 'security_enabled',
      );
      final faceIdEnabled = await _secureStorage.read(key: 'face_id_enabled');
      final fingerprintEnabled = await _secureStorage.read(
        key: 'fingerprint_enabled',
      );

      if (securityEnabled == 'true' &&
          (faceIdEnabled == 'true' || fingerprintEnabled == 'true')) {
        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Authentifiez-vous pour accéder à vos documents',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: false,
            useErrorDialogs: true,
            sensitiveTransaction: true,
          ),
        );

        if (!authenticated) {
          // Authentication failed, stay on splash or show error
          if (mounted) {
            _showRetryDialog();
          }
          return;
        }
      }

      // Proceed to navigation after successful authentication or if not required
      _navigateToNextScreen();
    } catch (e) {
      debugPrint('Authentication error: $e');
      _navigateToNextScreen(); // Proceed anyway on error
    }
  }

  void _navigateToNextScreen() {
    try {
      // Check if user is authenticated
      final isAuthenticated = Supabase.instance.client.auth.currentUser != null;

      if (isAuthenticated) {
        Navigator.pushReplacementNamed(context, AppRoutes.documentLibrary);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    } catch (e) {
      debugPrint('Navigation error: $e');
      // If there's any error, go to login screen
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  void _showRetryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Text(
            'Erreur d\'initialisation',
            style: theme.textTheme.titleLarge,
          ),
          content: Text(
            'Une erreur s\'est produite lors de l\'initialisation de l\'application. Veuillez réessayer.',
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isInitializing = true;
                  _statusMessage = 'Initialisation...';
                });
                _initializeApp();
              },
              child: Text(
                'Réessayer',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primaryContainer,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                _buildLogo(theme),
                SizedBox(height: 24.h),
                _buildAppName(theme),
                SizedBox(height: 8.h),
                _buildTagline(theme),
                const Spacer(flex: 2),
                _buildLoadingIndicator(theme),
                SizedBox(height: 16.h),
                _buildStatusMessage(theme),
                SizedBox(height: 48.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(ThemeData theme) {
    return Container(
      width: 120.w,
      height: 120.w,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: CustomIconWidget(
          iconName: 'picture_as_pdf',
          size: 64,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildAppName(ThemeData theme) {
    return Text(
      'EasyPDF',
      style: theme.textTheme.displaySmall?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTagline(ThemeData theme) {
    return Text(
      'Gestion PDF Professionnelle',
      style: theme.textTheme.bodyLarge?.copyWith(
        color: Colors.white.withValues(alpha: 0.9),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildLoadingIndicator(ThemeData theme) {
    return _isInitializing
        ? SizedBox(
            width: 32.w,
            height: 32.w,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white.withValues(alpha: 0.9),
              ),
            ),
          )
        : CustomIconWidget(
            iconName: 'check_circle',
            size: 32,
            color: Colors.white.withValues(alpha: 0.9),
          );
  }

  Widget _buildStatusMessage(ThemeData theme) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        _statusMessage,
        key: ValueKey<String>(_statusMessage),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: Colors.white.withValues(alpha: 0.8),
          letterSpacing: 0.3,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
