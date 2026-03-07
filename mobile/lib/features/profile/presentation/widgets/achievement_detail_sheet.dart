import 'package:flutter/material.dart';
import 'package:mobile/features/profile/domain/profile_page_data.dart';
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:mobile/shared/utils/date_time_utils.dart';
import 'package:mobile/shared/widgets/app_bottom_sheet.dart';

Future<void> showAchievementDetailSheet(BuildContext context, AchievementItem item) {
  return showAppBottomSheet<void>(
    context,
    title: item.name,
    titleAlignment: AppBottomSheetTitleAlignment.left,
    mode: AppBottomSheetMode.scrollable,
    scrollableBuilder: (context, scrollController) {
      final appTextStyles = AppTextStyles.of(context);
      return ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text(item.description, style: appTextStyles.bodyLarge),
          const SizedBox(height: 16),
          Text('取得條件', style: appTextStyles.sectionLabel),
          const SizedBox(height: 4),
          Text(item.conditionText, style: appTextStyles.body),
          if (item.isUnlocked && item.unlockedAt != null) ...[
            const SizedBox(height: 16),
            Text(
              '解鎖於 ${formatDate(item.unlockedAt!)}',
              style: appTextStyles.bodySmallMuted.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ],
      );
    },
  );
}
