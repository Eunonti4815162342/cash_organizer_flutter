import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'l10n/app_localizations.dart';
import 'infrastructure/ui/styles/app_styles.dart';
import 'infrastructure/ui/screens/dashboard_screen.dart';
import 'infrastructure/ui/screens/transaction_list_screen.dart';
import 'infrastructure/ui/screens/account_transactions_screen.dart';
import 'infrastructure/ui/screens/reports_list_screen.dart';
import 'infrastructure/ui/screens/category_list_screen.dart';
import 'infrastructure/ui/screens/login_screen.dart';
import 'services/api_service.dart';
import 'domain/models/account_item.dart';

// Importación condicional
import 'services/background_sync.dart'
    if (dart.library.io) 'services/background_sync_mobile.dart'
    if (dart.library.html) 'services/background_sync_web.dart';

final ValueNotifier<Locale> _appLocale = ValueNotifier(const Locale('en'));

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
  
  // Usar el manager que corresponda a la plataforma
  final syncManager = getSyncManager();
  await syncManager.initialize();
  syncManager.scheduleTask();
  
  runApp(ValueListenableBuilder<Locale>(
    valueListenable: _appLocale,
    builder: (context, locale, child) {
      return CashOrganizerApp(locale: locale);
    },
  ));
}

class CashOrganizerApp extends StatefulWidget {
  final Locale locale;
  const CashOrganizerApp({super.key, required this.locale});

  @override
  State<CashOrganizerApp> createState() => _CashOrganizerAppState();
}

class _CashOrganizerAppState extends State<CashOrganizerApp> {
  bool _isLoggedIn = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Siempre mostramos el Login primero para que gestione la biometría/sesión
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
      title: 'Cash Organizer',
      debugShowCheckedModeBanner: false,
      locale: widget.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), 
        Locale('es'), 
        Locale('pt'), 
      ],
      theme: ThemeData(
        primaryColor: AppColors.primaryBlue,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryBlue,
          primary: AppColors.primaryBlue,
          surface: AppColors.cardBackground,
        ),
        scaffoldBackgroundColor: AppColors.scaffoldBackground,
        useMaterial3: true,
      ),
      home: _isLoading 
        ? const Scaffold(body: Center(child: CircularProgressIndicator()))
        : _isLoggedIn 
          ? const ResponsiveMainLayout() 
          : LoginScreen(onLoginSuccess: () => setState(() => _isLoggedIn = true)),
    );
  }
}

class ResponsiveMainLayout extends StatefulWidget {
  const ResponsiveMainLayout({super.key});

  @override
  State<ResponsiveMainLayout> createState() => _ResponsiveMainLayoutState();
}

class _ResponsiveMainLayoutState extends State<ResponsiveMainLayout> {
  final ApiService _apiService = ApiService();
  int _selectedIndex = 0;
  String? _selectedAccountName;
  String? _selectedAccountId; 
  Key _screenKey = UniqueKey();
  List<AccountItem> _accounts = [];

  @override
  void initState() {
    super.initState();
    _refreshAccounts();
  }

  Future<void> _refreshAccounts() async {
    final accs = await _apiService.fetchAccounts();
    if (mounted) {
      setState(() {
        _accounts = accs;
      });
    }
  }

  List<Widget> get _screens => [
    const DashboardScreen(),
    TransactionListScreen(accountId: _selectedAccountId),
    AccountTransactionsScreen(key: _screenKey),
    const ReportsListScreen(),
    const CategoryListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = MediaQuery.of(context).size.width < 800;
    _selectedAccountName ??= l10n.allAccounts;

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
                  _buildWhiteToolbar(l10n),
                  Expanded(
                    child: Container(
                      color: const Color(0xFFEAEAEA),
                      child: _screens[_selectedIndex < _screens.length ? _selectedIndex : 0],
                    ),
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
      title: Text(
        l10n.appTitle,
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w400),
      ),
      actions: [
        if (!isMobile) ...[
          _buildLanguageToggle(),
          IconButton(
            icon: const Icon(Icons.sync, size: 20), 
            onPressed: () {
              _refreshAccounts();
              setState(() => _screenKey = UniqueKey());
            }
          ),
        ],
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildDrawer(AppLocalizations l10n) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primaryBlue),
            child: Center(
              child: Text(l10n.appTitle, style: const TextStyle(color: Colors.white, fontSize: 24)),
            ),
          ),
          Expanded(child: _buildSidebarItems(l10n)),
          const Divider(),
          _buildLanguageSidebarItem(l10n),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSidebar(AppLocalizations l10n) {
    return Container(
      width: 200,
      decoration: const BoxDecoration(
        color: AppColors.sidebarBackground,
        border: Border(right: BorderSide(color: Colors.black12)),
      ),
      child: _buildSidebarItems(l10n),
    );
  }

