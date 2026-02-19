import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/constants/record_type_constants.dart';
import 'package:mobile/features/accounting/domain/account_item.dart';
import 'package:mobile/shared/widgets/date_time_picker_sheet.dart';

class NewRecordPage extends StatefulWidget {
  const NewRecordPage({super.key});

  @override
  State<NewRecordPage> createState() => _NewRecordPageState();
}

class _NewRecordPageState extends State<NewRecordPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _amountFocusNode = FocusNode();
  final _tagInputController = TextEditingController();
  final _notesController = TextEditingController();
  late TabController _tabController;
  late PageController _pageController;
  bool _isSubmitting = false;

  RecordType _recordType = RecordType.expense;
  DateTime _selectedDate = DateTime.now();
  int _selectedMainCategoryIndex = 0;
  int? _selectedSubCategoryIndex;
  String? _selectedAccountId;
  String? _selectedAccountFromId;
  String? _selectedAccountToId;
  final List<String> _tags = [];

  bool get _hasUnsavedChanges =>
      _amountController.text.trim().isNotEmpty ||
      _tags.isNotEmpty ||
      _tagInputController.text.trim().isNotEmpty ||
      _notesController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 5, initialIndex: 0);
    _pageController = PageController(initialPage: 0);
    _amountController.addListener(() => setState(() {}));
    _tagInputController.addListener(() => setState(() {}));
    _notesController.addListener(() => setState(() {}));
    _tabController.addListener(_syncRecordTypeFromTab);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _amountFocusNode.requestFocus();
    });
  }

  void _syncRecordTypeFromTab() {
    if (!_tabController.indexIsChanging && mounted) {
      final index = _tabController.index;
      setState(() => _recordType = RecordType.values[index]);
      _pageController.jumpToPage(index);
    }
  }

  void _onPageChanged(int index) {
    if (_tabController.index != index) {
      _tabController.animateTo(index);
    }
    setState(() => _recordType = RecordType.values[index]);
  }

  @override
  void dispose() {
    _tabController.removeListener(_syncRecordTypeFromTab);
    _tabController.dispose();
    _pageController.dispose();
    _amountController.dispose();
    _amountFocusNode.dispose();
    _tagInputController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _requestClose() async {
    if (_isSubmitting) return;
    if (!_hasUnsavedChanges) {
      if (mounted) Navigator.of(context).pop(false);
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('捨棄變更？'),
        content: const Text('有未儲存的變更，確定要離開嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('離開'),
          ),
        ],
      ),
    );
    if (mounted && leave == true) {
      Navigator.of(context).pop(false);
    }
  }

  List<AccountItem> get _accounts => placeholderAccounts;

  String? _accountName(String? id) {
    if (id == null) return null;
    try {
      return _accounts.firstWhere((a) => a.id == id).name;
    } catch (_) {
      return null;
    }
  }

  AccountItem? _accountById(String? id) {
    if (id == null) return null;
    try {
      return _accounts.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  void _openAccountPickerSingle() {
    final list = filterAccountsForRecordType(
      _accounts,
      recordType: _recordType,
      isFrom: _recordType == RecordType.expense,
    );
    _showAccountBottomSheet(
      context,
      list,
      (a) => setState(() => _selectedAccountId = a.id),
    );
  }

  void _openAccountPickerFrom() {
    final list = filterAccountsForRecordType(
      _accounts,
      recordType: _recordType,
      isFrom: true,
    );
    _showAccountBottomSheet(
      context,
      list,
      (a) => setState(() => _selectedAccountFromId = a.id),
    );
  }

  void _openAccountPickerTo() {
    final list = filterAccountsForRecordType(
      _accounts,
      recordType: _recordType,
      isFrom: false,
    );
    _showAccountBottomSheet(
      context,
      list,
      (a) => setState(() => _selectedAccountToId = a.id),
    );
  }

  static void _showAccountBottomSheet(
    BuildContext context,
    List<AccountItem> accounts,
    ValueChanged<AccountItem> onSelect,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => ListView.builder(
          controller: scrollController,
          itemCount: accounts.length,
          itemBuilder: (context, index) {
            final a = accounts[index];
            return ListTile(
              leading: Icon(
                a.displayIcon,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(a.name),
              onTap: () {
                onSelect(a);
                Navigator.of(ctx).pop();
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    _amountFocusNode.unfocus();

    await Future<void>.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = RecordTypeColors.forType(_recordType);

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _hasUnsavedChanges) _requestClose();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('新增紀錄'),
          leading: TextButton(
            onPressed: _isSubmitting ? null : _requestClose,
            child: const Text(
              '捨棄',
              style: TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
          actions: [
            if (_isSubmitting)
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              TextButton(
                onPressed: _submit,
                child: const Text(
                  '送出',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              dividerHeight: 0,
              indicatorColor: typeColor,
              labelColor: typeColor,
              unselectedLabelColor: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: RecordType.values.map((t) => Tab(text: t.label)).toList(),
              onTap: (index) {
                setState(() => _recordType = RecordType.values[index]);
                _pageController.jumpToPage(index);
              },
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: 5,
            itemBuilder: (context, index) {
              final pageType = RecordType.values[index];
              final pageColor = RecordTypeColors.forType(pageType);
              return CustomScrollView(
                key: PageStorageKey<int>(index),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverToBoxAdapter(
                    child: _AmountDisplaySection(
                      amountController: _amountController,
                      amountFocusNode: _amountFocusNode,
                      typeColor: pageColor,
                      isSubmitting: _isSubmitting,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _MetaDataBar(
                      selectedDate: _selectedDate,
                      onDateTap: () async {
                        final picked = await showModalBottomSheet<DateTime>(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (ctx) => DateTimePickerSheet(
                            initial: _selectedDate,
                            onConfirm: (v) => Navigator.of(ctx).pop(v),
                            onCancel: () => Navigator.of(ctx).pop(),
                          ),
                        );
                        if (picked != null && mounted) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                      recordType: pageType,
                      singleAccount: _accountById(_selectedAccountId),
                      singleAccountLabel:
                          _accountName(_selectedAccountId) ??
                          accountChipLabel(
                            pageType,
                            isFrom: pageType == RecordType.expense,
                          ),
                      fromAccount: _accountById(_selectedAccountFromId),
                      toAccount: _accountById(_selectedAccountToId),
                      fromAccountLabel:
                          _accountName(_selectedAccountFromId) ??
                          accountChipLabel(pageType, isFrom: true),
                      toAccountLabel:
                          _accountName(_selectedAccountToId) ??
                          accountChipLabel(pageType, isFrom: false),
                      onAccountTap: _openAccountPickerSingle,
                      onAccountFromTap: _openAccountPickerFrom,
                      onAccountToTap: _openAccountPickerTo,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _CategorySection(
                      selectedMainIndex: _selectedMainCategoryIndex,
                      selectedSubIndex: _selectedSubCategoryIndex,
                      onMainSelected: (index) => setState(() {
                        _selectedMainCategoryIndex = index;
                        _selectedSubCategoryIndex = null;
                      }),
                      onSubSelected: (index) =>
                          setState(() => _selectedSubCategoryIndex = index),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _TagsSection(
                      tags: _tags,
                      inputController: _tagInputController,
                      enabled: !_isSubmitting,
                      onAddTag: (tag) {
                        final t = tag.trim();
                        if (t.isEmpty || _tags.contains(t)) return;
                        setState(() {
                          _tags.add(t);
                          _tagInputController.clear();
                        });
                      },
                      onRemoveTag: (tag) {
                        setState(() => _tags.remove(tag));
                      },
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _NotesSection(
                      controller: _notesController,
                      enabled: !_isSubmitting,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AmountDisplaySection extends StatelessWidget {
  const _AmountDisplaySection({
    required this.amountController,
    required this.amountFocusNode,
    required this.typeColor,
    required this.isSubmitting,
  });

  final TextEditingController amountController;
  final FocusNode amountFocusNode;
  final Color typeColor;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSubmitting ? null : () => amountFocusNode.requestFocus(),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '\$',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w300,
                color: typeColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: IntrinsicHeight(
                child: TextFormField(
                  controller: amountController,
                  focusNode: amountFocusNode,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                    hintText: '0',
                  ),
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w600,
                    color: typeColor,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: false,
                  ),
                  inputFormatters: [
                    _ThousandsSeparatorInputFormatter(),
                  ],
                  enabled: !isSubmitting,
                  validator: (value) {
                    if (value == null || _stripAmount(value).isEmpty) {
                      return '請輸入金額';
                    }
                    final amount = double.tryParse(_stripAmount(value));
                    if (amount == null || amount <= 0) {
                      return '請輸入有效金額';
                    }
                    return null;
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaDataBar extends StatelessWidget {
  const _MetaDataBar({
    required this.selectedDate,
    required this.onDateTap,
    required this.recordType,
    this.singleAccount,
    required this.singleAccountLabel,
    this.fromAccount,
    this.toAccount,
    required this.fromAccountLabel,
    required this.toAccountLabel,
    required this.onAccountTap,
    required this.onAccountFromTap,
    required this.onAccountToTap,
  });

  final DateTime selectedDate;
  final VoidCallback onDateTap;
  final RecordType recordType;
  final AccountItem? singleAccount;
  final String singleAccountLabel;
  final AccountItem? fromAccount;
  final AccountItem? toAccount;
  final String fromAccountLabel;
  final String toAccountLabel;
  final VoidCallback onAccountTap;
  final VoidCallback onAccountFromTap;
  final VoidCallback onAccountToTap;

  static String _formatDateTime(DateTime d) {
    final h24 = d.hour;
    final hour12 = h24 == 0 ? 12 : (h24 > 12 ? h24 - 12 : h24);
    final ampm = h24 < 12 ? 'AM' : 'PM';
    final timeStr =
        '${hour12.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} $ampm';
    final now = DateTime.now();
    if (d.year != now.year) {
      return '${d.year}/${d.month}/${d.day} $timeStr';
    }
    return '${d.month}/${d.day} $timeStr';
  }

  @override
  Widget build(BuildContext context) {
    final isDual = recordType.isDualAccount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _MetaChip(
                icon: Icons.calendar_today_outlined,
                label: _formatDateTime(selectedDate),
                onTap: onDateTap,
              ),
              const SizedBox(width: 12),
              if (isDual) ...[
                _AccountChip(
                  account: fromAccount,
                  label: fromAccountLabel,
                  onTap: onAccountFromTap,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                _AccountChip(
                  account: toAccount,
                  label: toAccountLabel,
                  onTap: onAccountToTap,
                ),
              ] else
                _AccountChip(
                  account: singleAccount,
                  label: singleAccountLabel,
                  onTap: onAccountTap,
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _AccountChip extends StatelessWidget {
  const _AccountChip({
    this.account,
    required this.label,
    required this.onTap,
  });

  final AccountItem? account;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = account?.displayIcon ?? Icons.account_balance_wallet_outlined;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.selectedMainIndex,
    this.selectedSubIndex,
    required this.onMainSelected,
    required this.onSubSelected,
  });

  final int selectedMainIndex;
  final int? selectedSubIndex;
  final ValueChanged<int> onMainSelected;
  final ValueChanged<int> onSubSelected;

  static const List<({String name, IconData icon})> _mainCategories = [
    (name: '飲食', icon: Icons.restaurant),
    (name: '交通', icon: Icons.directions_car),
    (name: '居家', icon: Icons.home),
    (name: '娛樂', icon: Icons.movie),
    (name: '購物', icon: Icons.shopping_bag),
    (name: '其他', icon: Icons.more_horiz),
  ];

  static const Map<int, List<String>> _subCategories = {
    0: ['早餐', '午餐', '晚餐', '飲料', '零食', '超市'],
    1: ['捷運', '公車', '計程車', '油費', '停車'],
    2: ['房租', '水電', '瓦斯', '網路', '傢俱'],
    3: ['電影', '遊戲', '運動', '旅遊'],
    4: ['服飾', '日用品', '3C'],
    5: ['其他'],
  };

  @override
  Widget build(BuildContext context) {
    final subs = _subCategories[selectedMainIndex] ?? ['其他'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '類別',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _mainCategories.length,
              separatorBuilder: (_, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _mainCategories[index];
                final selected = index == selectedMainIndex;
                return Material(
                  color: selected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => onMainSelected(index),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            cat.icon,
                            size: 24,
                            color: selected
                                ? Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            cat.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: selected
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const crossAxisCount = 3;
              const spacing = 8.0;
              final width =
                  (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                  crossAxisCount;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: List.generate(subs.length, (index) {
                  final selected = selectedSubIndex == index;
                  return SizedBox(
                    width: width,
                    child: Material(
                      color: selected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => onSubSelected(index),
                        borderRadius: BorderRadius.circular(12),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              subs[index],
                              style: TextStyle(
                                fontSize: 14,
                                color: selected
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _TagsSection extends StatelessWidget {
  const _TagsSection({
    required this.tags,
    required this.inputController,
    required this.enabled,
    required this.onAddTag,
    required this.onRemoveTag,
  });

  final List<String> tags;
  final TextEditingController inputController;
  final bool enabled;
  final ValueChanged<String> onAddTag;
  final ValueChanged<String> onRemoveTag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '標籤',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          InputDecorator(
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (tags.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (final tag in tags)
                        Chip(
                          label: Text(tag),
                          deleteIcon: Icon(
                            Icons.close,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          onDeleted: enabled ? () => onRemoveTag(tag) : null,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: inputController,
                        enabled: enabled,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: '新增標籤或專案，按 Enter 或 ＋ 加入',
                        ),
                        onSubmitted: (value) => onAddTag(value),
                      ),
                    ),
                    IconButton(
                      onPressed: enabled
                          ? () => onAddTag(inputController.text)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                      style: IconButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _NotesSection extends StatelessWidget {
  const _NotesSection({
    required this.controller,
    required this.enabled,
  });

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '備註',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            enabled: enabled,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: '選填',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
