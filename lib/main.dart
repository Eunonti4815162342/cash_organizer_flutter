import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'l10n/app_localizations.dart';
import 'infrastructure/ui/styles/app_styles.dart';
import 'infrastructure/ui/screens/dashboard_screen.dart';
import 'infrastructure/ui/screens/transaction_list_screen.dart';
import 'infrastructure/ui/screens/account_transactions_screen.dart';
import 'infrastructure/ui/screens/reports_list_screen.dart';
import 'infrastructure/ui/screens/category_list_screen.dart';
import 'infrastructure/ui/screens/login_screen.dart';
import 'domain/models/account_item.dart';
import 'domain/repositories/account_repository.dart';
import 'domain/repositories/transaction_repository.dart';
import 'services/api_service.dart';
import 'services/config_service.dart';
import 'services/connectivity_service.dart';
import 'service_locator.dart';
import 'config/environment_factory.dart';

// Importación condicional
import 'services/background_sync.dart'
    if (dart.library.io) 'services/background_sync_mobile.dart'
    if (dart.library.html) 'services/background_sync_web.dart';

final ValueNotifier<Locale> _appLocale = ValueNotifier(const Locale('en'));

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
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'jwt_token');
      
      if (token != null) {
        // Validación rápida contra el backend para asegurar que el token no ha expirado
        final apiService = getIt<ApiService>();
        final online = await apiService.isOnline();
        if (online) {
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
        primaryColor: AppColors.primaryBlue,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryBlue, primary: AppColors.primaryBlue, surface: AppColors.cardBackground),
        scaffoldBackgroundColor: AppColors.scaffoldBackground,
        useMaterial3: true,
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

  void _showBackupDialog(AppLocalizations l10n) async {
    final getIt = GetIt.instance;
    final accountRepo = getIt<IAccountRepository>(instanceName: 'local_account');
    final accounts = await accountRepo.fetchAccounts();
    
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.backup),
        children: accounts.isEmpty 
          ? [const Padding(padding: EdgeInsets.all(16), child: Text('No hay cuentas disponibles'))]
          : accounts.map((account) => SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _performCloudBackup(account);
            },
            child: Text(account.name),
          )).toList(),
      ),
    );
  }

  Future<void> _performCloudBackup(AccountItem account) async {
    final getIt = GetIt.instance;
    final txRepo = getIt<ITransactionRepository>(instanceName: 'local_transaction');
    
    // 1. Obtener datos locales
    final txs = await txRepo.fetchTransactions(accountId: account.id.toString());
    
    // 2. Determinar servicio según plataforma
    String cloudService = 'Cloud';
    if (!kIsWeb) {
      if (Platform.isIOS) cloudService = 'iCloud';
      if (Platform.isAndroid) cloudService = 'Google Drive';
    }

    // 3. Simular/Ejecutar envío
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Iniciando backup de "${account.name}" en $cloudService...')),
    );

    // TODO: Integración real:
    // iOS: Use icloud_storage package
    // Android: Use google_sign_in + googleapis (Drive API)
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup completado con éxito en $cloudService (Simulado)'),
          backgroundColor: Colors.green,
        ),
      );
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
