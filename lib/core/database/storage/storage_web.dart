import 'package:web/web.dart' as web;

import 'storage_stub.dart';

class _LocalStorageAppStorage implements AppStorage {
  static const _key = 'astro_journal_db';

  @override
  Future<String?> read() async {
    return web.window.localStorage.getItem(_key);
  }

  @override
  Future<void> write(String value) async {
    web.window.localStorage.setItem(_key, value);
  }

  @override
  Future<void> clear() async {
    web.window.localStorage.removeItem(_key);
  }
}

AppStorage createAppStorage() => _LocalStorageAppStorage();
