const jwt = require("jsonwebtoken");

/**
 * Middleware para verificar el JWT en cabeceras de petición.
 * Agrega `req.usuario` con { id, email, rol } si el token es válido.
 */
function authenticateToken(req, res, next) {
  const authHeader = req.headers["authorization"];
  const token = authHeader && authHeader.split(" ")[1]; // Bearer <token>

  if (!token) {
    return res.status(401).json({ error: "Token requerido" });
  }

  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    req.usuario = payload; // { id, email, rol, iat, exp }
    next();
  } catch (err) {
    if (err.name === "TokenExpiredError") {
      return res.status(401).json({ error: "Token expirado" });
    }
    return res.status(403).json({ error: "Token inválido" });
  }
}

module.exports = { authenticateToken };
