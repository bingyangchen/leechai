import 'package:flutter/material.dart';
import 'package:mobile/features/account/data/repositories/account.dart';
import 'package:mobile/features/account/domain/account.dart';
import 'package:mobile/features/entry/data/repositories/entry.dart' as entry_repo;
import 'package:mobile/features/entry/data/repositories/tag.dart' as tag_repo;
import 'package:mobile/features/entry/domain/entry_account_filter.dart';
import 'package:mobile/features/entry/domain/entry_type.dart';
import 'package:mobile/features/entry/presentation/constants/account_chip_labels.dart';
import 'package:mobile/features/entry/presentation/constants/entry_type_colors.dart';
import 'package:mobile/features/entry/presentation/widgets/account_chips_row.dart';
import 'package:mobile/features/entry/presentation/widgets/account_picker_sheet.dart';
import 'package:mobile/features/entry/presentation/widgets/amount_display_section.dart';
import 'package:mobile/features/entry/presentation/widgets/category_section.dart';
import 'package:mobile/features/entry/presentation/widgets/date_chip_row.dart';
import 'package:mobile/features/entry/presentation/widgets/notes_section.dart';
import 'package:mobile/features/entry/presentation/widgets/tags_section.dart';
import 'package:mobile/shared/utils/amount_input_formatter.dart';
import 'package:mobile/shared/widgets/date_time_picker_sheet.dart';
import 'package:mobile/shared/widgets/discard_changes_dialog.dart';

class NewEntryPage extends StatefulWidget {
  const NewEntryPage({super.key});

  @override
  State<NewEntryPage> createState() => _NewEntryPageState();
}

