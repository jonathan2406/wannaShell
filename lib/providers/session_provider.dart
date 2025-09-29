import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/cc_session.dart';
import '../models/session_status.dart';
import '../models/api_response.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';

/// Estados posibles para operaciones asíncronas
enum LoadingState {
  idle,
  loading,
  success,
  error,
}

/// Clase para manejar estados con datos y errores
class StateWrapper<T> {
  final LoadingState state;
  final T? data;
  final String? error;

  StateWrapper({
    required this.state,
    this.data,
    this.error,
  });

  bool get isLoading => state == LoadingState.loading;
  bool get isSuccess => state == LoadingState.success;
  bool get isError => state == LoadingState.error;
  bool get isIdle => state == LoadingState.idle;

  StateWrapper<T> copyWith({
    LoadingState? state,
    T? data,
    String? error,
  }) {
    return StateWrapper<T>(
      state: state ?? this.state,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}

/// Extensión para verificar estados
extension LoadingStateExtension on LoadingState {
  bool get isLoading => this == LoadingState.loading;
  bool get isSuccess => this == LoadingState.success;
  bool get isError => this == LoadingState.error;
  bool get isIdle => this == LoadingState.idle;
  String? get error => null; // Para compatibilidad
}

/// Provider para manejar el estado de las sesiones C&C (API FIRST)
class SessionProvider extends ChangeNotifier {
  // Servicios
  final ApiService _apiService = ApiService();

  // Estado de las sesiones
  List<CCSession> _sessions = [];
  List<CCSession> _filteredSessions = [];
  CCSession? _selectedSession;

  // Estados de carga
  LoadingState _sessionsState = LoadingState.idle;
  LoadingState _selectedSessionState = LoadingState.idle;
  LoadingState _deleteSessionState = LoadingState.idle;
  LoadingState _executeCommandState = LoadingState.idle;
  LoadingState _statisticsState = LoadingState.idle;

  // Estados con datos para compatibilidad con UI existente
  StateWrapper<CCSession> _createState = StateWrapper(state: LoadingState.idle);
  StateWrapper<CCSession> _updateState = StateWrapper(state: LoadingState.idle);

  // Filtros y búsqueda
  String _searchQuery = '';
  SessionStatus? _statusFilter;

  // Configuración
  bool _isOfflineMode = false;

  // Estadísticas
  Map<String, dynamic> _statistics = {};

  // Mensajes de error
  String? _errorMessage;
  String? _successMessage;

  // Resultados de comandos
  List<Map<String, dynamic>> _commandResults = [];

  /// Constructor
  SessionProvider() {
    _initializeServices();
  }

  /// Inicializar servicios
  void _initializeServices() async {
    try {
      await _apiService.initialize();
    } catch (e) {
      print('Error inicializando ApiService: $e');
      _isOfflineMode = true; // Forzar modo offline si API falla
    }
  }

  /// Inicializar el provider
  Future<void> initialize() async {
    try {
      await _loadInitialData();
    } catch (e) {
      _errorMessage = 'Error inicializando aplicación: ${e.toString()}';
      print('Error en initialize: $e');
    }
  }

  /// Cargar datos iniciales
  Future<void> _loadInitialData() async {
    await Future.wait([
      loadSessions(),
      loadStatistics(),
    ]);
  }

  // Getters
  List<CCSession> get sessions => _sessions;
  List<CCSession> get filteredSessions => _filteredSessions;
  CCSession? get selectedSession => _selectedSession;

  LoadingState get sessionsState => _sessionsState;
  LoadingState get selectedSessionState => _selectedSessionState;
  LoadingState get deleteSessionState => _deleteSessionState;
  LoadingState get executeCommandState => _executeCommandState;
  LoadingState get statisticsState => _statisticsState;

  // Getters para estados con datos
  StateWrapper<CCSession> get createState => _createState;
  StateWrapper<CCSession> get updateState => _updateState;

  String get searchQuery => _searchQuery;
  SessionStatus? get statusFilter => _statusFilter;
  bool get isOfflineMode => _isOfflineMode;
  Map<String, dynamic> get statistics => _statistics;

  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  List<Map<String, dynamic>> get commandResults => _commandResults;

  /// Cargar todas las sesiones (API FIRST con sincronización inteligente)
  Future<void> loadSessions({bool refresh = false}) async {
    _sessionsState = LoadingState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      if (!_isOfflineMode) {
        // 1. INTENTAR CARGAR DESDE API PRIMERO
        final apiResult = await _apiService.getAllSessions();

        if (apiResult.isSuccess && apiResult.data != null) {
          final apiSessions = apiResult.data!;

          // 2. SI ES REFRESH O PRIMERA CARGA, HACER SINCRONIZACIÓN INTELIGENTE
          if (refresh || _sessions.isEmpty) {
            final localSessions = await DatabaseService.getAllSessions();

            // Solo sincronizar si hay diferencias significativas
            if (_needsSync(apiSessions, localSessions)) {
              print('[LOAD] Detectadas diferencias, sincronizando...');
              await _performBidirectionalSync(apiSessions, localSessions);
              _sessions = await DatabaseService.getAllSessions();
            } else {
              print('[LOAD] Datos sincronizados, usando API');
              _sessions = apiSessions;
              // Actualizar timestamps en local
              for (final session in apiSessions) {
                await DatabaseService.updateSession(session);
              }
            }
          } else {
            // Carga normal, usar datos de API y actualizar cache
            _sessions = apiSessions;
            for (final session in apiSessions) {
              await DatabaseService.updateSession(session);
            }
          }

          _applyFilters();
          _sessionsState = LoadingState.success;
          notifyListeners();
          return;
        }
      }

      // 3. SI API FALLA, USAR CACHE LOCAL
      print('[LOAD] API no disponible, usando cache local');
      _sessions = await DatabaseService.getAllSessions();
      _applyFilters();
      _sessionsState = LoadingState.success;
    } catch (e) {
      _sessionsState = LoadingState.error;
      _errorMessage = 'Error cargando sesiones: ${e.toString()}';
      print('Error en loadSessions: $e');
    }

    notifyListeners();
  }

  /// Verificar si se necesita sincronización
  bool _needsSync(List<CCSession> apiSessions, List<CCSession> localSessions) {
    // Si tienen diferente cantidad, necesita sync
    if (apiSessions.length != localSessions.length) {
      return true;
    }

    // Crear mapas para comparación
    final apiMap = {for (var session in apiSessions) session.id: session};
    final localMap = {for (var session in localSessions) session.id: session};

    // Verificar si hay IDs diferentes
    if (!apiMap.keys.toSet().containsAll(localMap.keys.toSet()) ||
        !localMap.keys.toSet().containsAll(apiMap.keys.toSet())) {
      return true;
    }

    // Verificar si hay sesiones que necesitan actualización
    for (final apiSession in apiSessions) {
      final localSession = localMap[apiSession.id];
      if (localSession != null &&
          _sessionNeedsUpdate(localSession, apiSession)) {
        return true;
      }
    }

    return false;
  }

  /// Buscar sesiones
  Future<void> searchSessions(String query) async {
    _searchQuery = query;
    await _applyFilters();
    notifyListeners();
  }

  /// Filtrar por estado
  Future<void> filterByStatus(SessionStatus? status) async {
    _statusFilter = status;
    await _applyFilters();
    notifyListeners();
  }

  /// Aplicar filtros
  Future<void> _applyFilters() async {
    try {
      List<CCSession> filtered = List.from(_sessions);

      // Filtro por búsqueda
      if (_searchQuery.isNotEmpty) {
        filtered = filtered
            .where((session) =>
                session.machineName
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                session.ipAddress.contains(_searchQuery))
            .toList();
      }

      // Filtro por estado
      if (_statusFilter != null) {
        filtered = filtered
            .where((session) => session.status == _statusFilter)
            .toList();
      }

      _filteredSessions = filtered;
    } catch (e) {
      print('Error aplicando filtros: $e');
      _filteredSessions = _sessions;
    }
  }

  /// Seleccionar una sesión (API FIRST)
  Future<void> selectSession(String sessionId) async {
    _selectedSessionState = LoadingState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      if (!_isOfflineMode) {
        // 1. INTENTAR OBTENER DESDE API
        final apiResult = await _apiService.getSession(sessionId);
        if (apiResult.isSuccess && apiResult.data != null) {
          _selectedSession = apiResult.data;

          // Guardar en cache
          try {
            await DatabaseService.updateSession(_selectedSession!);
          } catch (e) {
            print('Error actualizando cache: $e');
          }

          _selectedSessionState = LoadingState.success;
          notifyListeners();
          return;
        }
      }

      // 2. SI API FALLA, USAR CACHE LOCAL
      _selectedSession = await DatabaseService.getSessionById(sessionId);
      if (_selectedSession != null) {
        _selectedSessionState = LoadingState.success;
      } else {
        _selectedSessionState = LoadingState.error;
        _errorMessage = 'Sesión no encontrada';
      }
    } catch (e) {
      _selectedSessionState = LoadingState.error;
      _errorMessage = 'Error cargando sesión: ${e.toString()}';
      print('Error en selectSession: $e');
    }

    notifyListeners();
  }

