import 'package:flutter/material.dart';

class AppColors {
  // Colores principales extraídos de la APK original
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
}

class AppTextStyles {
  static const TextStyle sidebarItem = TextStyle(
    fontSize: 13,
    color: AppColors.primaryText,
  );
  
  static const TextStyle sidebarItemBold = TextStyle(
    fontSize: 13,
    color: AppColors.primaryBlue,
    fontWeight: FontWeight.bold,
  );
  
  static const TextStyle tableHeader = TextStyle(
    fontSize: 11,
    color: AppColors.secondaryText,
  );
  
  static const TextStyle bodyText = TextStyle(
    fontSize: 14,
    color: AppColors.primaryText,
  );
}
