import 'dart:io' if (dart.library.io) 'dart:io';

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:sizer/sizer.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../services/collaboration_service.dart';
import './widgets/cloud_service_card_widget.dart';
import './widgets/import_option_card_widget.dart';
import './widgets/import_progress_sheet_widget.dart';

/// Document Import Screen
/// Facilitates seamless PDF acquisition from multiple sources with mobile-optimized
/// file selection and cloud integration
class DocumentImport extends StatefulWidget {
  const DocumentImport({super.key});

  @override
  State<DocumentImport> createState() => _DocumentImportState();
}

class _DocumentImportState extends State<DocumentImport> {
  bool _isImporting = false;
  bool _encryptionEnabled = false;
  List<Map<String, dynamic>> _importingFiles = [];
  List<CameraDescription>? _cameras;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _isGoogleDriveConnected = false;
  DateTime? _lastGoogleDriveSync;

  @override
  void initState() {
    super.initState();
    _initializeCameras();
    _checkCloudConnections();
    _initializeGoogleSignIn();
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      await _googleSignIn.initialize(serverClientId: null);
    } catch (e) {
      debugPrint('Error initializing Google Sign In: $e');
    }
  }

  Future<void> _checkCloudConnections() async {
    try {
      final googleConnected = await _secureStorage.read(
        key: 'google_drive_connected',
      );
      final lastSync = await _secureStorage.read(key: 'google_drive_last_sync');

      setState(() {
        _isGoogleDriveConnected = googleConnected == 'true';
        if (lastSync != null) {
          _lastGoogleDriveSync = DateTime.tryParse(lastSync);
        }
      });
    } catch (e) {
      debugPrint('Error checking cloud connections: $e');
    }
  }

  Future<void> _initializeCameras() async {
    try {
      _cameras = await availableCameras();
    } catch (e) {
      debugPrint('Error initializing cameras: $e');
    }
  }

  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Check Android version
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 33) {
        // Android 13+ (API 33+) - Request granular media permissions
        // These permissions show up in app settings under "Photos and videos"
        final photos = await Permission.photos.request();
        final videos = await Permission.videos.request();

        if (photos.isGranted || videos.isGranted) {
          return true;
        } else if (photos.isPermanentlyDenied || videos.isPermanentlyDenied) {
          _showOpenSettingsDialog();
          return false;
        }
        return false;
      } else if (sdkInt >= 30) {
        // Android 11-12 (API 30-32) - Use READ_EXTERNAL_STORAGE
        // This permission shows up in app settings under "Files and media"
        final status = await Permission.storage.request();

        if (status.isGranted) {
          return true;
        } else if (status.isPermanentlyDenied) {
          _showOpenSettingsDialog();
          return false;
        }
        return false;
      } else {
        // Android 10 and below - Use legacy storage permission
        final status = await Permission.storage.request();

        if (status.isGranted) {
          return true;
        } else if (status.isPermanentlyDenied) {
          _showOpenSettingsDialog();
          return false;
        }
        return false;
      }
    }
    return true;
  }

  void _showOpenSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission requise'),
        content: const Text(
          'L\'accès au stockage est nécessaire pour importer des documents. '
          'Veuillez activer la permission dans les paramètres de l\'application.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Ouvrir les paramètres'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeviceStorage() async {
    debugPrint('Device storage import triggered');
    final hasPermission = await _requestStoragePermission();
    if (!hasPermission) {
      debugPrint('Storage permission denied');
      _showPermissionDeniedDialog('Storage');
      return;
    }

    debugPrint('Storage permission granted, opening file picker');
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        debugPrint('Files selected: ${result.files.length}');
        if (result.files.length > 50) {
          _showErrorDialog('Maximum 50 files can be imported at once');
          return;
        }

        setState(() {
          _isImporting = true;
          _importingFiles = result.files.map((file) {
            return {
              'name': file.name,
              'size': file.size,
              'path': file.path,
              'progress': 0.0,
              'status': 'importing',
            };
          }).toList();
        });

        _showImportProgressSheet();
        await _processFileImport();
      } else {
        debugPrint('No files selected');
      }
    } catch (e) {
      debugPrint('File picker error: $e');
      _showErrorDialog('Failed to select files: ${e.toString()}');
    }
  }

  Future<void> _handleScanDocument() async {
    final hasPermission = await _requestCameraPermission();
    if (!hasPermission) {
      _showPermissionDeniedDialog('Camera');
      return;
    }

    if (_cameras == null || _cameras!.isEmpty) {
      _showErrorDialog('No camera available on this device');
      return;
    }

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => _DocumentScannerScreen(
          cameras: _cameras!,
          onDocumentScanned: (List<String> scannedPages) {
            setState(() {
              _isImporting = true;
              _importingFiles = scannedPages.asMap().entries.map((entry) {
                return {
                  'name': 'Scanned_Document_${entry.key + 1}.pdf',
                  'size': 0,
                  'path': entry.value,
                  'progress': 0.0,
                  'status': 'importing',
                };
              }).toList();
            });
            _showImportProgressSheet();
            _processFileImport();
          },
        ),
      ),
    );
  }

  Future<void> _handleCloudService(String serviceName) async {
    if (serviceName == 'Google Drive') {
      await _handleGoogleDriveConnection();
    } else {
      _showErrorDialog(
        'L\'intégration de $serviceName sera disponible dans une prochaine mise à jour',
      );
    }
  }

  Future<void> _handleGoogleDriveConnection() async {
    try {
      setState(() => _isImporting = true);

      await _googleSignIn.authenticate();

      await _secureStorage.write(key: 'google_drive_connected', value: 'true');
      await _secureStorage.write(
        key: 'google_drive_last_sync',
        value: DateTime.now().toIso8601String(),
      );

      setState(() {
        _isGoogleDriveConnected = true;
        _lastGoogleDriveSync = DateTime.now();
        _isImporting = false;
      });

      _showSuccessMessage('Google Drive connecté avec succès');
    } catch (e) {
      setState(() => _isImporting = false);
      _showErrorDialog('Erreur de connexion à Google Drive: ${e.toString()}');
    }
  }

  Future<void> _processFileImport() async {
    int successCount = 0;
    int failedCount = 0;

    try {
      // Get app documents directory
      final appDocDir = await getApplicationDocumentsDirectory();
      final documentsPath = '${appDocDir.path}/imported_documents';
      final documentsDir = Directory(documentsPath);

      // Create directory if it doesn't exist
      if (!await documentsDir.exists()) {
        await documentsDir.create(recursive: true);
      }

      for (int i = 0; i < _importingFiles.length; i++) {
        try {
          final fileData = _importingFiles[i];
          final sourcePath = fileData['path'] as String?;

          if (sourcePath == null || sourcePath.isEmpty) {
            setState(() {
              _importingFiles[i]['status'] = 'failed';
              _importingFiles[i]['progress'] = 0.0;
            });
            failedCount++;
            continue;
          }

          // Update progress: Starting
          setState(() {
            _importingFiles[i]['progress'] = 0.1;
          });

          // Copy file to app storage
          final sourceFile = File(sourcePath);
          if (!await sourceFile.exists()) {
            setState(() {
              _importingFiles[i]['status'] = 'failed';
              _importingFiles[i]['progress'] = 0.0;
            });
            failedCount++;
            continue;
          }

          // Update progress: Copying file
          setState(() {
            _importingFiles[i]['progress'] = 0.3;
          });

          final fileName = fileData['name'] as String;
          final destinationPath = '$documentsPath/$fileName';
          await sourceFile.copy(destinationPath);

          // Update progress: File copied
          setState(() {
            _importingFiles[i]['progress'] = 0.6;
          });

          // Get actual file size
          final fileSize = await sourceFile.length();
          final fileSizeStr = _formatFileSize(fileSize);

          // Update progress: Creating database record
          setState(() {
            _importingFiles[i]['progress'] = 0.8;
          });

          // Create document record in Supabase
          await CollaborationService.instance.createDocument(
            name: fileName,
            size: fileSizeStr,
            filePath: destinationPath,
            isEncrypted: _encryptionEnabled,
            tags: ['Imported'],
          );

          // Update progress: Complete
          setState(() {
            _importingFiles[i]['progress'] = 1.0;
            _importingFiles[i]['status'] = 'completed';
          });

          successCount++;
        } catch (e) {
          debugPrint('Failed to import file ${_importingFiles[i]['name']}: $e');
          setState(() {
            _importingFiles[i]['status'] = 'failed';
            _importingFiles[i]['progress'] = 0.0;
          });
          failedCount++;
        }
      }
    } catch (e) {
      debugPrint('Error during file import: $e');
    }

    await Future.delayed(const Duration(milliseconds: 500));
    _showSuccessDialog(successCount, failedCount);
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showImportProgressSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ImportProgressSheetWidget(
        files: _importingFiles,
        onCancel: (index) {
          setState(() {
            _importingFiles[index]['status'] = 'cancelled';
          });
        },
      ),
    );
  }

  void _showSuccessDialog(int successCount, int failedCount) {
    final theme = Theme.of(context);
    Navigator.of(context).pop();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(
                iconName: 'check_circle',
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
            SizedBox(width: 2.w),
            Text('Import Successful', style: theme.textTheme.titleLarge),
          ],
        ),
        content: Text(
          failedCount > 0
              ? '$successCount document(s) imported successfully\n$failedCount document(s) failed'
              : '$successCount document(s) imported successfully',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _isImporting = false;
                _importingFiles.clear();
              });
            },
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(
                context,
                rootNavigator: true,
              ).pushNamed('/document-library');
            },
            child: const Text('View in Library'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'error_outline',
              color: theme.colorScheme.error,
              size: 24,
            ),
            SizedBox(width: 2.w),
            const Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog(String permissionType) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'warning_amber',
              color: theme.colorScheme.error,
              size: 24,
            ),
            SizedBox(width: 2.w),
            const Text('Permission Required'),
          ],
        ),
        content: Text(
          '$permissionType permission is required to use this feature. Please enable it in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _toggleEncryption(bool value) async {
    if (value) {
      final canAuthenticate = await Permission.sensors.request().isGranted;
      if (!canAuthenticate) {
        _showErrorDialog('Biometric authentication is required for encryption');
        return;
      }
    }
    setState(() {
      _encryptionEnabled = value;
    });
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
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
          icon: CustomIconWidget(
            iconName: 'close',
            color: theme.colorScheme.onSurface,
            size: 24,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Import Documents',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose Import Source',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2.h),

              // Device Storage Import - Primary Option
              ImportOptionCardWidget(
                icon: 'folder',
                title: 'From Device Storage',
                description: 'Select PDF files from your device',
                onTap: _handleDeviceStorage,
              ),

              SizedBox(height: 2.h),

              // Scan Document Option
              ImportOptionCardWidget(
                icon: 'camera_alt',
                title: 'Scan Document',
                description: 'Capture documents using camera',
                onTap: _handleScanDocument,
              ),

              SizedBox(height: 3.h),

              Text(
                'Cloud Services',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2.h),

              CloudServiceCardWidget(
                serviceName: 'Google Drive',
                icon: 'cloud',
                isConnected: _isGoogleDriveConnected,
                lastSync: _lastGoogleDriveSync,
                onTap: () => _handleCloudService('Google Drive'),
              ),

              SizedBox(height: 1.5.h),

              CloudServiceCardWidget(
                serviceName: 'Dropbox',
                icon: 'cloud_upload',
                isConnected: false,
                lastSync: null,
                onTap: () => _handleCloudService('Dropbox'),
              ),

              SizedBox(height: 1.5.h),

              CloudServiceCardWidget(
                serviceName: 'iCloud',
                icon: 'cloud_done',
                isConnected: false,
                lastSync: null,
                onTap: () => _handleCloudService('iCloud'),
              ),

              SizedBox(height: 1.5.h),

              CloudServiceCardWidget(
                serviceName: 'OneDrive',
                icon: 'cloud_circle',
                isConnected: false,
                lastSync: null,
                onTap: () => _handleCloudService('OneDrive'),
              ),

              SizedBox(height: 3.h),

              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'security',
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          'Security',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 1.5.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Encrypt Sensitive Documents',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 0.5.h),
                              Text(
                                'Requires biometric authentication',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _encryptionEnabled,
                          onChanged: _toggleEncryption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 2.h),

              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'info_outline',
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        'Maximum 50 files can be imported at once',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentScannerScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final Function(List<String>) onDocumentScanned;

  const _DocumentScannerScreen({
    required this.cameras,
    required this.onDocumentScanned,
  });

  @override
  State<_DocumentScannerScreen> createState() => _DocumentScannerScreenState();
}

