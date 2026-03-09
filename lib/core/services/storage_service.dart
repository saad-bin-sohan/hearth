abstract class StorageService {
  Future<String?> readString(String key);
  Future<void> writeString(String key, String value);
  Future<void> delete(String key);
}

class InMemoryStorageService implements StorageService {
  final Map<String, String> _memory = <String, String>{};

  @override
  Future<void> delete(String key) async {
    _memory.remove(key);
  }

  @override
  Future<String?> readString(String key) async {
    return _memory[key];
  }

  @override
  Future<void> writeString(String key, String value) async {
    _memory[key] = value;
  }
}
