import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomImageWidget(
              imageUrl:
                  'https://images.unsplash.com/photo-1544396821-4dd40b938ad3?w=400&h=400&fit=crop',
              width: 60.w,
              height: 30.h,
              fit: BoxFit.contain,
              semanticLabel:
                  'Illustration of an empty folder with documents floating around it',
            ),
            SizedBox(height: 3.h),
            Text(
              'Aucun document',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              'Commencez par importer votre premier PDF pour organiser vos documents',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(
                  context,
                  rootNavigator: true,
                ).pushNamed('/document-import');
              },
              icon: CustomIconWidget(
                iconName: 'e145',
                size: 20,
                color: theme.colorScheme.onPrimary,
              ),
              label: Text(
                'Importer votre premier PDF',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.8.h),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
