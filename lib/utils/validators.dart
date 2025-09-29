import 'constants.dart';

/// Clase con validadores para formularios
class Validators {
  /// Valida que un campo no esté vacío
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Este campo'} es requerido';
    }
    return null;
  }

  /// Valida el nombre de la máquina
  static String? machineName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre de la máquina es requerido';
    }
    
    if (value.length > AppConstants.maxMachineNameLength) {
      return 'El nombre no puede exceder ${AppConstants.maxMachineNameLength} caracteres';
    }
    
    // Verificar caracteres válidos (alfanuméricos, guiones y guiones bajos)
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(value)) {
      return 'Solo se permiten letras, números, guiones y guiones bajos';
    }
    
    return null;
  }

  /// Valida la dirección IP
  static String? ipAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La dirección IP es requerida';
    }
    
    if (!AppConstants.ipAddressRegex.hasMatch(value.trim())) {
      return 'Ingrese una dirección IP válida (ej: 192.168.1.1)';
    }
    
    return null;
  }

  /// Valida el puerto
  static String? port(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Puerto es opcional
    }
    
    final portNumber = int.tryParse(value.trim());
    if (portNumber == null) {
      return 'El puerto debe ser un número';
    }
    
    if (portNumber < 1 || portNumber > 65535) {
      return 'El puerto debe estar entre 1 y 65535';
    }
    
    return null;
  }

  /// Valida el comando
  static String? command(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El comando es requerido';
    }
    
    if (value.trim().length < 2) {
      return 'El comando debe tener al menos 2 caracteres';
    }
    
    return null;
  }

  /// Valida las notas
  static String? notes(String? value) {
    if (value != null && value.length > AppConstants.maxNotesLength) {
      return 'Las notas no pueden exceder ${AppConstants.maxNotesLength} caracteres';
    }
    return null;
  }

  /// Valida la URL de la API
  static String? apiUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La URL de la API es requerida';
    }
    
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return 'Ingrese una URL válida (ej: http://localhost:3000/api)';
    }
    
    if (!['http', 'https'].contains(uri.scheme)) {
      return 'La URL debe usar protocolo HTTP o HTTPS';
    }
    
    return null;
  }

  /// Valida un email (opcional para configuraciones futuras)
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Email es opcional
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    );
    
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Ingrese un email válido';
    }
    
    return null;
  }

  /// Combina múltiples validadores
  static String? Function(String?) combine(List<String? Function(String?)> validators) {
    return (String? value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) {
          return result;
        }
      }
      return null;
    };
  }

  /// Valida longitud mínima
  static String? Function(String?) minLength(int min, [String? fieldName]) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return null; // Dejar que 'required' maneje campos vacíos
      }
      
      if (value.length < min) {
        return '${fieldName ?? 'Este campo'} debe tener al menos $min caracteres';
      }
      
      return null;
    };
  }

  /// Valida longitud máxima
  static String? Function(String?) maxLength(int max, [String? fieldName]) {
    return (String? value) {
      if (value != null && value.length > max) {
        return '${fieldName ?? 'Este campo'} no puede exceder $max caracteres';
      }
      return null;
    };
  }

  /// Valida que contenga solo números
  static String? numeric(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return null;
    }
    
    if (int.tryParse(value) == null) {
      return '${fieldName ?? 'Este campo'} debe contener solo números';
    }
    
    return null;
  }

  /// Valida rango numérico
  static String? Function(String?) numberRange(int min, int max, [String? fieldName]) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return null;
      }
      
      final number = int.tryParse(value);
      if (number == null) {
        return '${fieldName ?? 'Este campo'} debe ser un número';
      }
      
      if (number < min || number > max) {
        return '${fieldName ?? 'Este campo'} debe estar entre $min y $max';
      }
      
      return null;
    };
  }
}
