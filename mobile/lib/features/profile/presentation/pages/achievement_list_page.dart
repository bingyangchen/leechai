import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/features/entry/presentation/pages/entry_page.dart';
import 'package:mobile/features/profile/domain/achievement_definitions.dart';
import 'package:mobile/features/profile/domain/profile_page_data.dart';
import 'package:mobile/features/profile/presentation/widgets/achievement_badge_graphics.dart';
import 'package:mobile/features/profile/presentation/widgets/achievement_detail_sheet.dart';
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:mobile/shared/widgets/app_bottom_sheet.dart';

enum _AchievementFilter { all, inProgress, unlocked, locked }

class _AchievementGroup {
  const _AchievementGroup({required this.title, required this.ids});

  final String title;
  final List<String> ids;
}

const List<_AchievementGroup> _achievementGroups = [
  _AchievementGroup(
    title: '習慣起步',
    ids: ['first_entry', 'first_income', 'hundred_entries', 'thousand_entries'],
  ),
  _AchievementGroup(
    title: '持之以恆',
    ids: [
      'streak_7_days',
      'streak_30_days',
      'streak_100_days',
      'monthly_perfect',
      'four_weekends_streak',
      'backfill_streak_3',
    ],
  ),
  _AchievementGroup(title: '井井有條', ids: ['second_account', 'first_custom_tag']),
  _AchievementGroup(
    title: '財務守護',
    ids: ['first_budget', 'budget_guardian', 'positive_cashflow'],
  ),
  _AchievementGroup(title: '時光與驚喜', ids: ['one_year', 'night_owl', 'lucky_777']),
];

final Map<String, int> _achievementIdToOrder = {
  for (int i = 0; i < achievementDefinitions.length; i++)
    achievementDefinitions[i].id: i,
};

int _displayOrderIndex(String id) {
  return _achievementIdToOrder[id] ?? 9999;
}

int _sortByDisplayOrder(AchievementItem a, AchievementItem b) =>
    _displayOrderIndex(a.id).compareTo(_displayOrderIndex(b.id));

bool _achievementMatchesInProgress(AchievementItem item) {
  return !item.isUnlocked &&
      item.target > 0 &&
      item.current > 0 &&
      item.current < item.target;
}

bool _achievementMatchesLocked(AchievementItem item) {
  return !item.isUnlocked && !_achievementMatchesInProgress(item);
}

bool _achievementMatchesFilter(AchievementItem item, _AchievementFilter filter) {
  switch (filter) {
    case _AchievementFilter.all:
      return true;
    case _AchievementFilter.inProgress:
      return _achievementMatchesInProgress(item);
    case _AchievementFilter.unlocked:
      return item.isUnlocked;
    case _AchievementFilter.locked:
      return _achievementMatchesLocked(item);
  }
}

class AchievementListPage extends StatefulWidget {
  const AchievementListPage({
    super.key,
    required this.achievements,
    this.refreshTrigger,
    this.loadData,
  });

  final List<AchievementItem> achievements;
  final ValueListenable<int>? refreshTrigger;
  final Future<ProfilePageData> Function()? loadData;

  @override
  State<AchievementListPage> createState() => _AchievementListPageState();
}

