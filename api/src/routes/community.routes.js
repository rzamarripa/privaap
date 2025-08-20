const express = require("express");
const router = express.Router();
const { body, validationResult } = require("express-validator");
const Community = require("../models/Community.model");
const auth = require("../middlewares/auth");
const admin = require("../middlewares/admin");

// Middleware para validar errores
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      error: "Datos de entrada inválidos",
      details: errors.array(),
    });
  }
  next();
};

// GET /api/communities - Obtener todas las comunidades
router.get("/", auth, async (req, res) => {
  try {
    const communities = await Community.find().populate(
      "superAdminId",
      "name email"
    );
    res.json({
      success: true,
      data: communities,
    });
  } catch (error) {
    console.error("Error getting communities:", error);
    res.status(500).json({
      success: false,
      error: "Error interno del servidor",
    });
  }
});

// GET /api/communities/:id - Obtener comunidad por ID
router.get("/:id", auth, async (req, res) => {
  try {
    const community = await Community.findById(req.params.id)
      .populate("superAdminId", "name email")
      .populate("adminIds", "name email role");

    if (!community) {
      return res.status(404).json({
        success: false,
        error: "Comunidad no encontrada",
      });
    }

    res.json({
      success: true,
      data: community,
    });
  } catch (error) {
    console.error("Error getting community:", error);
    res.status(500).json({
      success: false,
      error: "Error interno del servidor",
    });
  }
});

// POST /api/communities - Crear nueva comunidad
router.post(
  "/",
  [
    auth,
    admin,
    body("name")
      .trim()
      .isLength({ min: 2, max: 100 })
      .withMessage("El nombre debe tener entre 2 y 100 caracteres"),
    body("address")
      .trim()
      .isLength({ min: 5, max: 200 })
      .withMessage("La dirección debe tener entre 5 y 200 caracteres"),
    body("description")
      .optional()
      .trim()
      .isLength({ max: 500 })
      .withMessage("La descripción no puede exceder 500 caracteres"),
    body("monthlyFee")
      .isFloat({ min: 0 })
      .withMessage("La mensualidad debe ser un número positivo"),
    body("currency")
      .isIn(["MXN", "USD", "EUR"])
      .withMessage("Moneda no válida"),
    body("totalHouses")
      .isInt({ min: 1, max: 1000 })
      .withMessage("El total de casas debe ser entre 1 y 1000"),
    handleValidationErrors,
  ],
  async (req, res) => {
    try {
      const { name, address, description, monthlyFee, currency, totalHouses } =
        req.body;

      // Verificar que el usuario sea super admin
      if (req.user.role !== "superAdmin") {
        return res.status(403).json({
          success: false,
          error: "Solo los super administradores pueden crear comunidades",
        });
      }

      // Crear la nueva comunidad
      const community = new Community({
        name,
        address,
        description: description || "",
        monthlyFee,
        currency,
        totalHouses,
        superAdminId: req.user.id,
        adminIds: [],
        isActive: true,
        settings: {
          allowResidents: true,
          requireApproval: true,
          maxFileSize: 5 * 1024 * 1024, // 5MB
        },
      });

      const savedCommunity = await community.save();

      res.status(201).json({
        success: true,
        message: "Comunidad creada exitosamente",
        data: savedCommunity,
      });
    } catch (error) {
      console.error("Error creating community:", error);
      res.status(500).json({
        success: false,
        error: "Error interno del servidor",
      });
    }
  }
);

// PUT /api/communities/:id - Actualizar comunidad
router.put(
  "/:id",
  [
    auth,
    admin,
    body("name").optional().trim().isLength({ min: 2, max: 100 }),
    body("address").optional().trim().isLength({ min: 5, max: 200 }),
    body("description").optional().trim().isLength({ max: 500 }),
    body("monthlyFee").optional().isFloat({ min: 0 }),
    body("currency").optional().isIn(["MXN", "USD", "EUR"]),
    body("totalHouses").optional().isInt({ min: 1, max: 1000 }),
    handleValidationErrors,
  ],
  async (req, res) => {
    try {
      const community = await Community.findById(req.params.id);

      if (!community) {
        return res.status(404).json({
          success: false,
          error: "Comunidad no encontrada",
        });
      }

      // Verificar permisos
      if (
        req.user.role !== "superAdmin" &&
        !community.adminIds.includes(req.user.id)
      ) {
        return res.status(403).json({
          success: false,
          error: "No tienes permisos para modificar esta comunidad",
        });
      }

      const updatedCommunity = await Community.findByIdAndUpdate(
        req.params.id,
        req.body,
        { new: true, runValidators: true }
      );

      res.json({
        success: true,
        message: "Comunidad actualizada exitosamente",
        data: updatedCommunity,
      });
    } catch (error) {
      console.error("Error updating community:", error);
      res.status(500).json({
        success: false,
        error: "Error interno del servidor",
      });
    }
  }
);

// DELETE /api/communities/:id - Eliminar comunidad
router.delete("/:id", [auth, admin], async (req, res) => {
  try {
    const community = await Community.findById(req.params.id);

    if (!community) {
      return res.status(404).json({
        success: false,
        error: "Comunidad no encontrada",
      });
    }

    // Solo super admins pueden eliminar comunidades
    if (req.user.role !== "superAdmin") {
      return res.status(403).json({
        success: false,
        error: "Solo los super administradores pueden eliminar comunidades",
      });
    }

    await Community.findByIdAndDelete(req.params.id);

    res.json({
      success: true,
      message: "Comunidad eliminada exitosamente",
    });
  } catch (error) {
    console.error("Error deleting community:", error);
    res.status(500).json({
      success: false,
      error: "Error interno del servidor",
    });
  }
});

// PUT /api/communities/:id/status - Cambiar estado de la comunidad
router.put("/:id/status", [auth, admin], async (req, res) => {
  try {
    const { isActive } = req.body;

    if (typeof isActive !== "boolean") {
      return res.status(400).json({
        success: false,
        error: "El estado debe ser un valor booleano",
      });
    }

    const community = await Community.findById(req.params.id);

    if (!community) {
      return res.status(404).json({
        success: false,
        error: "Comunidad no encontrada",
      });
    }

    // Verificar permisos
    if (
      req.user.role !== "superAdmin" &&
      !community.adminIds.includes(req.user.id)
    ) {
      return res.status(403).json({
        success: false,
        error: "No tienes permisos para modificar esta comunidad",
      });
    }

    community.isActive = isActive;
    await community.save();

    res.json({
      success: true,
      message: `Comunidad ${
        isActive ? "activada" : "desactivada"
      } exitosamente`,
      data: community,
    });
  } catch (error) {
    console.error("Error updating community status:", error);
    res.status(500).json({
      success: false,
      error: "Error interno del servidor",
    });
  }
});

module.exports = router;
