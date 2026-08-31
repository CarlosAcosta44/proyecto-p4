import 'package:local_auth/local_auth.dart';

/// Servicio para verificar identidad del usuario.
/// Intenta biometría (huella/Face ID) primero; si no está disponible
/// o el sensor está dañado, usa el PIN/patrón del dispositivo como respaldo.
class BiometriaService {
  static final _auth = LocalAuthentication();

  /// Verifica si el dispositivo soporta algún método de autenticación
  /// (biometría O credenciales del dispositivo como PIN/patrón).
  static Future<bool> disponible() async {
    return await _auth.isDeviceSupported();
  }

  /// Solicita verificación de identidad al usuario.
  /// - Si tiene huella/Face ID: muestra el diálogo biométrico.
  /// - Si el sensor está dañado o no hay huellas registradas: muestra PIN/patrón.
  /// - Retorna `true` si la verificación fue exitosa.
  static Future<bool> autenticar({
    String motivo = 'Confirma tu identidad para registrar la asistencia',
  }) async {
    try {
      // Verificar que el dispositivo soporte algún tipo de autenticación
      final soportado = await disponible();
      if (!soportado) return false;

      // Autenticar — sin biometricOnly: permite fallback automático a PIN/patrón
      // si la huella no está disponible o el sensor está dañado
      return await _auth.authenticate(
        localizedReason: motivo,
      );
    } catch (_) {
      return false;
    }
  }
}
