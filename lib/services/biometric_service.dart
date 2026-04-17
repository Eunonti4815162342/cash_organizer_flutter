import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

// Import local_auth only on mobile/desktop platforms
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  // Lazy initialization - only creates on non-web platforms
  Object? _auth;

  Object? _getAuth() {
    if (kIsWeb) return null;
    if (_auth == null) {
      try {
        _auth = LocalAuthentication();
      } catch (_) {
        return null;
      }
    }
    return _auth;
  }

  Future<bool> canCheckBiometrics() async {
    if (kIsWeb) return false;

    try {
      final auth = _getAuth();
      if (auth == null) return false;

      final localAuth = auth as LocalAuthentication;
      return await localAuth.canCheckBiometrics || await localAuth.isDeviceSupported();
    } on PlatformException catch (e) {
      print('[BiometricService] Error checking biometrics: $e');
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate({required String localizedReason}) async {
    if (kIsWeb) return false;

    try {
      final auth = _getAuth();
      if (auth == null) return false;

      final localAuth = auth as LocalAuthentication;
      return await localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      print('[BiometricService] Authentication error: $e');
      return false;
    } catch (_) {
      return false;
    }
  }
}
