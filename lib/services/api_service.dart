import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cc_session.dart';
import '../models/api_response.dart';
import '../models/session_status.dart';

/// Servicio para comunicación con la API REST del backend C&C (versión corregida)
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio _dio;
  String _baseUrl = 'http://localhost:3000/api'; // URL por defecto del backend

  /// Inicializa el servicio API
  Future<void> initialize() async {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Interceptor para logging en desarrollo
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print('[API] $obj'),
    ));

    // Interceptor para manejo de errores
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) {
        print('[API Error] ${error.message}');
        handler.next(error);
      },
    ));

    // Cargar URL personalizada si existe
    await _loadCustomBaseUrl();
  }

  /// Carga la URL base personalizada desde SharedPreferences
  Future<void> _loadCustomBaseUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customUrl = prefs.getString('api_base_url');
      if (customUrl != null && customUrl.isNotEmpty) {
        setBaseUrl(customUrl);
      }
    } catch (e) {
      print('[API] Error loading custom base URL: $e');
    }
  }

  /// Establece una nueva URL base para la API
  Future<void> setBaseUrl(String url) async {
    _baseUrl = url;
    _dio.options.baseUrl = url;

    // Guardar en SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('api_base_url', url);
    } catch (e) {
      print('[API] Error saving custom base URL: $e');
    }
  }

  /// Obtiene la URL base actual
  String get baseUrl => _baseUrl;

  /// Verifica la conectividad con el servidor
  Future<ApiResponse<bool>> checkConnection() async {
    try {
      final response = await _dio.get('/health');
      return ApiResponse.success(response.statusCode == 200);
    } catch (e) {
      return ApiResponse.error('Error de conexión: ${_getErrorMessage(e)}');
    }
  }

  /// Obtiene todas las sesiones
  Future<ApiResponse<List<CCSession>>> getAllSessions({
    int page = 1,
    int limit = 20,
    String? search,
    SessionStatus? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (status != null) {
        queryParams['status'] = _statusToApiString(status);
      }

      final response =
          await _dio.get('/sessions', queryParameters: queryParams);

      final List<dynamic> sessionsJson =
          response.data['sessions'] ?? response.data;
      final sessions = sessionsJson
          .map((json) => _apiJsonToSession(json as Map<String, dynamic>))
          .toList();

      return ApiResponse.success(sessions);
    } catch (e) {
      return ApiResponse.error(
          'Error obteniendo sesiones: ${_getErrorMessage(e)}');
    }
  }

  /// Obtiene una sesión específica por ID
  Future<ApiResponse<CCSession>> getSession(String id) async {
    try {
      final response = await _dio.get('/sessions/$id');
      final session = _apiJsonToSession(response.data);
      return ApiResponse.success(session);
    } catch (e) {
      return ApiResponse.error(
          'Error obteniendo sesión: ${_getErrorMessage(e)}');
    }
  }

  /// Crea una nueva sesión
  Future<ApiResponse<CCSession>> createSession(CCSession session) async {
    try {
      // Convertir sesión a formato compatible con API
      final apiData = _sessionToApiJson(session);
      print('[API] Enviando datos: $apiData'); // Debug

      final response = await _dio.post('/sessions', data: apiData);
      final createdSession = _apiJsonToSession(response.data);
      return ApiResponse.success(createdSession);
    } catch (e) {
      print('[API] Error creando sesión: $e'); // Debug
      return ApiResponse.error('Error creando sesión: ${_getErrorMessage(e)}');
    }
  }

  /// Actualiza una sesión existente
  Future<ApiResponse<CCSession>> updateSession(CCSession session) async {
    try {
      // Convertir sesión a formato compatible con API
      final apiData = _sessionToApiJson(session);

      final response = await _dio.put('/sessions/${session.id}', data: apiData);
      final updatedSession = _apiJsonToSession(response.data);
      return ApiResponse.success(updatedSession);
    } catch (e) {
      return ApiResponse.error(
          'Error actualizando sesión: ${_getErrorMessage(e)}');
    }
  }

  /// Elimina una sesión
  Future<ApiResponse<bool>> deleteSession(String id) async {
    try {
      await _dio.delete('/sessions/$id');
      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.error(
          'Error eliminando sesión: ${_getErrorMessage(e)}');
    }
  }

  /// Ejecuta un comando en una sesión específica
  Future<ApiResponse<CCSession>> executeCommand(
      String sessionId, String command) async {
    try {
      final response = await _dio.post(
        '/sessions/$sessionId/command',
        data: {'command': command},
      );

      // La API devuelve { session: {...}, commandResponse: {...} }
      final sessionData = response.data['session'];
      final updatedSession = _apiJsonToSession(sessionData);
      return ApiResponse.success(updatedSession);
    } catch (e) {
      return ApiResponse.error(
          'Error ejecutando comando: ${_getErrorMessage(e)}');
    }
  }

  /// Obtiene estadísticas del sistema C&C
  Future<ApiResponse<Map<String, dynamic>>> getStatistics() async {
    try {
      final response = await _dio.get('/statistics');
      return ApiResponse.success(response.data);
    } catch (e) {
      return ApiResponse.error(
          'Error obteniendo estadísticas: ${_getErrorMessage(e)}');
    }
  }

  /// Termina todas las sesiones activas
  Future<ApiResponse<bool>> terminateAllSessions() async {
    try {
      await _dio.post('/sessions/terminate-all');
      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.error(
          'Error terminando sesiones: ${_getErrorMessage(e)}');
    }
  }

  /// Obtiene el historial de comandos de una sesión
  Future<ApiResponse<List<String>>> getCommandHistory(String sessionId) async {
    try {
      final response = await _dio.get('/sessions/$sessionId/history');
      final List<dynamic> history = response.data['history'] ?? [];
      return ApiResponse.success(history.cast<String>());
    } catch (e) {
      return ApiResponse.error(
          'Error obteniendo historial: ${_getErrorMessage(e)}');
    }
  }

  /// Convierte CCSession a formato JSON compatible con API
  Map<String, dynamic> _sessionToApiJson(CCSession session) {
    return {
      // Limpiar machineName para que sea alfanumérico
      'machineName': _sanitizeMachineName(session.machineName),
      'ipAddress': session.ipAddress,
      'status': _statusToApiString(session.status),
      'port': session.port,
      'operatingSystem': session.operatingSystem,
      'notes': session.notes,
      // NO enviar id, lastCommand, commandHistory, timestamp - los maneja la API
    };
  }

  /// Convierte JSON de API a CCSession
  CCSession _apiJsonToSession(Map<String, dynamic> json) {
    return CCSession(
      id: json['id'] ?? '',
      machineName: json['machineName'] ?? '',
      ipAddress: json['ipAddress'] ?? '',
      status: _apiStringToStatus(json['status']),
      lastCommand: json['lastCommand'],
      commandHistory: json['commandHistory'] is List
          ? List<String>.from(json['commandHistory'])
          : [],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      port: json['port'],
      operatingSystem: json['operatingSystem'],
      notes: json['notes'],
    );
  }

  /// Limpia el nombre de máquina para que sea alfanumérico
  String _sanitizeMachineName(String machineName) {
    // Reemplazar caracteres no alfanuméricos con letras/números
    return machineName
        .replaceAll('-', '') // Quitar guiones
        .replaceAll('_', '') // Quitar guiones bajos
        .replaceAll(' ', '') // Quitar espacios
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'),
            ''); // Quitar cualquier otro carácter especial
  }

  /// Convierte SessionStatus a string para API
  String _statusToApiString(SessionStatus status) {
    switch (status) {
      case SessionStatus.active:
        return 'active';
      case SessionStatus.inactive:
        return 'inactive';
      case SessionStatus.connecting:
        return 'connecting';
      case SessionStatus.error:
        return 'error';
    }
  }

  /// Convierte string de API a SessionStatus
  SessionStatus _apiStringToStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return SessionStatus.active;
      case 'inactive':
        return SessionStatus.inactive;
      case 'connecting':
        return SessionStatus.connecting;
      case 'error':
        return SessionStatus.error;
      default:
        return SessionStatus.inactive;
    }
  }

  /// Extrae el mensaje de error de diferentes tipos de excepciones
  String _getErrorMessage(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return 'Tiempo de conexión agotado';
        case DioExceptionType.receiveTimeout:
          return 'Tiempo de respuesta agotado';
        case DioExceptionType.connectionError:
          return 'Error de conexión con el servidor';
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final message = error.response?.data?['error'] ??
              error.response?.data?['message'] ??
              'Error del servidor';

          // Si hay detalles de validación, incluirlos
          if (error.response?.data?['details'] != null) {
            final details = error.response!.data!['details'] as List;
            return 'Error HTTP $statusCode: $message. Detalles: ${details.join(', ')}';
          }

          return 'Error HTTP $statusCode: $message';
        case DioExceptionType.cancel:
          return 'Operación cancelada';
        default:
          return error.message ?? 'Error desconocido';
      }
    } else if (error is SocketException) {
      return 'Sin conexión a internet';
    } else {
      return error.toString();
    }
  }

  /// Cancela todas las peticiones pendientes
  void cancelAllRequests() {
    // Cerrar el cliente Dio si es necesario
    try {
      _dio.close();
    } catch (e) {
      print('[API] Error cerrando conexiones: $e');
    }
  }
}