class _DocumentScannerScreenState extends State<_DocumentScannerScreen> {
  CameraController? _cameraController;
  final List<String> _scannedPages = [];
  bool _isInitialized = false;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final camera = widget.cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => widget.cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      try {
        await _cameraController!.setFocusMode(FocusMode.auto);
      } catch (e) {
        debugPrint('Focus mode not supported: $e');
      }

      try {
        await _cameraController!.setFlashMode(FlashMode.auto);
      } catch (e) {
        debugPrint('Flash mode not supported: $e');
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _captureDocument() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final XFile photo = await _cameraController!.takePicture();
      _scannedPages.add(photo.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Page ${_scannedPages.length} captured'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error capturing photo: $e');
    } finally {
      setState(() {
        _isCapturing = false;
      });
    }
  }

  void _finishScanning() {
    if (_scannedPages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture at least one page')),
      );
      return;
    }

    Navigator.of(context).pop();
    widget.onDocumentScanned(_scannedPages);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: _isInitialized && _cameraController != null
          ? Stack(
              children: [
                Positioned.fill(child: CameraPreview(_cameraController!)),

                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          Text(
                            '${_scannedPages.length} page(s)',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: _scannedPages.isNotEmpty
                                ? _finishScanning
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 3.h),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Position document within frame',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          GestureDetector(
                            onTap: _captureDocument,
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isCapturing
                                    ? Colors.grey
                                    : Colors.white,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                              ),
                              child: _isCapturing
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            ),
    );
  }
}
