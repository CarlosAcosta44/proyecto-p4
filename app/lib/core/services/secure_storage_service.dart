import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Servicio para persistir y recuperar los tokens de autenticación
/// de forma segura usando el keychain/keystore del dispositivo.
class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';

  /// Guarda ambos tokens en el almacenamiento seguro.
  static Future<void> guardarTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _keyAccessToken, value: accessToken),
      _storage.write(key: _keyRefreshToken, value: refreshToken),
    ]);
  }

  /// Lee el access token almacenado. Retorna null si no existe.
  static Future<String?> leerAccessToken() =>
      _storage.read(key: _keyAccessToken);

  /// Lee el refresh token almacenado. Retorna null si no existe.
  static Future<String?> leerRefreshToken() =>
      _storage.read(key: _keyRefreshToken);

  /// Elimina ambos tokens (logout local).
  static Future<void> limpiarTokens() async {
    await Future.wait([
      _storage.delete(key: _keyAccessToken),
      _storage.delete(key: _keyRefreshToken),
    ]);
  }
}
