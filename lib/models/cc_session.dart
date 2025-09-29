import 'package:json_annotation/json_annotation.dart';
import 'session_status.dart';

part 'cc_session.g.dart';

/// Modelo de datos para una sesión de Comando y Control (C&C)
/// Representa una máquina conectada al sistema C&C
@JsonSerializable()
class CCSession {
  /// Identificador único de la sesión
  final String id;
  
  /// Nombre de la máquina objetivo
  final String machineName;
  
  /// Dirección IP de la máquina
  final String ipAddress;
  
  /// Estado actual de la sesión
  final SessionStatus status;
  
  /// Último comando ejecutado
  final String? lastCommand;
  
  /// Historial de comandos ejecutados
  final List<String> commandHistory;
  
  /// Marca de tiempo de la última actividad
  final DateTime timestamp;
  
  /// Puerto de conexión (opcional)
  final int? port;
  
  /// Sistema operativo de la máquina objetivo
  final String? operatingSystem;
  
  /// Información adicional sobre la sesión
  final String? notes;

  CCSession({
    required this.id,
    required this.machineName,
    required this.ipAddress,
    required this.status,
    this.lastCommand,
    List<String>? commandHistory,
    DateTime? timestamp,
    this.port,
    this.operatingSystem,
    this.notes,
  }) : 
    commandHistory = commandHistory ?? [],
    timestamp = timestamp ?? DateTime.now();

  /// Constructor para crear una nueva sesión
  factory CCSession.create({
    required String machineName,
    required String ipAddress,
    SessionStatus status = SessionStatus.inactive,
    int? port,
    String? operatingSystem,
    String? notes,
  }) {
    return CCSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      machineName: machineName,
      ipAddress: ipAddress,
      status: status,
      port: port,
      operatingSystem: operatingSystem,
      notes: notes,
    );
  }

  /// Constructor desde JSON
  factory CCSession.fromJson(Map<String, dynamic> json) => _$CCSessionFromJson(json);
  
  /// Convierte a JSON
  Map<String, dynamic> toJson() => _$CCSessionToJson(this);

  /// Crea una copia de la sesión con campos modificados
  CCSession copyWith({
    String? id,
    String? machineName,
    String? ipAddress,
    SessionStatus? status,
    String? lastCommand,
    List<String>? commandHistory,
    DateTime? timestamp,
    int? port,
    String? operatingSystem,
    String? notes,
  }) {
    return CCSession(
      id: id ?? this.id,
      machineName: machineName ?? this.machineName,
      ipAddress: ipAddress ?? this.ipAddress,
      status: status ?? this.status,
      lastCommand: lastCommand ?? this.lastCommand,
      commandHistory: commandHistory ?? this.commandHistory,
      timestamp: timestamp ?? this.timestamp,
      port: port ?? this.port,
      operatingSystem: operatingSystem ?? this.operatingSystem,
      notes: notes ?? this.notes,
    );
  }

  /// Añade un comando al historial y actualiza la sesión
  CCSession executeCommand(String command) {
    final newHistory = [...commandHistory, command];
    return copyWith(
      lastCommand: command,
      commandHistory: newHistory,
      timestamp: DateTime.now(),
      status: SessionStatus.active,
    );
  }

  /// Obtiene un resumen de la sesión para mostrar en listas
  String get summary {
    final statusText = status.displayName;
    final lastActivity = lastCommand != null 
        ? 'Último comando: $lastCommand' 
        : 'Sin comandos ejecutados';
    return '$machineName ($ipAddress) - $statusText\n$lastActivity';
  }

  /// Verifica si la sesión está activa
  bool get isActive => status == SessionStatus.active;

  /// Obtiene el tiempo transcurrido desde la última actividad
  Duration get timeSinceLastActivity => DateTime.now().difference(timestamp);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CCSession &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CCSession(id: $id, machineName: $machineName, ipAddress: $ipAddress, status: $status)';
  }
}
