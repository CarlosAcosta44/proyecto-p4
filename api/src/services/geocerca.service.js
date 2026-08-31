/**
 * Servicio de geocerca para validar si un punto GPS
 * se encuentra dentro del perímetro de una sede.
 */

const RADIO_TIERRA_M = 6_371_000; // Radio medio de la Tierra en metros

/**
 * Convierte grados a radianes.
 * @param {number} grados
 * @returns {number}
 */
function toRad(grados) {
  return (grados * Math.PI) / 180;
}

/**
 * Calcula la distancia en metros entre dos puntos GPS usando la fórmula de Haversine.
 * @param {number} lat1 - Latitud del punto 1
 * @param {number} lon1 - Longitud del punto 1
 * @param {number} lat2 - Latitud del punto 2
 * @param {number} lon2 - Longitud del punto 2
 * @returns {number} Distancia en metros
 */
function haversine(lat1, lon1, lat2, lon2) {
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);

  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return RADIO_TIERRA_M * c;
}

/**
 * Verifica si las coordenadas dadas están dentro del perímetro de una ficha.
 * @param {{ latitud: number, longitud: number, radio_m: number }} ficha
 * @param {{ latitud: number, longitud: number }} punto
 * @returns {{ valido: boolean, distancia_m: number }}
 */
function validarGeocerca(ficha, punto) {
  const distancia_m = haversine(
    ficha.latitud,
    ficha.longitud,
    punto.latitud,
    punto.longitud
  );

  return {
    valido: distancia_m <= ficha.radio_m,
    distancia_m: Math.round(distancia_m),
  };
}

/**
 * Verifica si la hora actual (en Colombia UTC-5) está dentro del horario de la ficha.
 * @param {{ hora_inicio: string, hora_fin: string }} ficha  ej: { hora_inicio: "07:00", hora_fin: "17:00" }
 * @returns {{ valido: boolean, hora_actual: string }}
 */
function validarHorario(ficha) {
  // Obtener hora actual en UTC-5 (Colombia)
  const ahora = new Date();
  const offsetMs = -5 * 60 * 60 * 1000;
  const ahoraColombia = new Date(ahora.getTime() + offsetMs);

  const hh = String(ahoraColombia.getUTCHours()).padStart(2, "0");
  const mm = String(ahoraColombia.getUTCMinutes()).padStart(2, "0");
  const hora_actual = `${hh}:${mm}`;

  const valido = hora_actual >= ficha.hora_inicio && hora_actual <= ficha.hora_fin;

  return { valido, hora_actual };
}

module.exports = { haversine, validarGeocerca, validarHorario };
