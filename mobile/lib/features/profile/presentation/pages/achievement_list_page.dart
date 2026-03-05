import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile/features/profile/domain/profile_page_data.dart';
import 'package:mobile/features/profile/presentation/widgets/achievement_badge_item.dart';
import 'package:mobile/features/profile/presentation/widgets/achievement_detail_sheet.dart';

class AchievementListPage extends StatefulWidget {
  const AchievementListPage({
    super.key,
    required this.achievements,
    required this.totalEntries,
    this.onEntryAdded,
    this.refreshTrigger,
    this.loadData,
  });

  final List<AchievementItem> achievements;
  final int totalEntries;
  final VoidCallback? onEntryAdded;
  final ValueListenable<int>? refreshTrigger;
  final Future<ProfilePageData> Function()? loadData;

  @override
  State<AchievementListPage> createState() => _AchievementListPageState();
}

class _AchievementListPageState extends State<AchievementListPage> {
  late List<AchievementItem> _achievements;
  late int _totalEntries;

  @override
  void initState() {
    super.initState();
    _achievements = widget.achievements;
    _totalEntries = widget.totalEntries;
    widget.refreshTrigger?.addListener(_onRefreshTriggered);
  }

  @override
  void didUpdateWidget(AchievementListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTrigger != widget.refreshTrigger) {
      oldWidget.refreshTrigger?.removeListener(_onRefreshTriggered);
      widget.refreshTrigger?.addListener(_onRefreshTriggered);
    }
  }

  @override
  void dispose() {
    widget.refreshTrigger?.removeListener(_onRefreshTriggered);
    super.dispose();
  }

  void _onRefreshTriggered() {
    final loadData = widget.loadData;
    if (loadData == null || !mounted) return;
    loadData().then((data) {
      if (mounted) {
        setState(() {
          _achievements = data.achievements;
          _totalEntries = data.totalEntries;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isFirstEntryLocked =
        _achievements.isNotEmpty &&
        _achievements.first.id == 'first_entry' &&
        !_achievements.first.isUnlocked;

    return Scaffold(
      appBar: AppBar(title: const Text('我的成就')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.start,
            children: [
              for (var index = 0; index < _achievements.length; index++)
                AchievementBadgeItem(
                  item: _achievements[index],
                  highlightCta: _totalEntries == 0 && index == 0 && isFirstEntryLocked,
                  onTap: () =>
                      showAchievementDetailSheet(context, _achievements[index]),
                  onEntryAdded: _totalEntries == 0 && index == 0
                      ? widget.onEntryAdded
                      : null,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
