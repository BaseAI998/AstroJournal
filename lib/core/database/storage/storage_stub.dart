abstract class AppStorage {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
}

AppStorage createAppStorage() {
  throw UnsupportedError('No storage implementation found for this platform.');
}
