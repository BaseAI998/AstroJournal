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

  Future<void> deleteEntries(Set<String> ids) async {
    try {
      await _db.deleteEntries(ids);
      await _loadEntries();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addComment(String entryId, String text) async {
    try {
      final currentState = state;
      if (currentState is! AsyncData<List<JournalEntry>>) return;

      final entries = currentState.value;
      final entryIndex = entries.indexWhere((e) => e.id == entryId);
      if (entryIndex == -1) return;

      final entry = entries[entryIndex];
      final newComment = JournalComment(
        text: text,
        createdAt: DateTime.now(),
      );

      final updatedEntry = entry.copyWith(
        comments: [...entry.comments, newComment],
      );

      await _db.updateEntry(updatedEntry);
      await _loadEntries();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteComment(String entryId, int commentIndex) async {
    try {
      final currentState = state;
      if (currentState is! AsyncData<List<JournalEntry>>) return;

      final entries = currentState.value;
      final entryIdx = entries.indexWhere((e) => e.id == entryId);
      if (entryIdx == -1) return;

      final entry = entries[entryIdx];
      if (commentIndex < 0 || commentIndex >= entry.comments.length) return;

      final updatedComments = [...entry.comments]..removeAt(commentIndex);
      final updatedEntry = entry.copyWith(comments: updatedComments);

      await _db.updateEntry(updatedEntry);
      await _loadEntries();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
