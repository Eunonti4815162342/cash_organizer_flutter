// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../../core/ports/storage_port.dart';

/// Web storage adapter using window.localStorage directly.
/// Avoids shared_preferences plugin which is unreliable on web release builds.
class WebStorageAdapter implements StoragePort {
  @override
  Future<void> write({required String key, required String value}) async {
    html.window.localStorage[key] = value;
  }

  @override
  Future<String?> read({required String key}) async {
    return html.window.localStorage[key];
  }

  @override
  Future<bool> containsKey({required String key}) async {
    return html.window.localStorage.containsKey(key);
  }

  @override
  Future<void> delete({required String key}) async {
    html.window.localStorage.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    html.window.localStorage.clear();
  }
}

StoragePort getStorageAdapter() => WebStorageAdapter();
