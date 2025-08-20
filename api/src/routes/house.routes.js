const express = require("express");
const { body, param } = require("express-validator");
const houseController = require("../controllers/house.controller.js");
const { protect, isAdmin } = require("../middlewares/auth.js");
const { validateRequest } = require("../middlewares/validation.js");

const router = express.Router();

// Middleware de autenticación para todas las rutas
router.use(protect);

// Obtener todas las casas (para super admin)
router.get("/all", isAdmin, houseController.getAllHouses);

// Obtener casas de una comunidad específica
router.get(
  "/community/:communityId",
  param("communityId").isMongoId().withMessage("ID de comunidad inválido"),
  validateRequest,
  houseController.getHousesByCommunity
);

// Obtener una casa específica
router.get(
  "/:id",
  param("id").isMongoId().withMessage("ID de casa inválido"),
  validateRequest,
  houseController.getHouseById
);

// Crear una nueva casa (solo administradores)
router.post(
  "/",
  isAdmin,
  [
    body("houseNumber")
      .notEmpty()
      .withMessage("El número de casa es obligatorio")
      .isString()
      .withMessage("El número de casa debe ser texto")
      .trim()
      .isLength({ min: 1, max: 10 })
      .withMessage("El número de casa debe tener entre 1 y 10 caracteres"),
    body("communityId")
      .notEmpty()
      .withMessage("La comunidad es obligatoria")
      .isMongoId()
      .withMessage("ID de comunidad inválido"),
  ],
  validateRequest,
  houseController.createHouse
);

// Actualizar una casa (solo administradores)
router.put(
  "/:id",
  isAdmin,
  [
    param("id").isMongoId().withMessage("ID de casa inválido"),
    body("houseNumber")
      .optional()
      .isString()
      .withMessage("El número de casa debe ser texto")
      .trim()
      .isLength({ min: 1, max: 10 })
      .withMessage("El número de casa debe tener entre 1 y 10 caracteres"),
    body("isActive")
      .optional()
      .isBoolean()
      .withMessage("El estado debe ser booleano"),
  ],
  validateRequest,
  houseController.updateHouse
);

// Eliminar una casa (desactivar - solo administradores)
router.delete(
  "/:id",
  isAdmin,
  param("id").isMongoId().withMessage("ID de casa inválido"),
  validateRequest,
  houseController.deleteHouse
);

module.exports = router;
