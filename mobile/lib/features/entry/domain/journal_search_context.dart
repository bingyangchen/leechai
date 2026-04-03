import 'package:mobile/features/account/domain/account.dart';

class JournalSearchContext {
  const JournalSearchContext({
    required this.entries,
    required this.accounts,
    required this.entryTagTitles,
  });

  final List<Map<String, Object?>> entries;
  final Map<String, Account> accounts;
  final Map<String, List<String>> entryTagTitles;
}
