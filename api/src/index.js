require("dotenv").config();
const express = require("express");
const cors = require("cors");

const authRoutes = require("./routes/auth.routes");
const marcacionesRoutes = require("./routes/marcaciones.routes");

const app = express();
const PORT = process.env.PORT || 3000;

// ─── Middlewares globales ────────────────────────────────────────────────────
app.use(cors());
app.use(express.json());

// ─── Rutas ───────────────────────────────────────────────────────────────────
app.use("/auth", authRoutes);
app.use("/marcaciones", marcacionesRoutes);

// ─── Health check ────────────────────────────────────────────────────────────
app.get("/health", (_req, res) => {
  res.json({ status: "ok", timestamp: new Date().toISOString() });
});

// ─── Manejo de rutas no encontradas ──────────────────────────────────────────
app.use((_req, res) => {
  res.status(404).json({ error: "Ruta no encontrada" });
});

// ─── Manejo global de errores ────────────────────────────────────────────────
app.use((err, _req, res, _next) => {
  console.error("[ERROR GLOBAL]", err);
  res.status(500).json({ error: "Error interno del servidor" });
});

// ─── Iniciar servidor ────────────────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`✅ Servidor P4 corriendo en http://localhost:${PORT}`);
});

module.exports = app;
