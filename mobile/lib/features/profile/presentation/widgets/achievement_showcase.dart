import 'package:flutter/material.dart';
import 'package:mobile/features/profile/domain/profile_page_data.dart';
import 'package:mobile/features/profile/presentation/pages/achievement_list_page.dart';
import 'package:mobile/features/profile/presentation/widgets/achievement_badge_item.dart';
import 'package:mobile/features/profile/presentation/widgets/achievement_detail_sheet.dart';

class AchievementShowcase extends StatelessWidget {
  const AchievementShowcase({
    super.key,
    required this.achievements,
    required this.totalEntries,
    this.onEntryAdded,
  });

  final List<AchievementItem> achievements;
  final int totalEntries;
  final VoidCallback? onEntryAdded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFirstEntryLocked =
        achievements.isNotEmpty &&
        achievements.first.id == 'first_entry' &&
        !achievements.first.isUnlocked;

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '我的成就',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AchievementListPage(),
                      ),
                    );
                  },
                  child: const Text('查看全部'),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (var index = 0; index < achievements.length; index++) ...[
                  if (index > 0) const SizedBox(width: 8),
                  AchievementBadgeItem(
                    item: achievements[index],
                    highlightCta: totalEntries == 0 && index == 0 && isFirstEntryLocked,
                    onTap: () =>
                        showAchievementDetailSheet(context, achievements[index]),
                    onEntryAdded: totalEntries == 0 && index == 0 ? onEntryAdded : null,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
