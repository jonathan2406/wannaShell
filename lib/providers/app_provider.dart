import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

/// Provider para manejar el estado global de la aplicación con integración API
class AppProvider extends ChangeNotifier {
  // Configuración de tema
  ThemeMode _themeMode = ThemeMode.system;
  
  // Configuración de API
  String _apiBaseUrl = 'http://localhost:3000/api';
  bool _isOfflineMode = false;
  bool _isApiConnected = false;
  
  // Mensajes globales
  String? _errorMessage;
  String? _successMessage;
  
  // Estado de navegación
  int _selectedNavIndex = 0;
  
  // Servicios
  final ApiService _apiService = ApiService();

  // Getters
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  String get apiBaseUrl => _apiBaseUrl;
  bool get isOfflineMode => _isOfflineMode;
  bool get isApiConnected => _isApiConnected;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  int get selectedNavIndex => _selectedNavIndex;

  /// Inicializar el provider
  Future<void> initialize() async {
    try {
      await _loadPreferences();
      await _initializeApiService();
      await _checkApiConnection();
    } catch (e) {
      print('Error inicializando AppProvider: $e');
      _isOfflineMode = true; // Forzar offline si hay problemas
    }
    notifyListeners();
  }

  /// Cargar preferencias guardadas
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Cargar tema
      final themeIndex = prefs.getInt('theme_mode') ?? 0;
      _themeMode = ThemeMode.values[themeIndex];
      
      // Cargar configuración de API
      _apiBaseUrl = prefs.getString('api_base_url') ?? 'http://localhost:3000/api';
      _isOfflineMode = prefs.getBool('offline_mode') ?? false;
      
    } catch (e) {
      print('Error cargando preferencias: $e');
    }
  }

  /// Inicializar servicio de API
  Future<void> _initializeApiService() async {
    try {
      await _apiService.initialize();
      if (_apiBaseUrl != _apiService.baseUrl) {
        await _apiService.setBaseUrl(_apiBaseUrl);
      }
    } catch (e) {
      print('Error inicializando API service: $e');
    }
  }

  /// Verificar conexión con la API
  Future<void> _checkApiConnection() async {
    if (_isOfflineMode) {
      _isApiConnected = false;
      return;
    }

    try {
      final result = await _apiService.checkConnection();
      _isApiConnected = result.isSuccess;
      
      if (!_isApiConnected) {
        print('API no disponible: ${result.error}');
      }
    } catch (e) {
      print('Error verificando conexión API: $e');
      _isApiConnected = false;
    }
  }

  /// Cambiar modo de tema
  Future<void> toggleDarkMode() async {
    _themeMode = _isDarkMode ? ThemeMode.light : ThemeMode.dark;
    await _saveThemePreference();
    notifyListeners();
  }

  /// Establecer modo de tema específico
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      await _saveThemePreference();
      notifyListeners();
    }
  }

  /// Guardar preferencia de tema
  Future<void> _saveThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('theme_mode', _themeMode.index);
    } catch (e) {
      print('Error guardando tema: $e');
    }
  }

  /// Establecer URL base de la API
  Future<void> setApiBaseUrl(String url) async {
    if (_apiBaseUrl != url) {
      _apiBaseUrl = url;
      
      try {
        await _apiService.setBaseUrl(url);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('api_base_url', url);
        
        // Verificar nueva conexión
        await _checkApiConnection();
        
        if (_isApiConnected) {
          showSuccess('URL de API actualizada y conectada');
        } else {
          showError('URL actualizada pero no se puede conectar a la API');
        }
      } catch (e) {
        showError('Error actualizando URL de API: ${e.toString()}');
      }
      
      notifyListeners();
    }
  }

  /// Configurar modo offline
  Future<void> setOfflineMode(bool isOffline) async {
    if (_isOfflineMode != isOffline) {
      _isOfflineMode = isOffline;
      
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('offline_mode', isOffline);
        
        if (!isOffline) {
          // Si salimos del modo offline, verificar conexión
          await _checkApiConnection();
          if (_isApiConnected) {
            showSuccess('Modo online activado - API conectada');
          } else {
            showError('Modo online activado pero API no disponible');
          }
        } else {
          _isApiConnected = false;
          showSuccess('Modo offline activado');
        }
      } catch (e) {
        showError('Error configurando modo offline: ${e.toString()}');
      }
      
      notifyListeners();
    }
  }

  /// Verificar conexión manualmente
  Future<void> testApiConnection() async {
    try {
      showSuccess('Verificando conexión...');
      await _checkApiConnection();
      
      if (_isApiConnected) {
        showSuccess('✅ API conectada correctamente');
      } else {
        showError('❌ No se puede conectar con la API');
      }
    } catch (e) {
      showError('Error verificando conexión: ${e.toString()}');
    }
    
    notifyListeners();
  }

  /// Establecer índice de navegación seleccionado
  void setSelectedNavIndex(int index) {
    if (_selectedNavIndex != index) {
      _selectedNavIndex = index;
      notifyListeners();
    }
  }

  /// Mostrar mensaje de éxito
  void showSuccess(String message) {
    _successMessage = message;
    _errorMessage = null;
    notifyListeners();
    
    // Auto-limpiar después de 3 segundos
    Future.delayed(const Duration(seconds: 3), () {
      if (_successMessage == message) {
        _successMessage = null;
        notifyListeners();
      }
    });
  }

  /// Mostrar mensaje de error
  void showError(String message) {
    _errorMessage = message;
    _successMessage = null;
    notifyListeners();
    
    // Auto-limpiar después de 5 segundos
    Future.delayed(const Duration(seconds: 5), () {
      if (_errorMessage == message) {
        _errorMessage = null;
        notifyListeners();
      }
    });
  }

  /// Limpiar mensajes
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Obtener estado de conexión como string
  String get connectionStatus {
    if (_isOfflineMode) {
      return 'Modo Offline';
    } else if (_isApiConnected) {
      return 'Conectado a API';
    } else {
      return 'API No Disponible';
    }
  }

  /// Obtener color del estado de conexión
  Color get connectionStatusColor {
    if (_isOfflineMode) {
      return Colors.orange;
    } else if (_isApiConnected) {
      return Colors.green;
    } else {
      return Colors.red;
    }
  }

  /// Obtener icono del estado de conexión
  IconData get connectionStatusIcon {
    if (_isOfflineMode) {
      return Icons.wifi_off;
    } else if (_isApiConnected) {
      return Icons.wifi;
    } else {
      return Icons.wifi_off;
    }
  }

  /// Reintentar conexión con API
  Future<void> retryApiConnection() async {
    if (!_isOfflineMode) {
      await _checkApiConnection();
      notifyListeners();
    }
  }

  /// Obtener información de debug
  Map<String, dynamic> get debugInfo {
    return {
      'apiBaseUrl': _apiBaseUrl,
      'isOfflineMode': _isOfflineMode,
      'isApiConnected': _isApiConnected,
      'themeMode': _themeMode.toString(),
      'selectedNavIndex': _selectedNavIndex,
    };
  }

  bool get _isDarkMode => _themeMode == ThemeMode.dark;

  @override
  void dispose() {
    // Limpiar recursos si es necesario
    super.dispose();
  }
}
