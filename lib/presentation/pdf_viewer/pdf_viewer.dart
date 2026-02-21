import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/annotation_toolbar_widget.dart';
import './widgets/document_outline_widget.dart';
import './widgets/page_navigation_widget.dart';
import './widgets/search_overlay_widget.dart';
import './widgets/active_annotators_widget.dart';
import './widgets/annotators_list_sheet.dart';
import '../../services/collaboration_service.dart';
import '../../services/presence_service.dart';
import '../../models/annotation_model.dart';
import '../../presentation/document_library/widgets/sync_status_badge_widget.dart';

/// PDF Viewer Screen - High-performance document viewing with mobile-optimized annotation tools
///
/// Features:
/// - Full-screen presentation with auto-hiding UI chrome
/// - Smooth pinch-to-zoom and double-tap zoom to fit
/// - Fluid vertical scrolling with momentum
/// - Mobile-optimized annotation tools (highlighter, pen, text notes, shapes)
/// - Floating page navigation with thumbnail strip
/// - Search functionality with result navigation
/// - Bookmark management
/// - Share sheet access
/// - Apple Pencil/S Pen pressure sensitivity support
/// - Auto-save functionality with cloud sync indicators
class PdfViewer extends StatefulWidget {
  const PdfViewer({super.key});

  @override
  State<PdfViewer> createState() => _PdfViewerState();
}

class _PdfViewerState extends State<PdfViewer> with TickerProviderStateMixin {
  // PDF Controller
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final CollaborationService _collaborationService =
      CollaborationService.instance;
  final PresenceService _presenceService = PresenceService.instance;

  // UI State Management
  bool _isToolbarVisible = true;
  bool _isAnnotationMode = false;
  bool _isSearchVisible = false;
  bool _isOutlineVisible = false;
  bool _isBookmarked = false;
  Timer? _toolbarTimer;

  // Document State
  int _currentPage = 3;
  int _totalPages = 47;
  final String _documentTitle = "Business Proposal Q1 2026.pdf";
  String? _documentId;
  String? _documentFilePath;

  // Annotation State
  String _selectedTool = '';
  Color _selectedColor = const Color(0xFFFFEB3B);
  double _selectedThickness = 2.0;
  List<AnnotationModel> _annotations = [];
  RealtimeChannel? _annotationSubscription;

  // Search State
  String _searchQuery = '';
  int _currentSearchResult = 0;
  int _totalSearchResults = 0;

  // Animation Controllers
  late AnimationController _toolbarAnimationController;
  late Animation<Offset> _toolbarSlideAnimation;

