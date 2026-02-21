import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Document Outline Widget - Side panel or bottom sheet with outline and bookmarks
///
/// Features:
/// - Document outline navigation
/// - Bookmarks list
/// - Annotations list with timestamps
/// - Quick page jumping
/// - Responsive layout (side panel for landscape, bottom sheet for portrait)
class DocumentOutlineWidget extends StatelessWidget {
  final List<Map<String, dynamic>> annotations;
  final int currentPage;
  final Function(int) onPageSelected;
  final VoidCallback onClose;

  const DocumentOutlineWidget({
    super.key,
    required this.annotations,
    required this.currentPage,
    required this.onPageSelected,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    if (isLandscape) {
      return _buildSidePanel(context, theme);
    } else {
      return _buildBottomSheet(context, theme);
    }
  }

  Widget _buildSidePanel(BuildContext context, ThemeData theme) {
    return Positioned(
      left: 0,
      top: 0,
      bottom: 0,
      child: Container(
        width: 300,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(2, 0),
            ),
          ],
        ),
        child: _buildContent(context, theme),
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context, ThemeData theme) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: _buildContent(
                context,
                theme,
                scrollController: scrollController,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme, {
    ScrollController? scrollController,
  }) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Document Info', style: theme.textTheme.titleLarge),
                IconButton(
                  icon: CustomIconWidget(
                    iconName: 'close',
                    color: theme.colorScheme.onSurface,
                    size: 24,
                  ),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          TabBar(
            tabs: const [
              Tab(text: 'Outline'),
              Tab(text: 'Annotations'),
            ],
            labelStyle: theme.textTheme.titleSmall,
            unselectedLabelStyle: theme.textTheme.bodyMedium,
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildOutlineTab(context, theme, scrollController),
                _buildAnnotationsTab(context, theme, scrollController),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutlineTab(
    BuildContext context,
    ThemeData theme,
    ScrollController? scrollController,
  ) {
    final outlineItems = [
      {'title': 'Executive Summary', 'page': 1},
      {'title': 'Financial Overview', 'page': 3},
      {'title': 'Q1 Performance', 'page': 5},
      {'title': 'Market Analysis', 'page': 8},
      {'title': 'Strategic Initiatives', 'page': 12},
      {'title': 'Risk Assessment', 'page': 15},
      {'title': 'Future Projections', 'page': 18},
      {'title': 'Appendix', 'page': 20},
    ];

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: outlineItems.length,
      itemBuilder: (context, index) {
        final item = outlineItems[index];
        final isCurrentPage = item['page'] == currentPage;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isCurrentPage
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            leading: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCurrentPage
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '${item['page']}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isCurrentPage
                        ? Colors.white
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            title: Text(
              item['title'] as String,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: isCurrentPage ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            trailing: isCurrentPage
                ? CustomIconWidget(
                    iconName: 'arrow_forward',
                    color: theme.colorScheme.primary,
                    size: 20,
                  )
                : null,
            onTap: () => onPageSelected(item['page'] as int),
          ),
        );
      },
    );
  }

  Widget _buildAnnotationsTab(
    BuildContext context,
    ThemeData theme,
    ScrollController? scrollController,
  ) {
    if (annotations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'edit_note',
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No annotations yet',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: annotations.length,
      itemBuilder: (context, index) {
        final annotation = annotations[index];
        final type = annotation['type'] as String;
        final page = annotation['page'] as int;
        final timestamp = annotation['timestamp'] as DateTime;

        IconData iconData;
        String typeLabel;

        switch (type) {
          case 'highlight':
            iconData = Icons.highlight;
            typeLabel = 'Highlight';
            break;
          case 'note':
            iconData = Icons.note;
            typeLabel = 'Note';
            break;
          case 'drawing':
            iconData = Icons.draw;
            typeLabel = 'Drawing';
            break;
          default:
            iconData = Icons.edit;
            typeLabel = 'Annotation';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outline, width: 1),
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                    (annotation['color'] as Color?)?.withValues(alpha: 0.2) ??
                    theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                iconData,
                color:
                    annotation['color'] as Color? ?? theme.colorScheme.primary,
                size: 20,
              ),
            ),
            title: Text(typeLabel, style: theme.textTheme.titleSmall),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                if (annotation['text'] != null)
                  Text(
                    annotation['text'] as String,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (annotation['content'] != null)
                  Text(
                    annotation['content'] as String,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Page $page',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• ${_formatTimestamp(timestamp)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: CustomIconWidget(
              iconName: 'arrow_forward',
              color: theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
            onTap: () => onPageSelected(page),
          ),
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
