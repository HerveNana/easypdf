import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/edit_toolbar_widget.dart';
import './widgets/insert_options_sheet.dart';
import './widgets/page_thumbnail_widget.dart';

/// Document Editor Screen
/// Enables comprehensive PDF manipulation with mobile-optimized page management
class DocumentEditor extends StatefulWidget {
  const DocumentEditor({super.key});

  @override
  State<DocumentEditor> createState() => _DocumentEditorState();
}

class _DocumentEditorState extends State<DocumentEditor> {
  // Selection state
  bool _isSelectionMode = false;
  final Set<int> _selectedPages = {};

  // Document state
  final String _documentName = "Annual_Report_2025.pdf";
  bool _hasUnsavedChanges = false;
  bool _isProcessing = false;

  // Mock pages data
  final List<Map<String, dynamic>> _pages = [
    {
      "id": 1,
      "thumbnail":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1976ba528-1764700386555.png",
      "semanticLabel":
          "Document page showing title 'Annual Report 2025' with blue header and company logo",
      "pageNumber": 1,
      "rotation": 0,
    },
    {
      "id": 2,
      "thumbnail":
          "https://img.rocket.new/generatedImages/rocket_gen_img_15eb08d59-1767597260170.png",
      "semanticLabel":
          "Document page with financial charts and graphs showing quarterly revenue data",
      "pageNumber": 2,
      "rotation": 0,
    },
    {
      "id": 3,
      "thumbnail":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1145b4328-1766532382655.png",
      "semanticLabel":
          "Document page containing executive summary text with bullet points",
      "pageNumber": 3,
      "rotation": 0,
    },
    {
      "id": 4,
      "thumbnail":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1d44dea85-1768392304393.png",
      "semanticLabel":
          "Document page displaying market analysis data with pie charts and statistics",
      "pageNumber": 4,
      "rotation": 0,
    },
    {
      "id": 5,
      "thumbnail":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1034b6be6-1765376424627.png",
      "semanticLabel":
          "Document page showing growth projections with line graphs and trend analysis",
      "pageNumber": 5,
      "rotation": 0,
    },
    {
      "id": 6,
      "thumbnail":
          "https://img.rocket.new/generatedImages/rocket_gen_img_14d237326-1769335121970.png",
      "semanticLabel":
          "Document page with team organizational chart and department structure",
      "pageNumber": 6,
      "rotation": 0,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(theme),
      body: _buildBody(theme),
      floatingActionButton: !_isSelectionMode ? _buildFAB(theme) : null,
      bottomNavigationBar: _isSelectionMode ? _buildBottomToolbar(theme) : null,
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return CustomAppBar(
      title: _documentName,
      subtitle: _isSelectionMode
          ? "${_selectedPages.length} page${_selectedPages.length != 1 ? 's' : ''} selected"
          : "${_pages.length} pages",
      showBackButton: true,
      onBackTap: () => _handleBackPress(),
      actions: [
        if (_isSelectionMode)
          TextButton(
            onPressed: _cancelSelection,
            child: Text(
              'Cancel',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          )
        else ...[
          if (_hasUnsavedChanges)
            TextButton(
              onPressed: _saveDocument,
              child: Text(
                'Save',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          IconButton(
            icon: CustomIconWidget(
              iconName: 'settings',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: _showSecuritySettings,
            tooltip: 'Security Settings',
          ),
        ],
      ],
    );
  }

  Widget _buildBody(ThemeData theme) {
    return _isProcessing
        ? _buildProcessingIndicator(theme)
        : Column(
            children: [
              if (_isSelectionMode) _buildSelectionActions(theme),
              Expanded(child: _buildPageGrid(theme)),
            ],
          );
  }

  Widget _buildProcessingIndicator(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.colorScheme.primary),
          SizedBox(height: 2.h),
          Text(
            'Processing document...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionActions(ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: _selectAll,
            icon: CustomIconWidget(
              iconName: 'select_all',
              color: theme.colorScheme.primary,
              size: 20,
            ),
            label: Text(
              'Select All',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const Spacer(),
          if (_selectedPages.isNotEmpty)
            TextButton(
              onPressed: _deselectAll,
              child: Text(
                'Deselect All',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPageGrid(ThemeData theme) {
    return GridView.builder(
      padding: EdgeInsets.all(4.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 3.w,
        mainAxisSpacing: 2.h,
      ),
      itemCount: _pages.length,
      itemBuilder: (context, index) {
        final page = _pages[index];
        final isSelected = _selectedPages.contains(page["id"]);

        return PageThumbnailWidget(
          page: page,
          isSelected: isSelected,
          isSelectionMode: _isSelectionMode,
          onTap: () => _handlePageTap(page["id"] as int),
          onLongPress: () => _handlePageLongPress(page["id"] as int),
          onRotate: () => _rotatePage(page["id"] as int),
        );
      },
    );
  }

  Widget _buildBottomToolbar(ThemeData theme) {
    return EditToolbarWidget(
      selectedCount: _selectedPages.length,
      onRotate: _rotateSelectedPages,
      onDuplicate: _duplicateSelectedPages,
      onDelete: _deleteSelectedPages,
      onExtract: _extractSelectedPages,
    );
  }

  Widget _buildFAB(ThemeData theme) {
    return FloatingActionButton.extended(
      onPressed: _showInsertOptions,
      backgroundColor: theme.colorScheme.primary,
      icon: CustomIconWidget(
        iconName: 'add',
        color: theme.colorScheme.onPrimary,
        size: 24,
      ),
      label: Text(
        'Insert',
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onPrimary,
        ),
      ),
    );
  }

  // Page interaction handlers
  void _handlePageTap(int pageId) {
    if (_isSelectionMode) {
      setState(() {
        _selectedPages.contains(pageId)
            ? _selectedPages.remove(pageId)
            : _selectedPages.add(pageId);
      });
    }
  }

  void _handlePageLongPress(int pageId) {
    if (!_isSelectionMode) {
      setState(() {
        _isSelectionMode = true;
        _selectedPages.add(pageId);
      });
    }
  }

  void _rotatePage(int pageId) {
    setState(() {
      final pageIndex = _pages.indexWhere((p) => p["id"] == pageId);
      if (pageIndex != -1) {
        final currentRotation = _pages[pageIndex]["rotation"] as int;
        _pages[pageIndex]["rotation"] = (currentRotation + 90) % 360;
        _hasUnsavedChanges = true;
      }
    });
  }

  // Selection actions
  void _selectAll() {
    setState(() {
      _selectedPages.clear();
      _selectedPages.addAll(_pages.map((p) => p["id"] as int));
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedPages.clear();
    });
  }

  void _cancelSelection() {
    setState(() {
      _isSelectionMode = false;
      _selectedPages.clear();
    });
  }

  // Toolbar actions
  void _rotateSelectedPages() {
    setState(() {
      for (final pageId in _selectedPages) {
        _rotatePage(pageId);
      }
    });
    _showSuccessMessage('${_selectedPages.length} page(s) rotated');
  }

  void _duplicateSelectedPages() {
    setState(() {
      final newPages = <Map<String, dynamic>>[];
      for (final pageId in _selectedPages) {
        final page = _pages.firstWhere((p) => p["id"] == pageId);
        final newPage = Map<String, dynamic>.from(page);
        newPage["id"] = _pages.length + newPages.length + 1;
        newPage["pageNumber"] = _pages.length + newPages.length + 1;
        newPages.add(newPage);
      }
      _pages.addAll(newPages);
      _hasUnsavedChanges = true;
    });
    _cancelSelection();
    _showSuccessMessage('${_selectedPages.length} page(s) duplicated');
  }

  void _deleteSelectedPages() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pages'),
        content: Text('Delete ${_selectedPages.length} selected page(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _pages.removeWhere((p) => _selectedPages.contains(p["id"]));
                _hasUnsavedChanges = true;
              });
              Navigator.pop(context);
              _cancelSelection();
              _showSuccessMessage('Pages deleted');
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _extractSelectedPages() {
    setState(() {
      _isProcessing = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isProcessing = false;
      });
      _cancelSelection();
      _showSuccessMessage('Pages extracted to new document');
    });
  }

  // Insert options
  void _showInsertOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InsertOptionsSheet(
        onBlankPage: _insertBlankPage,
        onFromCamera: _insertFromCamera,
        onFromPDF: _insertFromPDF,
        onFromGallery: _insertFromGallery,
      ),
    );
  }

  void _insertBlankPage() {
    setState(() {
      _pages.add({
        "id": _pages.length + 1,
        "thumbnail":
            "https://img.rocket.new/generatedImages/rocket_gen_img_171b539e0-1764770071350.png",
        "semanticLabel": "Blank white document page",
        "pageNumber": _pages.length + 1,
        "rotation": 0,
      });
      _hasUnsavedChanges = true;
    });
    Navigator.pop(context);
    _showSuccessMessage('Blank page inserted');
  }

  void _insertFromCamera() {
    Navigator.pop(context);
    _showSuccessMessage('Camera scan feature coming soon');
  }

  void _insertFromPDF() {
    Navigator.pop(context);
    _showSuccessMessage('PDF import feature coming soon');
  }

  void _insertFromGallery() {
    Navigator.pop(context);
    _showSuccessMessage('Gallery import feature coming soon');
  }

  // Document actions
  void _saveDocument() {
    setState(() {
      _isProcessing = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isProcessing = false;
        _hasUnsavedChanges = false;
      });
      _showSuccessMessage('Document saved successfully');
    });
  }

  void _showSecuritySettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CustomIconWidget(
                iconName: 'lock',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              title: const Text('Password Protection'),
              subtitle: const Text('Add password to document'),
              onTap: () {
                Navigator.pop(context);
                _showSuccessMessage('Password protection feature coming soon');
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CustomIconWidget(
                iconName: 'enhanced_encryption',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              title: const Text('Encryption'),
              subtitle: const Text('Enable document encryption'),
              onTap: () {
                Navigator.pop(context);
                _showSuccessMessage('Encryption feature coming soon');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleBackPress() {
    if (_hasUnsavedChanges) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text(
            'You have unsaved changes. Do you want to save before leaving?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context, rootNavigator: true).pop();
              },
              child: const Text('Discard'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _saveDocument();
                Future.delayed(const Duration(seconds: 2), () {
                  Navigator.of(context, rootNavigator: true).pop();
                });
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    } else {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
