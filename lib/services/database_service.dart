import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/cc_session.dart';
import '../models/session_status.dart';

/// Servicio para manejar la base de datos local SQLite
class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'cybersec_cc.db';
  static const int _databaseVersion = 1;
  static const String _tableName = 'sessions';

  /// Singleton para obtener la instancia de la base de datos
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Inicializar la base de datos
  static Future<Database> _initDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, _databaseName);

      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _createTables,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      print('Error inicializando base de datos: $e');
      rethrow;
    }
  }

  /// Crear las tablas de la base de datos
  static Future<void> _createTables(Database db, int version) async {
    try {
      await db.execute('''
        CREATE TABLE $_tableName(
          id TEXT PRIMARY KEY,
          machineName TEXT NOT NULL,
          ipAddress TEXT NOT NULL,
          status TEXT NOT NULL,
          lastCommand TEXT,
          commandHistory TEXT,
          timestamp TEXT NOT NULL,
          port INTEGER,
          operatingSystem TEXT,
          notes TEXT
        )
      ''');

      // Insertar datos de ejemplo
      await _insertSampleData(db);
    } catch (e) {
      print('Error creando tablas: $e');
      rethrow;
    }
  }

  /// Insertar datos de ejemplo
  static Future<void> _insertSampleData(Database db) async {
    final sampleSessions = [
      {
        'id': 'sample-1',
        'machineName': 'LAB-PC-001',
        'ipAddress': '192.168.1.100',
        'status': 'active',
        'lastCommand': 'whoami',
        'commandHistory': jsonEncode(['whoami', 'pwd', 'dir']),
        'timestamp': DateTime.now().subtract(Duration(minutes: 5)).toIso8601String(),
        'port': 4444,
        'operatingSystem': 'Windows 10',
        'notes': 'Máquina de pruebas principal del laboratorio'
      },
      {
        'id': 'sample-2',
        'machineName': 'LAB-LINUX-001',
        'ipAddress': '192.168.1.101',
        'status': 'inactive',
        'lastCommand': 'ps aux',
        'commandHistory': jsonEncode(['uname -a', 'ps aux', 'ls -la']),
        'timestamp': DateTime.now().subtract(Duration(minutes: 15)).toIso8601String(),
        'port': 4445,
        'operatingSystem': 'Ubuntu 20.04',
        'notes': 'Servidor Linux para pruebas de penetración'
      },
      {
        'id': 'sample-3',
        'machineName': 'LAB-MAC-001',
        'ipAddress': '192.168.1.102',
        'status': 'connecting',
        'lastCommand': null,
        'commandHistory': jsonEncode([]),
        'timestamp': DateTime.now().subtract(Duration(minutes: 2)).toIso8601String(),
        'port': 4446,
        'operatingSystem': 'macOS Monterey',
        'notes': 'MacBook para pruebas de compatibilidad multiplataforma'
      },
    ];

    for (final session in sampleSessions) {
      await db.insert(_tableName, session);
    }
  }

  /// Manejar actualizaciones de la base de datos
  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Implementar migraciones si es necesario
  }

  /// Obtener todas las sesiones
  static Future<List<CCSession>> getAllSessions() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        orderBy: 'timestamp DESC',
      );

      return maps.map((map) => _mapToSession(map)).toList();
    } catch (e) {
      print('Error obteniendo sesiones: $e');
      return [];
    }
  }

  /// Buscar sesiones por término
  static Future<List<CCSession>> searchSessions(String searchTerm) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'machineName LIKE ? OR ipAddress LIKE ? OR operatingSystem LIKE ?',
        whereArgs: ['%$searchTerm%', '%$searchTerm%', '%$searchTerm%'],
        orderBy: 'timestamp DESC',
      );

      return maps.map((map) => _mapToSession(map)).toList();
    } catch (e) {
      print('Error buscando sesiones: $e');
      return [];
    }
  }

  /// Filtrar sesiones por estado
  static Future<List<CCSession>> getSessionsByStatus(SessionStatus status) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'status = ?',
        whereArgs: [status.name],
        orderBy: 'timestamp DESC',
      );

      return maps.map((map) => _mapToSession(map)).toList();
    } catch (e) {
      print('Error filtrando sesiones: $e');
      return [];
    }
  }

  /// Obtener una sesión por ID
  static Future<CCSession?> getSessionById(String id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return _mapToSession(maps.first);
      }
      return null;
    } catch (e) {
      print('Error obteniendo sesión: $e');
      return null;
    }
  }

  /// Insertar una nueva sesión
  static Future<void> insertSession(CCSession session) async {
    try {
      final db = await database;
      await db.insert(
        _tableName,
        _sessionToMap(session),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error insertando sesión: $e');
      rethrow;
    }
  }

  /// Actualizar una sesión existente
  static Future<void> updateSession(CCSession session) async {
    try {
      final db = await database;
      await db.update(
        _tableName,
        _sessionToMap(session),
        where: 'id = ?',
        whereArgs: [session.id],
      );
    } catch (e) {
      print('Error actualizando sesión: $e');
      rethrow;
    }
  }

  /// Eliminar una sesión
  static Future<void> deleteSession(String id) async {
    try {
      final db = await database;
      await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error eliminando sesión: $e');
      rethrow;
    }
  }

  /// Ejecutar comando en una sesión (versión simplificada)
  static Future<Map<String, dynamic>> executeCommand(String sessionId, String command) async {
    try {
      final session = await getSessionById(sessionId);
      if (session == null) {
        throw Exception('Sesión no encontrada');
      }

      if (session.status != SessionStatus.active) {
        throw Exception('La sesión debe estar activa para ejecutar comandos');
      }

      // Actualizar historial (sin output simulado)
      final newHistory = List<String>.from(session.commandHistory)..add(command);
      
      final updatedSession = session.copyWith(
        lastCommand: command,
        commandHistory: newHistory,
        timestamp: DateTime.now(),
      );

      await updateSession(updatedSession);

      return {
        'command': command,
        'timestamp': DateTime.now().toIso8601String(),
        'success': true,
        'session': updatedSession,
      };
    } catch (e) {
      print('Error ejecutando comando: $e');
      return {
        'command': command,
        'timestamp': DateTime.now().toIso8601String(),
        'success': false,
        'error': e.toString(),
      };
    }
  }


  /// Convertir Map a CCSession
  static CCSession _mapToSession(Map<String, dynamic> map) {
    List<String> commandHistory = [];
    
    // Manejo seguro del historial de comandos
    if (map['commandHistory'] != null) {
      try {
        final historyData = map['commandHistory'];
        if (historyData is String) {
          // Si es string, intentar decodificar como JSON
          if (historyData.trim().startsWith('[')) {
            commandHistory = List<String>.from(jsonDecode(historyData));
          } else {
            // Si es un comando simple, crear lista con ese comando
            commandHistory = historyData.isEmpty ? [] : [historyData];
          }
        } else if (historyData is List) {
          // Si ya es una lista, convertir a List<String>
          commandHistory = List<String>.from(historyData);
        }
      } catch (e) {
        print('Error parseando commandHistory: $e');
        // En caso de error, crear lista vacía
        commandHistory = [];
      }
    }

    return CCSession(
      id: map['id'],
      machineName: map['machineName'],
      ipAddress: map['ipAddress'],
      status: SessionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SessionStatus.inactive,
      ),
      lastCommand: map['lastCommand'],
      commandHistory: commandHistory,
      timestamp: DateTime.parse(map['timestamp']),
      port: map['port'],
      operatingSystem: map['operatingSystem'],
      notes: map['notes'],
    );
  }

  /// Convertir CCSession a Map
  static Map<String, dynamic> _sessionToMap(CCSession session) {
    return {
      'id': session.id,
      'machineName': session.machineName,
      'ipAddress': session.ipAddress,
      'status': session.status.name,
      'lastCommand': session.lastCommand,
      'commandHistory': jsonEncode(session.commandHistory),
      'timestamp': session.timestamp.toIso8601String(),
      'port': session.port,
      'operatingSystem': session.operatingSystem,
      'notes': session.notes,
    };
  }

  /// Obtener estadísticas
  static Future<Map<String, dynamic>> getStatistics() async {
    try {
      final sessions = await getAllSessions();
      return {
        'totalSessions': sessions.length,
        'activeSessions': sessions.where((s) => s.status == SessionStatus.active).length,
        'inactiveSessions': sessions.where((s) => s.status == SessionStatus.inactive).length,
        'connectingSessions': sessions.where((s) => s.status == SessionStatus.connecting).length,
        'errorSessions': sessions.where((s) => s.status == SessionStatus.error).length,
        'totalCommands': sessions.fold<int>(0, (sum, session) => sum + session.commandHistory.length),
        'lastUpdate': DateTime.now().toIso8601String(),
        'mode': 'offline',
      };
    } catch (e) {
      print('Error obteniendo estadísticas: $e');
      return {
        'totalSessions': 0,
        'activeSessions': 0,
        'inactiveSessions': 0,
        'connectingSessions': 0,
        'errorSessions': 0,
        'totalCommands': 0,
        'lastUpdate': DateTime.now().toIso8601String(),
        'mode': 'offline',
      };
    }
  }

  /// Limpiar base de datos (para testing)
  static Future<void> clearDatabase() async {
    try {
      final db = await database;
      await db.delete(_tableName);
      await _insertSampleData(db);
    } catch (e) {
      print('Error limpiando base de datos: $e');
      rethrow;
    }
  }

  /// Recrear base de datos completamente (para solucionar problemas de formato)
  static Future<void> recreateDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, _databaseName);
      
      // Cerrar conexión actual si existe
      if (_database != null) {
        await _database!.close();
        _database = null;
      }
      
      // Eliminar archivo de base de datos
      await deleteDatabase(path);
      
      // Recrear base de datos
      _database = await _initDatabase();
    } catch (e) {
      print('Error recreando base de datos: $e');
      rethrow;
    }
  }
}
