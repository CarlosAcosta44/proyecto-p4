require("dotenv").config();
const { PrismaClient } = require("@prisma/client");
const bcrypt = require("bcryptjs");

const prisma = new PrismaClient();

async function main() {
  console.log("🌱 Creando ficha y usuario Carlos...\n");

  // 1. Crear ficha de Carlos (4°35'45.7"N 74°06'43.5"W)
  // Latitud: 4 + (35/60) + (45.7/3600) = 4.596027
  // Longitud: -(74 + (6/60) + (43.5/3600)) = -74.112083
  const ficha = await prisma.p4_ficha.upsert({
    where: { nombre: "Ficha 327641" },
    update: {},
    create: {
      nombre: "Ficha 327641",
      latitud: 4.596027,
      longitud: -74.112083,
      radio_m: 500,        // 500m de radio para pruebas
      hora_inicio: "00:00", // Sin restricción de horario
      hora_fin: "23:59",
    },
  });
  console.log(`✅ Ficha creada: "${ficha.nombre}" (ID: ${ficha.id}) con ubicación configurada.`);

  // 2. Crear usuario Carlos
  const passwordHash = await bcrypt.hash("carlos123", 10);

  const usuario = await prisma.p4_usuario.upsert({
    where: { email: "carlos@gmail.com" },
    update: { password_hash: passwordHash, ficha_id: ficha.id },
    create: {
      email: "carlos@gmail.com",
      password_hash: passwordHash,
      rol: "aprendiz",
      ficha_id: ficha.id,
    },
  });
  
  console.log(`✅ Usuario creado: "${usuario.email}" (ID: ${usuario.id})`);
  console.log(`   Contraseña: carlos123`);
  console.log(`   Ficha: ${ficha.nombre}`);
}

main()
  .catch((e) => {
    console.error("❌ Error en seed:", e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
