const express = require("express");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const { PrismaClient } = require("@prisma/client");

const router = express.Router();
const prisma = new PrismaClient();

/**
 * Genera un access token JWT de corta duración (15 minutos).
 */
function generarAccessToken(usuario) {
  return jwt.sign(
    { id: usuario.id, email: usuario.email, rol: usuario.rol },
    process.env.JWT_SECRET,
    { expiresIn: "15m" }
  );
}

/**
 * Genera un refresh token opaco de larga duración (7 días).
 * Lo guarda en la BD para poder revocarlo.
 */
async function generarRefreshToken(usuarioId) {
  const token = require("crypto").randomBytes(64).toString("hex");
  const expira_en = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 días

  await prisma.p4_refresh_token.create({
    data: { token, usuario_id: usuarioId, expira_en },
  });

  return token;
}

/**
 * POST /auth/login
 * Body: { email: string, password: string }
 * Respuesta: { accessToken, refreshToken, usuario: { id, email, rol } }
 */
router.post("/login", async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: "Email y contraseña son requeridos" });
  }

  try {
    const usuario = await prisma.p4_usuario.findUnique({
      where: { email: email.toLowerCase().trim() },
    });

    if (!usuario) {
      return res.status(401).json({ error: "Credenciales inválidas" });
    }

    const passwordValida = await bcrypt.compare(password, usuario.password_hash);
    if (!passwordValida) {
      return res.status(401).json({ error: "Credenciales inválidas" });
    }

    const accessToken = generarAccessToken(usuario);
    const refreshToken = await generarRefreshToken(usuario.id);

    return res.json({
      accessToken,
      refreshToken,
      usuario: { id: usuario.id, email: usuario.email, rol: usuario.rol },
    });
  } catch (err) {
    console.error("[POST /auth/login]", err);
    return res.status(500).json({ error: "Error interno del servidor" });
  }
});

/**
 * POST /auth/refresh
 * Body: { refreshToken: string }
 * Respuesta: { accessToken }
 */
router.post("/refresh", async (req, res) => {
  const { refreshToken } = req.body;

  if (!refreshToken) {
    return res.status(400).json({ error: "refreshToken es requerido" });
  }

  try {
    const tokenDB = await prisma.p4_refresh_token.findUnique({
      where: { token: refreshToken },
      include: { usuario: true },
    });

    if (!tokenDB) {
      return res.status(401).json({ error: "Refresh token inválido" });
    }

    if (tokenDB.revocado) {
      return res.status(401).json({ error: "Refresh token revocado" });
    }

    if (tokenDB.expira_en < new Date()) {
      return res.status(401).json({ error: "Refresh token expirado" });
    }

    // Rotación de tokens: revocar el actual y emitir uno nuevo
    await prisma.p4_refresh_token.update({
      where: { id: tokenDB.id },
      data: { revocado: true },
    });

    const nuevoRefreshToken = await generarRefreshToken(tokenDB.usuario_id);
    const accessToken = generarAccessToken(tokenDB.usuario);

    return res.json({ accessToken, refreshToken: nuevoRefreshToken });
  } catch (err) {
    console.error("[POST /auth/refresh]", err);
    return res.status(500).json({ error: "Error interno del servidor" });
  }
});

/**
 * POST /auth/logout
 * Body: { refreshToken: string }
 * Revoca el refresh token para cerrar sesión.
 */
router.post("/logout", async (req, res) => {
  const { refreshToken } = req.body;

  if (!refreshToken) {
    return res.status(400).json({ error: "refreshToken es requerido" });
  }

  try {
    await prisma.p4_refresh_token.updateMany({
      where: { token: refreshToken },
      data: { revocado: true },
    });
    return res.json({ mensaje: "Sesión cerrada exitosamente" });
  } catch (err) {
    console.error("[POST /auth/logout]", err);
    return res.status(500).json({ error: "Error interno del servidor" });
  }
});

module.exports = router;
