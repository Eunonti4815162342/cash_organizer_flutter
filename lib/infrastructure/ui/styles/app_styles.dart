import 'package:flutter/material.dart';

class AppColors {
  // Colores principales
  static const Color primaryBlue = Color(0xFF009FFB);
  static const Color primaryText = Color(0xFF4A636F);
  static const Color secondaryText = Colors.grey;

  // Fondos y Superficies
  static const Color windowBackground = Color(0xFFF5F5F5);
  static const Color scaffoldBackground = Color(0xFFF0F0F0);
  static const Color cardBackground = Colors.white;
  static const Color sidebarBackground = Color(0xFFFBFBFB);

  // Divisores y Bordes
  static const Color divider = Color(0xFFEEEEEE);
  static const Color tableHeader = Color(0xFFF5F5F5);

  // Estados y Semántica
  static const Color expenseRed = Colors.red;
  static const Color incomeGreen = Colors.green;
  static const Color warningOrange = Colors.orange;

  // Colores adicionales usados frecuentemente
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color black12 = Colors.black12;
  static const Color black26 = Colors.black26;

  // Paleta de gráficos (dashboard y reports)
  static const Color chart0 = Color(0xFF009FFB); // Azul primario
  static const Color chart1 = Color(0xFFF2994A); // Naranja
  static const Color chart2 = Color(0xFF27AE60); // Verde
  static const Color chart3 = Color(0xFF9B51E0); // Púrpura
  static const Color chart4 = Color(0xFFEB5757); // Rojo
  static const Color chart5 = Color(0xFF2D9CDB); // Azul claro
  static const Color chart6 = Color(0xFFF2C94C); // Amarillo
  static const Color chart7 = Color(0xFF219653); // Verde oscuro
  static const Color chart8 = Color(0xFF2F80ED); // Azul intenso
  static const Color chart9 = Color(0xFFE0E0E0); // Gris claro
  static const Color chart10 = Color(0xFFBDBDBD); // Gris oscuro
  static const Color chart11 = Color(0xFF828282); // Carbón
  static const Color chart12 = Color(0xFF56CCF2); // Turquesa
  static const Color chart13 = Color(0xFFBB6BD9); // Rosa/Lila
  static const Color chart14 = Color(0xFF6FCF97); // Menta

  static const List<Color> chartPalette = [
    chart0, chart1, chart2, chart3, chart4,
    chart5, chart6, chart7, chart8, chart9,
    chart10, chart11, chart12, chart13, chart14,
  ];
}

class AppTextStyles {
  static const TextStyle sidebarItem = TextStyle(
    fontFamily: 'AppFont',
    fontSize: 13,
    color: AppColors.primaryText,
  );

  static const TextStyle sidebarItemBold = TextStyle(
    fontFamily: 'AppFont',
    fontSize: 13,
    color: AppColors.primaryBlue,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle tableHeader = TextStyle(
    fontFamily: 'AppFont',
    fontSize: 11,
    color: AppColors.secondaryText,
  );

  static const TextStyle bodyText = TextStyle(
    fontFamily: 'AppFont',
    fontSize: 14,
    color: AppColors.primaryText,
  );

  static const TextStyle sectionLabel = TextStyle(
    fontFamily: 'AppFont',
    fontSize: 10,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryBlue,
  );

  static const TextStyle fieldLabel = TextStyle(
    fontFamily: 'AppFont',
    fontSize: 10,
    color: AppColors.primaryBlue,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle fieldValue = TextStyle(
    fontFamily: 'AppFont',
    fontSize: 15,
    color: AppColors.primaryText,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle hintText = TextStyle(
    fontFamily: 'AppFont',
    fontSize: 13,
    color: AppColors.secondaryText,
  );

  static const TextStyle screenTitle = TextStyle(
    fontFamily: 'AppFont',
    fontWeight: FontWeight.bold,
    letterSpacing: 1.2,
    color: AppColors.primaryText,
  );

  static const TextStyle listItemTitle = TextStyle(
    fontFamily: 'AppFont',
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryText,
  );

  static const TextStyle listItemSubtitle = TextStyle(
    fontFamily: 'AppFont',
    fontSize: 12,
    color: AppColors.secondaryText,
  );

  static const TextStyle amountText = TextStyle(
    fontFamily: 'AppFont',
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle dateSmall = TextStyle(
    fontFamily: 'AppFont',
    fontSize: 11,
    color: AppColors.secondaryText,
  );
}

class AppDimens {
  /// Ancho de pantalla por debajo del cual se considera diseño móvil
  static const double mobileBreakpoint = 800;
}