class _AchievementListPageState extends State<AchievementListPage>
    with TickerProviderStateMixin {
  late List<AchievementItem> _achievements;
  _AchievementFilter _filter = _AchievementFilter.all;
  late AnimationController _entranceController;
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;
  late List<AchievementItem> _filteredAchievements;
  late List<AchievementItem> _nextCards;
  late bool _showNextSection;
  late String? _recentLine;
  late int _totalCount;
  late int _unlockedCount;
  late bool _allUnlocked;
  late int _percent;
  late Map<_AchievementGroup, List<AchievementItem>> _groupItems;

  void _updateCachedValues(List<AchievementItem> achievements) {
    _achievements = achievements;
    _filteredAchievements =
        _achievements.where((item) => _achievementMatchesFilter(item, _filter)).toList()
          ..sort(_sortByDisplayOrder);

    _totalCount = _achievements.length;
    _unlockedCount = _countUnlocked(_achievements);
    _allUnlocked = _totalCount > 0 && _unlockedCount == _totalCount;
    _percent = _totalCount > 0 ? ((_unlockedCount / _totalCount) * 100).round() : 0;

    final inProgressForNext =
        _achievements.where(_achievementMatchesInProgress).toList()..sort((a, b) {
          final byProgress = b.progress.compareTo(a.progress);
          if (byProgress != 0) return byProgress;
          return _displayOrderIndex(a.id).compareTo(_displayOrderIndex(b.id));
        });
    _nextCards = inProgressForNext.take(4).toList();
    _showNextSection =
        (_filter == _AchievementFilter.all ||
            _filter == _AchievementFilter.inProgress) &&
        _nextCards.isNotEmpty;

    final recentUnlock =
        _achievements.where((a) => a.isUnlocked && a.unlockedAt != null).toList()
          ..sort((a, b) => b.unlockedAt!.compareTo(a.unlockedAt!));
    _recentLine = recentUnlock.isEmpty
        ? null
        : '最近解鎖：${recentUnlock.first.name} · ${DateFormat('y/MM/dd').format(recentUnlock.first.unlockedAt!)}';

    _groupItems = {};
    for (final group in _achievementGroups) {
      final idSet = group.ids.toSet();
      _groupItems[group] =
          _filteredAchievements.where((item) => idSet.contains(item.id)).toList()
            ..sort(_sortByDisplayOrder);
    }
  }

  @override
  void initState() {
    super.initState();
    _updateCachedValues(widget.achievements);
    widget.refreshTrigger?.addListener(_onRefreshTriggered);
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _pulseScale = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));
    _pulseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseController.reverse();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entranceController.forward();
    });
  }

  @override
  void didUpdateWidget(AchievementListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTrigger != widget.refreshTrigger) {
      oldWidget.refreshTrigger?.removeListener(_onRefreshTriggered);
      widget.refreshTrigger?.addListener(_onRefreshTriggered);
    }
    if (!listEquals(oldWidget.achievements, widget.achievements)) {
      _updateCachedValues(widget.achievements);
    }
  }

  @override
  void dispose() {
    widget.refreshTrigger?.removeListener(_onRefreshTriggered);
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  int _countUnlocked(List<AchievementItem> list) =>
      list.where((achievement) => achievement.isUnlocked).length;

  void _onRefreshTriggered() {
    final loadData = widget.loadData;
    if (loadData == null || !mounted) return;
    final before = _countUnlocked(_achievements);
    loadData().then((data) {
      if (mounted) {
        setState(() {
          _updateCachedValues(data.achievements);
          final after = _countUnlocked(_achievements);
          if (after != before) {
            _pulseController.forward(from: 0);
          }
        });
      }
    });
  }

  Future<void> _openAchievementDetail(AchievementItem item) async {
    final navigator = Navigator.of(context);
    final shouldOpenEntry = await showAchievementDetailSheet(context, item);
    if (shouldOpenEntry != true || !mounted) return;
    final saved = await navigator.push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const EntryPage()),
    );
    if (saved == true && mounted) _onRefreshTriggered();
  }

  void _showAchievementInfoSheet() {
    final theme = Theme.of(context);
    showAppBottomSheet<void>(
      context,
      title: '關於成就',
      titleAlignment: AppBottomSheetTitleAlignment.left,
      mode: AppBottomSheetMode.static,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Text(
            '成就是你記帳歷程的紀念。解鎖方式與進度僅用於鼓勵持續記錄，不影響帳本計算與同步。',
            style: theme.textStyles.body.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textStyles = theme.textStyles;
    final mediaQuery = MediaQuery.of(context);
    final topGradientHeight = mediaQuery.size.height * 0.06;

    final heroFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    final bodyFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.1, 1.0, curve: Curves.easeOut),
    );
    final bodySlide = Tween<Offset>(begin: const Offset(0, 0.025), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.1, 1.0, curve: Curves.easeOut),
          ),
        );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        toolbarHeight: kToolbarHeight,
        title: const Text('成就'),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: '說明',
            onPressed: _showAchievementInfoSheet,
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: topGradientHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.primaryContainer.withValues(alpha: 0.07),
                    colorScheme.surface.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: heroFade,
                  child: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 0.02),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _entranceController,
                            curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
                          ),
                        ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: _HeroSummaryCard(
                        unlockedCount: _unlockedCount,
                        totalCount: _totalCount,
                        percent: _percent,
                        allUnlocked: _allUnlocked,
                        recentLine: _recentLine,
                        pulseScale: _pulseScale,
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: bodyFade,
                  child: SlideTransition(
                    position: bodySlide,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: SegmentedButton<_AchievementFilter>(
                            showSelectedIcon: false,
                            style: SegmentedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 8,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                            segments: const [
                              ButtonSegment<_AchievementFilter>(
                                value: _AchievementFilter.all,
                                label: Text('全部'),
                              ),
                              ButtonSegment<_AchievementFilter>(
                                value: _AchievementFilter.inProgress,
                                label: Text('進行中'),
                              ),
                              ButtonSegment<_AchievementFilter>(
                                value: _AchievementFilter.unlocked,
                                label: Text('已解鎖'),
                              ),
                              ButtonSegment<_AchievementFilter>(
                                value: _AchievementFilter.locked,
                                label: Text('未解鎖'),
                              ),
                            ],
                            selected: {_filter},
                            onSelectionChanged: (selection) {
                              setState(() {
                                _filter = selection.first;
                                _updateCachedValues(_achievements);
                              });
                            },
                          ),
                        ),
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 220),
                          sizeCurve: Curves.easeInOut,
                          firstCurve: Curves.easeInOut,
                          secondCurve: Curves.easeInOut,
                          crossFadeState: _showNextSection
                              ? CrossFadeState.showFirst
                              : CrossFadeState.showSecond,
                          firstChild: Column(
                            key: const ValueKey('achievement_next_steps'),
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                                child: Row(
                                  children: [
                                    Text('即將解鎖', style: textStyles.titleSmallEmphasis),
                                    const Spacer(),
                                    Text(
                                      '依完成度',
                                      style: textStyles.labelSmallMuted.copyWith(
                                        fontSize: theme.textTheme.labelSmall?.fontSize,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 128,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: _nextCards.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(width: 12),
                                  itemBuilder: (context, index) {
                                    final cardWidth = mediaQuery.size.width * 0.72;
                                    return SizedBox(
                                      width: cardWidth,
                                      child: _NextAchievementCard(
                                        item: _nextCards[index],
                                        onTap: () =>
                                            _openAchievementDetail(_nextCards[index]),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                          secondChild: const SizedBox(
                            key: ValueKey('achievement_next_steps_placeholder'),
                            width: double.infinity,
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeInOut,
                          switchOutCurve: Curves.easeInOut,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(opacity: animation, child: child);
                          },
                          child: _filteredAchievements.isEmpty
                              ? _FilterEmptyState(
                                  key: ValueKey(_filter),
                                  filter: _filter,
                                  onViewAll: () {
                                    setState(() {
                                      _filter = _AchievementFilter.all;
                                      _updateCachedValues(_achievements);
                                    });
                                  },
                                )
                              : Padding(
                                  key: ValueKey(_filter),
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      for (
                                        var groupIndex = 0;
                                        groupIndex < _achievementGroups.length;
                                        groupIndex++
                                      ) ...[
                                        _AchievementGroupSection(
                                          group: _achievementGroups[groupIndex],
                                          sectionItems:
                                              _groupItems[_achievementGroups[groupIndex]] ??
                                              const [],
                                          onOpen: _openAchievementDetail,
                                        ),
                                        if (groupIndex < _achievementGroups.length - 1)
                                          const SizedBox(height: 28),
                                      ],
                                    ],
                                  ),
                                ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            24,
                            16,
                            24 + mediaQuery.padding.bottom,
                          ),
                          child: Text(
                            '成就僅為紀念，不影響你的帳本資料。',
                            textAlign: TextAlign.center,
                            style: textStyles.bodySmallMuted.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.75,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroSummaryCard extends StatelessWidget {
  const _HeroSummaryCard({
    required this.unlockedCount,
    required this.totalCount,
    required this.percent,
    required this.allUnlocked,
    this.recentLine,
    required this.pulseScale,
  });

  final int unlockedCount;
  final int totalCount;
  final int percent;
  final bool allUnlocked;
  final String? recentLine;
  final Animation<double> pulseScale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textStyles = theme.textStyles;
    final subtitle = allUnlocked ? '該有的都有了——繼續記帳，讓數字說故事。' : '每一步記帳，都是給未來自己的線索。';

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    colorScheme.primaryContainer.withValues(alpha: 0.14),
                    colorScheme.surfaceContainerHighest,
                  ],
                  stops: const [0.0, 0.45],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedBuilder(
                        animation: pulseScale,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: pulseScale.value,
                            alignment: Alignment.centerLeft,
                            child: child,
                          );
                        },
                        child: Text(
                          '已解鎖 $unlockedCount / $totalCount',
                          style: textStyles.titleLargeEmphasis.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (recentLine != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          recentLine!,
                          style: textStyles.labelSmallMuted.copyWith(
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textStyles.bodySmallMuted.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          value: totalCount > 0 ? unlockedCount / totalCount : 0,
                          strokeWidth: 7,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          color: colorScheme.primary,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Text(
                        '$percent%',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NextAchievementCard extends StatelessWidget {
  const _NextAchievementCard({required this.item, required this.onTap});

  final AchievementItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textStyles = theme.textStyles;
    final remaining = item.target - item.current;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AchievementBadgeGraphics(
                    size: 64,
                    item: item,
                    showProgressRing: true,
                    glow: false,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textStyles.titleSmallEmphasis,
                        ),
                        const SizedBox(height: 4),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: '還差 ', style: textStyles.bodySmallMuted),
                              TextSpan(
                                text: '$remaining',
                                style: textStyles.bodySmallMuted.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(text: ' 步', style: textStyles.bodySmallMuted),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                height: 4,
                child: LinearProgressIndicator(
                  value: item.progress.clamp(0.0, 1.0),
                  borderRadius: BorderRadius.circular(2),
                  backgroundColor: colorScheme.outline.withValues(alpha: 0.18),
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterEmptyState extends StatelessWidget {
  const _FilterEmptyState({super.key, required this.filter, required this.onViewAll});

  final _AchievementFilter filter;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final textStyles = Theme.of(context).textStyles;

    if (filter == _AchievementFilter.inProgress) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
            Text(
              '目前沒有進行中的成就',
              style: textStyles.titleEmphasis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '試試完成一筆記帳，或看看「全部」。',
              style: textStyles.bodyMuted,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: onViewAll, child: const Text('查看全部')),
          ],
        ),
      );
    }

    final (title, subtitle) = switch (filter) {
      _AchievementFilter.unlocked => ('沒有符合的成就', '試試其他篩選條件。'),
      _AchievementFilter.locked => ('沒有符合的成就', '試試其他篩選條件。'),
      _ => ('沒有符合的成就', null),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Column(
        children: [
          Text(title, style: textStyles.titleEmphasis, textAlign: TextAlign.center),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle, style: textStyles.bodyMuted, textAlign: TextAlign.center),
          ],
          const SizedBox(height: 12),
          TextButton(onPressed: onViewAll, child: const Text('查看全部')),
        ],
      ),
    );
  }
}

class _AchievementGroupSection extends StatelessWidget {
  const _AchievementGroupSection({
    required this.group,
    required this.sectionItems,
    required this.onOpen,
  });

  final _AchievementGroup group;
  final List<AchievementItem> sectionItems;
  final Future<void> Function(AchievementItem item) onOpen;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textStyles;

    if (sectionItems.isEmpty) {
      return const SizedBox.shrink();
    }

    final unlockedInSection = sectionItems.where((item) => item.isUnlocked).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(child: Text(group.title, style: textStyles.titleSmallEmphasis)),
              Text(
                '$unlockedInSection/${sectionItems.length}',
                style: textStyles.labelSmallMuted,
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                for (var index = 0; index < sectionItems.length; index++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: index < sectionItems.length - 1 ? 12 : 0,
                    ),
                    child: _AchievementListRow(
                      item: sectionItems[index],
                      onTap: () => onOpen(sectionItems[index]),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AchievementListRow extends StatelessWidget {
  const _AchievementListRow({required this.item, required this.onTap});

  final AchievementItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textStyles;
    final secretLocked = item.isSecret && !item.isUnlocked;

    String statusLine() {
      if (item.isUnlocked) {
        if (item.completedCount > 1) {
          return '重複解鎖 ×${item.completedCount}';
        }
        if (item.unlockedAt != null) {
          return '已解鎖 · ${DateFormat('y/MM/dd').format(item.unlockedAt!)}';
        }
        return '已解鎖';
      }
      if (item.target > 0) {
        return '${item.current} / ${item.target}';
      }
      return '完成度 ${(item.progress * 100).round()}%';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AchievementBadgeGraphics(
                    size: 60,
                    item: item,
                    showProgressRing: true,
                    glow: false,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: textStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          statusLine(),
                          style: item.isUnlocked
                              ? textStyles.bodySmallMuted
                              : textStyles.bodySmallMuted.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    secretLocked ? Icons.lock_outline : Icons.chevron_right,
                    size: 22,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
