import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/features/account/data/repositories/account.dart'
    show AccountRepository;
import 'package:mobile/features/account/domain/account.dart';
import 'package:mobile/features/entry/data/repositories/entry.dart'
    show EntryRepository;
import 'package:mobile/features/entry/data/repositories/tag.dart' show TagRepository;
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
import 'package:mobile/shared/utils/thousand_separator_input_formatter.dart';
import 'package:mobile/shared/widgets/app_bottom_sheet.dart';
import 'package:mobile/shared/widgets/confirm_delete_dialog.dart';
import 'package:mobile/shared/widgets/date_time_picker_sheet.dart';
import 'package:mobile/shared/widgets/discard_changes_dialog.dart';

class EntryPage extends StatefulWidget {
  const EntryPage({super.key, this.entryId});
  final String? entryId;

  @override
  State<EntryPage> createState() => _EntryPageState();
}

class _EntryPageState extends State<EntryPage> with SingleTickerProviderStateMixin {
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

  String? _originalAmountDisplay;
  DateTime? _originalDate;
  String? _originalAccountId;
  String? _originalAccountFromId;
  String? _originalAccountToId;
  int? _originalExpenseCategoryIndex;
  int? _originalIncomeCategoryIndex;
  List<String>? _originalTags;
  String? _originalNotes;
  EntryType? _originalEntryType;

  bool get _isEditMode => widget.entryId != null;

