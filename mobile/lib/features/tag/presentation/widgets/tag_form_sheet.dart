import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/features/entry/data/repositories/tag.dart' show TagRepository;
import 'package:mobile/shared/widgets/app_bottom_sheet.dart';
import 'package:mobile/shared/widgets/confirm_delete_dialog.dart';

Future<bool?> showTagFormSheet(
  BuildContext context, {
  Map<String, String>? existingTag,
}) {
  final isEdit = existingTag != null;
  return showAppBottomSheet<bool>(
    context,
    title: isEdit ? '編輯標籤' : '新增標籤',
    showCloseButton: false,
    mode: AppBottomSheetMode.scrollable,
    initialChildSize: 0.35,
    minChildSize: 0.25,
    maxChildSize: 0.75,
    scrollableBuilder: (ctx, scrollController) => _TagFormSheet(
      existingTag: existingTag,
      scrollController: scrollController,
      onSuccess: () => Navigator.of(ctx).pop(true),
    ),
  );
}

class _TagFormSheet extends StatefulWidget {
  const _TagFormSheet({
    this.existingTag,
    required this.scrollController,
    required this.onSuccess,
  });

  final Map<String, String>? existingTag;
  final ScrollController scrollController;
  final VoidCallback onSuccess;

  @override
  State<_TagFormSheet> createState() => _TagFormSheetState();
}

class _TagFormSheetState extends State<_TagFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  bool _isSubmitting = false;
  String? _titleError;

  bool get _isEdit => widget.existingTag != null;
  String get _originalTitle => widget.existingTag?['title'] ?? '';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: _originalTitle);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _onDelete() async {
    final id = widget.existingTag!['id']!;
    final title = widget.existingTag!['title']!;
    final count = await TagRepository.getUsageCount(id);
    if (!mounted) return;
    final content = count > 0
        ? '確定要刪除標籤「$title」嗎？\n這將影響 $count 筆記帳紀錄，且刪除後無法復原。'
        : '確定要刪除標籤「$title」嗎？';
    final confirm = await ConfirmDeleteDialog.show(context, content: content);
    if (confirm != true || !mounted) return;
    await TagRepository.softDelete(id);
    if (!mounted) return;
    widget.onSuccess();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('標籤已刪除'), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _onSave() async {
    if (_isSubmitting) return;
    setState(() => _titleError = null);
    if (!_formKey.currentState!.validate()) return;
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    if (_isEdit && title == _originalTitle) {
      widget.onSuccess();
      return;
    }

    final duplicate = await TagRepository.existsByTitle(
      title,
      excludeId: _isEdit ? widget.existingTag!['id'] : null,
    );
    if (!mounted) return;
    if (duplicate) {
      setState(() => _titleError = '此標籤名稱已存在');
      return;
    }

    setState(() => _isSubmitting = true);
    FocusScope.of(context).unfocus();

    try {
      if (_isEdit) {
        await TagRepository.updateTitle(widget.existingTag!['id']!, title);
      } else {
        await TagRepository.getOrCreateByTitle(title);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }

    if (!mounted) return;
    HapticFeedback.mediumImpact();
    widget.onSuccess();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEdit ? '標籤已更新' : '標籤已新增'),
        behavior: SnackBarBehavior.floating,
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
                  child: TextFormField(
                    controller: _titleController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: '標籤名稱',
                      hintText: '請輸入標籤名稱',
                      errorText: _titleError,
                    ),
                    textInputAction: TextInputAction.done,
                    onChanged: (_) {
                      if (_titleError != null) setState(() => _titleError = null);
                    },
                    onFieldSubmitted: (_) => _onSave(),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '請輸入標籤名稱';
                      }
                      return null;
                    },
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
