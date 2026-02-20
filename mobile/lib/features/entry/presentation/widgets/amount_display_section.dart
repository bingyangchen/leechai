import 'package:flutter/material.dart';
import 'package:mobile/shared/utils/amount_input_formatter.dart';

class AmountDisplaySection extends StatelessWidget {
  const AmountDisplaySection({
    super.key,
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
                    ThousandsSeparatorInputFormatter(),
                  ],
                  enabled: !isSubmitting,
                  validator: (value) {
                    if (value == null || stripAmount(value).isEmpty) {
                      return '請輸入金額';
                    }
                    final amount = double.tryParse(stripAmount(value));
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
