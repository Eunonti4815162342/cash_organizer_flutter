import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'infrastructure/ui/styles/app_styles.dart';
import 'infrastructure/ui/screens/dashboard_screen.dart';
import 'infrastructure/ui/screens/transaction_list_screen.dart';
import 'infrastructure/ui/screens/account_transactions_screen.dart';
import 'infrastructure/ui/screens/reports_list_screen.dart';
import 'infrastructure/ui/screens/category_list_screen.dart';
import 'infrastructure/ui/widgets/account_form_dialog.dart';

final ValueNotifier<Locale> _appLocale = ValueNotifier(const Locale('en'));

void main() {
  runApp(ValueListenableBuilder<Locale>(
    valueListenable: _appLocale,
    builder: (context, locale, child) {
      return CashOrganizerApp(locale: locale);
    },
  ));
}

class CashOrganizerApp extends StatelessWidget {
  final Locale locale;
  const CashOrganizerApp({super.key, required this.locale});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cash Organizer',
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('es'), // Spanish
        Locale('pt'), // Portuguese
      ],
      theme: ThemeData(
        primaryColor: AppColors.primaryBlue,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryBlue,
          primary: AppColors.primaryBlue,
          surface: AppColors.cardBackground,
        ),
        scaffoldBackgroundColor: AppColors.scaffoldBackground,
        fontFamily: 'Segoe UI',
        useMaterial3: true,
      ),
      home: const DesktopMainLayout(),
    );
  }
}

class DesktopMainLayout extends StatefulWidget {
  const DesktopMainLayout({super.key});

  @override
  State<DesktopMainLayout> createState() => _DesktopMainLayoutState();
}

class _DesktopMainLayoutState extends State<DesktopMainLayout> {
  int _selectedIndex = 0;
  String? _selectedAccountName;
  bool _isSidebarVisible = true;
  Key _screenKey = UniqueKey();

