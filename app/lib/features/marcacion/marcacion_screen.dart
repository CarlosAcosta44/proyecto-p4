import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../auth/auth_provider.dart';
import '../auth/login_screen.dart';
import 'marcacion_provider.dart';
import '../../core/services/biometria_service.dart';

class MarcacionScreen extends ConsumerStatefulWidget {
  final UsuarioModel usuario;

  const MarcacionScreen({super.key, required this.usuario});

  @override
  ConsumerState<MarcacionScreen> createState() => _MarcacionScreenState();
}

class _MarcacionScreenState extends ConsumerState<MarcacionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  String _tipoActual = 'entrada'; // "entrada" | "salida"

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<Position?> _obtenerUbicacion() async {
    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.deniedForever ||
        permiso == LocationPermission.denied) {
      return null;
    }
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  Future<void> _marcar() async {
    // 1. Autenticación biométrica
    final biometriaOk = await BiometriaService.autenticar(
      motivo: 'Confirma tu identidad para registrar la $_tipoActual',
    );

    if (!biometriaOk) {
      _mostrarSnack('Autenticación biométrica cancelada o fallida', isError: true);
      return;
    }

    // 2. Obtener ubicación GPS
    final posicion = await _obtenerUbicacion();
    if (posicion == null) {
      _mostrarSnack('No se pudo obtener la ubicación GPS', isError: true);
      return;
    }

    // 3. Enviar marcación al servidor
    await ref.read(marcacionProvider.notifier).registrar(
          latitud: posicion.latitude,
          longitud: posicion.longitude,
          tipo: _tipoActual,
        );
  }

  void _mostrarSnack(String mensaje, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor:
            isError ? Colors.redAccent : const Color(0xFF00C851),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final marcacionState = ref.watch(marcacionProvider);

    // Mostrar resultado de la marcación con SnackBar
    ref.listen<MarcacionState>(marcacionProvider, (_, next) {
      if (next is MarcacionExitosa) {
        _mostrarSnack('✅ ${next.resultado.mensaje}');
        // Alternar tipo para la siguiente marcación
        setState(() {
          _tipoActual = _tipoActual == 'entrada' ? 'salida' : 'entrada';
        });
        Future.delayed(const Duration(seconds: 2), () {
          ref.read(marcacionProvider.notifier).resetear();
        });
      } else if (next is MarcacionRechazada) {
        _mostrarSnack('❌ ${next.resultado.mensaje}', isError: true);
        Future.delayed(const Duration(seconds: 3), () {
          ref.read(marcacionProvider.notifier).resetear();
        });
      } else if (next is MarcacionErrorState) {
        _mostrarSnack('⚠️ ${next.mensaje}', isError: true);
        Future.delayed(const Duration(seconds: 2), () {
          ref.read(marcacionProvider.notifier).resetear();
        });
      }
    });

    final isLoading = marcacionState is MarcacionLoading;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar personalizada
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hola, ${widget.usuario.email.split('@').first}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.usuario.rol.toUpperCase(),
                          style: TextStyle(
                            color: const Color(0xFF00D4FF).withValues(alpha: 0.8),
                            fontSize: 12,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout_rounded,
                          color: Colors.white54),
                      onPressed: _logout,
                      tooltip: 'Cerrar sesión',
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Estado actual
              Text(
                'MARCAR',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _tipoActual.toUpperCase(),
                style: TextStyle(
                  color: _tipoActual == 'entrada'
                      ? const Color(0xFF00C851)
                      : const Color(0xFFFF6B6B),
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 50),

              // Botón biométrico pulsante
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: isLoading ? 1.0 : _pulseAnimation.value,
                    child: child,
                  );
                },
                child: GestureDetector(
                  onTap: isLoading ? null : _marcar,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          (_tipoActual == 'entrada'
                                  ? const Color(0xFF00C851)
                                  : const Color(0xFFFF6B6B))
                              .withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                      ),
                      border: Border.all(
                        color: _tipoActual == 'entrada'
                            ? const Color(0xFF00C851)
                            : const Color(0xFFFF6B6B),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_tipoActual == 'entrada'
                                  ? const Color(0xFF00C851)
                                  : const Color(0xFFFF6B6B))
                              .withValues(alpha: 0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF00D4FF),
                              strokeWidth: 3,
                            ),
                          )
                        : Icon(
                            Icons.fingerprint,
                            size: 90,
                            color: _tipoActual == 'entrada'
                                ? const Color(0xFF00C851)
                                : const Color(0xFFFF6B6B),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Text(
                isLoading
                    ? 'Procesando...'
                    : 'Toca para registrar tu $_tipoActual',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),

              const Spacer(),

              // Toggle entrada / salida manual
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTipoButton('entrada', Icons.login_rounded),
                    const SizedBox(width: 16),
                    _buildTipoButton('salida', Icons.logout_rounded),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipoButton(String tipo, IconData icon) {
    final isSelected = _tipoActual == tipo;
    final color = tipo == 'entrada'
        ? const Color(0xFF00C851)
        : const Color(0xFFFF6B6B);

    return GestureDetector(
      onTap: () => setState(() => _tipoActual = tipo),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? color : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? color : Colors.white38, size: 18),
            const SizedBox(width: 8),
            Text(
              tipo[0].toUpperCase() + tipo.substring(1),
              style: TextStyle(
                color: isSelected ? color : Colors.white38,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
