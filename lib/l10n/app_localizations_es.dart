// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Organizador de Gastos';

  @override
  String get allAccounts => 'Todas las cuentas';

  @override
  String get accounts => 'Cuentas';

  @override
  String get transactions => 'Transacciones';

  @override
  String get categories => 'Categorías';

  @override
  String get budgets => 'Presupuestos';

  @override
  String get reports => 'Informes';

  @override
  String get newCategory => 'Nueva categoría';

  @override
  String get save => 'Guardar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get description => 'Descripción';

  @override
  String get type => 'Tipo';

  @override
  String get expense => 'Gasto';

  @override
  String get income => 'Ingreso';

  @override
  String get subcategoryOf => 'Subcategoría de';

  @override
  String get selectParentCategory => 'Seleccionar categoría...';

  @override
  String get pleaseSelectParentCategory =>
      'Por favor, selecciona una categoría padre';

  @override
  String get search => 'Buscar';

  @override
  String get allDates => 'Todas las fechas';

  @override
  String get categoryName => 'Nombre de la categoría';

  @override
  String get goPremium => 'Go Premium';

  @override
  String get premiumSubtitle => 'Funciones avanzadas para ti';
}
