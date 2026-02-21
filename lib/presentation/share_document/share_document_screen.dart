import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/collaboration_service.dart';
import '../../widgets/custom_icon_widget.dart';

class ShareDocumentScreen extends StatefulWidget {
  const ShareDocumentScreen({super.key});

  @override
  State<ShareDocumentScreen> createState() => _ShareDocumentScreenState();
}

class _ShareDocumentScreenState extends State<ShareDocumentScreen> {
  final TextEditingController _emailController = TextEditingController();
  final CollaborationService _collaborationService =
      CollaborationService.instance;

  String _selectedPermission = 'view';
  bool _isLoading = false;
  List<Map<String, dynamic>> _shares = [];
  String? _documentId;
  String? _documentName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _documentId = args['documentId'] as String?;
      _documentName = args['documentName'] as String?;
      if (_documentId != null) {
        _loadShares();
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadShares() async {
    if (_documentId == null) return;

    try {
      final shares = await _collaborationService.getDocumentShares(
        _documentId!,
      );
      if (mounted) {
        setState(() {
          _shares = shares;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load shares: $e')));
      }
    }
  }

  Future<void> _shareDocument() async {
    if (_documentId == null || _emailController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await _collaborationService.shareDocument(
        documentId: _documentId!,
        userEmail: _emailController.text.trim(),
        permission: _selectedPermission,
      );

      _emailController.clear();
      await _loadShares();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document shared successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to share: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _removeShare(String shareId) async {
    try {
      await _collaborationService.removeDocumentShare(shareId);
      await _loadShares();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Share removed')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to remove share: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Share Document',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Document info
          Container(
            padding: EdgeInsets.all(4.w),
            color: theme.colorScheme.surfaceContainerHighest.withAlpha(77),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'description',
                  color: theme.colorScheme.primary,
                  size: 20.sp,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    _documentName ?? 'Document',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Share form
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share with',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'Enter email address',
                    prefixIcon: Icon(Icons.email_outlined, size: 18.sp),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 1.5.h,
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 2.h),
                Text(
                  'Permission',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 1.h),
                Row(
                  children: [
                    Expanded(
                      child: _PermissionChip(
                        label: 'View',
                        value: 'view',
                        isSelected: _selectedPermission == 'view',
                        onTap: () =>
                            setState(() => _selectedPermission = 'view'),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: _PermissionChip(
                        label: 'Comment',
                        value: 'comment',
                        isSelected: _selectedPermission == 'comment',
                        onTap: () =>
                            setState(() => _selectedPermission = 'comment'),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: _PermissionChip(
                        label: 'Edit',
                        value: 'edit',
                        isSelected: _selectedPermission == 'edit',
                        onTap: () =>
                            setState(() => _selectedPermission = 'edit'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _shareDocument,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 18.sp,
                            width: 18.sp,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.onPrimary,
                            ),
                          )
                        : Text(
                            'Share',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, thickness: 1),

          // Shared with list
          Expanded(
            child: _shares.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: 'people_outline',
                          size: 48.sp,
                          color: theme.colorScheme.onSurface.withAlpha(77),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Not shared yet',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(153),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(4.w),
                    itemCount: _shares.length,
                    itemBuilder: (context, index) {
                      final share = _shares[index];
                      final userProfile =
                          share['user_profiles'] as Map<String, dynamic>?;

                      return Card(
                        margin: EdgeInsets.only(bottom: 2.h),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Text(
                              (userProfile?['full_name'] as String? ?? 'U')[0]
                                  .toUpperCase(),
                              style: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          title: Text(
                            userProfile?['full_name'] as String? ?? 'Unknown',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            userProfile?['email'] as String? ?? '',
                            style: theme.textTheme.bodySmall,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 3.w,
                                  vertical: 0.5.h,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Text(
                                  share['permission'] as String? ?? 'view',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color:
                                        theme.colorScheme.onSecondaryContainer,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: CustomIconWidget(
                                  iconName: 'close',
                                  color: theme.colorScheme.error,
                                  size: 18.sp,
                                ),
                                onPressed: () =>
                                    _removeShare(share['id'] as String),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PermissionChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  const _PermissionChip({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.h),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest.withAlpha(77),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
