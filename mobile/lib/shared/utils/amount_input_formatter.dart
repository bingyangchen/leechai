import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

String stripAmount(String value) => value.replaceAll(',', '').trim();

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  ThousandsSeparatorInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.replaceAll(',', '');
    final buffer = StringBuffer();
    var hasDot = false;
    var decimalCount = 0;
    for (var i = 0; i < raw.length; i++) {
      final c = raw[i];
      if (c == '.') {
        if (hasDot) break;
        hasDot = true;
        buffer.write(c);
      } else if (c.codeUnitAt(0) >= 0x30 && c.codeUnitAt(0) <= 0x39) {
        if (hasDot) {
          if (decimalCount >= 2) continue;
          decimalCount++;
        }
        buffer.write(c);
      }
    }
    final valid = buffer.toString();
    final formatted = _addThousandsSeparators(valid);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static final _integerFormat = NumberFormat('#,##0');

  static String _addThousandsSeparators(String numStr) {
    if (numStr.isEmpty) return numStr;
    final parts = numStr.split('.');
    final intPart = parts[0].isEmpty ? '0' : parts[0];
    final decPart = parts.length > 1 ? parts[1] : '';
    final formatted = _integerFormat.format(int.tryParse(intPart) ?? 0);
    return decPart.isEmpty ? formatted : '$formatted.$decPart';
  }
}
