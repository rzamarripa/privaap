const express = require("express");
const router = express.Router();
const { body, query, param } = require("express-validator");
const monthlyFeeController = require("../controllers/monthly-fee.controller");
const auth = require("../middlewares/auth");
const admin = require("../middlewares/admin");

// Validaciones para crear mensualidad
const createMonthlyFeeValidation = [
  body("communityId").isMongoId().withMessage("ID de comunidad inválido"),
  body("userId").isMongoId().withMessage("ID de usuario inválido"),
  body("houseId").isMongoId().withMessage("ID de casa inválido"),
  body("month")
    .matches(/^\d{4}-\d{2}$/)
    .withMessage("El formato del mes debe ser YYYY-MM (ejemplo: 2024-01)"),
  body("amount")
    .isFloat({ min: 0 })
    .withMessage("El monto debe ser un número positivo"),
  body("dueDate")
    .isISO8601()
    .withMessage("La fecha de vencimiento debe ser una fecha válida"),
  body("status")
    .optional()
    .isIn(["pendiente", "pagado", "vencido", "parcial", "exento"])
    .withMessage("Estado no válido"),
  body("discountAmount")
    .optional()
    .isFloat({ min: 0 })
    .withMessage("El descuento debe ser un número positivo"),
  body("lateFeeAmount")
    .optional()
    .isFloat({ min: 0 })
    .withMessage("La penalización debe ser un número positivo"),
];

// Validaciones para actualizar mensualidad
const updateMonthlyFeeValidation = [
  body("amount")
    .optional()
    .isFloat({ min: 0 })
    .withMessage("El monto debe ser un número positivo"),
  body("amountPaid")
    .optional()
    .isFloat({ min: 0 })
    .withMessage("El monto pagado debe ser un número positivo"),
  body("status")
    .optional()
    .isIn(["pendiente", "pagado", "vencido", "parcial", "exento"])
    .withMessage("Estado no válido"),
  body("dueDate")
    .optional()
    .isISO8601()
    .withMessage("La fecha de vencimiento debe ser una fecha válida"),
  body("paidDate")
    .optional()
    .isISO8601()
    .withMessage("La fecha de pago debe ser una fecha válida"),
  body("paymentMethod")
    .optional()
    .isIn(["efectivo", "transferencia", "cheque", "tarjeta", "otro"])
    .withMessage("Método de pago no válido"),
  body("receiptNumber")
    .optional()
    .trim()
    .isLength({ max: 50 })
    .withMessage("El número de recibo no puede exceder 50 caracteres"),
  body("notes")
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage("Las notas no pueden exceder 500 caracteres"),
  body("discountAmount")
    .optional()
    .isFloat({ min: 0 })
    .withMessage("El descuento debe ser un número positivo"),
  body("lateFeeAmount")
    .optional()
    .isFloat({ min: 0 })
    .withMessage("La penalización debe ser un número positivo"),
];

// Validaciones para registrar pago
const recordPaymentValidation = [
  body("amount")
    .isFloat({ min: 0.01 })
    .withMessage("El monto del pago debe ser mayor a 0"),
  body("paymentMethod")
    .isIn(["efectivo", "transferencia", "cheque", "tarjeta", "otro"])
    .withMessage("Método de pago no válido"),
  body("receiptNumber")
    .optional()
    .trim()
    .isLength({ max: 50 })
    .withMessage("El número de recibo no puede exceder 50 caracteres"),
  body("notes")
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage("Las notas no pueden exceder 500 caracteres"),
];

// Validaciones para generar mensualidades
const generateMonthlyFeesValidation = [
  body("communityId").isMongoId().withMessage("ID de comunidad inválido"),
  body("month")
    .matches(/^\d{4}-\d{2}$/)
    .withMessage("El formato del mes debe ser YYYY-MM (ejemplo: 2024-01)"),
];

// Validaciones para parámetros de consulta
const queryValidation = [
  query("page")
    .optional()
    .isInt({ min: 1 })
    .withMessage("La página debe ser un número entero mayor a 0"),
  query("limit")
    .optional()
    .isInt({ min: 1, max: 100 })
    .withMessage("El límite debe ser un número entre 1 y 100"),
  query("status")
    .optional()
    .isIn(["pendiente", "pagado", "vencido", "parcial", "exento"])
    .withMessage("Estado no válido"),
  query("month")
    .optional()
    .matches(/^\d{4}-\d{2}$/)
    .withMessage("El formato del mes debe ser YYYY-MM"),
  query("communityId")
    .optional()
    .isMongoId()
    .withMessage("ID de comunidad inválido"),
  query("userId").optional().isMongoId().withMessage("ID de usuario inválido"),
  query("sortBy")
    .optional()
    .isIn(["month", "dueDate", "amount", "status", "createdAt"])
    .withMessage("Campo de ordenamiento no válido"),
  query("sortOrder")
    .optional()
    .isIn(["asc", "desc"])
    .withMessage("Orden de clasificación no válido"),
];

// Validaciones para parámetros de ruta
const paramValidation = [
  param("id").isMongoId().withMessage("ID de mensualidad inválido"),
  param("communityId").isMongoId().withMessage("ID de comunidad inválido"),
];

// Rutas públicas (requieren autenticación)
router.get("/user", auth, monthlyFeeController.getUserMonthlyFees);

// Rutas de administrador
router.get(
  "/",
  auth,
  admin,
  queryValidation,
  monthlyFeeController.getAllMonthlyFees
);
router.get("/summary", auth, admin, monthlyFeeController.getFinancialSummary);
router.post(
  "/",
  auth,
  admin,
  createMonthlyFeeValidation,
  monthlyFeeController.createMonthlyFee
);
router.post(
  "/generate",
  auth,
  admin,
  generateMonthlyFeesValidation,
  monthlyFeeController.generateMonthlyFeesForMonth
);

// Rutas específicas por ID
router.get(
  "/:id",
  auth,
  paramValidation,
  monthlyFeeController.getMonthlyFeeById
);
router.put(
  "/:id",
  auth,
  admin,
  paramValidation,
  updateMonthlyFeeValidation,
  monthlyFeeController.updateMonthlyFee
);
router.delete(
  "/:id",
  auth,
  admin,
  paramValidation,
  monthlyFeeController.deleteMonthlyFee
);

// Rutas específicas por comunidad
router.get(
  "/community/:communityId",
  auth,
  admin,
  paramValidation,
  monthlyFeeController.getCommunityMonthlyFees
);

// Ruta para registrar pagos
router.post(
  "/:id/payment",
  auth,
  admin,
  paramValidation,
  recordPaymentValidation,
  monthlyFeeController.recordPayment
);

module.exports = router;
