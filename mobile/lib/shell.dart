import 'package:flutter/material.dart';
import 'package:mobile/features/account/presentation/pages/account_page.dart';
import 'package:mobile/features/entry/presentation/pages/entry_page.dart';
import 'package:mobile/features/entry/presentation/pages/journal_page.dart';
import 'package:mobile/features/profile/presentation/pages/profile_page.dart';
import 'package:mobile/features/statistics/presentation/pages/statistics_page.dart';
import 'package:mobile/shared/theme/app_theme.dart';

class Shell extends StatefulWidget {
  const Shell({super.key, required this.refreshTrigger});
  final ValueNotifier<int> refreshTrigger;

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  static const double _bottomNavBarHeight = 88;
  int _currentIndex = 0;

  List<Widget> _buildPages() => [
    JournalPage(refreshTrigger: widget.refreshTrigger),
    StatisticsPage(
      refreshTrigger: widget.refreshTrigger,
      isPageVisible: _currentIndex == 1,
    ),
    AssetsPage(refreshTrigger: widget.refreshTrigger),
    ProfilePage(
      refreshTrigger: widget.refreshTrigger,
      isPageVisible: _currentIndex == 3,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final navLabelStyle = theme.textStyles.bodySmallMuted;
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _buildPages()),
      floatingActionButton: _currentIndex < 3
          ? FloatingActionButton(
              onPressed: () async {
                final added = await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(builder: (context) => const EntryPage()),
                );
                if (!context.mounted) return;
                if (added == true) {
                  widget.refreshTrigger.value++;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('紀錄已新增'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: SizedBox(
        height: _bottomNavBarHeight,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(top: BorderSide(color: theme.dividerColor)),
          ),
          child: BottomNavigationBar(
            backgroundColor: colorScheme.surface.withValues(alpha: 0),
            elevation: 0,
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: navLabelStyle,
            unselectedLabelStyle: navLabelStyle,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.list_alt_outlined),
                activeIcon: Icon(Icons.list_alt),
                label: '明細',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.pie_chart_outline),
                activeIcon: Icon(Icons.pie_chart),
                label: '統計',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_outlined),
                activeIcon: Icon(Icons.account_balance_wallet),
                label: '資產',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: '個人',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
