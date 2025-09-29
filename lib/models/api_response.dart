/// Clase genérica para respuestas de la API
class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool isSuccess;
  final int? statusCode;

  ApiResponse.success(this.data)
      : error = null,
        isSuccess = true,
        statusCode = 200;

  ApiResponse.error(this.error, {this.statusCode})
      : data = null,
        isSuccess = false;

  ApiResponse.loading()
      : data = null,
        error = null,
        isSuccess = false,
        statusCode = null;

  bool get isLoading => data == null && error == null;
  bool get hasError => error != null;
  bool get hasData => data != null;
}

/// Estados posibles para las operaciones CRUD
enum CrudState {
  idle,
  loading,
  success,
  error,
}

/// Clase para manejar el estado de las operaciones CRUD
class CrudOperation<T> {
  final CrudState state;
  final T? data;
  final String? error;
  final String? message;

  const CrudOperation({
    required this.state,
    this.data,
    this.error,
    this.message,
  });

  const CrudOperation.idle() : this(state: CrudState.idle);
  const CrudOperation.loading() : this(state: CrudState.loading);
  const CrudOperation.success(T data, {String? message}) 
      : this(state: CrudState.success, data: data, message: message);
  const CrudOperation.error(String error) 
      : this(state: CrudState.error, error: error);

  bool get isIdle => state == CrudState.idle;
  bool get isLoading => state == CrudState.loading;
  bool get isSuccess => state == CrudState.success;
  bool get isError => state == CrudState.error;
}