class _NewEntryPageState extends State<NewEntryPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _amountFocusNode = FocusNode();
  final _tagInputController = TextEditingController();
  final _notesController = TextEditingController();
  late TabController _tabController;
  late PageController _pageController;
  bool _isSubmitting = false;
  EntryType _entryType = EntryType.expense;
  DateTime _selectedDate = DateTime.now();
  String? _selectedAccountId;
  String? _selectedAccountFromId;
  String? _selectedAccountToId;
  final List<String> _tags = [];
  List<Account> _balanceAccounts = [];
  List<Account> _categoryExpenseAccounts = [];
  List<Account> _categoryIncomeAccounts = [];
  int _selectedExpenseCategoryIndex = 0;
  int _selectedIncomeCategoryIndex = 0;

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
    _tabController.addListener(_syncEntryTypeFromTab);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBalanceAccounts();
      _loadCategoryAccounts();
      _amountFocusNode.requestFocus();
    });
  }

  void _syncEntryTypeFromTab() {
    if (!_tabController.indexIsChanging && mounted) {
      final index = _tabController.index;
      setState(() => _entryType = EntryType.values[index]);
      _applyDefaultAccounts();
      _pageController.jumpToPage(index);
    }
  }

  void _onPageChanged(int index) {
    if (_tabController.index != index) {
      _tabController.animateTo(index);
    }
    setState(() => _entryType = EntryType.values[index]);
    _applyDefaultAccounts();
  }

  @override
  void dispose() {
    _tabController.removeListener(_syncEntryTypeFromTab);
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
    final leave = await DiscardChangesDialog.show(context);
    if (mounted && leave == true) Navigator.of(context).pop(false);
  }

  Future<void> _loadBalanceAccounts() async {
    final accounts = await AccountRepository.getBalanceAccounts();
    if (mounted) {
      setState(() => _balanceAccounts = accounts);
      _applyDefaultAccounts();
    }
  }

  Future<void> _loadCategoryAccounts() async {
    final expenseAccounts = await AccountRepository.getByType('expense');
    final incomeAccounts = await AccountRepository.getByType('income');
    if (mounted) {
      setState(() {
        _categoryExpenseAccounts = expenseAccounts;
        _categoryIncomeAccounts = incomeAccounts;
      });
    }
  }

  void _applyDefaultAccounts() {
    if (_entryType.isDualAccount) {
      final fromList = filterAccountsForEntryType(
        _balanceAccounts,
        entryType: _entryType,
        isFrom: true,
      );
      final toList = filterAccountsForEntryType(
        _balanceAccounts,
        entryType: _entryType,
        isFrom: false,
      );
      setState(() {
        _selectedAccountFromId = fromList.isNotEmpty ? fromList.first.id : null;
        if (toList.isEmpty) {
          _selectedAccountToId = null;
        } else {
          final other = toList.where((a) => a.id != _selectedAccountFromId).toList();
          _selectedAccountToId = other.isNotEmpty ? other.first.id : null;
        }
      });
    } else {
      final list = filterAccountsForEntryType(
        _balanceAccounts,
        entryType: _entryType,
        isFrom: _entryType == EntryType.expense,
      );
      setState(() {
        _selectedAccountId = list.isNotEmpty ? list.first.id : null;
      });
    }
  }

  String? _accountName(String? id) {
    if (id == null) return null;
    try {
      return _balanceAccounts.firstWhere((a) => a.id == id).name;
    } catch (_) {
      return null;
    }
  }

  Account? _accountById(String? id) {
    if (id == null) return null;
    try {
      return _balanceAccounts.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  void _openAccountPicker({
    required bool isFrom,
    required void Function(Account) onSelect,
    String? excludeAccountId,
  }) {
    final accounts = filterAccountsForEntryType(
      _balanceAccounts,
      entryType: _entryType,
      isFrom: isFrom,
    );
    showAccountPickerSheet(
      context,
      accounts: accounts,
      onSelect: onSelect,
      excludeAccountId: excludeAccountId,
    );
  }

  void _openAccountPickerSingle() {
    _openAccountPicker(
      isFrom: _entryType == EntryType.expense,
      onSelect: (a) => setState(() => _selectedAccountId = a.id),
    );
  }

  void _openAccountPickerFrom() {
    _openAccountPicker(
      isFrom: true,
      onSelect: (a) => setState(() => _selectedAccountFromId = a.id),
      excludeAccountId: _selectedAccountToId,
    );
  }

  void _openAccountPickerTo() {
    _openAccountPicker(
      isFrom: false,
      onSelect: (a) => setState(() => _selectedAccountToId = a.id),
      excludeAccountId: _selectedAccountFromId,
    );
  }

  ({String debit, String credit})? _getDebitCreditAccountIds() {
    switch (_entryType) {
      case EntryType.expense:
        if (_selectedExpenseCategoryIndex >= _categoryExpenseAccounts.length ||
            _selectedAccountId == null) {
          return null;
        }
        return (
          debit: _categoryExpenseAccounts[_selectedExpenseCategoryIndex].id,
          credit: _selectedAccountId!,
        );
      case EntryType.income:
        if (_selectedIncomeCategoryIndex >= _categoryIncomeAccounts.length ||
            _selectedAccountId == null) {
          return null;
        }
        return (
          debit: _selectedAccountId!,
          credit: _categoryIncomeAccounts[_selectedIncomeCategoryIndex].id,
        );
      case EntryType.transfer:
        if (_selectedAccountFromId == null || _selectedAccountToId == null) return null;
        return (debit: _selectedAccountToId!, credit: _selectedAccountFromId!);
      case EntryType.borrow:
        if (_selectedAccountFromId == null || _selectedAccountToId == null) return null;
        return (debit: _selectedAccountToId!, credit: _selectedAccountFromId!);
      case EntryType.repay:
        if (_selectedAccountFromId == null || _selectedAccountToId == null) return null;
        return (debit: _selectedAccountFromId!, credit: _selectedAccountToId!);
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    final accounts = _getDebitCreditAccountIds();
    if (accounts == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('請選擇帳戶與分類'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final amountStr = stripAmount(_amountController.text);
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) return;

    setState(() => _isSubmitting = true);
    _amountFocusNode.unfocus();

    try {
      final tagIds = <String>[];
      for (final title in _tags) {
        final id = await tag_repo.TagRepository.getOrCreateByTitle(title);
        tagIds.add(id);
      }
      if (!mounted) return;
      await entry_repo.EntryRepository.insert(
        type: _entryType.name,
        debitAccountId: accounts.debit,
        creditAccountId: accounts.credit,
        amount: amount,
        tagIds: tagIds,
        memo: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        occurredAt: _selectedDate,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = EntryTypeColors.forType(_entryType);

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
            child: const Text('捨棄'),
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
              TextButton(onPressed: _submit, child: const Text('送出')),
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
              unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: EntryType.values.map((t) => Tab(text: t.label)).toList(),
              onTap: (index) {
                setState(() => _entryType = EntryType.values[index]);
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
              final pageType = EntryType.values[index];
              final pageColor = EntryTypeColors.forType(pageType);
              return CustomScrollView(
                key: PageStorageKey<int>(index),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverToBoxAdapter(
                    child: AmountDisplaySection(
                      amountController: _amountController,
                      amountFocusNode: _amountFocusNode,
                      typeColor: pageColor,
                      isSubmitting: _isSubmitting,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: DateChipRow(
                      selectedDate: _selectedDate,
                      onDateTap: () async {
                        final picked = await showModalBottomSheet<DateTime>(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (ctx) => DateTimePickerSheet(
                            initial: _selectedDate,
                            onConfirm: (v, {fromDrag = false}) {
                              setState(() => _selectedDate = v);
                              if (!fromDrag) Navigator.of(ctx).pop(v);
                            },
                            onCancel: () => Navigator.of(ctx).pop(),
                          ),
                        );
                        if (picked != null && mounted) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  SliverToBoxAdapter(
                    child: AccountChipsRow(
                      entryType: pageType,
                      singleAccount: _accountById(_selectedAccountId),
                      singleAccountLabel:
                          _accountName(_selectedAccountId) ??
                          accountChipLabel(
                            pageType,
                            isFrom: pageType == EntryType.expense,
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
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverToBoxAdapter(
                    child: pageType == EntryType.expense || pageType == EntryType.income
                        ? CategorySection(
                            categories:
                                (pageType == EntryType.expense
                                        ? _categoryExpenseAccounts
                                        : _categoryIncomeAccounts)
                                    .map((a) => (name: a.subType, icon: a.displayIcon))
                                    .toList(),
                            selectedIndex: pageType == EntryType.expense
                                ? _selectedExpenseCategoryIndex
                                : _selectedIncomeCategoryIndex,
                            onSelected: (index) => setState(() {
                              if (pageType == EntryType.expense) {
                                _selectedExpenseCategoryIndex = index;
                              } else {
                                _selectedIncomeCategoryIndex = index;
                              }
                            }),
                          )
                        : const SizedBox.shrink(),
                  ),
                  SliverToBoxAdapter(
                    child: TagsSection(
                      tags: _tags,
                      inputController: _tagInputController,
                      enabled: !_isSubmitting,
                      onAddTag: (tag) {
                        final t = tag.trim();
                        if (t.isEmpty || _tags.contains(t)) return;
                        tag_repo.TagRepository.getOrCreateByTitle(t).then((_) {
                          if (!mounted) return;
                          setState(() {
                            _tags.add(t);
                            _tagInputController.clear();
                          });
                        });
                      },
                      onRemoveTag: (tag) {
                        setState(() => _tags.remove(tag));
                      },
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: NotesSection(
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
