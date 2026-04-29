import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../services/api_service.dart';
import '../../../services/biometric_service.dart';
import '../../../core/ports/storage_port.dart';
import '../../../services/storage/storage_factory.dart';
import '../../persistence/sqlite/database_helper.dart';
import '../styles/app_styles.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final ApiService _apiService;
  final _biometricService = BiometricService();
  final StoragePort _storage = StorageFactory.create();
  bool _isLoading = false;
  bool _showRegister = false;
  bool _showForgotPassword = false;
  bool _rememberMe = true;
  bool _canUseBiometrics = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _apiService = GetIt.instance.get<ApiService>();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final canCheck = await _biometricService.canCheckBiometrics();
    final hasToken = await _storage.containsKey(key: 'jwt_token');
    
    if (mounted) {
      setState(() => _canUseBiometrics = canCheck && hasToken);
    }

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
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        rememberMe: _rememberMe,
      );

      if (response != null && response.containsKey('token')) {
        widget.onLoginSuccess();
      } else {
        _showErrorDialog('Login Error', 'Respuesta inesperada del servidor.');
      }
    } catch (e) {
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
            const Text('Verify your network connection and try again.'),
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
    if (_showForgotPassword) {
      return ForgotPasswordScreen(onBackToLogin: () => setState(() => _showForgotPassword = false));
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
                'NATAVE',
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
                fillColor: WidgetStateProperty.resolveWith<Color>((states) =>
                  states.contains(WidgetState.selected) ? AppColors.primaryBlue : Colors.grey),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (val) => setState(() => _rememberMe = val ?? false),
              ),
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
                ),
                const Text('Usar Biometría', style: TextStyle(fontSize: 12, color: AppColors.primaryBlue)),
              ],
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _showForgotPassword = true),
                child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(fontSize: 13, color: AppColors.secondaryText)),
              ),
              TextButton(
                onPressed: () => setState(() => _showRegister = true),
                child: const Text('¿No tienes cuenta? Regístrate aquí'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  await DatabaseHelper().clearDatabase();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Base de datos local eliminada'), backgroundColor: Colors.orange),
                    );
                  }
                },
                child: const Text('⚠️ Borrar Base de Datos Local', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