  Widget _buildSidebarItems(AppLocalizations l10n) {
    return ListView(
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
        _buildSidebarItem(99, Icons.help_outline, 'Help'),
        ListTile(
          leading: const Icon(Icons.logout, size: 20, color: Colors.redAccent),
          title: const Text('Logout', style: TextStyle(fontSize: 13, color: Colors.redAccent)),
          onTap: () async {
            await _apiService.logout();
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => CashOrganizerApp(locale: _appLocale.value)),
                (route) => false,
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildSidebarSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 15, bottom: 5),
      child: Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondaryText)),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon, size: 20, color: isSelected ? AppColors.primaryBlue : AppColors.primaryText),
      title: Text(label, style: isSelected ? AppTextStyles.sidebarItemBold : AppTextStyles.sidebarItem),
      selected: isSelected,
      onTap: () {
        setState(() => _selectedIndex = index);
        if (MediaQuery.of(context).size.width < 800) Navigator.pop(context);
      },
    );
  }

  Widget _buildWhiteToolbar(AppLocalizations l10n) {
    return Container(
      height: 50,
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(bottom: BorderSide(color: Colors.black12)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildAccountSelector(l10n),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildAccountSelector(AppLocalizations l10n) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        setState(() {
          if (value == 'all') {
            _selectedAccountName = l10n.allAccounts;
            _selectedAccountId = null;
          } else {
            final acc = _accounts.firstWhere((a) => a.id.toString() == value);
            _selectedAccountName = acc.name;
            _selectedAccountId = value;
          }
          _screenKey = UniqueKey(); 
        });
      },
      child: Row(
        children: [
          Text(_selectedAccountName!, style: const TextStyle(fontSize: 14, color: AppColors.primaryText, fontWeight: FontWeight.w500)),
          const Icon(Icons.arrow_drop_down, color: AppColors.secondaryText),
        ],
      ),
      itemBuilder: (context) => [
        PopupMenuItem(value: 'all', child: Text(l10n.allAccounts)),
        if (_accounts.isNotEmpty) ...[
          const PopupMenuDivider(),
          ..._accounts.map((acc) => PopupMenuItem(value: acc.id.toString(), child: Text(acc.name))),
        ],
      ],
    );
  }

  Widget _buildLanguageSidebarItem(AppLocalizations l10n) {
    return ListTile(
      leading: const Icon(Icons.language, size: 20),
      title: Text(l10n.language),
      trailing: const Icon(Icons.arrow_drop_down),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => SimpleDialog(
            title: Text(l10n.language),
            children: [
              _languageOption('en', 'English'),
              _languageOption('es', 'Español'),
              _languageOption('pt', 'Português'),
            ],
          ),
        );
      },
    );
  }

  Widget _languageOption(String code, String name) {
    return SimpleDialogOption(
      onPressed: () {
        _appLocale.value = Locale(code);
        Navigator.pop(context);
      },
      child: Text(name),
    );
  }

  Widget _buildLanguageToggle() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.language, color: Colors.white, size: 20),
      onSelected: (value) => _appLocale.value = Locale(value),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'en', child: Text('English')),
        const PopupMenuItem(value: 'es', child: Text('Español')),
        const PopupMenuItem(value: 'pt', child: Text('Português')),
      ],
    );
  }
}
