import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/database.dart';
import 'database_provider.dart';

final profileProvider = StateNotifierProvider<ProfileNotifier, AsyncValue<Profile?>>((ref) {
  return ProfileNotifier(ref.watch(databaseProvider));
});

class ProfileNotifier extends StateNotifier<AsyncValue<Profile?>> {
  final AppDatabase _db;

  ProfileNotifier(this._db) : super(const AsyncValue.loading()) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _db.getProfile();
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveProfile(Profile profile) async {
    try {
      await _db.saveProfile(profile);
      await _loadProfile();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
