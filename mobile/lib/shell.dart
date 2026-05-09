import 'package:flutter/material.dart';
import 'package:mobile/features/account/presentation/pages/account_page.dart';
import 'package:mobile/features/entry/presentation/pages/entry_page.dart';
import 'package:mobile/features/entry/presentation/pages/journal_page.dart';
import 'package:mobile/features/profile/presentation/pages/profile_page.dart';
import 'package:mobile/features/statistics/presentation/pages/statistics_page.dart';
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:mobile/shared/utils/snackbar.dart';

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
    JournalPage(
      refreshTrigger: widget.refreshTrigger,
      isPageVisible: _currentIndex == 0,
    ),
    StatisticsPage(
      refreshTrigger: widget.refreshTrigger,
      isPageVisible: _currentIndex == 1,
    ),
    AccountPage(refreshTrigger: widget.refreshTrigger),
    ProfilePage(
      refreshTrigger: widget.refreshTrigger,
      isPageVisible: _currentIndex == 3,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  showReplacingSnackBar(
                    context,
                    const SnackBar(
                      content: Text('紀錄新增成功！'),
                      duration: Duration(milliseconds: 1500),
                    ),
                  );
                }
              },
              child: const Icon(Icons.add_rounded),
            )
          : null,
      bottomNavigationBar: SizedBox(
        height: _bottomNavBarHeight,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(top: BorderSide(color: theme.dividerColor)),
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: navLabelStyle,
            unselectedLabelStyle: navLabelStyle,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.list_alt_outlined),
                activeIcon: Icon(Icons.list_alt_rounded),
                label: '明細',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_outlined),
                activeIcon: Icon(Icons.bar_chart_rounded),
                label: '總覽',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_outlined),
                activeIcon: Icon(Icons.account_balance_wallet_rounded),
                label: '帳戶',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: '個人',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
