// Configuración base de la API.
// En producción cambiar baseUrl por la URL del servidor desplegado.
class AppConfig {
  static const String baseUrl = 'http://192.168.11.10:3000'; // IP de la PC en la red local
  // static const String baseUrl = 'http://10.0.2.2:3000'; // Android Emulator → localhost
  // static const String baseUrl = 'http://localhost:3000'; // iOS Simulator / web
}
