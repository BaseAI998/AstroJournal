import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/database.dart';
import 'database_provider.dart';

/// Currently selected origin map id (null = none selected).
final activeOriginMapIdProvider = StateProvider<String?>((ref) => null);

/// All origin maps list.
final originMapListProvider =
    StateNotifierProvider<OriginMapNotifier, AsyncValue<List<OriginMap>>>((ref) {
  return OriginMapNotifier(ref.watch(databaseProvider));
});

/// Entry IDs that belong to the currently active origin map.
final activeOriginMapEntryIdsProvider = Provider<Set<String>>((ref) {
  final activeId = ref.watch(activeOriginMapIdProvider);
  if (activeId == null) return {};
  final mapsState = ref.watch(originMapListProvider);
  return mapsState.whenData((maps) {
    final map = maps.where((m) => m.id == activeId).firstOrNull;
    return map?.entryIds ?? <String>{};
  }).value ?? {};
});

class OriginMapNotifier extends StateNotifier<AsyncValue<List<OriginMap>>> {
  final AppDatabase _db;

  OriginMapNotifier(this._db) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final maps = await _db.getAllOriginMaps();
      state = AsyncValue.data(maps);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveOriginMap(OriginMap map) async {
    try {
      await _db.saveOriginMap(map);
      await _load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteOriginMap(String id) async {
    try {
      await _db.deleteOriginMap(id);
      await _load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
