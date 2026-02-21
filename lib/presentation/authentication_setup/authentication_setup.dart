import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/biometric_option_widget.dart';
import './widgets/pin_setup_widget.dart';

/// Authentication Setup Screen
/// Enables users to configure biometric security for PDF document protection
/// Uses stack navigation, accessible from splash or settings
class AuthenticationSetup extends StatefulWidget {
  const AuthenticationSetup({super.key});

  @override
  State<AuthenticationSetup> createState() => _AuthenticationSetupState();
}

class _AuthenticationSetupState extends State<AuthenticationSetup> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _isFaceIdAvailable = false;
  bool _isFingerprintAvailable = false;
  bool _isFaceIdEnabled = false;
  bool _isFingerprintEnabled = false;
  bool _isPinSetupComplete = false;
  bool _isLoading = false;
  bool _showSuccess = false;
  String? _setupPin;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
    _loadSavedSettings();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();

      if (canCheckBiometrics && isDeviceSupported) {
        final List<BiometricType> availableBiometrics = await _localAuth
            .getAvailableBiometrics();

        setState(() {
          _isFaceIdAvailable = availableBiometrics.contains(BiometricType.face);
          _isFingerprintAvailable = availableBiometrics.contains(
            BiometricType.fingerprint,
          );
        });
      }
    } catch (e) {
      debugPrint('Error checking biometric availability: $e');
    }
  }

  Future<void> _loadSavedSettings() async {
    try {
      final faceIdEnabled = await _secureStorage.read(key: 'face_id_enabled');
      final fingerprintEnabled = await _secureStorage.read(
        key: 'fingerprint_enabled',
      );
      final savedPin = await _secureStorage.read(key: 'security_pin');

      setState(() {
        _isFaceIdEnabled = faceIdEnabled == 'true';
        _isFingerprintEnabled = fingerprintEnabled == 'true';
        _isPinSetupComplete = savedPin != null && savedPin.isNotEmpty;
        _setupPin = savedPin;
      });
    } catch (e) {
      debugPrint('Error loading saved settings: $e');
    }
  }

  Future<void> _toggleBiometric(String type, bool value) async {
    if (value) {
      final bool authenticated = await _authenticateBiometric(type);
      if (!authenticated) {
        _showErrorMessage('Authentification échouée. Veuillez réessayer.');
        return;
      }
    }

    HapticFeedback.mediumImpact();

    setState(() {
      if (type == 'face_id') {
        _isFaceIdEnabled = value;
      } else {
        _isFingerprintEnabled = value;
      }
    });

    await _secureStorage.write(key: '${type}_enabled', value: value.toString());

    if (value) {
      _showErrorMessage(
        type == 'face_id'
            ? 'Face ID activé avec succès'
            : 'Empreinte digitale activée avec succès',
      );
    }
  }

  Future<bool> _authenticateBiometric(String type) async {
    try {
      final bool authenticated = await _localAuth.authenticate(
        localizedReason: type == 'face_id'
            ? 'Authentifiez-vous avec Face ID pour activer la sécurité'
            : 'Authentifiez-vous avec l\'empreinte digitale pour activer la sécurité',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );
      return authenticated;
    } catch (e) {
      debugPrint('Error authenticating: $e');
      return false;
    }
  }

  void _handlePinSetup(String pin) {
    HapticFeedback.mediumImpact();
    setState(() {
      _setupPin = pin;
      _isPinSetupComplete = true;
    });
  }

  Future<void> _enableSecurity() async {
    if (!_isFaceIdEnabled && !_isFingerprintEnabled && !_isPinSetupComplete) {
      _showErrorMessage('Veuillez activer au moins une méthode de sécurité');
      return;
    }

    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 1500));

    if (_setupPin != null) {
      await _secureStorage.write(key: 'security_pin', value: _setupPin);
    }

    await _secureStorage.write(key: 'security_enabled', value: 'true');

    setState(() {
      _isLoading = false;
      _showSuccess = true;
    });

    await Future.delayed(const Duration(milliseconds: 2000));

    if (mounted) {
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushReplacementNamed('/document-library');
    }
  }

  void _skipForNow() {
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushReplacementNamed('/document-library');
  }

  void _goBack() {
    Navigator.of(context).pop();
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: _showSuccess ? _buildSuccessView(theme) : _buildSetupView(theme),
      ),
    );
  }

  Widget _buildSuccessView(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/success.json',
            width: 40.w,
            height: 40.w,
            repeat: false,
          ),
          SizedBox(height: 3.h),
          Text(
            'Sécurité activée !',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Vos documents sont maintenant protégés',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupView(ThemeData theme) {
    return Stack(
      children: [
        Positioned(
          top: 2.h,
          left: 2.w,
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
            onPressed: _goBack,
          ),
        ),
        SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme),
              SizedBox(height: 4.h),
              _buildSecurityIcon(theme),
              SizedBox(height: 4.h),
              _buildBenefitsSection(theme),
              SizedBox(height: 4.h),
              _buildBiometricOptions(theme),
              SizedBox(height: 4.h),
              PinSetupWidget(
                onPinSetup: _handlePinSetup,
                isPinSetupComplete: _isPinSetupComplete,
              ),
              SizedBox(height: 4.h),
              _buildActionButtons(theme),
              SizedBox(height: 2.h),
            ],
          ),
        ),
        if (_isLoading) _buildLoadingOverlay(theme),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        IconButton(
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: theme.colorScheme.onSurface,
            size: 24,
          ),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Retour',
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configuration de sécurité',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                'Protégez vos documents PDF',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityIcon(ThemeData theme) {
    return Center(
      child: Container(
        width: 30.w,
        height: 30.w,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: CustomIconWidget(
          iconName: 'shield',
          color: theme.colorScheme.onPrimary,
          size: 15.w,
        ),
      ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
    );
  }

  Widget _buildBenefitsSection(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pourquoi activer la sécurité ?',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          _buildBenefitItem(
            theme,
            'lock',
            'Protection des documents sensibles',
            'Vos PDF restent privés et sécurisés',
          ),
          SizedBox(height: 1.5.h),
          _buildBenefitItem(
            theme,
            'fingerprint',
            'Accès rapide et sécurisé',
            'Déverrouillez avec biométrie ou PIN',
          ),
          SizedBox(height: 1.5.h),
          _buildBenefitItem(
            theme,
            'verified_user',
            'Conformité professionnelle',
            'Respecte les normes de sécurité',
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(
    ThemeData theme,
    String iconName,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: CustomIconWidget(
            iconName: iconName,
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBiometricOptions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Méthodes biométriques',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 2.h),
        if (_isFaceIdAvailable)
          BiometricOptionWidget(
            iconName: 'face',
            title: 'Face ID',
            description: 'Déverrouillez avec reconnaissance faciale',
            isEnabled: _isFaceIdEnabled,
            onToggle: (value) => _toggleBiometric('face_id', value),
          ),
        if (_isFaceIdAvailable && _isFingerprintAvailable)
          SizedBox(height: 2.h),
        if (_isFingerprintAvailable)
          BiometricOptionWidget(
            iconName: 'fingerprint',
            title: 'Empreinte digitale',
            description: 'Déverrouillez avec votre empreinte',
            isEnabled: _isFingerprintEnabled,
            onToggle: (value) => _toggleBiometric('fingerprint', value),
          ),
        if (!_isFaceIdAvailable && !_isFingerprintAvailable)
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.error.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'info',
                  color: theme.colorScheme.error,
                  size: 24,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    'Aucune biométrie disponible sur cet appareil',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    final bool canEnableSecurity =
        _isFaceIdEnabled || _isFingerprintEnabled || _isPinSetupComplete;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 6.h,
          child: ElevatedButton(
            onPressed: canEnableSecurity ? _enableSecurity : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              disabledBackgroundColor: theme.colorScheme.outline.withValues(
                alpha: 0.2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Activer la sécurité',
              style: theme.textTheme.titleMedium?.copyWith(
                color: canEnableSecurity
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(height: 2.h),
        TextButton(
          onPressed: _skipForNow,
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurfaceVariant,
          ),
          child: Text(
            'Passer pour le moment',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surface.withValues(alpha: 0.9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 15.w,
              height: 15.w,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'Génération des clés de sécurité...',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
