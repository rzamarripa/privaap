module.exports = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({ error: "No autorizado" });
  }

  // Permitir tanto administradores como super admins
  if (req.user.role !== "administrador" && req.user.role !== "superAdmin") {
    return res
      .status(403)
      .json({
        error:
          "Acceso denegado. Se requieren privilegios de administrador o super administrador",
      });
  }

  next();
};
