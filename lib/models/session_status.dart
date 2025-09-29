/// Enumeración para el estado de las sesiones de C&C
enum SessionStatus {
  active('activo'),
  inactive('inactivo'),
  connecting('conectando'),
  error('error');

  const SessionStatus(this.displayName);
  final String displayName;

  /// Convierte una cadena a SessionStatus
  static SessionStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'activo':
      case 'active':
        return SessionStatus.active;
      case 'inactivo':
      case 'inactive':
        return SessionStatus.inactive;
      case 'conectando':
      case 'connecting':
        return SessionStatus.connecting;
      case 'error':
        return SessionStatus.error;
      default:
        return SessionStatus.inactive;
    }
  }

  /// Convierte SessionStatus a cadena para API
  String toApiString() {
    switch (this) {
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
}
