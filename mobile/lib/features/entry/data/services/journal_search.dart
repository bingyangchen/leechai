import 'package:mobile/features/account/data/repositories/account.dart'
    show AccountRepository;
import 'package:mobile/features/account/domain/account.dart';
import 'package:mobile/features/entry/data/repositories/entry.dart'
    show EntryRepository;
import 'package:mobile/features/entry/domain/entry_type.dart';

class JournalSearchResultPage {
  const JournalSearchResultPage({
    required this.entries,
    required this.entryIdToTagTitles,
  });

  final List<Map<String, Object?>> entries;
  final Map<String, List<String>> entryIdToTagTitles;
}

class JournalSearchService {
  JournalSearchService._();

  static Future<Map<String, Account>> loadAccounts() async {
    final accounts = <String, Account>{};
    for (final account in await AccountRepository.getAll()) {
      accounts[account.id] = account;
    }
    return accounts;
  }

  static Future<JournalSearchResultPage> searchPage({
    required String query,
    required int limit,
    required int offset,
  }) async {
    final entries = await EntryRepository.searchJournalPage(
      query: query,
      matchingTypeNames: _matchingTypeNames(query),
      limit: limit,
      offset: offset,
    );
    final entryIds = entries.map((entry) => entry['id'] as String).toList();
    final entryIdToTagTitles = await EntryRepository.getTagTitlesForEntries(entryIds);
    return JournalSearchResultPage(
      entries: entries,
      entryIdToTagTitles: entryIdToTagTitles,
    );
  }

  static List<String> _matchingTypeNames(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return const [];
    return EntryTypeX.userFacingTypes
        .where(
          (type) =>
              type.name.toLowerCase().contains(normalizedQuery) ||
              type.label.toLowerCase().contains(normalizedQuery),
        )
        .map((type) => type.name)
        .toList();
  }
}
