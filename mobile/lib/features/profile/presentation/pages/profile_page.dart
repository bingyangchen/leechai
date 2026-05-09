import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/features/auth/data/services/auth.dart';
import 'package:mobile/features/budget/data/repositories/budget.dart';
import 'package:mobile/features/entry/data/repositories/entry.dart';
import 'package:mobile/features/profile/data/repositories/achievement.dart';
import 'package:mobile/features/profile/data/services/cloud_sync.dart';
import 'package:mobile/features/profile/domain/achievement_definitions.dart';
import 'package:mobile/features/profile/domain/profile_page_data.dart';
import 'package:mobile/features/profile/presentation/pages/achievement_list_page.dart';
import 'package:mobile/features/profile/presentation/widgets/cloud_sync_banner.dart';
import 'package:mobile/features/profile/presentation/widgets/profile_settings_section.dart';
import 'package:mobile/features/profile/presentation/widgets/user_stats_card.dart';
import 'package:mobile/shared/utils/refresh_snap_back.dart';
import 'package:mobile/shared/widgets/app_refresh_indicator.dart';
import 'package:mobile/shared/widgets/haptic_refresh_wrapper.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.refreshTrigger, this.isPageVisible = true});
  final ValueListenable<int>? refreshTrigger;
  final bool isPageVisible;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<ProfilePageData> _future;
  ProfilePageData? _lastData;
  final ValueNotifier<bool> _cardInteracting = ValueNotifier<bool>(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _future = _loadData();
    widget.refreshTrigger?.addListener(_onRefresh);
    AuthService.instance.currentUser.addListener(_onExternalStateChanged);
    CloudSyncService.instance.status.addListener(_onExternalStateChanged);
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
    AuthService.instance.currentUser.removeListener(_onExternalStateChanged);
    CloudSyncService.instance.status.removeListener(_onExternalStateChanged);
    widget.refreshTrigger?.removeListener(_onRefresh);
    _scrollController.dispose();
    _cardInteracting.dispose();
    super.dispose();
  }

  void _onExternalStateChanged() {
    if (mounted) setState(() {});
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
    final consecutiveActiveDays = await _computeConsecutiveActiveDays(now);
    final achievementRows = await AchievementRepository.getAll();
    final achievements = achievementsFromRepositoryRows(
      achievementRows,
      achievementDefinitions,
    );
    final totalBudgetSummary = await BudgetRepository.getTotalForMonth(
      now.year,
      now.month,
    );
    return ProfilePageData(
      consecutiveActiveDays: consecutiveActiveDays,
      totalEntries: totalEntries,
      totalDays: totalDays,
      entriesThisMonth: monthEntries.length,
      noSpendDaysThisWeek: 0,
      achievements: achievements,
      totalBudgetSummary: totalBudgetSummary,
    );
  }

  static Future<int> _computeConsecutiveActiveDays(DateTime now) async {
    const maxDays = 999;
    final start = now.subtract(const Duration(days: maxDays));
    final end = now;
    final rows = await EntryRepository.getByCreatedAtDateRange(start, end);
    final activeDates = <DateTime>{};
    for (final row in rows) {
      final createdAt = row['created_at'];
      if (createdAt == null) continue;
      final date = DateTime.parse(createdAt as String).toLocal();
      activeDates.add(DateTime(date.year, date.month, date.day));
    }
    final today = DateTime(now.year, now.month, now.day);
    var count = 0;
    var day = today;
    while (activeDates.contains(day)) {
      count++;
      day = day.subtract(const Duration(days: 1));
    }
    return count;
  }

  static SystemUiOverlayStyle _edgeToEdgeStatusBarStyle(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemStatusBarContrastEnforced: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<ProfilePageData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasData) _lastData = snapshot.data;
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const SafeArea(
              bottom: false,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final data = snapshot.data ?? _lastData;
          if (data == null) return const SizedBox.shrink();
          final statusBarOverlapInset = MediaQuery.viewPaddingOf(context).top;
          final scrollBody = HapticRefreshWrapper(
            child: SafeArea(
              top: false,
              bottom: false,
              child: ValueListenableBuilder<bool>(
                valueListenable: _cardInteracting,
                builder: (context, isCardInteracting, child) => CustomScrollView(
                  clipBehavior: Clip.none,
                  controller: _scrollController,
                  physics: isCardInteracting
                      ? const NeverScrollableScrollPhysics()
                      : const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    appSliverRefreshControl(
                      statusBarOverlapInset: statusBarOverlapInset,
                      onRefresh: () =>
                          runRefreshWithSnapBack(_scrollController, () async {
                            // NOTE: placebo effect
                            await Future.delayed(const Duration(milliseconds: 600));
                            _onRefresh();
                            await _future;
                          }),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 16 + statusBarOverlapInset),
                        child: UserStatsCard(
                          data: data,
                          isPageVisible: widget.isPageVisible,
                          interactionNotifier: _cardInteracting,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => AchievementListPage(
                                  achievements: data.achievements,
                                  refreshTrigger: widget.refreshTrigger,
                                  loadData: _loadData,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: CloudSyncBanner(),
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
              ),
            ),
          );
          if (widget.isPageVisible) {
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: _edgeToEdgeStatusBarStyle(context),
              child: scrollBody,
            );
          }
          return scrollBody;
        },
      ),
    );
  }
}
