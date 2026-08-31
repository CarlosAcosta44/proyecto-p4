import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../services/secure_storage_service.dart';

/// Interceptor de Dio que:
/// 1. Inyecta el JWT en cada petición (Authorization: Bearer TOKEN)
/// 2. Si recibe 401, intenta renovar el access token usando el refresh token
/// 3. Reintenta la petición original con el nuevo token
/// 4. Si la renovación falla, limpia los tokens (sesión expirada)
class InterceptorAuth extends Interceptor {
  final Dio dio;

  InterceptorAuth(this.dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await SecureStorageService.leerAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Solo intervenir en errores 401
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    final refreshToken = await SecureStorageService.leerRefreshToken();
    if (refreshToken == null) {
      await SecureStorageService.limpiarTokens();
      return handler.next(err);
    }

    try {
      // Crear una instancia Dio limpia (sin interceptor) para el refresh
      final dioRefresh = Dio(BaseOptions(baseUrl: AppConfig.baseUrl));
      final response = await dioRefresh.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final nuevoAccessToken = response.data['accessToken'] as String;
      final nuevoRefreshToken = response.data['refreshToken'] as String;

      await SecureStorageService.guardarTokens(
        accessToken: nuevoAccessToken,
        refreshToken: nuevoRefreshToken,
      );

      // Reintentar la petición original con el nuevo token
      final opciones = err.requestOptions;
      opciones.headers['Authorization'] = 'Bearer $nuevoAccessToken';

      final retryResponse = await dio.fetch(opciones);
      return handler.resolve(retryResponse);
    } catch (_) {
      // Si el refresh falló, limpiar sesión
      await SecureStorageService.limpiarTokens();
      return handler.next(err);
    }
  }
}

/// Crea y configura la instancia principal de Dio con el interceptor de auth.
Dio crearDioConAuth() {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(InterceptorAuth(dio));

  return dio;
}
