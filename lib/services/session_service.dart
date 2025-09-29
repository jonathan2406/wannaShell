import '../models/cc_session.dart';
import '../models/session_status.dart';
import '../models/api_response.dart';
import 'database_service.dart';
import 'api_service.dart';

/// Servicio que coordina entre la base de datos local y la API remota
class SessionService {
  final ApiService _apiService = ApiService();
  bool _isOfflineMode = false;

  /// Configurar modo offline
  void setOfflineMode(bool isOffline) {
    _isOfflineMode = isOffline;
  }

  /// Obtener todas las sesiones
  Future<List<CCSession>> getAllSessions({
    String? search,
    SessionStatus? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      List<CCSession> sessions;
      
      if (search != null && search.isNotEmpty) {
        sessions = await DatabaseService.searchSessions(search);
      } else if (status != null) {
        sessions = await DatabaseService.getSessionsByStatus(status);
      } else {
        sessions = await DatabaseService.getAllSessions();
      }

      // Sincronizar con API si no estamos offline
      if (!_isOfflineMode) {
        _syncWithApiInBackground();
      }

      return sessions;
    } catch (e) {
      print('Error obteniendo sesiones: $e');
      return [];
    }
  }

  /// Sincronización en segundo plano con la API
  Future<void> _syncWithApiInBackground() async {
    try {
      final apiResult = await _apiService.getAllSessions();
      if (apiResult.isSuccess && apiResult.data != null) {
        for (final session in apiResult.data!) {
          await DatabaseService.insertSession(session);
        }
      }
    } catch (e) {
      // Error de API no es crítico, seguimos con datos locales
      print('Error sincronizando con API: $e');
    }
  }

  /// Obtener una sesión específica
  Future<CCSession?> getSession(String id) async {
    try {
      return await DatabaseService.getSessionById(id);
    } catch (e) {
      print('Error obteniendo sesión: $e');
      return null;
    }
  }

  /// Crear nueva sesión
  Future<CCSession?> createSession(CCSession session) async {
    try {
      // Insertar en base de datos local
      await DatabaseService.insertSession(session);
      
      // Intentar crear en API si no estamos offline
      if (!_isOfflineMode) {
        try {
          final apiResult = await _apiService.createSession(session);
          if (apiResult.isSuccess && apiResult.data != null) {
            // Actualizar con datos de la API si es exitoso
            await DatabaseService.updateSession(apiResult.data!);
            return apiResult.data;
          }
        } catch (e) {
          print('Error creando en API: $e');
        }
      }
      
      return session;
    } catch (e) {
      print('Error creando sesión: $e');
      throw Exception('Error creando sesión: ${e.toString()}');
    }
  }

  /// Actualizar sesión
  Future<CCSession?> updateSession(CCSession session) async {
    try {
      // Actualizar en base de datos local
      await DatabaseService.updateSession(session);
      
      // Intentar actualizar en API si no estamos offline
      if (!_isOfflineMode) {
        try {
          final apiResult = await _apiService.updateSession(session);
          if (apiResult.isSuccess && apiResult.data != null) {
            // Actualizar con datos de la API si es exitoso
            await DatabaseService.updateSession(apiResult.data!);
            return apiResult.data;
          }
        } catch (e) {
          print('Error actualizando en API: $e');
        }
      }
      
      return session;
    } catch (e) {
      print('Error actualizando sesión: $e');
      throw Exception('Error actualizando sesión: ${e.toString()}');
    }
  }

  /// Eliminar sesión
  Future<bool> deleteSession(String id) async {
    try {
      // Eliminar de base de datos local
      await DatabaseService.deleteSession(id);
      
      // Intentar eliminar en API si no estamos offline
      if (!_isOfflineMode) {
        try {
          await _apiService.deleteSession(id);
        } catch (e) {
          print('Error eliminando en API: $e');
        }
      }
      
      return true;
    } catch (e) {
      print('Error eliminando sesión: $e');
      throw Exception('Error eliminando sesión: ${e.toString()}');
    }
  }

  /// Ejecutar comando
  Future<Map<String, dynamic>?> executeCommand(String sessionId, String command) async {
    try {
      return await DatabaseService.executeCommand(sessionId, command);
    } catch (e) {
      print('Error ejecutando comando: $e');
      throw Exception('Error ejecutando comando: ${e.toString()}');
    }
  }

  /// Obtener estadísticas
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      return await DatabaseService.getStatistics();
    } catch (e) {
      print('Error obteniendo estadísticas: $e');
      return {
        'totalSessions': 0,
        'activeSessions': 0,
        'inactiveSessions': 0,
        'connectingSessions': 0,
        'errorSessions': 0,
        'lastUpdate': DateTime.now().toIso8601String(),
        'mode': 'offline',
      };
    }
  }

  /// Terminar todas las sesiones activas
  Future<int> terminateAllSessions() async {
    try {
      final sessions = await DatabaseService.getAllSessions();
      final activeSessions = sessions.where((s) => s.status == SessionStatus.active).toList();
      
      for (final session in activeSessions) {
        final terminatedSession = session.copyWith(
          status: SessionStatus.inactive,
          timestamp: DateTime.now(),
        );
        await DatabaseService.updateSession(terminatedSession);
      }
      
      return activeSessions.length;
    } catch (e) {
      print('Error terminando sesiones: $e');
      throw Exception('Error terminando sesiones: ${e.toString()}');
    }
  }

  /// Limpiar todos los datos
  Future<void> clearAllData() async {
    try {
      await DatabaseService.clearDatabase();
    } catch (e) {
      print('Error limpiando datos: $e');
      throw Exception('Error limpiando datos: ${e.toString()}');
    }
  }
}
