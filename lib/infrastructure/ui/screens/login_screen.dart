import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import '../../../services/auth_service.dart';
import '../../../services/biometric_service.dart';
import '../styles/app_styles.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AuthService _authService;
  final _biometricService = BiometricService();
  final _storage = const FlutterSecureStorage();
  bool _isLoading = false;
  bool _showRegister = false;
  bool _rememberMe = true;
  bool _canUseBiometrics = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _authService = GetIt.instance.get<AuthService>();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final canCheck = await _biometricService.canCheckBiometrics();
    final hasToken = await _storage.containsKey(key: 'jwt_token');
    
    if (mounted) {
      setState(() => _canUseBiometrics = canCheck && hasToken);
    }

    // Auto-lanzar biometría si es posible para mayor comodidad
    if (_canUseBiometrics) {
      _handleBiometricLogin();
    }
  }

  Future<void> _handleBiometricLogin() async {
    final authenticated = await _biometricService.authenticate(
      localizedReason: 'Escanea tu huella o usa FaceID para ingresar',
    );

    if (authenticated && mounted) {
      widget.onLoginSuccess();
    }
  }

  Future<void> _handleLogin() async {
    print('[LoginScreen] Attempting login for: ${_emailController.text}');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        rememberMe: _rememberMe,
      );

      print('[LoginScreen] Auth Login Result: ${response != null}');
      if (response != null && response.containsKey('token')) {
        print('[LoginScreen] Token received, saving to storage...');
        await _storage.write(key: 'jwt_token', value: response['token']);
        print('[LoginScreen] Token saved, notifying success...');
        widget.onLoginSuccess();
      } else {
        _showErrorDialog('Login Error', 'Respuesta inesperada del servidor.');
      }
    } catch (e) {
      print('[LoginScreen] Unexpected Exception: $e');
      _showErrorDialog('Connection Error', e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Technical Details:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
              child: Text(message, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
            ),
            const SizedBox(height: 16),
            const Text('Verify Tailscale connection and server IP (100.86.48.34:8085)'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showRegister) {
      return RegisterScreen(onBackToLogin: () => setState(() => _showRegister = false));
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_balance_wallet, size: 64, color: AppColors.primaryBlue),
              const SizedBox(height: 16),
              const Text(
                'CashKeep',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                title: const Text('Recordar en este dispositivo', style: TextStyle(fontSize: 13)),
                value: _rememberMe,
                activeColor: AppColors.primaryBlue,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (val) => setState(() => _rememberMe = val ?? false),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                    : const Text('INGRESAR'),
                ),
              ),
              if (_canUseBiometrics) ...[
                const SizedBox(height: 16),
                IconButton(
                  icon: const Icon(Icons.fingerprint, size: 48, color: AppColors.primaryBlue),
                  onPressed: _handleBiometricLogin,
                  tooltip: 'Ingresar con biometría',
                ),
                const Text('Usar Biometría', style: TextStyle(fontSize: 12, color: AppColors.primaryBlue)),
              ],
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _showRegister = true),
                child: const Text('¿No tienes cuenta? Regístrate aquí'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
