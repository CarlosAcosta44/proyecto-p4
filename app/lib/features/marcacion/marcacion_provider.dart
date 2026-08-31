import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';

// ─── Modelos ─────────────────────────────────────────────────────────────────

class MarcacionResultado {
  final bool exitosa;
  final String mensaje;
  final String? estado;
  final int? distanciaM;

  const MarcacionResultado({
    required this.exitosa,
    required this.mensaje,
    this.estado,
    this.distanciaM,
  });
}

// ─── Repository ──────────────────────────────────────────────────────────────

class MarcacionRepository {
  final Dio _dio;

  MarcacionRepository(this._dio);

  /// Envía una marcación al servidor con las coordenadas GPS actuales.
  Future<MarcacionResultado> marcar({
    required double latitud,
    required double longitud,
    required String tipo, // "entrada" | "salida"
  }) async {
    try {
      final response = await _dio.post('/marcaciones', data: {
        'latitud': latitud,
        'longitud': longitud,
        'tipo': tipo,
      });

      return MarcacionResultado(
        exitosa: true,
        mensaje: response.data['mensaje'] as String,
        estado: 'aceptada',
        distanciaM: response.data['distancia_m'] as int?,
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      final mensaje = data?['error'] ?? 'Error al registrar marcación';
      final estado = e.response?.statusCode == 422
          ? (data?['distancia_m'] != null
              ? 'rechazada_geocerca'
              : 'rechazada_horario')
          : 'error';

      return MarcacionResultado(
        exitosa: false,
        mensaje: mensaje.toString(),
        estado: estado,
        distanciaM: data?['distancia_m'] as int?,
      );
    }
  }
}

// ─── State ───────────────────────────────────────────────────────────────────

sealed class MarcacionState {
  const MarcacionState();
}

class MarcacionIdle extends MarcacionState {
  const MarcacionIdle();
}

class MarcacionLoading extends MarcacionState {
  const MarcacionLoading();
}

class MarcacionExitosa extends MarcacionState {
  final MarcacionResultado resultado;
  const MarcacionExitosa(this.resultado);
}

class MarcacionRechazada extends MarcacionState {
  final MarcacionResultado resultado;
  const MarcacionRechazada(this.resultado);
}

class MarcacionErrorState extends MarcacionState {
  final String mensaje;
  const MarcacionErrorState(this.mensaje);
}

// ─── Notifier (Riverpod 3.x) ─────────────────────────────────────────────────

class MarcacionNotifier extends Notifier<MarcacionState> {
  @override
  MarcacionState build() => const MarcacionIdle();

  Future<void> registrar({
    required double latitud,
    required double longitud,
    required String tipo,
  }) async {
    state = const MarcacionLoading();

    final repo = MarcacionRepository(ref.read(dioProvider));
    final resultado = await repo.marcar(
      latitud: latitud,
      longitud: longitud,
      tipo: tipo,
    );

    if (resultado.exitosa) {
      state = MarcacionExitosa(resultado);
    } else if (resultado.estado?.startsWith('rechazada') == true) {
      state = MarcacionRechazada(resultado);
    } else {
      state = MarcacionErrorState(resultado.mensaje);
    }
  }

  void resetear() => state = const MarcacionIdle();
}

// ─── Providers ───────────────────────────────────────────────────────────────

final marcacionProvider =
    NotifierProvider<MarcacionNotifier, MarcacionState>(
  MarcacionNotifier.new,
);
