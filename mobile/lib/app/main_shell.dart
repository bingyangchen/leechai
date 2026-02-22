import 'package:flutter/material.dart';
import 'package:mobile/features/account/presentation/pages/assets_page.dart';
import 'package:mobile/features/entry/presentation/pages/journal_page.dart';
import 'package:mobile/features/entry/presentation/pages/new_entry_page.dart';
import 'package:mobile/features/settings/presentation/pages/settings_page.dart';
import 'package:mobile/features/statistics/presentation/pages/analysis_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const double _bottomNavBarHeight = 88;
  int _currentIndex = 0;
  late final PageController _pageController;
  final ValueNotifier<int> _journalRefreshTrigger = ValueNotifier(0);
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _pages = [
      JournalPage(refreshTrigger: _journalRefreshTrigger),
      AnalysisPage(),
      AssetsPage(),
      SettingsPage(),
    ];
  }

  @override
  void dispose() {
    _journalRefreshTrigger.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        children: _pages,
      ),
      floatingActionButton: _currentIndex < 3
          ? FloatingActionButton(
              onPressed: () async {
                final added = await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(builder: (context) => const NewEntryPage()),
                );
                if (!context.mounted) return;
                if (added == true) {
                  _journalRefreshTrigger.value++;
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
            color: Theme.of(context).colorScheme.surface,
            border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            currentIndex: _currentIndex,
            onTap: (index) {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: const TextStyle(fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: '明細'),
              BottomNavigationBarItem(icon: Icon(Icons.pie_chart_outline), label: '統計'),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_outlined),
                label: '資產',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: '設定'),
            ],
          ),
        ),
      ),
    );
  }
}
