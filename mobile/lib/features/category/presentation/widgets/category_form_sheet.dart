import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/features/account/data/repositories/account.dart'
    show AccountRepository;
import 'package:mobile/features/account/domain/account.dart';
import 'package:mobile/features/category/presentation/constants/category_icon_options.dart';
import 'package:mobile/features/entry/data/repositories/entry.dart'
    show EntryRepository;
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:mobile/shared/utils/snackbar.dart';
import 'package:mobile/shared/widgets/app_bottom_sheet.dart';
import 'package:mobile/shared/widgets/confirm_delete_dialog.dart';

Future<bool?> showCategoryFormSheet(
  BuildContext context, {
  required AccountType categoryType,
  Account? existingCategory,
  VoidCallback? onRestore,
}) {
  final isEdit = existingCategory != null;
  return showAppBottomSheet<bool>(
    context,
    title: isEdit ? '編輯分類' : '新增分類',
    showCloseButton: false,
    mode: AppBottomSheetMode.scrollable,
    initialChildSize: 0.8,
    minChildSize: 0.5,
    maxChildSize: 0.95,
    scrollableBuilder: (_, scrollController) => _CategoryFormSheet(
      categoryType: categoryType,
      existingCategory: existingCategory,
      scrollController: scrollController,
      onSuccess: () => Navigator.of(context).pop(true),
      onRestore: onRestore,
    ),
  );
}

class _CategoryFormSheet extends StatefulWidget {
  const _CategoryFormSheet({
    required this.categoryType,
    this.existingCategory,
    required this.scrollController,
    required this.onSuccess,
    this.onRestore,
  });

  final AccountType categoryType;
  final Account? existingCategory;
  final ScrollController scrollController;
  final VoidCallback onSuccess;
  final VoidCallback? onRestore;

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late IconData _selectedIcon;
  bool _isSubmitting = false;

  bool get _isEdit => widget.existingCategory != null;

  String get _displayName =>
      widget.existingCategory?.name?.trim() ?? widget.existingCategory?.subType ?? '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _displayName);
    _selectedIcon = widget.existingCategory?.displayIcon ?? categoryIconOptions.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _onDelete() async {
    final account = widget.existingCategory!;
    final entries = await EntryRepository.getByAccountId(account.id);
    if (!mounted) return;
    if (entries.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('無法刪除'),
          content: const Text('此分類已有交易紀錄，為確保帳務正確，請先刪除相關紀錄。'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(c);
                widget.onSuccess();
              },
              child: const Text('確定'),
            ),
          ],
        ),
      );
      return;
    }
    final name = account.name ?? account.subType;
    final confirm = await ConfirmDeleteDialog.show(context, content: '確定要刪除 $name 嗎？');
    if (confirm != true || !mounted) return;
    final deleted = await AccountRepository.softDelete(account.id);
    if (!mounted) return;
    if (deleted) {
      final accountId = account.id;
      final messenger = ScaffoldMessenger.of(context);
      widget.onSuccess();
      showReplacingSnackBarForMessenger(
        messenger,
        SnackBar(
          content: const Text('分類已刪除'),
          duration: const Duration(seconds: 4),
          persist: false,
          action: SnackBarAction(
            label: '復原',
            onPressed: () async {
              await AccountRepository.restore(accountId);
              widget.onRestore?.call();
              showReplacingSnackBarForMessenger(
                messenger,
                const SnackBar(
                  content: Text('已復原'),
                  duration: Duration(milliseconds: 1500),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  Future<void> _onSave() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSubmitting = true);
    FocusScope.of(context).unfocus();

    try {
      if (_isEdit) {
        await AccountRepository.update(
          id: widget.existingCategory!.id,
          name: name,
          initialBalance: 0,
          icon: _selectedIcon,
          subType: name,
        );
      } else {
        await AccountRepository.insert(
          type: widget.categoryType,
          subType: name,
          name: name,
          initialBalance: 0,
          icon: _selectedIcon,
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }

    if (!mounted) return;
    if (!_isEdit) HapticFeedback.mediumImpact();
    widget.onSuccess();
    if (!context.mounted) return;
    showReplacingSnackBar(
      context,
      SnackBar(
        content: Text(_isEdit ? '分類更新成功！' : '分類建立成功！'),
        duration: Duration(milliseconds: 1500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: widget.scrollController,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: '分類名稱',
                          hintText: '請輸入分類名稱',
                        ),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _onSave(),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '請輸入分類名稱';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      Text('圖示', style: theme.textStyles.sectionLabel),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 1,
                        ),
                        itemCount: categoryIconOptions.length,
                        itemBuilder: (context, index) {
                          final icon = categoryIconOptions[index];
                          final selected = icon.codePoint == _selectedIcon.codePoint;
                          return Material(
                            color: selected
                                ? theme.colorScheme.primary.withValues(alpha: 0.22)
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: () => setState(() => _selectedIcon = icon),
                              borderRadius: BorderRadius.circular(12),
                              child: Icon(
                                icon,
                                size: 28,
                                color: selected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + viewInsets.bottom),
            child: Row(
              children: [
                if (_isEdit) ...[
                  TextButton(
                    onPressed: _isSubmitting ? null : _onDelete,
                    child: Text('刪除', style: TextStyle(color: theme.colorScheme.error)),
                  ),
                  const Spacer(),
                ] else
                  const Spacer(),
                TextButton(
                  onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _isSubmitting ? null : _onSave,
                  child: _isSubmitting
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : const Text('儲存'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
