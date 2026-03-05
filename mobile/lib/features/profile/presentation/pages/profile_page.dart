import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile/features/entry/data/repositories/entry.dart'
    show EntryRepository;
import 'package:mobile/features/profile/domain/profile_page_data.dart';
import 'package:mobile/features/profile/presentation/widgets/achievement_showcase.dart';
import 'package:mobile/features/profile/presentation/widgets/profile_settings_section.dart';
import 'package:mobile/features/profile/presentation/widgets/profile_skeleton.dart';
import 'package:mobile/features/profile/presentation/widgets/user_stats_card.dart';
import 'package:mobile/shared/constants/refresh_trigger.dart';
import 'package:mobile/shared/widgets/haptic_refresh_wrapper.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.refreshTrigger});
  final ValueListenable<int>? refreshTrigger;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<ProfilePageData> _future;
  ProfilePageData? _lastData;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
    widget.refreshTrigger?.addListener(_onRefresh);
  }

  @override
  void didUpdateWidget(ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTrigger != widget.refreshTrigger) {
      oldWidget.refreshTrigger?.removeListener(_onRefresh);
      widget.refreshTrigger?.addListener(_onRefresh);
    }
  }

  @override
  void dispose() {
    widget.refreshTrigger?.removeListener(_onRefresh);
    super.dispose();
  }

  void _onRefresh() {
    setState(() {
      _future = _loadData();
    });
  }

  Future<ProfilePageData> _loadData() async {
    final totalEntries = await EntryRepository.getCount();
    final now = DateTime.now();
    final earliest = await EntryRepository.getEarliestCreatedAt();
    final totalDays = earliest != null
        ? now.difference(earliest.toLocal()).inDays + 1
        : 0;
    final monthEntries = await EntryRepository.getByMonth(now);
    return ProfilePageData(
      weeklyStreak: 0,
      totalEntries: totalEntries,
      totalDays: totalDays,
      entriesThisMonth: monthEntries.length,
      noSpendDaysThisWeek: 0,
      achievements: buildAchievements(totalEntries),
      totalBudgetSummary: 20000,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('個人')),
      body: FutureBuilder<ProfilePageData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasData) _lastData = snapshot.data;
          if (snapshot.connectionState == ConnectionState.waiting &&
              _lastData == null) {
            return const ProfileSkeleton();
          }
          if (snapshot.hasError) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('載入失敗：${snapshot.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => setState(() {
                        _future = _loadData();
                      }),
                      child: const Text('重試'),
                    ),
                  ],
                ),
              ),
            );
          }
          final data = snapshot.data ?? _lastData!;
          return HapticRefreshWrapper(
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                CupertinoSliverRefreshControl(
                  refreshTriggerPullDistance: kRefreshTriggerPullDistance,
                  onRefresh: () async {
                    _onRefresh();
                    await _future;
                  },
                ),
                SliverToBoxAdapter(child: UserStatsCard(data: data)),
                SliverToBoxAdapter(
                  child: AchievementShowcase(
                    achievements: data.achievements,
                    totalEntries: data.totalEntries,
                    onEntryAdded: () =>
                        (widget.refreshTrigger as ValueNotifier<int>?)?.value++,
                  ),
                ),
                SliverToBoxAdapter(
                  child: ProfileSettingsSection(
                    totalBudgetSummary: data.totalBudgetSummary,
                    refreshTrigger: widget.refreshTrigger,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
