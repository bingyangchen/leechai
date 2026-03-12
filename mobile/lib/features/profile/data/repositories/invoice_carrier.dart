import 'package:shared_preferences/shared_preferences.dart';

const _keyInvoiceCarrier = 'invoice_carrier';

class InvoiceCarrierRepository {
  Future<String?> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyInvoiceCarrier);
  }

  Future<bool> save(String? value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value == null || value.isEmpty) {
        await prefs.remove(_keyInvoiceCarrier);
      } else {
        await prefs.setString(_keyInvoiceCarrier, value);
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
