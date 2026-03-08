import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile/features/account/data/repositories/account.dart'
    show AccountRepository;
import 'package:mobile/features/account/domain/account.dart';
import 'package:mobile/features/category/presentation/widgets/category_form_sheet.dart';
import 'package:mobile/shared/theme/app_theme.dart';

class CategoryManagementPage extends StatefulWidget {
  const CategoryManagementPage({super.key, this.refreshTrigger});
  final ValueListenable<int>? refreshTrigger;

  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Future<List<Account>>? _expenseFuture;
  Future<List<Account>>? _incomeFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    _loadCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadCategories() {
    setState(() {
      _expenseFuture = AccountRepository.getByType('expense');
      _incomeFuture = AccountRepository.getByType('income');
    });
  }

  AccountType get _currentType =>
      _tabController.index == 0 ? AccountType.expense : AccountType.income;

  void _onCategoryChanged() {
    _loadCategories();
    (widget.refreshTrigger as ValueNotifier<int>?)?.value++;
  }

  Future<void> _onAddCategory() async {
    final updated = await showCategoryFormSheet(context, categoryType: _currentType);
    if (updated == true && mounted) _onCategoryChanged();
  }

  Future<void> _onTapCategory(Account category) async {
    final updated = await showCategoryFormSheet(
      context,
      categoryType: _currentType,
      existingCategory: category,
    );
    if (updated == true && mounted) _onCategoryChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('分類管理'),
        toolbarHeight: kToolbarHeight,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(icon: const Icon(Icons.add), onPressed: _onAddCategory),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          dividerColor: theme.colorScheme.outline.withValues(alpha: 0.2),
          tabs: const [
            Tab(text: '支出'),
            Tab(text: '收入'),
          ],
          onTap: (_) => setState(() {}),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CategoryList(future: _expenseFuture!, onTap: _onTapCategory),
          _CategoryList(future: _incomeFuture!, onTap: _onTapCategory),
        ],
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({required this.future, required this.onTap});

  final Future<List<Account>> future;
  final ValueChanged<Account> onTap;

  static const double _iconSize = 40;
  static const double _iconRadius = 12;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<List<Account>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snapshot.data ?? [];
        if (list.isEmpty) {
          return Center(child: Text('尚無分類', style: theme.textStyles.bodyLargeMuted));
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          itemCount: list.length,
          separatorBuilder: (context, index) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            final category = list[index];
            final name = category.name ?? category.subType;
            return Material(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: Container(
                  width: _iconSize,
                  height: _iconSize,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(_iconRadius),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    category.displayIcon,
                    size: 24,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                title: Text(name),
                trailing: Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
                onTap: () => onTap(category),
              ),
            );
          },
        );
      },
    );
  }
}
