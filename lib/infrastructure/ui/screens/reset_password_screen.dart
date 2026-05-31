import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../services/api_service.dart';
import '../styles/app_styles.dart';
import '../widgets/app_components.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final VoidCallback onSuccess;

  const ResetPasswordScreen({super.key, required this.email, required this.onSuccess});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  late final ApiService _apiService;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _apiService = GetIt.instance.get<ApiService>();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    final token = _tokenController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (token.isEmpty) {
      setState(() => _error = 'Introduce el código recibido por email');
      return;
    }
    if (password.length < 8) {
      setState(() => _error = 'La contraseña debe tener al menos 8 caracteres');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Las contraseñas no coinciden');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final success = await _apiService.resetPassword(token, password);
      if (!mounted) return;
      if (success) {
        _showSuccessAndReturn();
      } else {
        setState(() => _error = 'Código inválido o expirado. Solicita uno nuevo.');
      }
    } catch (e) {
      setState(() => _error = 'Error de conexión. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessAndReturn() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('¡Contraseña actualizada!'),
          ],
        ),
        content: const Text('Tu contraseña ha sido restablecida. Ya puedes iniciar sesión.'),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.of(context).pop();
              widget.onSuccess();
            },
            child: const Text('INICIAR SESIÓN'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                const Icon(Icons.key, size: 64, color: AppColors.primaryBlue),
                const SizedBox(height: 16),
                const Text(
                  'Nueva contraseña',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                ),
                const SizedBox(height: 8),
                Text(
                  'Revisa tu email (${widget.email}) e introduce el código junto con tu nueva contraseña.',
                  style: const TextStyle(fontSize: 13, color: AppColors.secondaryText),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                AppTextField(
                  controller: _tokenController,
                  label: 'Código recibido por email',
                  hint: 'Introduce el código',
                  prefixIcon: Icons.vpn_key_outlined,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _passwordController,
                  label: 'Nueva contraseña',
                  hint: '••••••••',
                  prefixIcon: Icons.lock_outline,
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _confirmController,
                  label: 'Confirmar contraseña',
                  hint: '••••••••',
                  prefixIcon: Icons.lock_reset,
                  obscureText: true,
                  errorText: _error,
                ),
                const SizedBox(height: 32),
                AppButton(
                  label: 'Restablecer contraseña',
                  isLoading: _isLoading,
                  onPressed: _handleReset,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    '← Volver',
                    style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
