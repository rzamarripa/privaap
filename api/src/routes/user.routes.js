const express = require("express");
const router = express.Router();
const { body } = require("express-validator");
const userController = require("../controllers/user.controller");
const auth = require("../middlewares/auth");
const admin = require("../middlewares/admin");

// Get all users (all authenticated users can see for comment names)
router.get("/", auth, userController.getAllUsers);

// Create new user (admin only)
router.post(
  "/",
  auth,
  admin,
  [
    body("name")
      .notEmpty()
      .trim()
      .withMessage("El nombre no puede estar vacío"),
    body("email").isEmail().normalizeEmail().withMessage("Email inválido"),
    body("phoneNumber")
      .isLength({ min: 10, max: 10 })
      .withMessage("El número de teléfono debe tener exactamente 10 dígitos")
      .matches(/^[0-9]+$/)
      .withMessage("El número de teléfono solo debe contener dígitos"),
    body("password")
      .isLength({ min: 6 })
      .withMessage("La contraseña debe tener al menos 6 caracteres"),
    body("role")
      .isIn(["superAdmin", "administrador", "residente"])
      .withMessage("Rol inválido"),
    body("house")
      .if(body("role").equals("residente"))
      .notEmpty()
      .trim()
      .withMessage("El número de casa es requerido para residentes"),
    body("communityId")
      .if(body("role").equals("residente"))
      .notEmpty()
      .withMessage("El ID de comunidad es requerido para residentes"),
    body("isActive")
      .optional()
      .isBoolean()
      .withMessage("Estado debe ser booleano"),
  ],
  userController.createUser
);

// Get user by ID
router.get("/:id", auth, userController.getUserById);

// Update user
router.put(
  "/:id",
  auth,
  [
    body("name")
      .optional()
      .notEmpty()
      .trim()
      .withMessage("El nombre no puede estar vacío"),
    body("email")
      .optional()
      .isEmail()
      .normalizeEmail()
      .withMessage("Email inválido"),
    body("phoneNumber")
      .optional()
      .isMobilePhone()
      .withMessage("Número de teléfono inválido"),
    body("house").optional().trim(),
  ],
  userController.updateUser
);

// Update user role (admin only)
router.patch(
  "/:id/role",
  auth,
  admin,
  [
    body("role")
      .isIn(["administrador", "residente"])
      .withMessage("Rol inválido"),
  ],
  userController.updateUserRole
);

// Activate/Deactivate user (admin only)
router.patch(
  "/:id/status",
  auth,
  admin,
  [body("isActive").isBoolean().withMessage("Estado debe ser booleano")],
  userController.updateUserStatus
);

// Delete user (admin only)
router.delete("/:id", auth, admin, userController.deleteUser);

// Upload profile image
router.post("/:id/profile-image", auth, userController.uploadProfileImage);

// Change user password (super admin only)
router.patch(
  "/:id/password",
  auth,
  admin,
  [
    body("newPassword")
      .isLength({ min: 6 })
      .withMessage("La nueva contraseña debe tener al menos 6 caracteres"),
  ],
  userController.changeUserPassword
);

module.exports = router;
