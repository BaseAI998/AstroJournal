import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/database.dart';
import '../core/services/ai_service.dart';
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

  /// Send a message to the AI and get a response.
  /// If [userMessage] is null, triggers the AI opening message (first visit).
  Future<String> sendAIMessage(String entryId, Profile profile, {String? userMessage}) async {
    final currentState = state;
    if (currentState is! AsyncData<List<JournalEntry>>) {
      throw Exception('日记数据未加载');
    }

    final entries = currentState.value;
    final entryIndex = entries.indexWhere((e) => e.id == entryId);
    if (entryIndex == -1) throw Exception('日记不存在');

    final entry = entries[entryIndex];
    final aiService = AIService();

    // Add user message to conversation first (if provided)
    List<AIMessage> updatedConversation = [...entry.aiConversation];
    if (userMessage != null) {
      updatedConversation.add(AIMessage(
        role: 'user',
        text: userMessage,
        createdAt: DateTime.now(),
      ));
    }

    // Call AI
    final reply = await aiService.chat(
      profile: profile,
      entry: entry,
      history: updatedConversation,
    );

    // Add AI reply
    updatedConversation.add(AIMessage(
      role: 'assistant',
      text: reply,
      createdAt: DateTime.now(),
    ));

    final updatedEntry = entry.copyWith(aiConversation: updatedConversation);
    await _db.updateEntry(updatedEntry);
    await _loadEntries();

    return reply;
  }
}