  List<Widget> get _screens => [
    const DashboardScreen(),
    const TransactionListScreen(),
    AccountTransactionsScreen(key: _screenKey),
    const ReportsListScreen(),
    const CategoryListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    _selectedAccountName ??= 'Todas as contas';

    return Scaffold(
      body: Column(
        children: [
          _buildBlueTopBar(l10n),
          Expanded(
            child: Row(
              children: [
                if (_isSidebarVisible) _buildSidebar(l10n),
                Expanded(
                  child: Column(
                    children: [
                      _buildWhiteToolbar(),
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
        ],
      ),
    );
  }

  Widget _buildBlueTopBar(AppLocalizations l10n) {
    return Container(
      height: 50,
      color: AppColors.primaryBlue,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white, size: 22),
            onPressed: () => setState(() => _isSidebarVisible = !_isSidebarVisible),
          ),
          const SizedBox(width: 15),
          const Text(
            'Cash Organizer',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w400),
          ),
          const Spacer(),
          _buildLanguageToggle(),
          const SizedBox(width: 10),
          const Text('Salvo', style: TextStyle(color: Colors.white70, fontSize: 13)),
          IconButton(icon: const Icon(Icons.sync, color: Colors.white, size: 20), onPressed: () {}),
          IconButton(icon: const Icon(Icons.calendar_today, color: Colors.white, size: 20), onPressed: () {}),
          IconButton(icon: const Icon(Icons.apps, color: Colors.white, size: 20), onPressed: () {}),
          const SizedBox(width: 10),
          Container(
            width: 180,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(fontSize: 13),
                prefixIcon: Icon(Icons.search, size: 18, color: AppColors.secondaryText),
                border: InputBorder.none,
                contentPadding: EdgeInsets.only(bottom: 12),
              ),
            ),
          ),
          const SizedBox(width: 15),
          const Icon(Icons.cloud_done_outlined, color: Colors.white70, size: 24),
          const SizedBox(width: 8),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('usuario@email.com', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              Text('Online', style: TextStyle(color: Colors.white70, fontSize: 10)),
            ],
          ),
          const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 16),
        ],
      ),
    );
  }

  Widget _buildWhiteToolbar() {
    return Container(
      height: 45,
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(bottom: BorderSide(color: Colors.black12)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildAccountSelector(),
          const SizedBox(width: 12),
          if (_selectedIndex == 2)
            ElevatedButton.icon(
              onPressed: () => _showNewAccountDialog(),
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              label: const Text('Nova conta', style: TextStyle(fontSize: 13, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          const Spacer(),
          IconButton(icon: const Icon(Icons.person_add_outlined, color: AppColors.primaryBlue, size: 20), onPressed: () {}),
          const Text('Sharing access', style: TextStyle(color: AppColors.primaryText, fontSize: 12)),
          const SizedBox(width: 10),
          const Icon(Icons.settings_outlined, color: AppColors.secondaryText, size: 20),
        ],
      ),
    );
  }

  Widget _buildAccountSelector() {
    return PopupMenuButton<String>(
      onSelected: (value) => setState(() => _selectedAccountName = value),
      child: Row(
        children: [
          Text(_selectedAccountName!, style: const TextStyle(fontSize: 14, color: AppColors.primaryText)),
          const Icon(Icons.arrow_drop_down, color: AppColors.secondaryText),
        ],
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'Todas as contas', child: Text('Todas as contas')),
        const PopupMenuDivider(),
        const PopupMenuItem(enabled: false, child: Text('Grupos de contas', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
        const PopupMenuItem(value: 'Caixa', child: Padding(padding: EdgeInsets.only(left: 12), child: Text('Caixa'))),
        const PopupMenuItem(value: 'Empréstimos', child: Padding(padding: EdgeInsets.only(left: 12), child: Text('Empréstimos'))),
        const PopupMenuItem(value: 'Santa Filomena', child: Padding(padding: EdgeInsets.only(left: 12), child: Text('Santa Filomena'))),
      ],
    );
  }

  Widget _buildSidebar(AppLocalizations l10n) {
    return Container(
      width: 200,
      decoration: const BoxDecoration(
        color: AppColors.sidebarBackground,
        border: Border(right: BorderSide(color: Colors.black12)),
      ),
      child: Column(
        children: [
          _buildSidebarItem(0, Icons.dashboard_outlined, 'Principal'),
          const Divider(height: 1),
          _buildSidebarSection('OPERATIONS'),
          _buildSidebarItem(2, Icons.account_balance_wallet_outlined, l10n.accounts),
          _buildSidebarItem(1, Icons.list_alt_outlined, l10n.transactions),
          _buildSidebarSection('INFORMATION'),
          _buildSidebarItem(3, Icons.bar_chart_outlined, l10n.reports),
          _buildSidebarItem(4, Icons.category_outlined, l10n.categories),
          _buildSidebarItem(99, Icons.sell_outlined, 'Payees'),
          const Spacer(),
          const Divider(height: 1),
          _buildSidebarItem(99, Icons.help_outline, 'Help'),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildSidebarSection(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16, top: 15, bottom: 5),
      child: Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondaryText)),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: isSelected ? AppColors.cardBackground : Colors.transparent,
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? AppColors.primaryBlue : AppColors.primaryText),
            const SizedBox(width: 10),
            Text(label, style: isSelected ? AppTextStyles.sidebarItemBold : AppTextStyles.sidebarItem),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageToggle() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.language, color: Colors.white, size: 20),
      onSelected: (value) {
        _appLocale.value = Locale(value);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'en', child: Text('English')),
        const PopupMenuItem(value: 'es', child: Text('Español')),
        const PopupMenuItem(value: 'pt', child: Text('Português')),
      ],
    );
  }

  void _showNewAccountDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AccountFormDialog(),
    ).then((saved) {
      if (saved == true) {
        setState(() {
          _screenKey = UniqueKey();
        });
      }
    });
  }
}
