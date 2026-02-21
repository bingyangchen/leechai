import 'package:flutter/material.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/features/account/domain/account.dart';
import 'package:mobile/features/account/domain/asset_type.dart';
import 'package:mobile/features/account/domain/liability_type.dart';

class AccountRepository {
  AccountRepository._();

  static const String _table = 'account';

  static Future<List<Account>> getAll() async {
    final db = await AppDatabase.database;
    final rows = await db.query(
      _table,
      where: 'deleted_at IS NULL',
      orderBy: 'created_at ASC',
    );
    return rows.map(_rowToAccount).toList();
  }

  static Account _rowToAccount(Map<String, Object?> row) {
    final id = row['id'] as String;
    final name = row['name'] as String;
    final typeStr = row['type'] as String? ?? 'asset';
    final subTypeStr = row['sub_type'] as String? ?? '';

    final type = _parseAccountType(typeStr);
    final icon = _iconFor(typeStr, subTypeStr);
    final isPaymentMethod = _isPaymentMethod(typeStr, subTypeStr);

    return Account(
      id: id,
      name: name,
      type: type,
      isPaymentMethod: isPaymentMethod,
      icon: icon,
    );
  }

  static bool _isPaymentMethod(String typeStr, String subTypeStr) {
    if (typeStr == 'asset') {
      final t = AssetTypeX.fromName(subTypeStr);
      return t?.isPaymentMethod ?? false;
    }
    if (typeStr == 'liability') {
      final t = LiabilityTypeX.fromName(subTypeStr);
      return t?.isPaymentMethod ?? false;
    }
    return false;
  }

  static AccountType _parseAccountType(String typeStr) {
    switch (typeStr) {
      case 'liability':
        return AccountType.liability;
      case 'asset':
      default:
        return AccountType.asset;
    }
  }

  static IconData? _iconFor(String typeStr, String subTypeStr) {
    if (typeStr == 'asset') {
      final assetType = AssetTypeX.fromName(subTypeStr);
      return assetType?.icon;
    }
    if (typeStr == 'liability') {
      final liabilityType = LiabilityTypeX.fromName(subTypeStr);
      return liabilityType?.icon;
    }
    return null;
  }
}
