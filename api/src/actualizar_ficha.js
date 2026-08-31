/**
 * Script para actualizar las coordenadas y radio de la ficha de prueba.
 *
 * Cómo obtener tus coordenadas:
 * 1. Abre Google Maps en el navegador o celular
 * 2. Mantén presionado el punto exacto donde quieres centrar el área
 * 3. Aparecerán dos números en la parte inferior (ej: 4.6536, -74.1013)
 * 4. El primero es la LATITUD, el segundo es la LONGITUD
 * 5. Edita los valores abajo y ejecuta: node src/actualizar_ficha.js
 */
require("dotenv").config();
const { PrismaClient } = require("@prisma/client");

const prisma = new PrismaClient();

// ──────────────────────────────────────────────────────────────────────────────
//  ✏️  EDITA AQUÍ LOS VALORES QUE QUIERAS
// ──────────────────────────────────────────────────────────────────────────────

const CONFIG = {
  // Coordenadas del centro del área permitida
  // Ejemplo casa:   latitud: 4.6536,  longitud: -74.1013
  // Ejemplo SENA:   latitud: 4.7110,  longitud: -74.0724
  latitud: 4.638611,
  longitud: -74.184722,

  // Radio en metros. Ejemplos:
  //   50   → muy estricto (solo dentro del edificio)
  //   100  → un bloque alrededor
  //   300  → unas pocas cuadras
  //   500  → barrio completo (bueno para pruebas)
  // 1000  → kilómetro a la redonda
  radio_m: 500,

  // Horario permitido (formato "HH:MM" en hora Colombia UTC-5)
  // Para pruebas sin restricción de horario: "00:00" y "23:59"
  hora_inicio: "00:00",
  hora_fin: "23:59",
};

// ──────────────────────────────────────────────────────────────────────────────

async function main() {
  console.log("🔧 Actualizando ficha de prueba...\n");
  console.log(`   📍 Coordenadas: ${CONFIG.latitud}, ${CONFIG.longitud}`);
  console.log(`   📏 Radio: ${CONFIG.radio_m} metros`);
  console.log(`   🕐 Horario: ${CONFIG.hora_inicio} – ${CONFIG.hora_fin}\n`);

  const ficha = await prisma.p4_ficha.update({
    where: { nombre: "Ficha 2977225 - Prueba" },
    data: {
      latitud: CONFIG.latitud,
      longitud: CONFIG.longitud,
      radio_m: CONFIG.radio_m,
      hora_inicio: CONFIG.hora_inicio,
      hora_fin: CONFIG.hora_fin,
    },
  });

  console.log(`✅ Ficha actualizada exitosamente (ID: ${ficha.id})`);
  console.log(`\n   🗺️  Ver en Google Maps:`);
  console.log(`   https://www.google.com/maps?q=${ficha.latitud},${ficha.longitud}`);
  console.log(`\n   El radio de ${ficha.radio_m}m cubre aproximadamente:`);
  console.log(`   ${(ficha.radio_m / 1000).toFixed(2)} km de diámetro`);
}

main()
  .catch((e) => {
    console.error("❌ Error:", e.message);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
