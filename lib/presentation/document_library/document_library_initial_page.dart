import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../models/document_model.dart';
import '../../services/collaboration_service.dart';
import '../../services/presence_service.dart';
import './widgets/document_grid_item_widget.dart';
import './widgets/empty_state_widget.dart';
import './widgets/filter_chip_widget.dart';
import './widgets/presence_indicator_widget.dart';
import './widgets/sync_status_badge_widget.dart';

class DocumentLibraryInitialPage extends StatefulWidget {
  const DocumentLibraryInitialPage({super.key});

  @override
  State<DocumentLibraryInitialPage> createState() =>
      _DocumentLibraryInitialPageState();
}

class _DocumentLibraryInitialPageState extends State<DocumentLibraryInitialPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final CollaborationService _collaborationService =
      CollaborationService.instance;
  final PresenceService _presenceService = PresenceService.instance;
  bool _isGridView = true;
  bool _isSelectionMode = false;
  final Set<int> _selectedDocuments = {};
  bool _isLoadingDocuments = true;
  List<DocumentModel> _supabaseDocuments = [];
  String _syncStatus = 'connected';
  final Map<String, List<Map<String, dynamic>>> _documentViewers = {};
  RealtimeChannel? _presenceChannel;

  List<Map<String, dynamic>> _documents = [
    {
      "id": 1,
      "name": "Rapport_Annuel_2025.pdf",
      "size": "2.4 MB",
      "modifiedDate": DateTime(2026, 1, 25, 14, 30),
      "thumbnail":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1712339cd-1765570178329.png",
      "semanticLabel":
          "Document thumbnail showing a professional business report cover with blue and white design",
      "isFavorite": true,
      "isEncrypted": true,
      "tags": ["Rapport", "2025"],
    },
    {
      "id": 2,
      "name": "Contrat_Client_Dupont.pdf",
      "size": "1.8 MB",
      "modifiedDate": DateTime(2026, 1, 24, 10, 15),
      "thumbnail":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1504053bf-1764783239720.png",
      "semanticLabel":
          "Legal contract document with formal text layout and signature lines",
      "isFavorite": false,
      "isEncrypted": true,
      "tags": ["Contrat", "Client"],
    },
    {
      "id": 3,
      "name": "Facture_Janvier_2026.pdf",
      "size": "856 KB",
      "modifiedDate": DateTime(2026, 1, 23, 16, 45),
      "thumbnail":
          "https://images.unsplash.com/photo-1507362569319-ce3cce2b6e32",
      "semanticLabel":
          "Invoice document with itemized list and payment details",
      "isFavorite": false,
      "isEncrypted": false,
      "tags": ["Facture", "2026"],
    },
    {
      "id": 4,
      "name": "Présentation_Projet_Alpha.pdf",
      "size": "5.2 MB",
      "modifiedDate": DateTime(2026, 1, 22, 9, 20),
      "thumbnail":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1ec5bbd4c-1764661313208.png",
      "semanticLabel":
          "Business presentation slides with charts and graphs on white background",
      "isFavorite": true,
      "isEncrypted": false,
      "tags": ["Présentation", "Projet"],
    },
    {
      "id": 5,
      "name": "Guide_Utilisateur_v3.pdf",
      "size": "3.1 MB",
      "modifiedDate": DateTime(2026, 1, 21, 13, 10),
      "thumbnail":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1281e1a53-1765534081304.png",
      "semanticLabel":
          "User manual document with step-by-step instructions and screenshots",
      "isFavorite": false,
      "isEncrypted": false,
      "tags": ["Guide", "Documentation"],
    },
    {
      "id": 6,
      "name": "Devis_Travaux_Maison.pdf",
      "size": "1.2 MB",
      "modifiedDate": DateTime(2026, 1, 20, 11, 30),
      "thumbnail":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1c2ceb99a-1767390944633.png",
      "semanticLabel":
          "Construction estimate document with cost breakdown and timeline",
      "isFavorite": false,
      "isEncrypted": true,
      "tags": ["Devis", "Travaux"],
    },
  ];

  final List<Map<String, String>> _activeFilters = [
    {"label": "Cette semaine", "count": "12"},
    {"label": "PDF", "count": "45"},
    {"label": "Chiffrés", "count": "8"},
  ];

  @override
  void initState() {
    super.initState();
    _loadDocumentsFromSupabase();
    _initializePresence();
  }


  Future<void> _initializePresence() async {
    try {
      await _presenceService.startPresenceTracking();
      _updateSyncStatus('connected');
      _subscribeToPresenceChanges();
    } catch (e) {
      _updateSyncStatus('disconnected');
    }
  }

  void _subscribeToPresenceChanges() {
    _presenceChannel = _presenceService.subscribeToPresence(
      onPresenceChanged: (presence) {
        final documentId = presence['current_document_id'] as String?;
        if (documentId != null) {
          _loadDocumentViewers(documentId);
        }
      },
    );
  }

  Future<void> _loadDocumentViewers(String documentId) async {
    try {
      final viewers = await _presenceService.getActiveViewers(documentId);
      if (mounted) {
        setState(() {
          _documentViewers[documentId] = viewers;
        });
      }
    } catch (e) {
      debugPrint('Failed to load document viewers: $e');
    }
  }

  void _updateSyncStatus(String status) {
    if (mounted) {
      setState(() {
        _syncStatus = status;
      });
    }
  }

  Future<void> _loadDocumentsFromSupabase() async {
    try {
      final documents = await _collaborationService.getAllDocuments();
      if (mounted) {
        setState(() {
          _supabaseDocuments = documents;
          _isLoadingDocuments = false;
          // Convert Supabase documents to legacy format
          final supabaseLegacyDocs = documents
              .map((doc) => doc.toLegacyFormat())
              .toList();
          // Replace _documents with Supabase documents + hardcoded documents
          // This prevents duplicates on reload
          _documents = [
            ...supabaseLegacyDocs,
            {
              "id": 1,
              "name": "Rapport_Annuel_2025.pdf",
              "size": "2.4 MB",
              "modifiedDate": DateTime(2026, 1, 25, 14, 30),
              "thumbnail":
                  "https://img.rocket.new/generatedImages/rocket_gen_img_1712339cd-1765570178329.png",
              "semanticLabel":
                  "Document thumbnail showing a professional business report cover with blue and white design",
              "isFavorite": true,
              "isEncrypted": true,
              "tags": ["Rapport", "2025"],
            },
            {
              "id": 2,
              "name": "Contrat_Client_Dupont.pdf",
              "size": "1.8 MB",
              "modifiedDate": DateTime(2026, 1, 24, 10, 15),
              "thumbnail":
                  "https://img.rocket.new/generatedImages/rocket_gen_img_1504053bf-1764783239720.png",
              "semanticLabel":
                  "Legal contract document with formal text layout and signature lines",
              "isFavorite": false,
              "isEncrypted": true,
              "tags": ["Contrat", "Client"],
            },
            {
              "id": 3,
              "name": "Facture_Janvier_2026.pdf",
              "size": "856 KB",
              "modifiedDate": DateTime(2026, 1, 23, 16, 45),
              "thumbnail":
                  "https://images.unsplash.com/photo-1507362569319-ce3cce2b6e32",
              "semanticLabel":
                  "Invoice document with itemized list and payment details",
              "isFavorite": false,
              "isEncrypted": false,
              "tags": ["Facture", "2026"],
            },
            {
              "id": 4,
              "name": "Présentation_Projet_Alpha.pdf",
              "size": "5.2 MB",
              "modifiedDate": DateTime(2026, 1, 22, 9, 20),
              "thumbnail":
                  "https://img.rocket.new/generatedImages/rocket_gen_img_1ec5bbd4c-1764661313208.png",
              "semanticLabel":
                  "Business presentation slides with charts and graphs on white background",
              "isFavorite": true,
              "isEncrypted": false,
              "tags": ["Présentation", "Projet"],
            },
            {
              "id": 5,
              "name": "Guide_Utilisateur_v3.pdf",
              "size": "3.1 MB",
              "modifiedDate": DateTime(2026, 1, 21, 13, 10),
              "thumbnail":
                  "https://img.rocket.new/generatedImages/rocket_gen_img_1281e1a53-1765534081304.png",
              "semanticLabel":
                  "User manual document with step-by-step instructions and screenshots",
              "isFavorite": false,
              "isEncrypted": false,
              "tags": ["Guide", "Documentation"],
            },
            {
              "id": 6,
              "name": "Devis_Travaux_Maison.pdf",
              "size": "1.2 MB",
              "modifiedDate": DateTime(2026, 1, 20, 11, 30),
              "thumbnail":
                  "https://img.rocket.new/generatedImages/rocket_gen_img_1c2ceb99a-1767390944633.png",
              "semanticLabel":
                  "Construction estimate document with cost breakdown and timeline",
              "isFavorite": false,
              "isEncrypted": true,
              "tags": ["Devis", "Travaux"],
            },
          ];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDocuments = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _presenceChannel?.unsubscribe();
    super.dispose();
  }

  void _toggleView() {
    setState(() {
      _isGridView = !_isGridView;
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedDocuments.clear();
      }
    });
  }

  void _toggleDocumentSelection(int id) {
    setState(() {
      if (_selectedDocuments.contains(id)) {
        _selectedDocuments.remove(id);
      } else {
        _selectedDocuments.add(id);
      }
    });
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Trier par', style: theme.textTheme.titleLarge),
              SizedBox(height: 2.h),
              _buildSortOption('Nom', Icons.sort_by_alpha),
              _buildSortOption('Date de modification', Icons.access_time),
              _buildSortOption('Taille', Icons.storage),
              SizedBox(height: 1.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String label, IconData icon) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CustomIconWidget(
        iconName: icon.codePoint.toRadixString(16),
        size: 24,
        color: theme.colorScheme.onSurface,
      ),
      title: Text(label, style: theme.textTheme.bodyLarge),
      onTap: () {
        Navigator.pop(context);
      },
    );
  }

  void _showDocumentOptions(Map<String, dynamic> document) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CustomIconWidget(
                  iconName: Icons.open_in_new.codePoint.toRadixString(16),
                  size: 20.sp,
                  color: theme.colorScheme.onSurface,
                ),
                title: Text('Ouvrir', style: theme.textTheme.bodyLarge),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    AppRoutes.pdfViewer,
                    arguments: {'documentId': document['id']},
                  );
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: Icons.share.codePoint.toRadixString(16),
                  size: 20.sp,
                  color: theme.colorScheme.onSurface,
                ),
                title: Text('Partager', style: theme.textTheme.bodyLarge),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    AppRoutes.shareDocument,
                    arguments: {
                      'documentId': document['id'],
                      'documentName': document['name'],
                    },
                  );
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: Icons.folder_outlined.codePoint.toRadixString(16),
                  size: 20.sp,
                  color: theme.colorScheme.onSurface,
                ),
                title: Text(
                  'Déplacer vers dossier',
                  style: theme.textTheme.bodyLarge,
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: Icons.delete_outline.codePoint.toRadixString(16),
                  size: 20.sp,
                  color: theme.colorScheme.error,
                ),
                title: Text(
                  'Supprimer',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              SizedBox(height: 1.h),
            ],
          ),
        );
      },
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
        title: Row(
          children: [
            Text(
              'Bibliothèque',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 2.w),
            SyncStatusBadgeWidget(status: _syncStatus),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            color: theme.colorScheme.surface,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 6.h,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.outline,
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Rechercher des documents...',
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        prefixIcon: Padding(
                          padding: EdgeInsets.all(1.5.w),
                          child: CustomIconWidget(
                            iconName: 'e567',
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 3.w,
                          vertical: 1.5.h,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      builder: (context) {
                        final theme = Theme.of(context);
                        return Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 2.h,
                            horizontal: 4.w,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Filtrer par',
                                style: theme.textTheme.titleLarge,
                              ),
                              SizedBox(height: 2.h),
                              ListTile(
                                leading: Icon(Icons.calendar_today),
                                title: Text('Date'),
                                onTap: () => Navigator.pop(context),
                              ),
                              ListTile(
                                leading: Icon(Icons.label),
                                title: Text('Tags'),
                                onTap: () => Navigator.pop(context),
                              ),
                              ListTile(
                                leading: Icon(Icons.lock),
                                title: Text('Chiffrés uniquement'),
                                onTap: () => Navigator.pop(context),
                              ),
                              SizedBox(height: 1.h),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 6.h,
                    width: 12.w,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.outline,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: CustomIconWidget(
                        iconName: 'ef4f',
                        size: 20,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                InkWell(
                  onTap: _toggleView,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 6.h,
                    width: 12.w,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.outline,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: CustomIconWidget(
                        iconName: _isGridView ? 'f1ca' : 'e8ef',
                        size: 20,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_activeFilters.isNotEmpty)
            Container(
              height: 6.h,
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              color: theme.colorScheme.surface,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _activeFilters.length,
                separatorBuilder: (context, index) => SizedBox(width: 2.w),
                itemBuilder: (context, index) {
                  return FilterChipWidget(
                    label: _activeFilters[index]["label"]!,
                    count: _activeFilters[index]["count"]!,
                    onDeleted: () {
                      setState(() {
                        _activeFilters.removeAt(index);
                      });
                    },
                  );
                },
              ),
            ),
          Expanded(
            child: _documents.isEmpty
                ? const EmptyStateWidget()
                : RefreshIndicator(
                    onRefresh: () async {
                      await Future.delayed(const Duration(seconds: 1));
                    },
                    child: _isGridView
                        ? GridView.builder(
                            padding: EdgeInsets.all(4.w),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 3.w,
                                  mainAxisSpacing: 2.h,
                                  childAspectRatio: 0.75,
                                ),
                            itemCount: _documents.length,
                            itemBuilder: (context, index) {
                              final document = _documents[index];
                              final documentId = document["id"].toString();
                              final viewers =
                                  _documentViewers[documentId] ?? [];

                              return Stack(
                                children: [
                                  DocumentGridItemWidget(
                                    document: document,
                                    isSelected: _selectedDocuments.contains(
                                      document["id"],
                                    ),
                                    isSelectionMode: _isSelectionMode,
                                    onTap: () {
                                      if (_isSelectionMode) {
                                        _toggleDocumentSelection(
                                          document["id"] as int,
                                        );
                                      } else {
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.pdfViewer,
                                          arguments: {
                                            'documentId': document['id'],
                                          },
                                        );
                                      }
                                    },
                                    onLongPress: () {
                                      _showDocumentOptions(document);
                                    },
                                  ),
                                  if (viewers.isNotEmpty)
                                    Positioned(
                                      top: 1.h,
                                      right: 1.w,
                                      child: PresenceIndicatorWidget(
                                        activeViewers: viewers,
                                      ),
                                    ),
                                ],
                              );
                            },
                          )
                        : ListView.separated(
                            padding: EdgeInsets.all(4.w),
                            itemCount: _documents.length,
                            separatorBuilder: (context, index) =>
                                SizedBox(height: 1.h),
                            itemBuilder: (context, index) {
                              final document = _documents[index];
                              final documentId = document["id"].toString();
                              final viewers =
                                  _documentViewers[documentId] ?? [];

                              return Row(
                                children: [
                                  Expanded(
                                    child: DocumentGridItemWidget(
                                      document: document,
                                      isSelected: _selectedDocuments.contains(
                                        document["id"],
                                      ),
                                      isSelectionMode: _isSelectionMode,
                                      isListView: true,
                                      onTap: () {
                                        if (_isSelectionMode) {
                                          _toggleDocumentSelection(
                                            document["id"] as int,
                                          );
                                        } else {
                                          Navigator.pushNamed(
                                            context,
                                            AppRoutes.pdfViewer,
                                            arguments: {
                                              'documentId': document['id'],
                                            },
                                          );
                                        }
                                      },
                                      onLongPress: () {
                                        _showDocumentOptions(document);
                                      },
                                    ),
                                  ),
                                  if (viewers.isNotEmpty) SizedBox(width: 2.w),
                                  PresenceIndicatorWidget(
                                    activeViewers: viewers,
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _isSelectionMode
          ? Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: _toggleSelectionMode,
                      icon: CustomIconWidget(
                        iconName: 'e5cd',
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      label: Text(
                        'Annuler',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _selectedDocuments.isEmpty
                          ? null
                          : () {
                              final selectedIds = _selectedDocuments.toList();
                              final selectedDocs = _documents
                                  .where(
                                    (doc) => selectedIds.contains(doc['id']),
                                  )
                                  .toList();
                              if (selectedDocs.isNotEmpty) {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.shareDocument,
                                  arguments: {
                                    'documentId': selectedDocs.first['id'],
                                    'documentName': selectedDocs.first['name'],
                                  },
                                );
                              }
                            },
                      icon: CustomIconWidget(
                        iconName: 'f0c6',
                        size: 20,
                        color: _selectedDocuments.isEmpty
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.primary,
                      ),
                      label: Text(
                        'Partager',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: _selectedDocuments.isEmpty
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _selectedDocuments.isEmpty
                          ? null
                          : () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(
                                    'Supprimer ${_selectedDocuments.length} document(s)?',
                                  ),
                                  content: Text(
                                    'Cette action est irréversible.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('Annuler'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _documents.removeWhere(
                                            (doc) => _selectedDocuments
                                                .contains(doc['id']),
                                          );
                                          _selectedDocuments.clear();
                                          _isSelectionMode = false;
                                        });
                                        Navigator.pop(context);
                                      },
                                      child: Text(
                                        'Supprimer',
                                        style: TextStyle(
                                          color: theme.colorScheme.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                      icon: CustomIconWidget(
                        iconName: 'e1bb',
                        size: 20,
                        color: _selectedDocuments.isEmpty
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.error,
                      ),
                      label: Text(
                        'Supprimer',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: _selectedDocuments.isEmpty
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: _toggleSelectionMode,
                      icon: CustomIconWidget(
                        iconName: 'e5ca',
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      label: Text(
                        'Sélectionner',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _showSortOptions,
                      icon: CustomIconWidget(
                        iconName: 'e164',
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      label: Text(
                        'Trier',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Nouveau dossier'),
                            content: TextField(
                              decoration: InputDecoration(
                                hintText: 'Nom du dossier',
                                border: OutlineInputBorder(),
                              ),
                              autofocus: true,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Annuler'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Dossier créé avec succès'),
                                    ),
                                  );
                                },
                                child: Text('Créer'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: CustomIconWidget(
                        iconName: 'e2c8',
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      label: Text(
                        'Nouveau dossier',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(
            context,
            rootNavigator: true,
          ).pushNamed('/document-import');
        },
        icon: CustomIconWidget(
          iconName: 'e145',
          size: 24,
          color: theme.colorScheme.onPrimary,
        ),
        label: Text(
          'Importer',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
      ),
    );
  }
}
