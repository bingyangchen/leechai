import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NewRecordPage extends StatefulWidget {
  const NewRecordPage({super.key});

  @override
  State<NewRecordPage> createState() => _NewRecordPageState();
}

class _NewRecordPageState extends State<NewRecordPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _amountFocusNode = FocusNode();
  bool _isSubmitting = false;

  bool get _hasUnsavedChanges => _amountController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocusNode.dispose();
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

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    _amountFocusNode.unfocus();

    // 模擬送出（之後可換成實際 API）
    await Future<void>.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _hasUnsavedChanges) _requestClose();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('新增紀錄'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _isSubmitting ? null : _requestClose,
          ),
        ),
        body: Form(
          key: _formKey,
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _amountController,
                        focusNode: _amountFocusNode,
                        decoration: const InputDecoration(
                          labelText: '金額',
                          hintText: '請輸入金額',
                          prefixIcon: Icon(Icons.attach_money),
                          border: OutlineInputBorder(),
                          filled: true,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: false,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        autofocus: true,
                        enabled: !_isSubmitting,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '請輸入金額';
                          }
                          final amount = double.tryParse(value.trim());
                          if (amount == null || amount <= 0) {
                            return '請輸入有效金額';
                          }
                          return null;
                        },
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isSubmitting
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                ),
                              )
                            : const Text('送出'),
                      ),
                      const SizedBox(height: 24),
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