  /// Crear nueva sesión (API FIRST)
  Future<bool> createSession(CCSession session) async {
    _createState = StateWrapper(state: LoadingState.loading);
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      CCSession? createdSession;

      if (!_isOfflineMode) {
        // 1. CREAR EN API PRIMERO
        final apiResult = await _apiService.createSession(session);
        if (apiResult.isSuccess && apiResult.data != null) {
          createdSession = apiResult.data!;
          _successMessage = 'Sesión creada en servidor';
        } else {
          throw Exception(apiResult.error ?? 'Error desconocido');
        }
      } else {
        // 2. SI OFFLINE, CREAR LOCALMENTE
        createdSession = session;
        _successMessage = 'Sesión creada localmente (offline)';
      }

      // 3. GUARDAR EN CACHE LOCAL
      await DatabaseService.insertSession(createdSession);

      _createState =
          StateWrapper(state: LoadingState.success, data: createdSession);

      // 4. RECARGAR LISTA
      await loadSessions();

      return true;
    } catch (e) {
      _createState = StateWrapper(
        state: LoadingState.error,
        error: 'Error creando sesión: ${e.toString()}',
      );
      _errorMessage = 'Error creando sesión: ${e.toString()}';
      print('Error en createSession: $e');
      notifyListeners();
      return false;
    }
  }

  /// Actualizar sesión (API FIRST)
  Future<bool> updateSession(CCSession session) async {
    _updateState = StateWrapper(state: LoadingState.loading);
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      CCSession? updatedSession;

      if (!_isOfflineMode) {
        // 1. ACTUALIZAR EN API PRIMERO
        final apiResult = await _apiService.updateSession(session);
        if (apiResult.isSuccess && apiResult.data != null) {
          updatedSession = apiResult.data!;
          _successMessage = 'Sesión actualizada en servidor';
        } else {
          throw Exception(apiResult.error ?? 'Error desconocido');
        }
      } else {
        // 2. SI OFFLINE, ACTUALIZAR LOCALMENTE
        updatedSession = session;
        _successMessage = 'Sesión actualizada localmente (offline)';
      }

      // 3. ACTUALIZAR CACHE LOCAL
      await DatabaseService.updateSession(updatedSession);

      _updateState =
          StateWrapper(state: LoadingState.success, data: updatedSession);

      // 4. ACTUALIZAR SESIÓN SELECCIONADA SI ES LA MISMA
      if (_selectedSession?.id == session.id) {
        _selectedSession = updatedSession;
      }

      // 5. RECARGAR LISTA
      await loadSessions();

      return true;
    } catch (e) {
      _updateState = StateWrapper(
        state: LoadingState.error,
        error: 'Error actualizando sesión: ${e.toString()}',
      );
      _errorMessage = 'Error actualizando sesión: ${e.toString()}';
      print('Error en updateSession: $e');
      notifyListeners();
      return false;
    }
  }

  /// Eliminar sesión (API FIRST)
  Future<bool> deleteSession(String sessionId) async {
    _deleteSessionState = LoadingState.loading;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      if (!_isOfflineMode) {
        // 1. ELIMINAR EN API PRIMERO
        final apiResult = await _apiService.deleteSession(sessionId);
        if (!apiResult.isSuccess) {
          throw Exception(apiResult.error ?? 'Error desconocido');
        }
        _successMessage = 'Sesión eliminada del servidor';
      } else {
        _successMessage = 'Sesión eliminada localmente (offline)';
      }

      // 2. ELIMINAR DE CACHE LOCAL
      await DatabaseService.deleteSession(sessionId);

      _deleteSessionState = LoadingState.success;

      // 3. LIMPIAR SESIÓN SELECCIONADA SI ES LA MISMA
      if (_selectedSession?.id == sessionId) {
        _selectedSession = null;
      }

      // 4. RECARGAR LISTA
      await loadSessions();

      return true;
    } catch (e) {
      _deleteSessionState = LoadingState.error;
      _errorMessage = 'Error eliminando sesión: ${e.toString()}';
      print('Error en deleteSession: $e');
      notifyListeners();
      return false;
    }
  }

  /// Ejecutar comando en una sesión (API FIRST)
  Future<Map<String, dynamic>?> executeCommand(
      String sessionId, String command) async {
    _executeCommandState = LoadingState.loading;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      Map<String, dynamic>? result;

      if (!_isOfflineMode) {
        // 1. EJECUTAR EN API PRIMERO
        final apiResult = await _apiService.executeCommand(sessionId, command);
        if (apiResult.isSuccess && apiResult.data != null) {
          // La API devuelve la sesión actualizada
          final updatedSession = apiResult.data!;

          result = {
            'command': command,
            'timestamp': DateTime.now().toIso8601String(),
            'success': true,
            'session': updatedSession,
            'source': 'api'
          };

          // Actualizar cache local
          await DatabaseService.updateSession(updatedSession);
          _successMessage = 'Comando ejecutado en servidor';
        } else {
          throw Exception(apiResult.error ?? 'Error desconocido');
        }
      } else {
        // 2. SI OFFLINE, EJECUTAR LOCALMENTE
        result = await DatabaseService.executeCommand(sessionId, command);
        result!['source'] = 'local';
        _successMessage = 'Comando ejecutado localmente (offline)';
      }

      // 3. AGREGAR A RESULTADOS
      if (result != null) {
        _commandResults.add(result);

        // 4. ACTUALIZAR SESIÓN SELECCIONADA
        if (_selectedSession?.id == sessionId && result['session'] != null) {
          _selectedSession = result['session'] as CCSession;
        }
      }

      _executeCommandState = LoadingState.success;

      // 5. RECARGAR SESIONES PARA REFLEJAR CAMBIOS
      await loadSessions();

      return result;
    } catch (e) {
      _executeCommandState = LoadingState.error;
      _errorMessage = 'Error ejecutando comando: ${e.toString()}';
      print('Error en executeCommand: $e');
      notifyListeners();
      return null;
    }
  }

  /// Cargar estadísticas (API FIRST)
  Future<void> loadStatistics() async {
    _statisticsState = LoadingState.loading;
    notifyListeners();

    try {
      if (!_isOfflineMode) {
        // 1. INTENTAR OBTENER DESDE API
        final apiResult = await _apiService.getStatistics();
        if (apiResult.isSuccess && apiResult.data != null) {
          _statistics = apiResult.data!;
          _statisticsState = LoadingState.success;
          notifyListeners();
          return;
        }
      }

      // 2. SI API FALLA, CALCULAR LOCALMENTE
      _statistics = await DatabaseService.getStatistics();
      _statistics['mode'] = _isOfflineMode ? 'offline' : 'local_fallback';
      _statisticsState = LoadingState.success;
    } catch (e) {
      _statisticsState = LoadingState.error;
      _errorMessage = 'Error cargando estadísticas: ${e.toString()}';
      print('Error en loadStatistics: $e');
    }

    notifyListeners();
  }

  /// Configurar modo offline
  void setOfflineMode(bool isOffline) {
    _isOfflineMode = isOffline;
    notifyListeners();

    if (!isOffline) {
      // Si salimos del modo offline, recargar desde API
      loadSessions();
      loadStatistics();
    }
  }

  /// Sincronizar manualmente con API
  Future<void> syncWithApi() async {
    if (_isOfflineMode) {
      _errorMessage = 'No se puede sincronizar en modo offline';
      notifyListeners();
      return;
    }

    _sessionsState = LoadingState.loading;
    notifyListeners();

    try {
      // 1. OBTENER DATOS DE API
      final apiResult = await _apiService.getAllSessions();
      if (apiResult.isSuccess && apiResult.data != null) {
        final apiSessions = apiResult.data!;

        // 2. OBTENER DATOS LOCALES
        final localSessions = await DatabaseService.getAllSessions();

        // 3. SINCRONIZACIÓN BIDIRECCIONAL
        await _performBidirectionalSync(apiSessions, localSessions);

        // 4. RECARGAR DATOS SINCRONIZADOS
        _sessions = await DatabaseService.getAllSessions();
        _applyFilters();
        _successMessage = 'Sincronización bidireccional completada';
        _sessionsState = LoadingState.success;
      } else {
        throw Exception(apiResult.error ?? 'Error desconocido');
      }
    } catch (e) {
      _errorMessage = 'Error en sincronización: ${e.toString()}';
      _sessionsState = LoadingState.error;
    }

    notifyListeners();
  }

  /// Realizar sincronización bidireccional entre API y base de datos local
  Future<void> _performBidirectionalSync(
      List<CCSession> apiSessions, List<CCSession> localSessions) async {
    try {
      // Crear mapas por ID para comparación eficiente
      final apiMap = {for (var session in apiSessions) session.id: session};
      final localMap = {for (var session in localSessions) session.id: session};

      // PASO 1: Sincronizar sesiones de API a local
      for (final apiSession in apiSessions) {
        final localSession = localMap[apiSession.id];

        if (localSession == null) {
          // Sesión existe en API pero no en local → Agregar a local
          await DatabaseService.insertSession(apiSession);
          print('[SYNC] Agregada a local: ${apiSession.machineName}');
        } else {
          // Sesión existe en ambos → Actualizar local con datos de API (API es la fuente de verdad)
          if (_sessionNeedsUpdate(localSession, apiSession)) {
            await DatabaseService.updateSession(apiSession);
            print('[SYNC] Actualizada en local: ${apiSession.machineName}');
          }
        }
      }

      // PASO 2: Sincronizar sesiones locales que no están en API
      for (final localSession in localSessions) {
        if (!apiMap.containsKey(localSession.id)) {
          // Sesión existe en local pero no en API → Enviar a API
          try {
            final createResult = await _apiService.createSession(localSession);
            if (createResult.isSuccess && createResult.data != null) {
              // Actualizar local con datos de API (puede tener ID diferente)
              await DatabaseService.deleteSession(localSession.id);
              await DatabaseService.insertSession(createResult.data!);
              print('[SYNC] Enviada a API: ${localSession.machineName}');
            }
          } catch (e) {
            print(
                '[SYNC] Error enviando ${localSession.machineName} a API: $e');
            // Mantener en local aunque no se pudo enviar a API
          }
        }
      }

      print('[SYNC] Sincronización bidireccional completada');
    } catch (e) {
      print('[SYNC] Error en sincronización bidireccional: $e');
      throw e;
    }
  }

  /// Verificar si una sesión necesita actualización
  bool _sessionNeedsUpdate(CCSession local, CCSession api) {
    return local.timestamp.isBefore(api.timestamp) ||
        local.lastCommand != api.lastCommand ||
        local.status != api.status ||
        local.commandHistory.length != api.commandHistory.length;
  }

  /// Limpiar mensajes
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Limpiar resultados de comandos
  void clearCommandResults() {
    _commandResults.clear();
    notifyListeners();
  }

  /// Obtener sesiones por estado
  List<CCSession> getSessionsByStatus(SessionStatus status) {
    return _sessions.where((session) => session.status == status).toList();
  }

  /// Obtener conteo de sesiones por estado
  int getSessionCountByStatus(SessionStatus status) {
    return getSessionsByStatus(status).length;
  }

  /// Refrescar datos (pull-to-refresh)
  Future<void> refresh() async {
    await Future.wait([
      loadSessions(refresh: true),
      loadStatistics(),
    ]);
  }

  /// Recrear base de datos (para solucionar problemas de formato)
  Future<void> recreateDatabase() async {
    try {
      _sessionsState = LoadingState.loading;
      notifyListeners();

      await DatabaseService.recreateDatabase();
      await loadSessions();
      await loadStatistics();

      _successMessage = 'Base de datos recreada exitosamente';
    } catch (e) {
      _errorMessage = 'Error recreando base de datos: ${e.toString()}';
      _sessionsState = LoadingState.error;
    }
    notifyListeners();
  }

  /// Métodos adicionales para compatibilidad con la UI existente

  /// Establecer query de búsqueda (alias para searchSessions)
  Future<void> setSearchQuery(String query) async {
    await searchSessions(query);
  }

  /// Establecer filtro de estado (alias para filterByStatus)
  Future<void> setStatusFilter(SessionStatus? status) async {
    await filterByStatus(status);
  }

  /// Cargar más sesiones (paginación - simplificado para compatibilidad)
  Future<void> loadMoreSessions() async {
    // En esta implementación simplificada, solo recargamos
    await loadSessions();
  }

  /// Terminar todas las sesiones activas (API FIRST)
  Future<void> terminateAllSessions() async {
    try {
      if (!_isOfflineMode) {
        // 1. TERMINAR EN API PRIMERO
        final apiResult = await _apiService.terminateAllSessions();
        if (!apiResult.isSuccess) {
          throw Exception(apiResult.error ?? 'Error desconocido');
        }
        _successMessage = 'Todas las sesiones terminadas en servidor';
      } else {
        // 2. SI OFFLINE, TERMINAR LOCALMENTE
        final activeSessions =
            _sessions.where((s) => s.status == SessionStatus.active).toList();

        for (final session in activeSessions) {
          final terminatedSession = session.copyWith(
            status: SessionStatus.inactive,
            timestamp: DateTime.now(),
          );
          await DatabaseService.updateSession(terminatedSession);
        }
        _successMessage = 'Todas las sesiones terminadas localmente (offline)';
      }

      // 3. RECARGAR DATOS
      await loadSessions();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error terminando sesiones: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Getters de estadísticas para compatibilidad
  int get totalSessions => _sessions.length;
  int get activeSessions => getSessionCountByStatus(SessionStatus.active);
  int get inactiveSessions => getSessionCountByStatus(SessionStatus.inactive);

  /// Getter para paginación (simplificado)
  bool get hasMoreData => false; // Simplificado para esta implementación

  @override
  void dispose() {
    // Limpiar recursos si es necesario
    super.dispose();
  }
}
