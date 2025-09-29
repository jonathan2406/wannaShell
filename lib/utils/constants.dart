import 'package:flutter/material.dart';

/// Constantes utilizadas en toda la aplicación
class AppConstants {
  // Colores del tema
  static const Color primaryColor = Color(0xFF1E88E5);
  static const Color secondaryColor = Color(0xFF26A69A);
  static const Color errorColor = Color(0xFFE53935);
  static const Color warningColor = Color(0xFFFB8C00);
  static const Color successColor = Color(0xFF43A047);
  
  // Colores para estados de sesión
  static const Color activeColor = Color(0xFF4CAF50);
  static const Color inactiveColor = Color(0xFF9E9E9E);
  static const Color connectingColor = Color(0xFF2196F3);
  static const Color errorSessionColor = Color(0xFFF44336);
  
  // Espaciado
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
  
  // Bordes redondeados
  static const double borderRadiusS = 4.0;
  static const double borderRadiusM = 8.0;
  static const double borderRadiusL = 12.0;
  static const double borderRadiusXL = 16.0;
  
  // Elevaciones
  static const double elevationS = 2.0;
  static const double elevationM = 4.0;
  static const double elevationL = 8.0;
  
  // Tamaños de iconos
  static const double iconS = 16.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  static const double iconXL = 48.0;
  
  // Duraciones de animación
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  
  // Breakpoints responsivos
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 1024.0;
  static const double desktopBreakpoint = 1440.0;
  
  // Configuración de paginación
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Configuración de red
  static const Duration networkTimeout = Duration(seconds: 10);
  static const int maxRetryAttempts = 3;
  
  // Validaciones
  static const int minPasswordLength = 6;
  static const int maxMachineNameLength = 50;
  static const int maxNotesLength = 500;
  
  // Expresiones regulares
  static final RegExp ipAddressRegex = RegExp(
    r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
  );
  
  static final RegExp portRegex = RegExp(r'^([1-9][0-9]{0,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$');
  
  // Comandos comunes para C&C
  static const List<String> commonCommands = [
    'whoami',
    'pwd',
    'ls -la',
    'ps aux',
    'netstat -an',
    'ifconfig',
    'uname -a',
    'cat /etc/passwd',
    'systemctl status',
    'df -h',
  ];
  
  // Sistemas operativos comunes
  static const List<String> commonOS = [
    'Windows 10',
    'Windows 11',
    'Windows Server 2019',
    'Windows Server 2022',
    'Ubuntu 20.04',
    'Ubuntu 22.04',
    'CentOS 7',
    'CentOS 8',
    'Debian 10',
    'Debian 11',
    'macOS Monterey',
    'macOS Ventura',
    'Kali Linux',
    'Parrot Security OS',
  ];
}

/// Utilidades para el tema de la aplicación
class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppConstants.primaryColor,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: AppConstants.elevationS,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingL,
          vertical: AppConstants.paddingM,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingM,
        vertical: AppConstants.paddingM,
      ),
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppConstants.primaryColor,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: AppConstants.elevationS,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingL,
          vertical: AppConstants.paddingM,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingM,
        vertical: AppConstants.paddingM,
      ),
    ),
  );
}
