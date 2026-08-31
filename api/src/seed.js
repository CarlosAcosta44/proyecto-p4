/**
 * Script seed para crear datos iniciales de prueba en P4.
 * Ejecutar con: node src/seed.js
 */
require("dotenv").config();
const { PrismaClient } = require("@prisma/client");
const bcrypt = require("bcryptjs");

const prisma = new PrismaClient();

async function main() {
  console.log("🌱 Iniciando seed de P4...\n");

  // 1. Crear ficha de prueba (coordenadas del SENA - puedes ajustar)
  const ficha = await prisma.p4_ficha.upsert({
    where: { nombre: "Ficha 2977225 - Prueba" },
    update: {},
    create: {
      nombre: "Ficha 2977225 - Prueba",
      latitud: 4.710989,   // ← Bogotá centro (ajusta a tu ubicación real)
      longitud: -74.072092,
      radio_m: 500,        // 500m de radio para pruebas amplias
      hora_inicio: "00:00", // Sin restricción de horario para pruebas
      hora_fin: "23:59",
    },
  });
  console.log(`✅ Ficha creada: "${ficha.nombre}" (ID: ${ficha.id})`);

  // 2. Crear usuario de prueba
  const passwordHash = await bcrypt.hash("ceet2025", 10);

  const usuario = await prisma.p4_usuario.upsert({
    where: { email: "aprendiz@ceet.edu.co" },
    update: { password_hash: passwordHash },
    create: {
      email: "aprendiz@ceet.edu.co",
      password_hash: passwordHash,
      rol: "aprendiz",
      ficha_id: ficha.id,
    },
  });
  console.log(`✅ Usuario creado: "${usuario.email}" (ID: ${usuario.id})`);
  console.log(`   Contraseña: ceet2025`);
  console.log(`   Rol: ${usuario.rol}`);
  console.log(`   Ficha: ${ficha.nombre}`);

  console.log("\n🎉 Seed completado exitosamente.");
  console.log("   Credenciales de prueba:");
  console.log("   📧 Email:      aprendiz@ceet.edu.co");
  console.log("   🔑 Contraseña: ceet2025");
}

main()
  .catch((e) => {
    console.error("❌ Error en seed:", e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
