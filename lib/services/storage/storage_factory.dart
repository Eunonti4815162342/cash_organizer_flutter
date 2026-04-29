import 'package:flutter/foundation.dart';
import '../../core/ports/storage_port.dart';
import 'secure_storage_adapter.dart';
import 'web_storage_adapter.dart';

class StorageFactory {
  static StoragePort create() {
    // In Web non-secure context (HTTP), FlutterSecureStorage fails.
    // We use kIsWeb to provide a fallback.
    if (kIsWeb) {
      return WebStorageAdapter();
    }
    return SecureStorageAdapter();
  }
}
