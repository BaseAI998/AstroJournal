import 'dart:html' as html;

import 'storage_stub.dart';

class _LocalStorageAppStorage implements AppStorage {
  static const _key = 'astro_journal_db';

  @override
  Future<String?> read() async {
    return html.window.localStorage[_key];
  }

  @override
  Future<void> write(String value) async {
    html.window.localStorage[_key] = value;
  }

  @override
  Future<void> clear() async {
    html.window.localStorage.remove(_key);
  }
}

AppStorage createAppStorage() => _LocalStorageAppStorage();
