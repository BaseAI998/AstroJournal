import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/database.dart';
import 'database_provider.dart';

final journalProvider = StateNotifierProvider<JournalNotifier, AsyncValue<List<JournalEntry>>>((ref) {
  return JournalNotifier(ref.watch(databaseProvider));
});

class JournalNotifier extends StateNotifier<AsyncValue<List<JournalEntry>>> {
  final AppDatabase _db;

  JournalNotifier(this._db) : super(const AsyncValue.loading()) {
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    try {
      final entries = await _db.getAllEntries();
      state = AsyncValue.data(entries);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addEntry(JournalEntry entry) async {
    try {
      await _db.addEntry(entry);
      await _loadEntries();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateEntry(JournalEntry entry) async {
    try {
      await _db.updateEntry(entry);
      await _loadEntries();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