  bool get _hasUnsavedChanges {
    if (_isEditMode) {
      if (_originalEntryType == null) return false;
      if (_entryType != _originalEntryType) return true;
      if (_amountController.text.trim() != (_originalAmountDisplay ?? '')) return true;
      if (_selectedDate != _originalDate) return true;
      if (_selectedAccountId != _originalAccountId) return true;
      if (_selectedAccountFromId != _originalAccountFromId) return true;
      if (_selectedAccountToId != _originalAccountToId) return true;
      if (_selectedExpenseCategoryIndex != (_originalExpenseCategoryIndex ?? 0)) {
        return true;
      }
      if (_selectedIncomeCategoryIndex != (_originalIncomeCategoryIndex ?? 0)) {
        return true;
      }
      if (_notesController.text.trim() != (_originalNotes ?? '')) return true;
      final orig = _originalTags ?? [];
      if (_tags.length != orig.length) return true;
      for (var i = 0; i < _tags.length; i++) {
        if (_tags[i] != orig[i]) return true;
      }
      if (_tagInputController.text.trim().isNotEmpty) return true;
      return false;
    }
    return _amountController.text.trim().isNotEmpty ||
        _tags.isNotEmpty ||
        _tagInputController.text.trim().isNotEmpty ||
        _notesController.text.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      vsync: this,
      length: EntryTypeX.userFacingTypes.length,
      initialIndex: 0,
    );
    _pageController = PageController(initialPage: 0);
    _amountController.addListener(() => setState(() {}));
    _tagInputController.addListener(() => setState(() {}));
    _notesController.addListener(() => setState(() {}));
    _tabController.addListener(_syncEntryTypeFromTab);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
      if (!_isEditMode) _amountFocusNode.requestFocus();
    });
  }

  Future<void> _loadInitialData() async {
    await _loadBalanceAccounts();
    await _loadCategoryAccounts();
    if (_isEditMode && widget.entryId != null && mounted) {
      await _loadEntryForEdit(widget.entryId!);
    }
  }

  Future<void> _loadEntryForEdit(String entryId) async {
    final entry = await EntryRepository.getById(entryId);
    if (entry == null || !mounted) return;
    final tagIds = await EntryRepository.getTagIdsForEntry(entryId);
    final tagTitlesMap = await TagRepository.getTitlesByIds(tagIds);
    final tagTitles = tagIds
        .map((id) => tagTitlesMap[id])
        .where((t) => t != null && t.isNotEmpty)
        .cast<String>()
        .toList();

    final typeStr = entry['type'] as String? ?? 'expense';
    final type = EntryType.values.asNameMap()[typeStr] ?? EntryType.expense;
    if (type == EntryType.adjustment) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('這是系統自動調整的紀錄，無法編輯唷！'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
        Navigator.of(context).pop();
      });
      return;
    }
    final typeIndex = EntryTypeX.userFacingTypes.indexOf(type);
    final amount = (entry['amount'] as num?)?.toDouble() ?? 0.0;
    final occurredAtStr = entry['occurred_at'] as String?;
    DateTime occurredAt = DateTime.now();
    if (occurredAtStr != null) {
      try {
        occurredAt = DateTime.parse(occurredAtStr).toLocal();
      } catch (_) {}
    }
    final memo = entry['memo'] as String? ?? '';
    final debitId = entry['debit_account_id'] as String? ?? '';
    final creditId = entry['credit_account_id'] as String? ?? '';

    if (!mounted) return;
    setState(() {
      _entryType = type;
      _amountController.text = formatAmountForDisplay(amount);
      _selectedDate = occurredAt;
      _notesController.text = memo;
      _tags.clear();
      _tags.addAll(tagTitles);
      switch (type) {
        case EntryType.adjustment:
          return;
        case EntryType.expense:
          _selectedAccountId = creditId;
          final idx = _categoryExpenseAccounts.indexWhere((a) => a.id == debitId);
          _selectedExpenseCategoryIndex = idx >= 0
              ? idx
              : 0.clamp(0, _categoryExpenseAccounts.length - 1);
          break;
        case EntryType.income:
          _selectedAccountId = debitId;
          final idx = _categoryIncomeAccounts.indexWhere((a) => a.id == creditId);
          _selectedIncomeCategoryIndex = idx >= 0
              ? idx
              : 0.clamp(0, _categoryIncomeAccounts.length - 1);
          break;
        case EntryType.transfer:
        case EntryType.borrow:
        case EntryType.repay:
          _selectedAccountFromId = creditId;
          _selectedAccountToId = debitId;
          break;
      }
      _originalEntryType = type;
      _originalAmountDisplay = _amountController.text.trim();
      _originalDate = _selectedDate;
      _originalAccountId = _selectedAccountId;
      _originalAccountFromId = _selectedAccountFromId;
      _originalAccountToId = _selectedAccountToId;
      _originalExpenseCategoryIndex = _selectedExpenseCategoryIndex;
      _originalIncomeCategoryIndex = _selectedIncomeCategoryIndex;
      _originalTags = List<String>.from(_tags);
      _originalNotes = _notesController.text.trim();
    });
    _tabController.animateTo(typeIndex);
    _pageController.jumpToPage(typeIndex);
  }

  void _syncEntryTypeFromTab() {
    if (!_tabController.indexIsChanging && mounted) {
      final index = _tabController.index;
      final newType = EntryTypeX.userFacingTypes[index];
      final didChangeType = newType != _entryType;
      setState(() => _entryType = newType);
      if (didChangeType) _applyDefaultAccounts();
      _pageController.jumpToPage(index);
    }
  }

  void _onPageChanged(int index) {
    if (_tabController.index != index) {
      _tabController.animateTo(index);
    }
    final newType = EntryTypeX.userFacingTypes[index];
    final didChangeType = newType != _entryType;
    setState(() => _entryType = newType);
    if (didChangeType) _applyDefaultAccounts();
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

  Future<void> _requestDelete() async {
    if (_isSubmitting || !_isEditMode || widget.entryId == null) return;
    final confirmed = await ConfirmDeleteDialog.show(context, content: '確定要刪除這筆紀錄嗎？');
    if (confirmed != true || !mounted) return;
    setState(() => _isSubmitting = true);
    try {
      await EntryRepository.softDelete(widget.entryId!);
      if (!mounted) return;
      Navigator.of(context).pop(<String, String>{'deleted': widget.entryId!});
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
      if (!_isEditMode) _applyDefaultAccounts();
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
      onSelect: (a) {
        AccountRepository.updateLastUsedAt(a.id);
        setState(() => _selectedAccountId = a.id);
      },
    );
  }

  void _openAccountPickerFrom() {
    _openAccountPicker(
      isFrom: true,
      onSelect: (a) {
        AccountRepository.updateLastUsedAt(a.id);
        setState(() => _selectedAccountFromId = a.id);
      },
      excludeAccountId: _selectedAccountToId,
    );
  }

  void _openAccountPickerTo() {
    _openAccountPicker(
      isFrom: false,
      onSelect: (a) {
        AccountRepository.updateLastUsedAt(a.id);
        setState(() => _selectedAccountToId = a.id);
      },
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
      case EntryType.borrow:
      case EntryType.repay:
        if (_selectedAccountFromId == null || _selectedAccountToId == null) return null;
        return (debit: _selectedAccountToId!, credit: _selectedAccountFromId!);
      case EntryType.adjustment:
        return null;
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    final accounts = _getDebitCreditAccountIds();
    if (accounts == null) {
      if (mounted) {
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('記得選擇帳戶與分類唷！'),
            backgroundColor: theme.colorScheme.error,
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
        final id = await TagRepository.getOrCreateByTitle(title);
        tagIds.add(id);
      }
      if (!mounted) return;
      final memo = _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim();
      if (_isEditMode && widget.entryId != null) {
        await EntryRepository.update(
          id: widget.entryId!,
          type: _entryType.name,
          debitAccountId: accounts.debit,
          creditAccountId: accounts.credit,
          amount: amount,
          tagIds: tagIds,
          memo: memo,
          occurredAt: _selectedDate,
        );
      } else {
        await EntryRepository.insert(
          type: _entryType.name,
          debitAccountId: accounts.debit,
          creditAccountId: accounts.credit,
          amount: amount,
          tagIds: tagIds,
          memo: memo,
          occurredAt: _selectedDate,
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }

    if (!mounted) return;
    if (!_isEditMode) HapticFeedback.mediumImpact();
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = EntryTypeColors.forType(context, _entryType);
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _hasUnsavedChanges) _requestClose();
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: kToolbarHeight,
          title: Text(_isEditMode ? '編輯紀錄' : '新增紀錄'),
          leading: TextButton(
            onPressed: _isSubmitting ? null : _requestClose,
            child: const Text('捨棄'),
          ),
          actions: [
            if (_isEditMode)
              IconButton(
                onPressed: _isSubmitting ? null : _requestDelete,
                icon: const Icon(Icons.delete_outline),
                tooltip: '刪除',
              ),
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
            child: IgnorePointer(
              ignoring: _isEditMode,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                dividerHeight: 0,
                indicatorColor: typeColor,
                labelColor: typeColor,
                unselectedLabelColor: _isEditMode
                    ? Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.38)
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: EntryTypeX.userFacingTypes
                    .map((t) => Tab(text: t.label))
                    .toList(),
                onTap: (index) {
                  _pageController.jumpToPage(index);
                },
              ),
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          child: PageView.builder(
            controller: _pageController,
            physics: _isEditMode ? const NeverScrollableScrollPhysics() : null,
            onPageChanged: _onPageChanged,
            itemCount: EntryTypeX.userFacingTypes.length,
            itemBuilder: (context, index) {
              final pageType = EntryTypeX.userFacingTypes[index];
              final pageColor = EntryTypeColors.forType(context, pageType);
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
                        final picked = await showAppBottomSheet<DateTime>(
                          context,
                          mode: AppBottomSheetMode.static,
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
                        TagRepository.getOrCreateByTitle(t).then((_) {
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
