import 'package:flutter/material.dart';
import 'package:mobile/features/account/data/repositories/account.dart'
    show AccountRepository;
import 'package:mobile/features/account/domain/account.dart';
import 'package:mobile/features/account/domain/asset_type.dart';
import 'package:mobile/features/account/domain/liability_type.dart';
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:mobile/shared/utils/thousand_separator_input_formatter.dart';
import 'package:mobile/shared/widgets/app_bottom_sheet.dart';
import 'package:mobile/shared/widgets/discard_changes_dialog.dart';

Future<bool?> showAddAccountSheet(
  BuildContext context, {
  required AccountType type,
  required String subType,
  required String subTypeLabel,
  required IconData icon,
}) {
  return showAppBottomSheet<bool>(
    context,
    mode: AppBottomSheetMode.scrollable,
    title: '新增$subTypeLabel帳戶',
    showCloseButton: false,
    initialChildSize: 0.6,
    maxChildSize: 0.9,
    scrollableBuilder: (ctx, scrollController) => _AddAccountForm(
      type: type,
      subType: subType,
      subTypeLabel: subTypeLabel,
      icon: icon,
      scrollController: scrollController,
      onSuccess: () => Navigator.of(ctx).pop(true),
    ),
  );
}

class _AddAccountForm extends StatefulWidget {
  const _AddAccountForm({
    required this.type,
    required this.subType,
    required this.subTypeLabel,
    required this.icon,
    required this.scrollController,
    required this.onSuccess,
  });

  final AccountType type;
  final String subType;
  final String subTypeLabel;
  final IconData icon;
  final ScrollController scrollController;
  final VoidCallback onSuccess;

  @override
  State<_AddAccountForm> createState() => _AddAccountFormState();
}

class _AddAccountFormState extends State<_AddAccountForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _amountFocusNode = FocusNode();
  final _nameController = TextEditingController();
  bool _isSubmitting = false;

  bool get _hasUnsavedChanges =>
      _amountController.text.trim().isNotEmpty ||
      _nameController.text.trim().isNotEmpty;

  String get _amountLabel => widget.type == AccountType.liability ? '初始未繳金額' : '初始餘額';

  String get _namePlaceholder {
    switch (widget.subType) {
      case 'bank':
        return '台新銀行-薪轉戶';
      case 'creditCard':
        return '富邦 J 卡';
      case 'cash':
        return '現金';
      case 'epayment':
        return 'Line Pay、街口';
      case 'storedValueCard':
        return '悠遊卡';
      case 'securities':
        return '台股帳戶';
      case 'loan':
        return '房貸';
      default:
        return '輸入帳戶名稱';
    }
  }

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() => setState(() {}));
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocusNode.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _requestClose() async {
    if (_isSubmitting) return;
    if (!_hasUnsavedChanges) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final leave = await DiscardChangesDialog.show(
      context,
      title: '放棄新增？',
      content: '您輸入的資料將遺失。',
      confirmLabel: '放棄',
    );
    if (mounted && leave == true) Navigator.of(context).pop();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    final amountStr = stripAmount(_amountController.text);
    final amount = double.tryParse(amountStr) ?? 0;
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSubmitting = true);
    _amountFocusNode.unfocus();
    FocusScope.of(context).unfocus();

    try {
      await AccountRepository.insert(
        type: widget.type,
        subType: widget.subType,
        name: name,
        initialBalance: amount,
        icon: _iconForSubType(),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }

    if (!mounted) return;
    widget.onSuccess();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('帳戶建立成功'), behavior: SnackBarBehavior.floating),
    );
  }

  IconData? _iconForSubType() {
    final at = AssetTypeX.fromName(widget.subType);
    if (at != null) return at.icon;
    final lt = LiabilityTypeX.fromName(widget.subType);
    if (lt != null) return lt.icon;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLiability = widget.type == AccountType.liability;
    final amountColor = isLiability
        ? AccountingColors.of(context).liability
        : theme.colorScheme.primary;

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _hasUnsavedChanges) _requestClose();
      },
      child: Form(
        key: _formKey,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: CustomScrollView(
            controller: widget.scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: amountColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(widget.icon, size: 32, color: amountColor),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: _namePlaceholder,
                            border: InputBorder.none,
                            enabledBorder: const UnderlineInputBorder(),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: amountColor, width: 2),
                            ),
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                          style:
                              theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ) ??
                              TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.left,
                          enabled: !_isSubmitting,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '請輸入帳戶名稱';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _amountLabel,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _amountController,
                          focusNode: _amountFocusNode,
                          decoration: InputDecoration(
                            hintText: '\$ 0',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w500,
                            color: amountColor,
                          ),
                          textAlign: TextAlign.right,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: false,
                          ),
                          inputFormatters: [ThousandsSeparatorInputFormatter()],
                          enabled: !_isSubmitting,
                          validator: (value) {
                            final raw = value == null ? '' : stripAmount(value);
                            if (raw.isEmpty) return null;
                            final a = double.tryParse(raw);
                            if (a == null || a < 0) return '請輸入有效金額';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
                    top: 24,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isSubmitting ? null : _submit,
                          child: _isSubmitting
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Theme.of(context).colorScheme.onPrimary,
                                  ),
                                )
                              : const Text('儲存'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
