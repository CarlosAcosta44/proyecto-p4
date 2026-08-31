const express = require("express");
const { PrismaClient } = require("@prisma/client");
const { authenticateToken } = require("../middleware/auth.middleware");
const { validarGeocerca, validarHorario } = require("../services/geocerca.service");

const router = express.Router();
const prisma = new PrismaClient();

/**
 * POST /marcaciones
 * Registra una marcación de entrada o salida.
 * Requiere JWT en cabecera Authorization: Bearer <token>
 * Body: { latitud: number, longitud: number, tipo: "entrada" | "salida" }
 */
router.post("/", authenticateToken, async (req, res) => {
  const { latitud, longitud, tipo } = req.body;

  // Validación de campos
  if (latitud == null || longitud == null) {
    return res.status(400).json({ error: "latitud y longitud son requeridos" });
  }
  if (!["entrada", "salida"].includes(tipo)) {
    return res.status(400).json({ error: 'tipo debe ser "entrada" o "salida"' });
  }

  try {
    // Obtener usuario con su ficha asignada
    const usuario = await prisma.p4_usuario.findUnique({
      where: { id: req.usuario.id },
      include: { ficha: true },
    });

    if (!usuario || !usuario.ficha) {
      return res.status(404).json({ error: "Usuario o ficha no encontrada" });
    }

    const ficha = usuario.ficha;
    const punto = { latitud: parseFloat(latitud), longitud: parseFloat(longitud) };

    // 1. Validar geocerca (Haversine)
    const geocerca = validarGeocerca(ficha, punto);
    if (!geocerca.valido) {
      const marcacion = await prisma.p4_marcacion.create({
        data: {
          usuario_id: usuario.id,
          latitud: punto.latitud,
          longitud: punto.longitud,
          tipo,
          estado: "rechazada_geocerca",
        },
      });
      return res.status(422).json({
        error: "Fuera del perímetro permitido",
        distancia_m: geocerca.distancia_m,
        radio_permitido_m: ficha.radio_m,
        marcacion_id: marcacion.id,
      });
    }

    // 2. Validar horario de la ficha
    const horario = validarHorario(ficha);
    if (!horario.valido) {
      const marcacion = await prisma.p4_marcacion.create({
        data: {
          usuario_id: usuario.id,
          latitud: punto.latitud,
          longitud: punto.longitud,
          tipo,
          estado: "rechazada_horario",
        },
      });
      return res.status(422).json({
        error: "Fuera del horario permitido",
        hora_actual: horario.hora_actual,
        horario_ficha: `${ficha.hora_inicio} - ${ficha.hora_fin}`,
        marcacion_id: marcacion.id,
      });
    }

    // 3. Registrar marcación aceptada
    const marcacion = await prisma.p4_marcacion.create({
      data: {
        usuario_id: usuario.id,
        latitud: punto.latitud,
        longitud: punto.longitud,
        tipo,
        estado: "aceptada",
      },
    });

    return res.status(201).json({
      mensaje: `Marcación de ${tipo} registrada exitosamente`,
      marcacion: {
        id: marcacion.id,
        tipo: marcacion.tipo,
        estado: marcacion.estado,
        marcado_en: marcacion.marcado_en,
      },
      distancia_m: geocerca.distancia_m,
    });
  } catch (err) {
    console.error("[POST /marcaciones]", err);
    return res.status(500).json({ error: "Error interno del servidor" });
  }
});

/**
 * GET /marcaciones/consolidado
 * Devuelve el resumen de asistencia del usuario autenticado.
 * Query params opcionales: ?fecha=YYYY-MM-DD
 */
router.get("/consolidado", authenticateToken, async (req, res) => {
  const { fecha } = req.query;

  try {
    // Construir filtro de fecha
    let filtroFecha = {};
    if (fecha) {
      const inicio = new Date(`${fecha}T00:00:00.000Z`);
      const fin = new Date(`${fecha}T23:59:59.999Z`);
      filtroFecha = { marcado_en: { gte: inicio, lte: fin } };
    }

    const marcaciones = await prisma.p4_marcacion.findMany({
      where: {
        usuario_id: req.usuario.id,
        estado: "aceptada",
        ...filtroFecha,
      },
      orderBy: { marcado_en: "asc" },
      select: {
        id: true,
        tipo: true,
        estado: true,
        latitud: true,
        longitud: true,
        marcado_en: true,
      },
    });

    // Agrupar por día
    const porDia = {};
    for (const m of marcaciones) {
      const dia = m.marcado_en.toISOString().split("T")[0];
      if (!porDia[dia]) porDia[dia] = { entradas: [], salidas: [] };
      if (m.tipo === "entrada") porDia[dia].entradas.push(m);
      else porDia[dia].salidas.push(m);
    }

    return res.json({
      usuario_id: req.usuario.id,
      total_marcaciones: marcaciones.length,
      consolidado: porDia,
    });
  } catch (err) {
    console.error("[GET /marcaciones/consolidado]", err);
    return res.status(500).json({ error: "Error interno del servidor" });
  }
});

/**
 * GET /marcaciones
 * Historial de todas las marcaciones del usuario autenticado (con estado).
 */
router.get("/", authenticateToken, async (req, res) => {
  try {
    const marcaciones = await prisma.p4_marcacion.findMany({
      where: { usuario_id: req.usuario.id },
      orderBy: { marcado_en: "desc" },
      take: 50,
    });

    return res.json({ marcaciones });
  } catch (err) {
    console.error("[GET /marcaciones]", err);
    return res.status(500).json({ error: "Error interno del servidor" });
  }
});

module.exports = router;
