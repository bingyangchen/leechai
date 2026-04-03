import 'package:mobile/features/account/data/repositories/account.dart'
    show AccountRepository;
import 'package:mobile/features/account/domain/account.dart';
import 'package:mobile/features/entry/data/repositories/entry.dart'
    show EntryRepository;
import 'package:mobile/features/entry/data/repositories/tag.dart' show TagRepository;
import 'package:mobile/features/entry/domain/entry_type.dart';
import 'package:mobile/features/entry/domain/journal_search_context.dart';

class JournalSearchService {
  JournalSearchService._();

  static Future<JournalSearchContext> loadContext() async {
    final rawEntries = await EntryRepository.getAll();
    final entries = rawEntries.where((entry) {
      final typeStr = entry['type'] as String? ?? 'expense';
      final type = EntryType.values.asNameMap()[typeStr];
      return type != EntryType.adjustment;
    }).toList();
    final allAccounts = <String, Account>{};
    for (final account in await AccountRepository.getAll()) {
      allAccounts[account.id] = account;
    }
    final tagIds = <String>{};
    final entryTagIds = <String, List<String>>{};
    for (final entry in entries) {
      final id = entry['id'] as String;
      final ids = await EntryRepository.getTagIdsForEntry(id);
      entryTagIds[id] = ids;
      tagIds.addAll(ids);
    }
    final tagTitles = await TagRepository.getTitlesByIds(tagIds.toList());
    final entryTagTitles = <String, List<String>>{};
    for (final entry in entryTagIds.entries) {
      entryTagTitles[entry.key] = entry.value
          .map((id) => tagTitles[id] ?? '')
          .where((title) => title.isNotEmpty)
          .toList();
    }
    return JournalSearchContext(
      entries: entries,
      accounts: allAccounts,
      entryTagTitles: entryTagTitles,
    );
  }
}
