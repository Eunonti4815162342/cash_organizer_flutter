import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' show join;
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart' show getDatabasesPath;
import 'core/logger/app_logger.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'infrastructure/ui/styles/app_styles.dart';
import 'infrastructure/ui/screens/dashboard_screen.dart';
import 'infrastructure/ui/screens/transaction_list_screen.dart';
import 'infrastructure/ui/screens/account_transactions_screen.dart';
import 'infrastructure/ui/screens/reports_list_screen.dart';
import 'infrastructure/ui/screens/category_list_screen.dart';
import 'infrastructure/ui/screens/login_screen.dart';
import 'services/api_service.dart';
import 'services/config_service.dart';
import 'services/connectivity_service.dart';
import 'service_locator.dart';
import 'config/environment_factory.dart';
import 'services/storage/storage_factory.dart';
import 'services/api/api_client.dart';
import 'infrastructure/persistence/sqlite/database_helper.dart';

// Importación condicional
import 'services/background_sync.dart'
    if (dart.library.io) 'services/background_sync_mobile.dart'
    if (dart.library.html) 'services/background_sync_web.dart';

final ValueNotifier<Locale> _appLocale = ValueNotifier(const Locale('en'));

/// Lee el claim 'sub' (email) de un JWT sin validar su firma.
/// La firma la valida siempre el backend en cada petición autenticada;
/// esto es sólo una comprobación local de "¿es de la sesión esperada?".
String? _extractJwtEmail(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final claims = jsonDecode(payload) as Map<String, dynamic>;
    return claims['sub'] as String?;
  } catch (_) {
    return null;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load runtime configuration from assets/config.json
  await ConfigService.init();
  // Initialize environment: use production to connect to deployed backend
  EnvironmentFactory.init(type: EnvironmentType.production);
  setupServiceLocator();
  if (!kIsWeb) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
  ConnectivityService().initialize();
  final syncManager = getSyncManager();
  await syncManager.initialize();
  syncManager.scheduleTask();
  runApp(ValueListenableBuilder<Locale>(
    valueListenable: _appLocale,
    builder: (context, locale, child) => NataveApp(locale: locale),
  ));
}

class NataveApp extends StatefulWidget {
  final Locale locale;
  const NataveApp({super.key, required this.locale});
  @override
  State<NataveApp> createState() => _NataveAppState();
}

