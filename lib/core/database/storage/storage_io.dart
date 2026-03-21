import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'storage_stub.dart';

class _FileAppStorage implements AppStorage {
  File? _file;

  Future<File> _getFile() async {
    final existing = _file;
    if (existing != null) return existing;

    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'astro_journal.json'));
    _file = file;
    return file;
  }

  @override
  Future<String?> read() async {
    final file = await _getFile();
    final exists = await file.exists();
    if (!exists) return null;
    return file.readAsString();
  }

  @override
  Future<void> write(String value) async {
    final file = await _getFile();
    await file.writeAsString(value);
  }

  @override
  Future<void> clear() async {
    final file = await _getFile();
    final exists = await file.exists();
    if (exists) {
      await file.delete();
    }
  }
}

AppStorage createAppStorage() => _FileAppStorage();
