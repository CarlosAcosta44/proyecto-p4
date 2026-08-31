import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/interceptor_auth.dart';
import '../../core/services/secure_storage_service.dart';

// ─── Modelo ─────────────────────────────────────────────────────────────────

class UsuarioModel {
  final int id;
  final String email;
  final String rol;

  const UsuarioModel({
    required this.id,
    required this.email,
    required this.rol,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) => UsuarioModel(
        id: json['id'] as int,
        email: json['email'] as String,
        rol: json['rol'] as String,
      );
}

// ─── Repository ─────────────────────────────────────────────────────────────

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  /// Inicia sesión y guarda los tokens en almacenamiento seguro.
  Future<UsuarioModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email.trim().toLowerCase(),
      'password': password,
    });

    await SecureStorageService.guardarTokens(
      accessToken: response.data['accessToken'] as String,
      refreshToken: response.data['refreshToken'] as String,
    );

    return UsuarioModel.fromJson(
      response.data['usuario'] as Map<String, dynamic>,
    );
  }

  /// Cierra la sesión: notifica al servidor y limpia tokens locales.
  Future<void> logout() async {
    final refreshToken = await SecureStorageService.leerRefreshToken();
    if (refreshToken != null) {
      try {
        await _dio.post('/auth/logout', data: {'refreshToken': refreshToken});
      } catch (_) {
        // Ignorar error al revocar en servidor; siempre limpiar local
      }
    }
    await SecureStorageService.limpiarTokens();
  }
}

// ─── State ───────────────────────────────────────────────────────────────────

sealed class AuthState {
  const AuthState();
}

class AuthIdle extends AuthState {
  const AuthIdle();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UsuarioModel usuario;
  const AuthAuthenticated(this.usuario);
}

class AuthError extends AuthState {
  final String mensaje;
  const AuthError(this.mensaje);
}

// ─── Notifier (Riverpod 3.x) ─────────────────────────────────────────────────

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthIdle();

  Future<void> login({required String email, required String password}) async {
    state = const AuthLoading();
    try {
      final repo = AuthRepository(ref.read(dioProvider));
      final usuario = await repo.login(email: email, password: password);
      state = AuthAuthenticated(usuario);
    } on DioException catch (e) {
      final mensaje = e.response?.data?['error'] ?? 'Error de conexión';
      state = AuthError(mensaje.toString());
    } catch (_) {
      state = const AuthError('Error inesperado. Intenta de nuevo.');
    }
  }

  Future<void> logout() async {
    final repo = AuthRepository(ref.read(dioProvider));
    await repo.logout();
    state = const AuthIdle();
  }

  void resetError() {
    if (state is AuthError) state = const AuthIdle();
  }
}

// ─── Providers ───────────────────────────────────────────────────────────────

final dioProvider = Provider<Dio>((ref) => crearDioConAuth());

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
