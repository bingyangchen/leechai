import 'package:flutter/material.dart';
import 'package:mobile/core/constants/record_type_constants.dart';

enum AccountType {
  asset,
  securities,
  liability,
}

class AccountItem {
  const AccountItem({
    required this.id,
    required this.name,
    required this.type,
    this.isPaymentMethod = false,
    this.icon,
  });

  final String id;
  final String name;
  final AccountType type;
  final bool isPaymentMethod;
  final IconData? icon;

  IconData get displayIcon {
    if (icon != null) return icon!;
    switch (type) {
      case AccountType.asset:
        return isPaymentMethod ? Icons.account_balance_wallet : Icons.savings;
      case AccountType.securities:
        return Icons.show_chart;
      case AccountType.liability:
        return Icons.credit_card;
    }
  }
}

List<AccountItem> filterAccountsForRecordType(
  List<AccountItem> all, {
  required RecordType recordType,
  required bool isFrom,
}) {
  switch (recordType) {
    case RecordType.expense:
      return all.where((a) => a.isPaymentMethod).toList();
    case RecordType.income:
      return all.where((a) => a.type == AccountType.asset).toList();
    case RecordType.transfer:
      return all
          .where(
            (a) =>
                a.type == AccountType.asset || a.type == AccountType.securities,
          )
          .toList();
    case RecordType.borrow:
      if (isFrom) {
        return all.where((a) => a.type == AccountType.liability).toList();
      }
      return all.where((a) => a.type == AccountType.asset).toList();
    case RecordType.repay:
      if (isFrom) {
        return all.where((a) => a.type == AccountType.asset).toList();
      }
      return all.where((a) => a.type == AccountType.liability).toList();
  }
}

String accountChipLabel(RecordType recordType, {required bool isFrom}) {
  switch (recordType) {
    case RecordType.expense:
      return '支付工具';
    case RecordType.income:
      return '存入帳戶';
    case RecordType.transfer:
      return isFrom ? '轉出' : '轉入';
    case RecordType.borrow:
      return isFrom ? '債權人' : '存入';
    case RecordType.repay:
      return isFrom ? '付款源' : '還債';
  }
}

List<AccountItem> get placeholderAccounts {
  return [
    const AccountItem(
      id: 'cash',
      name: '現金',
      type: AccountType.asset,
      isPaymentMethod: true,
    ),
    const AccountItem(
      id: 'bank_ctbc',
      name: '中信銀行',
      type: AccountType.asset,
      isPaymentMethod: true,
    ),
    const AccountItem(
      id: 'bank_cathay',
      name: '國泰世華',
      type: AccountType.asset,
      isPaymentMethod: true,
    ),
    const AccountItem(
      id: 'linepay',
      name: 'Line Pay',
      type: AccountType.asset,
      isPaymentMethod: true,
    ),
    const AccountItem(
      id: 'jkopay',
      name: '街口',
      type: AccountType.asset,
      isPaymentMethod: true,
    ),
    const AccountItem(
      id: 'easycard',
      name: '悠遊卡',
      type: AccountType.asset,
      isPaymentMethod: true,
    ),
    const AccountItem(
      id: 'cc_cathay',
      name: '國泰信用卡',
      type: AccountType.liability,
      isPaymentMethod: true,
    ),
    const AccountItem(
      id: 'cc_other',
      name: '玉山信用卡',
      type: AccountType.liability,
      isPaymentMethod: true,
    ),
    const AccountItem(
      id: 'stock',
      name: '股票帳戶',
      type: AccountType.securities,
      isPaymentMethod: false,
    ),
    const AccountItem(
      id: 'fund',
      name: '基金帳戶',
      type: AccountType.securities,
      isPaymentMethod: false,
    ),
    const AccountItem(
      id: 'loan_house',
      name: '房貸',
      type: AccountType.liability,
      isPaymentMethod: false,
    ),
    const AccountItem(
      id: 'loan_friend',
      name: '欠朋友 A',
      type: AccountType.liability,
      isPaymentMethod: false,
    ),
  ];
}
