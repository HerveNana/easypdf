import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/collaboration_service.dart';
import './widgets/destructive_action_widget.dart';
import './widgets/settings_item_widget.dart';
import './widgets/settings_section_widget.dart';
import './widgets/settings_switch_widget.dart';
import './widgets/user_profile_header_widget.dart';

/// Settings screen providing comprehensive app configuration
/// with mobile-optimized organization and accessibility features
class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final CollaborationService _collaborationService =
      CollaborationService.instance;
  String _userName = 'Loading...';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _collaborationService.getCurrentUserProfile();
      if (profile != null && mounted) {
        setState(() {
          _userName = profile.fullName;
          _userEmail = profile.email;
        });
      }
    } catch (e) {
      debugPrint('Failed to load user profile: $e');
    }
  }

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sign out failed: $e')));
      }
    }
  }

  // Security & Privacy settings
  bool _biometricEnabled = true;
  bool _encryptionEnabled = true;

  // Display & Reading settings
  String _themeMode = 'auto';
  bool _pageAnimations = true;
  double _zoomLevel = 1.0;

  // Cloud & Sync settings
  bool _cloudSyncEnabled = true;
  final String _syncStatus = 'Synchronisé';

  // Accessibility settings
  bool _highContrastMode = false;
  double _fontSize = 1.0;

  // Storage & Performance
  String _cacheSize = '245 MB';
  bool _performanceMode = false;

  void _showThemeDialog() {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(
          'Thème',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Clair'),
              value: 'light',
              groupValue: _themeMode,
              onChanged: (value) {
                setState(() => _themeMode = value!);
                Navigator.of(dialogContext).pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('Sombre'),
              value: 'dark',
              groupValue: _themeMode,
              onChanged: (value) {
                setState(() => _themeMode = value!);
                Navigator.of(dialogContext).pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('Automatique'),
              value: 'auto',
              groupValue: _themeMode,
              onChanged: (value) {
                setState(() => _themeMode = value!);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showZoomDialog() {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(
          'Niveau de zoom',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${(_zoomLevel * 100).toInt()}%',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Slider(
              value: _zoomLevel,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              label: '${(_zoomLevel * 100).toInt()}%',
              onChanged: (value) {
                setState(() => _zoomLevel = value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showFontSizeDialog() {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(
          'Taille de police',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _fontSize == 0.8
                  ? 'Petit'
                  : _fontSize == 1.0
                  ? 'Normal'
                  : _fontSize == 1.2
                  ? 'Grand'
                  : 'Très grand',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Slider(
              value: _fontSize,
              min: 0.8,
              max: 1.4,
              divisions: 3,
              label: _fontSize == 0.8
                  ? 'Petit'
                  : _fontSize == 1.0
                  ? 'Normal'
                  : _fontSize == 1.2
                  ? 'Grand'
                  : 'Très grand',
              onChanged: (value) {
                setState(() => _fontSize = value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(
          'Langue',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Français'),
              leading: const Text('🇫🇷'),
              trailing: CustomIconWidget(
                iconName: 'check',
                color: theme.colorScheme.primary,
                size: 20,
              ),
              onTap: () => Navigator.of(dialogContext).pop(),
            ),
            ListTile(
              title: const Text('English'),
              leading: const Text('🇬🇧'),
              onTap: () => Navigator.of(dialogContext).pop(),
            ),
            ListTile(
              title: const Text('Español'),
              leading: const Text('🇪🇸'),
              onTap: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        ),
      ),
    );
  }

  void _clearCache() {
    final theme = Theme.of(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Cache vidé avec succès'),
        backgroundColor: theme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
    setState(() => _cacheSize = '0 MB');
  }

  void _resetApp() {
    final theme = Theme.of(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Application réinitialisée'),
        backgroundColor: theme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _deleteAllData() {
    final theme = Theme.of(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Toutes les données ont été supprimées'),
        backgroundColor: theme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _exportSettings() {
    final theme = Theme.of(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Paramètres exportés avec succès'),
        backgroundColor: theme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Paramètres',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User Profile Header
            UserProfileHeaderWidget(),

            // Security & Privacy Section
            SettingsSectionWidget(
              title: 'SÉCURITÉ & CONFIDENTIALITÉ',
              children: [
                SettingsSwitchWidget(
                  iconName: 'fingerprint',
                  title: 'Authentification biométrique',
                  subtitle: 'Face ID / Touch ID',
                  value: _biometricEnabled,
                  onChanged: (value) =>
                      setState(() => _biometricEnabled = value),
                ),
                SettingsSwitchWidget(
                  iconName: 'lock',
                  title: 'Chiffrement local',
                  subtitle: 'Activé',
                  value: _encryptionEnabled,
                  onChanged: (value) =>
                      setState(() => _encryptionEnabled = value),
                ),
                SettingsItemWidget(
                  iconName: 'privacy_tip',
                  title: 'Politique de confidentialité',
                  onTap: () {},
                  showDivider: false,
                ),
              ],
            ),

            // Display & Reading Section
            SettingsSectionWidget(
              title: 'AFFICHAGE & LECTURE',
              children: [
                SettingsItemWidget(
                  iconName: 'brightness_6',
                  title: 'Thème',
                  subtitle: _themeMode == 'light'
                      ? 'Clair'
                      : _themeMode == 'dark'
                      ? 'Sombre'
                      : 'Automatique',
                  onTap: _showThemeDialog,
                ),
                SettingsSwitchWidget(
                  iconName: 'animation',
                  title: 'Animations de page',
                  value: _pageAnimations,
                  onChanged: (value) => setState(() => _pageAnimations = value),
                ),
                SettingsItemWidget(
                  iconName: 'zoom_in',
                  title: 'Niveau de zoom',
                  subtitle: '${(_zoomLevel * 100).toInt()}%',
                  onTap: _showZoomDialog,
                  showDivider: false,
                ),
              ],
            ),

            // Cloud & Sync Section
            SettingsSectionWidget(
              title: 'CLOUD & SYNCHRONISATION',
              children: [
                SettingsSwitchWidget(
                  iconName: 'cloud',
                  title: 'Synchronisation cloud',
                  subtitle: _syncStatus,
                  value: _cloudSyncEnabled,
                  onChanged: (value) =>
                      setState(() => _cloudSyncEnabled = value),
                ),
                SettingsItemWidget(
                  iconName: 'cloud_upload',
                  title: 'Services connectés',
                  subtitle: 'Google Drive, Dropbox',
                  onTap: () {},
                  showDivider: false,
                ),
              ],
            ),

            // Accessibility Section
            SettingsSectionWidget(
              title: 'ACCESSIBILITÉ',
              children: [
                SettingsSwitchWidget(
                  iconName: 'contrast',
                  title: 'Mode contraste élevé',
                  value: _highContrastMode,
                  onChanged: (value) =>
                      setState(() => _highContrastMode = value),
                ),
                SettingsItemWidget(
                  iconName: 'text_fields',
                  title: 'Taille de police',
                  subtitle: _fontSize == 0.8
                      ? 'Petit'
                      : _fontSize == 1.0
                      ? 'Normal'
                      : _fontSize == 1.2
                      ? 'Grand'
                      : 'Très grand',
                  onTap: _showFontSizeDialog,
                ),
                SettingsItemWidget(
                  iconName: 'accessibility',
                  title: 'VoiceOver / TalkBack',
                  subtitle: 'Paramètres système',
                  onTap: () {},
                  showDivider: false,
                ),
              ],
            ),

            // Language & Region Section
            SettingsSectionWidget(
              title: 'LANGUE & RÉGION',
              children: [
                SettingsItemWidget(
                  iconName: 'language',
                  title: 'Langue',
                  subtitle: 'Français',
                  onTap: _showLanguageDialog,
                ),
                SettingsItemWidget(
                  iconName: 'location_on',
                  title: 'Région',
                  subtitle: 'France (EUR)',
                  onTap: () {},
                  showDivider: false,
                ),
              ],
            ),

            // Storage & Performance Section
            SettingsSectionWidget(
              title: 'STOCKAGE & PERFORMANCE',
              children: [
                SettingsItemWidget(
                  iconName: 'storage',
                  title: 'Taille du cache',
                  subtitle: _cacheSize,
                  onTap: _clearCache,
                ),
                SettingsSwitchWidget(
                  iconName: 'speed',
                  title: 'Mode performance',
                  subtitle: 'Optimiser pour les grands PDF',
                  value: _performanceMode,
                  onChanged: (value) =>
                      setState(() => _performanceMode = value),
                ),
                SettingsItemWidget(
                  iconName: 'backup',
                  title: 'Exporter les paramètres',
                  onTap: _exportSettings,
                  showDivider: false,
                ),
              ],
            ),

            // Destructive Actions Section
            SettingsSectionWidget(
              title: 'ACTIONS CRITIQUES',
              children: [
                DestructiveActionWidget(
                  iconName: 'restart_alt',
                  title: 'Réinitialiser l\'application',
                  confirmTitle: 'Réinitialiser l\'application',
                  confirmMessage:
                      'Cette action réinitialisera tous les paramètres à leurs valeurs par défaut. Vos documents ne seront pas supprimés.',
                  onConfirm: _resetApp,
                ),
                const SizedBox(height: 1),
                DestructiveActionWidget(
                  iconName: 'delete_forever',
                  title: 'Supprimer toutes les données',
                  confirmTitle: 'Supprimer toutes les données',
                  confirmMessage:
                      'Cette action supprimera définitivement tous vos documents et paramètres. Cette action est irréversible.',
                  onConfirm: _deleteAllData,
                ),
              ],
            ),

            // Sign Out Button
            Padding(
              padding: EdgeInsets.all(4.w),
              child: DestructiveActionWidget(
                iconName: 'logout',
                title: 'Se déconnecter',
                confirmTitle: 'Déconnexion',
                confirmMessage: 'Êtes-vous sûr de vouloir vous déconnecter?',
                onConfirm: _signOut,
              ),
            ),

            // Footer with app info
            Container(
              margin: const EdgeInsets.only(top: 24, bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: 'picture_as_pdf',
                        color: theme.colorScheme.primary,
                        size: 32,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'EasyPDF',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version 1.0.0 (Build 100)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'Politique de confidentialité',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      Text(
                        ' • ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'Conditions d\'utilisation',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: 'verified_user',
                        color: theme.colorScheme.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Conforme RGPD',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