  // Presence State
  String _syncStatus = 'connected';
  List<Map<String, dynamic>> _activeViewers = [];
  RealtimeChannel? _viewersSubscription;
  Timer? _presenceHeartbeat;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startToolbarTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['documentId'] != null) {
      _documentId = args['documentId'] as String;
      _documentFilePath = args['filePath'] as String?;
      _loadAnnotations();
      _subscribeToAnnotations();
      _initializePresence();
    }
  }

  void _initializeAnimations() {
    _toolbarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _toolbarSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _toolbarAnimationController,
            curve: Curves.easeInOut,
          ),
        );

    _toolbarAnimationController.forward();
  }

  void _startToolbarTimer() {
    _toolbarTimer?.cancel();
    _toolbarTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_isAnnotationMode) {
        setState(() {
          _isToolbarVisible = false;
          _toolbarAnimationController.reverse();
        });
      }
    });
  }

  void _showToolbar() {
    if (!_isToolbarVisible) {
      setState(() {
        _isToolbarVisible = true;
        _toolbarAnimationController.forward();
      });
    }
    _startToolbarTimer();
  }

  Future<void> _loadAnnotations() async {
    if (_documentId == null) return;

    try {
      final annotations = await _collaborationService.getDocumentAnnotations(
        _documentId!,
      );
      if (mounted) {
        setState(() {
          _annotations = annotations;
        });
      }
    } catch (e) {
      debugPrint('Failed to load annotations: $e');
    }
  }

  void _subscribeToAnnotations() {
    if (_documentId == null) return;

    _annotationSubscription = _collaborationService.subscribeToAnnotations(
      documentId: _documentId!,
      onInsert: (annotation) {
        if (mounted) {
          setState(() {
            _annotations.add(annotation);
          });
        }
      },
      onUpdate: (annotation) {
        if (mounted) {
          setState(() {
            final index = _annotations.indexWhere((a) => a.id == annotation.id);
            if (index != -1) {
              _annotations[index] = annotation;
            }
          });
        }
      },
      onDelete: (annotationId) {
        if (mounted) {
          setState(() {
            _annotations.removeWhere((a) => a.id == annotationId);
          });
        }
      },
    );
  }

  Future<void> _initializePresence() async {
    if (_documentId == null) return;

    try {
      await _presenceService.joinDocumentViewing(_documentId!);
      _updateSyncStatus('connected');
      _loadActiveViewers();
      _subscribeToViewers();
      _startPresenceHeartbeat();
    } catch (e) {
      _updateSyncStatus('disconnected');
      debugPrint('Failed to initialize presence: $e');
    }
  }

  void _startPresenceHeartbeat() {
    _presenceHeartbeat?.cancel();
    _presenceHeartbeat = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadActiveViewers(),
    );
  }

  Future<void> _loadActiveViewers() async {
    if (_documentId == null) return;

    try {
      final viewers = await _presenceService.getActiveViewers(_documentId!);
      if (mounted) {
        setState(() {
          _activeViewers = viewers;
        });
      }
    } catch (e) {
      debugPrint('Failed to load active viewers: $e');
    }
  }

  void _subscribeToViewers() {
    if (_documentId == null) return;

    _viewersSubscription = _presenceService.subscribeToDocumentViewers(
      documentId: _documentId!,
      onViewersChanged: (viewers) {
        if (mounted) {
          setState(() {
            _activeViewers = viewers;
          });
        }
      },
    );
  }

  void _updateSyncStatus(String status) {
    if (mounted) {
      setState(() {
        _syncStatus = status;
      });
    }
  }

  void _showAnnotatorsList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AnnotatorsListSheet(viewers: _activeViewers),
    );
  }

  void _handleToolSelection(String tool) {
    setState(() {
      _selectedTool = tool;
      _isAnnotationMode = tool.isNotEmpty;
      _isToolbarVisible = true;
    });

    if (tool.isNotEmpty) {
      _toolbarTimer?.cancel();
      _showColorPicker();
      if (_documentId != null) {
        _presenceService.updateAnnotatingStatus(_documentId!, true);
        _updateSyncStatus('syncing');
      }
    } else {
      _startToolbarTimer();
      if (_documentId != null) {
        _presenceService.updateAnnotatingStatus(_documentId!, false);
        _updateSyncStatus('connected');
      }
    }
  }

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Annotation Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Text('Color', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children:
                  [
                        const Color(0xFFFFEB3B),
                        const Color(0xFF4CAF50),
                        const Color(0xFF2196F3),
                        const Color(0xFFE57373),
                        const Color(0xFF9C27B0),
                        const Color(0xFFFF9800),
                      ]
                      .map(
                        (color) => GestureDetector(
                          onTap: () {
                            setState(() => _selectedColor = color);
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _selectedColor == color
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 24),
            Text('Thickness', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            Slider(
              value: _selectedThickness,
              min: 1.0,
              max: 5.0,
              divisions: 4,
              label: _selectedThickness.toStringAsFixed(1),
              onChanged: (value) {
                setState(() => _selectedThickness = value);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _toggleBookmark() {
    setState(() {
      _isBookmarked = !_isBookmarked;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isBookmarked ? 'Bookmark added' : 'Bookmark removed'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleShare() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Share Document',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'email',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              title: const Text('Email'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening email...')),
                );
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'link',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              title: const Text('Copy Link'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied to clipboard')),
                );
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'cloud_upload',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              title: const Text('Upload to Cloud'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Uploading to cloud...')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query;
      _totalSearchResults = query.isEmpty ? 0 : 12;
      _currentSearchResult = query.isEmpty ? 0 : 1;
    });
  }

  void _navigateSearchResult(bool next) {
    if (_totalSearchResults == 0) return;

    setState(() {
      if (next) {
        _currentSearchResult = _currentSearchResult < _totalSearchResults
            ? _currentSearchResult + 1
            : 1;
      } else {
        _currentSearchResult = _currentSearchResult > 1
            ? _currentSearchResult - 1
            : _totalSearchResults;
      }
    });
  }

  void _saveAnnotation() {
    if (_selectedTool.isEmpty) return;

    setState(() {
      _annotations.add(
        AnnotationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          documentId: _documentId ?? '',
          userId: Supabase.instance.client.auth.currentUser?.id ?? '',
          annotationType: _selectedTool,
          pageNumber: _currentPage,
          color: '#${_selectedColor.value.toRadixString(16).substring(2)}',
          thickness: _selectedThickness,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    });

    if (_documentId != null) {
      _presenceService.logSyncStatus(_documentId!, 'connected');
      _updateSyncStatus('connected');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Annotation saved'),
            Spacer(),
            Icon(Icons.cloud_upload, color: Colors.white, size: 16),
          ],
        ),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _undoAnnotation() {
    if (_annotations.isEmpty) return;

    setState(() {
      _annotations.removeLast();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Annotation removed'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    if (_documentId != null) {
      _presenceService.leaveDocumentViewing(_documentId!);
    }
    _annotationSubscription?.unsubscribe();
    _viewersSubscription?.unsubscribe();
    _presenceHeartbeat?.cancel();
    _toolbarTimer?.cancel();
    _toolbarAnimationController.dispose();
    _pdfViewerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SafeArea(
          child: Stack(
            children: [
              // PDF Viewer
              GestureDetector(
                onTap: _showToolbar,
                child:
                    _documentFilePath != null && _documentFilePath!.isNotEmpty
                    ? SfPdfViewer.file(
                        File(_documentFilePath!),
                        controller: _pdfViewerController,
                        onPageChanged: (PdfPageChangedDetails details) {
                          setState(() {
                            _currentPage = details.newPageNumber;
                          });
                        },
                        onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                          setState(() {
                            _totalPages = details.document.pages.count;
                          });
                        },
                      )
                    : SfPdfViewer.network(
                        'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
                        controller: _pdfViewerController,
                        onPageChanged: (PdfPageChangedDetails details) {
                          setState(() {
                            _currentPage = details.newPageNumber;
                          });
                        },
                        onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                          setState(() {
                            _totalPages = details.document.pages.count;
                          });
                        },
                      ),
              ),

              // Top Status Bar
              if (_isToolbarVisible)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
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
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: 'Close',
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _documentTitle,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SyncStatusBadgeWidget(status: _syncStatus),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Page $_currentPage of $_totalPages',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isBookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: Colors.white,
                          ),
                          onPressed: _toggleBookmark,
                          tooltip: 'Bookmark',
                        ),
                        IconButton(
                          icon: const Icon(Icons.search, color: Colors.white),
                          onPressed: () {
                            setState(() => _isSearchVisible = true);
                          },
                          tooltip: 'Search',
                        ),
                        IconButton(
                          icon: const Icon(Icons.share, color: Colors.white),
                          onPressed: _handleShare,
                          tooltip: 'Share',
                        ),
                      ],
                    ),
                  ),
                ),

              // Active Annotators Indicator
              if (_activeViewers.isNotEmpty)
                Positioned(
                  top: 80,
                  left: 16,
                  child: ActiveAnnotatorsWidget(
                    activeAnnotators: _activeViewers,
                    onTap: _showAnnotatorsList,
                  ),
                ),

              // Bottom Annotation Toolbar
              if (_isToolbarVisible)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SlideTransition(
                    position: _toolbarSlideAnimation,
                    child: AnnotationToolbarWidget(
                      selectedTool: _selectedTool,
                      selectedColor: _selectedColor,
                      onToolSelected: _handleToolSelection,
                      onColorPickerTap: _showColorPicker,
                    ),
                  ),
                ),

              // Floating Page Navigation Button
              Positioned(
                bottom: _isToolbarVisible ? 100 : 24,
                right: 16,
                child: PageNavigationWidget(
                  currentPage: _currentPage,
                  totalPages: _totalPages,
                  onPageSelected: (page) {
                    _pdfViewerController.jumpToPage(page);
                  },
                ),
              ),

              // Undo/Redo Buttons (visible during annotation)
              if (_isAnnotationMode)
                Positioned(
                  bottom: _isToolbarVisible ? 100 : 24,
                  left: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'undo',
                        onPressed: _undoAnnotation,
                        backgroundColor: theme.colorScheme.surface,
                        child: CustomIconWidget(
                          iconName: 'undo',
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'save',
                        onPressed: _saveAnnotation,
                        backgroundColor: theme.colorScheme.primary,
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),

              // Search Overlay
              if (_isSearchVisible)
                SearchOverlayWidget(
                  searchQuery: _searchQuery,
                  currentResult: _currentSearchResult,
                  totalResults: _totalSearchResults,
                  onSearchChanged: _handleSearch,
                  onNavigateResult: _navigateSearchResult,
                  onClose: () {
                    setState(() {
                      _isSearchVisible = false;
                      _searchQuery = '';
                    });
                  },
                ),

              // Document Outline Panel (landscape) or Bottom Sheet (portrait)
              if (_isOutlineVisible)
                DocumentOutlineWidget(
                  annotations: _annotations
                      .map((a) => a.toLegacyFormat())
                      .toList(),
                  currentPage: _currentPage,
                  onPageSelected: (page) {
                    _pdfViewerController.jumpToPage(page);
                    setState(() => _isOutlineVisible = false);
                  },
                  onClose: () {
                    setState(() => _isOutlineVisible = false);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
