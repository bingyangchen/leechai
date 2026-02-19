import 'package:flutter/material.dart';
import 'package:mobile/core/constants/record_type_constants.dart';
import 'package:mobile/features/accounting/domain/account_item.dart';
import 'package:mobile/features/accounting/presentation/widgets/account_chips_row.dart';
import 'package:mobile/features/accounting/presentation/widgets/account_picker_sheet.dart';
import 'package:mobile/features/accounting/presentation/widgets/amount_display_section.dart';
import 'package:mobile/features/accounting/presentation/widgets/category_section.dart';
import 'package:mobile/features/accounting/presentation/widgets/date_chip_row.dart';
import 'package:mobile/features/accounting/presentation/widgets/notes_section.dart';
import 'package:mobile/features/accounting/presentation/widgets/tags_section.dart';
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
      _applyDefaultAccounts();
      _amountFocusNode.requestFocus();
    });
  }

  void _syncRecordTypeFromTab() {
    if (!_tabController.indexIsChanging && mounted) {
      final index = _tabController.index;
      setState(() => _recordType = RecordType.values[index]);
      _applyDefaultAccounts();
      _pageController.jumpToPage(index);
    }
  }

  void _onPageChanged(int index) {
    if (_tabController.index != index) {
      _tabController.animateTo(index);
    }
    setState(() => _recordType = RecordType.values[index]);
    _applyDefaultAccounts();
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

  void _applyDefaultAccounts() {
    if (_recordType.isDualAccount) {
      final fromList = filterAccountsForRecordType(
        _accounts,
        recordType: _recordType,
        isFrom: true,
      );
      final toList = filterAccountsForRecordType(
        _accounts,
        recordType: _recordType,
        isFrom: false,
      );
      setState(() {
        _selectedAccountFromId = fromList.isNotEmpty ? fromList.first.id : null;
        if (toList.isEmpty) {
          _selectedAccountToId = null;
        } else {
          final other = toList
              .where((a) => a.id != _selectedAccountFromId)
              .toList();
          _selectedAccountToId = other.isNotEmpty ? other.first.id : null;
        }
      });
    } else {
      final list = filterAccountsForRecordType(
        _accounts,
        recordType: _recordType,
        isFrom: _recordType == RecordType.expense,
      );
      setState(() {
        _selectedAccountId = list.isNotEmpty ? list.first.id : null;
      });
    }
  }

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
    showAccountPickerSheet(
      context,
      accounts: list,
      onSelect: (a) => setState(() => _selectedAccountId = a.id),
    );
  }

  void _openAccountPickerFrom() {
    final list = filterAccountsForRecordType(
      _accounts,
      recordType: _recordType,
      isFrom: true,
    );
    showAccountPickerSheet(
      context,
      accounts: list,
      onSelect: (a) => setState(() => _selectedAccountFromId = a.id),
      excludeAccountId: _selectedAccountToId,
    );
  }

  void _openAccountPickerTo() {
    final list = filterAccountsForRecordType(
      _accounts,
      recordType: _recordType,
      isFrom: false,
    );
    showAccountPickerSheet(
      context,
      accounts: list,
      onSelect: (a) => setState(() => _selectedAccountToId = a.id),
      excludeAccountId: _selectedAccountFromId,
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
                            onConfirm: (v) => Navigator.of(ctx).pop(v),
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
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverToBoxAdapter(
                    child: CategorySection(
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
                    child: TagsSection(
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
