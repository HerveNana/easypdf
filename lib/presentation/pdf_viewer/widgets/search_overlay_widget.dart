import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Search Overlay Widget - Full-screen search with result navigation
///
/// Features:
/// - Full-screen search overlay
/// - Real-time search results
/// - Navigation arrows for result jumping
/// - Result counter display
/// - Close button to exit search
class SearchOverlayWidget extends StatefulWidget {
  final String searchQuery;
  final int currentResult;
  final int totalResults;
  final Function(String) onSearchChanged;
  final Function(bool) onNavigateResult;
  final VoidCallback onClose;

  const SearchOverlayWidget({
    super.key,
    required this.searchQuery,
    required this.currentResult,
    required this.totalResults,
    required this.onSearchChanged,
    required this.onNavigateResult,
    required this.onClose,
  });

  @override
  State<SearchOverlayWidget> createState() => _SearchOverlayWidgetState();
}

class _SearchOverlayWidgetState extends State<SearchOverlayWidget> {
  late TextEditingController _searchController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
    _focusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: CustomIconWidget(
                      iconName: 'arrow_back',
                      color: theme.colorScheme.onSurface,
                      size: 24,
                    ),
                    onPressed: widget.onClose,
                    tooltip: 'Close search',
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      style: theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'Search in document...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                      textInputAction: TextInputAction.search,
                      onChanged: widget.onSearchChanged,
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: CustomIconWidget(
                        iconName: 'clear',
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        widget.onSearchChanged('');
                      },
                      tooltip: 'Clear',
                    ),
                ],
              ),
            ),
            if (widget.totalResults > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: theme.colorScheme.surfaceContainerHighest,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${widget.currentResult} of ${widget.totalResults} results',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: CustomIconWidget(
                            iconName: 'keyboard_arrow_up',
                            color: theme.colorScheme.primary,
                            size: 24,
                          ),
                          onPressed: () => widget.onNavigateResult(false),
                          tooltip: 'Previous result',
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: CustomIconWidget(
                            iconName: 'keyboard_arrow_down',
                            color: theme.colorScheme.primary,
                            size: 24,
                          ),
                          onPressed: () => widget.onNavigateResult(true),
                          tooltip: 'Next result',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            Expanded(
              child: widget.searchQuery.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomIconWidget(
                            iconName: 'search',
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Search for text in document',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : widget.totalResults == 0
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomIconWidget(
                            iconName: 'search_off',
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No results found',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: widget.totalResults,
                      itemBuilder: (context, index) {
                        final isCurrentResult =
                            index + 1 == widget.currentResult;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isCurrentResult
                                ? theme.colorScheme.primary.withValues(
                                    alpha: 0.1,
                                  )
                                : theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isCurrentResult
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline,
                              width: isCurrentResult ? 2 : 1,
                            ),
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isCurrentResult
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 3}',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: isCurrentResult
                                        ? Colors.white
                                        : theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            title: RichText(
                              text: TextSpan(
                                style: theme.textTheme.bodyMedium,
                                children: [
                                  const TextSpan(text: '...financial '),
                                  TextSpan(
                                    text: widget.searchQuery,
                                    style: TextStyle(
                                      backgroundColor: const Color(
                                        0xFFFFEB3B,
                                      ).withValues(alpha: 0.3),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const TextSpan(text: ' metrics for Q1...'),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: isCurrentResult
                                ? CustomIconWidget(
                                    iconName: 'arrow_forward',
                                    color: theme.colorScheme.primary,
                                    size: 20,
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