class _NataveAppState extends State<NataveApp> {
  bool _isLoggedIn = false;
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }
  Future<void> _checkLoginStatus() async {
    setState(() => _isLoading = true);
    try {
      final storage = StorageFactory.create();
      final token = await storage.read(key: 'jwt_token');

      if (token != null) {
        // Confiamos en la sesión guardada (con o sin conexión) siempre que el
        // email del token coincida con el de la última sesión iniciada: así
        // evitamos mostrar los datos cacheados de otra cuenta si el token
        // quedase desincronizado. Si luego el token resulta inválido/expirado,
        // las peticiones autenticadas ya lo gestionan con un 401 propio.
        final storedEmail = await storage.read(key: 'user_email');
        final tokenEmail = _extractJwtEmail(token);
        if (tokenEmail != null && tokenEmail == storedEmail) {
          setState(() {
            _isLoggedIn = true;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Error checking login status: $e');
    }

    // Token ausente/inválido o email desincronizado: no confiamos en la
    // sesión guardada. Limpiamos también la caché local (SQLite + token en
    // memoria) para que, si a continuación entra un usuario distinto en el
    // mismo dispositivo, no vea datos cacheados de la sesión anterior (ver
    // el bug de la transacción "Alimentacion" que sobrevivía a un logout
    // implícito como este).
    try {
      final storage = StorageFactory.create();
      await storage.delete(key: 'jwt_token');
      await storage.delete(key: 'user_email');
      ApiClient.clearTokenCache();
      if (!kIsWeb) await DatabaseHelper().clearAllData();
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NATAVE',
      debugShowCheckedModeBanner: false,
      locale: widget.locale,
      localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      supportedLocales: const [Locale('en'), Locale('es'), Locale('pt')],
      theme: ThemeData(
        fontFamily: 'AppFont',
        primaryColor: AppColors.primaryBlue,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryBlue,
          primary: AppColors.primaryBlue,
          surface: AppColors.cardBackground,
          surfaceContainerHighest: AppColors.windowBackground,
        ),
        scaffoldBackgroundColor: AppColors.scaffoldBackground,
        dividerColor: AppColors.divider,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontFamily: 'AppFont',
            fontSize: 18,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.cardBackground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.divider),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: false,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintStyle: const TextStyle(
            fontFamily: 'AppFont',
            fontSize: 13,
            color: AppColors.secondaryText,
          ),
          labelStyle: const TextStyle(
            fontFamily: 'AppFont',
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlue,
            letterSpacing: 1.1,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.expenseRed),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.expenseRed, width: 1.5),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(
              fontFamily: 'AppFont',
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryBlue,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(
              fontFamily: 'AppFont',
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titleTextStyle: const TextStyle(
            fontFamily: 'AppFont',
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
          contentTextStyle: const TextStyle(
            fontFamily: 'AppFont',
            fontSize: 14,
            color: AppColors.primaryText,
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.primaryBlue;
            return null;
          }),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        chipTheme: ChipThemeData(
          selectedColor: AppColors.primaryBlue,
          backgroundColor: Colors.grey.shade100,
          labelStyle: const TextStyle(fontFamily: 'AppFont', fontSize: 10, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          contentTextStyle: const TextStyle(fontFamily: 'AppFont', fontSize: 13),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        popupMenuTheme: PopupMenuThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          textStyle: const TextStyle(fontFamily: 'AppFont', fontSize: 13, color: AppColors.primaryText),
        ),
      ),
      home: _isLoading 
        ? const Scaffold(body: Center(child: CircularProgressIndicator()))
        : _isLoggedIn ? const ResponsiveMainLayout() : LoginScreen(onLoginSuccess: () => setState(() => _isLoggedIn = true)),
    );
  }
}

class ResponsiveMainLayout extends StatefulWidget {
  const ResponsiveMainLayout({super.key});
  @override
  State<ResponsiveMainLayout> createState() => _ResponsiveMainLayoutState();
}

class _ResponsiveMainLayoutState extends State<ResponsiveMainLayout> {
  late final ApiService _apiService;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _apiService = getIt<ApiService>();
  }

  List<Widget> get _screens => [
    const DashboardScreen(),
    const TransactionListScreen(),
    const AccountTransactionsScreen(),
    const ReportsListScreen(),
    const CategoryListScreen(),
  ];

  String _getPageTitle(AppLocalizations l10n) {
    switch (_selectedIndex) {
      case 0: return l10n.dashboard;
      case 1: return l10n.transactions;
      case 2: return l10n.accounts;
      case 3: return l10n.reports;
      case 4: return l10n.categories;
      default: return 'NATAVE';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      appBar: _buildAppBar(l10n, isMobile),
      drawer: isMobile ? _buildDrawer(l10n) : null,
      body: SafeArea(
        top: false, 
        child: Row(
          children: [
            if (!isMobile) _buildSidebar(l10n),
            Expanded(
              child: Column(
                children: [
                  _buildWhiteToolbar(),
                  _OfflineBanner(),
                  Expanded(
                    child: Container(color: const Color(0xFFEAEAEA), child: _screens[_selectedIndex]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n, bool isMobile) {
    return AppBar(
      backgroundColor: AppColors.primaryBlue,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      title: Text(_getPageTitle(l10n), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w400)),
      actions: [
        if (!isMobile) ...[_buildLanguageToggle(), IconButton(icon: const Icon(Icons.sync, size: 20), onPressed: () => setState(() {}))],
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildDrawer(AppLocalizations l10n) {
    return Drawer(
      child: Column(
        children: [
          Container(
            height: 120, width: double.infinity, color: AppColors.primaryBlue,
            padding: const EdgeInsets.only(top: 40),
            child: Center(child: Text(l10n.appTitle, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildSidebarItem(0, Icons.dashboard_outlined, l10n.dashboard),
                _buildSidebarSection('OPERATIONS'),
                _buildSidebarItem(2, Icons.account_balance_wallet_outlined, l10n.accounts),
                _buildSidebarItem(1, Icons.list_alt_outlined, l10n.transactions),
                _buildSidebarSection('INFORMATION'),
                _buildSidebarItem(3, Icons.bar_chart_outlined, l10n.reports),
                _buildSidebarItem(4, Icons.category_outlined, l10n.categories),
                const Divider(),
                _buildBackupSidebarItem(l10n),
                _buildLanguageSidebarItem(l10n),
                ListTile(
                  leading: const Icon(Icons.logout, size: 20, color: Colors.redAccent),
                  title: const Text('Logout', style: TextStyle(fontSize: 13, color: Colors.redAccent)),
                  onTap: () async {
                    await _apiService.logout();
                    if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => NataveApp(locale: _appLocale.value)), (route) => false);
                  },
                ),
                _buildDeleteAccountTile(l10n),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarSidebar(AppLocalizations l10n) {
    return Container(
      width: 200, decoration: const BoxDecoration(color: AppColors.sidebarBackground, border: Border(right: BorderSide(color: Colors.black12))),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildSidebarItem(0, Icons.dashboard_outlined, l10n.dashboard),
          _buildSidebarSection('OPERATIONS'),
          _buildSidebarItem(2, Icons.account_balance_wallet_outlined, l10n.accounts),
          _buildSidebarItem(1, Icons.list_alt_outlined, l10n.transactions),
          _buildSidebarSection('INFORMATION'),
          _buildSidebarItem(3, Icons.bar_chart_outlined, l10n.reports),
          _buildSidebarItem(4, Icons.category_outlined, l10n.categories),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, size: 20, color: Colors.redAccent),
            title: const Text('Logout', style: TextStyle(fontSize: 13, color: Colors.redAccent)),
            onTap: () async {
              await _apiService.logout();
              if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => NataveApp(locale: _appLocale.value)), (route) => false);
            },
          ),
          _buildDeleteAccountTile(l10n),
        ],
      ),
    );
  }

  Widget _buildSidebarSection(String title) {
    return Padding(padding: const EdgeInsets.only(left: 16, top: 15, bottom: 5), child: Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondaryText)));
  }

  Widget _buildSidebarItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon, size: 20, color: isSelected ? AppColors.primaryBlue : AppColors.primaryText),
      title: Text(label, style: isSelected ? AppTextStyles.sidebarItemBold : AppTextStyles.sidebarItem),
      selected: isSelected,
      onTap: () {
        setState(() => _selectedIndex = index);
        // Si podemos hacer pop (es decir, el drawer está abierto), lo cerramos
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
    );
  }

  Widget _buildWhiteToolbar() {
    return Container(height: 1, decoration: const BoxDecoration(color: Colors.black12));
  }

  Widget _buildLanguageSidebarItem(AppLocalizations l10n) {
    return ListTile(
      leading: const Icon(Icons.language, size: 20),
      title: Text(l10n.language),
      trailing: const Icon(Icons.arrow_drop_down),
      onTap: () {
        showDialog(context: context, builder: (context) => SimpleDialog(title: Text(l10n.language), children: [_languageOption('en', 'English'), _languageOption('es', 'Español'), _languageOption('pt', 'Português')]));
      },
    );
  }

  Widget _buildBackupSidebarItem(AppLocalizations l10n) {
    return ListTile(
      leading: const Icon(Icons.cloud_upload_outlined, size: 20),
      title: Text(l10n.backup),
      onTap: () => _showBackupDialog(l10n),
    );
  }

  Widget _buildDeleteAccountTile(AppLocalizations l10n) {
    return ListTile(
      leading: const Icon(Icons.delete_forever_outlined, size: 20, color: Colors.redAccent),
      title: Text(l10n.deleteAccount, style: const TextStyle(fontSize: 13, color: Colors.redAccent)),
      onTap: () => _showDeleteAccountDialog(l10n),
    );
  }

  void _showDeleteAccountDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAccountConfirmTitle),
        content: Text(l10n.deleteAccountConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performDeleteAccount(l10n);
            },
            child: Text(l10n.deleteAccount, style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteAccount(AppLocalizations l10n) async {
    try {
      await _apiService.deleteUserAccount();
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(l10n.deleteAccountSuccess),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => NataveApp(locale: _appLocale.value)), (route) => false);
      }
    } catch (e, st) {
      AppLogger.error('Account deletion failed', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showBackupDialog(AppLocalizations l10n) {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El backup local no está disponible en la versión web')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.backup),
        content: const Text(
          'Se exportará la base de datos local como archivo .db. '
          'Podrás guardarlo en Google Drive, iCloud, enviarlo por email, etc.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performBackup();
            },
            child: const Text('Exportar'),
          ),
        ],
      ),
    );
  }

  Future<void> _performBackup() async {
    final dbDir = await getDatabasesPath();
    final sourcePath = join(dbDir, ConfigService.databaseName);
    final sourceFile = File(sourcePath);

    if (!await sourceFile.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró la base de datos local')),
        );
      }
      return;
    }

    final now = DateTime.now();
    final stamp =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final backupPath = join(dbDir, 'natave_backup_$stamp.db');

    try {
      await sourceFile.copy(backupPath);

      await Share.shareXFiles(
        [XFile(backupPath, mimeType: 'application/octet-stream')],
        subject: 'Natave backup $stamp',
      );
    } catch (e, st) {
      AppLogger.error('Backup failed', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear el backup: $e')),
        );
      }
    } finally {
      final backupFile = File(backupPath);
      if (await backupFile.exists()) await backupFile.delete();
    }
  }

  Widget _languageOption(String code, String name) {
    return SimpleDialogOption(onPressed: () { _appLocale.value = Locale(code); Navigator.pop(context); }, child: Text(name));
  }

  Widget _buildLanguageToggle() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.language, color: Colors.white, size: 20),
      onSelected: (value) => _appLocale.value = Locale(value),
      itemBuilder: (context) => [const PopupMenuItem(value: 'en', child: Text('English')), const PopupMenuItem(value: 'es', child: Text('Español')), const PopupMenuItem(value: 'pt', child: Text('Português'))],
    );
  }

  Widget _buildSidebar(AppLocalizations l10n) {
    return _sidebarSidebar(l10n);
  }
}

class _OfflineBanner extends StatefulWidget {
  @override
  State<_OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<_OfflineBanner> {
  bool _isOffline = ConnectivityService().isOffline;

  @override
  void initState() {
    super.initState();
    ConnectivityService().offlineStream.listen((offline) {
      if (mounted) setState(() => _isOffline = offline);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isOffline ? 36 : 0,
      color: const Color(0xFFF59E0B),
      child: _isOffline
          ? const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off_rounded, size: 14, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  'Sin conexión · Los cambios se sincronizarán al reconectar',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            )
          : null,
    );
  }
}
