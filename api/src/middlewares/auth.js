const jwt = require("jsonwebtoken");
const User = require("../models/User.model");

// Protect routes - Default export for simpler usage
const protect = async (req, res, next) => {
  let token;

  if (
    req.headers.authorization &&
    req.headers.authorization.startsWith("Bearer")
  ) {
    token = req.headers.authorization.split(" ")[1];
  }

  if (!token) {
    return res.status(401).json({
      success: false,
      error: "No autorizado para acceder a este recurso",
    });
  }

  try {
    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    req.user = await User.findById(decoded.userId).select("-password");

    if (!req.user) {
      return res.status(401).json({
        success: false,
        error: "Usuario no encontrado",
      });
    }

    if (!req.user.isActive) {
      return res.status(401).json({
        success: false,
        error: "Usuario desactivado",
      });
    }

    next();
  } catch (err) {
    return res.status(401).json({
      success: false,
      error: "Token inválido",
    });
  }
};

// Grant access to specific roles
exports.authorize = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        error: `El rol de usuario ${req.user.role} no está autorizado para acceder a este recurso`,
      });
    }
    next();
  };
};

// Check if user is admin or super admin
exports.isAdmin = (req, res, next) => {
  if (req.user.role !== "administrador" && req.user.role !== "superAdmin") {
    return res.status(403).json({
      success: false,
      error:
        "Solo los administradores y super administradores pueden acceder a este recurso",
    });
  }
  next();
};

// Check if user is the owner of the resource or admin
exports.isOwnerOrAdmin = (model) => {
  return async (req, res, next) => {
    try {
      const resource = await model.findById(req.params.id);

      if (!resource) {
        return res.status(404).json({
          success: false,
          error: "Recurso no encontrado",
        });
      }

      // Check if user is owner or admin
      const isOwner =
        resource.createdBy?.toString() === req.user._id.toString() ||
        resource.proposedBy?.toString() === req.user._id.toString() ||
        resource.author?.toString() === req.user._id.toString() ||
        resource.user?.toString() === req.user._id.toString();

      if (
        !isOwner &&
        req.user.role !== "administrador" &&
        req.user.role !== "superAdmin"
      ) {
        return res.status(403).json({
          success: false,
          error: "No tienes permiso para realizar esta acción",
        });
      }

      req.resource = resource;
      next();
    } catch (err) {
      return res.status(500).json({
        success: false,
        error: "Error al verificar permisos",
      });
    }
  };
};

// Export default for simple auth middleware
module.exports = protect;

// Export named functions
module.exports.protect = protect;
module.exports.authorize = exports.authorize;
module.exports.isAdmin = exports.isAdmin;
module.exports.isOwnerOrAdmin = exports.isOwnerOrAdmin;
