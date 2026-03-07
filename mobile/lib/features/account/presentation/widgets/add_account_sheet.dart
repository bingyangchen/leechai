import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  return showAccountFormSheet(
    context,
    type: type,
    subType: subType,
    subTypeLabel: subTypeLabel,
    icon: icon,
  );
}

Future<bool?> showAccountFormSheet(
  BuildContext context, {
  Account? existingAccount,
  AccountType? type,
  String? subType,
  String? subTypeLabel,
  IconData? icon,
  bool hasEntries = false,
}) {
  final isEdit = existingAccount != null;
  final accountType = type ?? existingAccount!.type;
  final accountSubType = subType ?? existingAccount!.subType;
  final accountSubTypeLabel =
      subTypeLabel ??
      (AssetTypeX.fromName(accountSubType)?.label ??
          LiabilityTypeX.fromName(accountSubType)?.label ??
          accountSubType);
  final accountIcon = isEdit ? (icon ?? existingAccount.displayIcon) : icon!;

  return showAppBottomSheet<bool>(
    context,
    mode: AppBottomSheetMode.scrollable,
    title: isEdit ? '編輯帳戶' : '新增$accountSubTypeLabel帳戶',
    showCloseButton: false,
    initialChildSize: 0.85,
    maxChildSize: 0.95,
    scrollableBuilder: (ctx, scrollController) => _AddAccountForm(
      existingAccount: existingAccount,
      type: accountType,
      subType: accountSubType,
      subTypeLabel: accountSubTypeLabel,
      icon: accountIcon,
      scrollController: scrollController,
      onSuccess: () => Navigator.of(ctx).pop(true),
      hasEntries: hasEntries,
    ),
  );
}

class _AddAccountForm extends StatefulWidget {
  const _AddAccountForm({
    this.existingAccount,
    required this.type,
    required this.subType,
    required this.subTypeLabel,
    required this.icon,
    required this.scrollController,
    required this.onSuccess,
    this.hasEntries = false,
  });

  final Account? existingAccount;
  final AccountType type;
  final String subType;
  final String subTypeLabel;
  final IconData icon;
  final ScrollController scrollController;
  final VoidCallback onSuccess;
  final bool hasEntries;

  @override
  State<_AddAccountForm> createState() => _AddAccountFormState();
}

class _AddAccountFormState extends State<_AddAccountForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  final _amountFocusNode = FocusNode();
  late final TextEditingController _nameController;
  final _nameFocusNode = FocusNode();

  bool _isSubmitting = false;

  bool get _isEdit => widget.existingAccount != null;
  String get _initialName => widget.existingAccount?.name?.trim() ?? '';
  double get _initialAmount => widget.existingAccount?.initialBalance ?? 0;
  bool get _hasUnsavedChanges {
    final name = _nameController.text.trim();
    final amountStr = stripAmount(_amountController.text);
    final amount = double.tryParse(amountStr) ?? 0;
    if (_isEdit) {
      return name != _initialName || amount != _initialAmount;
    }
    return name.isNotEmpty || amount > 0;
  }

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
    final existing = widget.existingAccount;
    final initialName = existing?.name?.trim() ?? '';
    final initialAmount = existing?.initialBalance ?? 0;
    _nameController = TextEditingController(text: initialName);
    _amountController = TextEditingController(
      text: initialAmount != 0 ? formatAmountForDisplay(initialAmount) : '',
    );
    _amountController.addListener(() => setState(() {}));
    _nameController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocusNode.requestFocus();
      if (_isEdit && initialName.isNotEmpty) {
        _nameController.selection = TextSelection.collapsed(offset: initialName.length);
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocusNode.dispose();
    _nameController.dispose();
    _nameFocusNode.dispose();
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
      title: _isEdit ? '放棄編輯？' : '放棄新增？',
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
      if (_isEdit) {
        await AccountRepository.update(
          id: widget.existingAccount!.id,
          name: name,
          initialBalance: amount,
          icon: widget.icon,
        );
      } else {
        await AccountRepository.insert(
          type: widget.type,
          subType: widget.subType,
          name: name,
          initialBalance: amount,
          icon: _iconForSubType(),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }

    if (!mounted) return;
    if (!_isEdit) HapticFeedback.mediumImpact();
    widget.onSuccess();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEdit ? '帳戶已更新' : '帳戶建立成功'),
        behavior: SnackBarBehavior.floating,
      ),
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
    final colorScheme = theme.colorScheme;
    final appTextStyles = AppTextStyles.of(context);
    final isLiability = widget.type == AccountType.liability;
    final amountColor = isLiability
        ? AccountingColors.of(context).liability
        : colorScheme.primary;

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
                          focusNode: _nameFocusNode,
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
                          style: appTextStyles.headlineSmallEmphasis,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(_amountLabel, style: appTextStyles.titleMuted),
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
                              style: appTextStyles.headlineEmphasis.copyWith(
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
                      if (widget.hasEntries && _isEdit) ...[
                        const SizedBox(height: 8),
                        Text('修改初始餘額會影響帳戶最終餘額', style: appTextStyles.bodySmallMuted),
                      ],
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
                                    color: colorScheme.onPrimary,
                                  ),
                                )
                              : Text(_isEdit ? '儲存修改' : '儲存'),
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
