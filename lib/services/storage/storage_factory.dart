import 'storage_stub.dart'
    if (dart.library.io) 'secure_storage_adapter.dart'
    if (dart.library.html) 'web_storage_adapter.dart';
import '../../core/ports/storage_port.dart';

class StorageFactory {
  static StoragePort create() {
    return getStorageAdapter();
  }
}
