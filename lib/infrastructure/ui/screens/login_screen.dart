import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../services/api_service.dart';
import '../../../services/biometric_service.dart';
import '../../../core/ports/storage_port.dart';
import '../../../services/storage/storage_factory.dart';
import '../../persistence/sqlite/database_helper.dart';
import '../styles/app_styles.dart';
import '../widgets/app_components.dart';
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
    final bool isCredentialError = message.toLowerCase().contains('401') ||
        message.toLowerCase().contains('unauthorized') ||
        message.toLowerCase().contains('invalid');
    final String friendlyMessage = isCredentialError
        ? 'Email o contraseña incorrectos. Comprueba tus datos e inténtalo de nuevo.'
        : 'No se pudo conectar al servidor. Verifica tu conexión e inténtalo de nuevo.';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Error de acceso'),
          ],
        ),
        content: Text(friendlyMessage),
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
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_balance_wallet, size: 72, color: AppColors.primaryBlue),
                const SizedBox(height: 16),
                const Text(
                  'NATAVE',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryBlue, letterSpacing: 2),
                ),
                const SizedBox(height: 32),
                AppTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'tu@email.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: '••••••••',
                  prefixIcon: Icons.lock_outline,
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Recordar en este dispositivo', style: TextStyle(fontSize: 13, color: AppColors.primaryText)),
                  value: _rememberMe,
                  activeColor: AppColors.primaryBlue,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (val) => setState(() => _rememberMe = val ?? false),
                ),
                const SizedBox(height: 32),
                AppButton(
                  label: 'Ingresar',
                  isLoading: _isLoading,
                  onPressed: _handleLogin,
                ),
                if (_canUseBiometrics) ...[
                  const SizedBox(height: 20),
                  IconButton(
                    icon: const Icon(Icons.fingerprint, size: 48, color: AppColors.primaryBlue),
                    onPressed: _handleBiometricLogin,
                  ),
                  const Text('USAR BIOMETRÍA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryBlue, letterSpacing: 1)),
                ],
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() => _showForgotPassword = true),
                  child: const Text('¿OLVIDASTE TU CONTRASEÑA?', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondaryText, letterSpacing: 0.5)),
                ),
                TextButton(
                  onPressed: () => setState(() => _showRegister = true),
                  child: const Text('¿NO TIENES CUENTA? REGÍSTRATE AQUÍ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryBlue, letterSpacing: 0.5)),
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
                  child: const Text('⚠️ BORRAR BASE DE DATOS LOCAL', style: TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
