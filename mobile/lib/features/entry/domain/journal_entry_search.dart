import 'package:mobile/features/account/domain/account.dart';
import 'package:mobile/features/entry/domain/entry_type.dart';
import 'package:mobile/features/entry/domain/journal_search_context.dart';
import 'package:mobile/shared/constants/weekday.dart';
import 'package:mobile/shared/utils/thousand_separator_input_formatter.dart';

List<Map<String, Object?>> filterJournalEntriesBySearchQuery({
  required JournalSearchContext context,
  required String query,
}) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return [];
  final out = <Map<String, Object?>>[];
  for (final entry in context.entries) {
    final typeStr = entry['type'] as String? ?? 'expense';
    final type = EntryType.values.asNameMap()[typeStr];
    if (type == EntryType.adjustment) continue;
    final haystack = _journalEntrySearchHaystack(
      entry: entry,
      type: type ?? EntryType.expense,
      accounts: context.accounts,
      entryTagTitles: context.entryTagTitles,
    );
    if (haystack.contains(normalized)) {
      out.add(entry);
    }
  }
  return out;
}

String _journalEntrySearchHaystack({
  required Map<String, Object?> entry,
  required EntryType type,
  required Map<String, Account> accounts,
  required Map<String, List<String>> entryTagTitles,
}) {
  final rawParts = <String>[];
  final memo = entry['memo'] as String?;
  if (memo != null && memo.trim().isNotEmpty) {
    rawParts.add(memo);
  }
  final debitId = entry['debit_account_id'] as String? ?? '';
  final creditId = entry['credit_account_id'] as String? ?? '';
  final debitAccount = accounts[debitId];
  final creditAccount = accounts[creditId];
  rawParts.add(_categoryLabelForSearch(type, debitAccount, creditAccount));
  final accountLabel = _accountLabelForSearch(type, debitAccount, creditAccount);
  if (accountLabel != null && accountLabel.isNotEmpty) {
    rawParts.add(accountLabel);
  }
  if (debitAccount?.name != null) rawParts.add(debitAccount!.name!);
  if (debitAccount?.subType.isNotEmpty == true) rawParts.add(debitAccount!.subType);
  if (creditAccount?.name != null) rawParts.add(creditAccount!.name!);
  if (creditAccount?.subType.isNotEmpty == true) rawParts.add(creditAccount!.subType);
  final amount = (entry['amount'] as num?)?.toDouble() ?? 0.0;
  final amountDisplay = formatAmountForDisplay(amount);
  rawParts.add(amountDisplay);
  rawParts.add(stripAmount(amountDisplay));
  final amountTwoDecimals = formatAmountForDisplay(amount, decimalPlaces: 2);
  rawParts.add(amountTwoDecimals);
  rawParts.add(stripAmount(amountTwoDecimals));
  _appendOccurredAtSearchParts(entry, rawParts);
  final entryId = entry['id'] as String? ?? '';
  for (final tagTitle in entryTagTitles[entryId] ?? const <String>[]) {
    if (tagTitle.isNotEmpty) rawParts.add(tagTitle);
  }
  return _joinHaystackParts(rawParts);
}

String _joinHaystackParts(List<String> rawParts) {
  final seenLowercase = <String>{};
  final distinct = <String>[];
  for (final part in rawParts) {
    final trimmed = part.trim();
    if (trimmed.isEmpty) continue;
    final key = trimmed.toLowerCase();
    if (seenLowercase.contains(key)) continue;
    seenLowercase.add(key);
    distinct.add(trimmed);
  }
  return distinct.join(' ').toLowerCase();
}

void _appendOccurredAtSearchParts(Map<String, Object?> entry, List<String> parts) {
  final occurredAt = entry['occurred_at'] as String? ?? '';
  final DateTime local;
  try {
    local = DateTime.parse(occurredAt).toLocal();
  } catch (_) {
    return;
  }
  final year = local.year;
  final month = local.month;
  final day = local.day;
  final monthPadded = month.toString().padLeft(2, '0');
  final dayPadded = day.toString().padLeft(2, '0');
  parts.add('$year-$monthPadded-$dayPadded');
  parts.add('$year/$monthPadded/$dayPadded');
  parts.add('$year/$month/$day');
  parts.add('$year年$month月$day日');
  final weekdayLabel = chineseWeekdayLabels[local.weekday - 1];
  parts.add(weekdayLabel);
  parts.add('週$weekdayLabel');
}

String _categoryLabelForSearch(EntryType type, Account? debit, Account? credit) {
  switch (type) {
    case EntryType.expense:
      return debit?.subType.isNotEmpty == true ? debit!.subType : (debit?.name ?? '支出');
    case EntryType.income:
      return credit?.subType.isNotEmpty == true
          ? credit!.subType
          : (credit?.name ?? '收入');
    case EntryType.adjustment:
      return type.label;
    case EntryType.transfer:
    case EntryType.borrow:
    case EntryType.repay:
      return type.label;
  }
}

String? _accountLabelForSearch(EntryType type, Account? debit, Account? credit) {
  switch (type) {
    case EntryType.expense:
      return credit?.name ?? credit?.subType;
    case EntryType.income:
      return debit?.name ?? debit?.subType;
    case EntryType.transfer:
    case EntryType.borrow:
    case EntryType.repay:
      if (debit != null && credit != null) {
        return '${credit.name ?? credit.subType} → ${debit.name ?? debit.subType}';
      }
      return null;
    case EntryType.adjustment:
      return null;
  }
}
