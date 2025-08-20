const express = require("express");
const router = express.Router();
const { body } = require("express-validator");
const expenseController = require("../controllers/expense.controller");
const auth = require("../middlewares/auth");
const admin = require("../middlewares/admin");

// Get all expenses
router.get("/", auth, expenseController.getAllExpenses);

// Get expense by ID
router.get("/:id", auth, expenseController.getExpenseById);

// Get expenses by category
router.get(
  "/category/:category",
  auth,
  expenseController.getExpensesByCategory
);

// Get expenses by date range
router.get(
  "/date-range/:startDate/:endDate",
  auth,
  expenseController.getExpensesByDateRange
);

// Get expense summary/statistics
router.get("/stats/summary", auth, expenseController.getExpenseSummary);

// Create new expense
router.post(
  "/",
  auth,
  [
    body("title").notEmpty().trim().withMessage("El título es requerido"),
    body("description")
      .notEmpty()
      .trim()
      .withMessage("La descripción es requerida"),
    body("amount").isNumeric().withMessage("El monto debe ser numérico"),
    body("category").notEmpty().withMessage("La categoría es requerida"),
    body("date").isISO8601().withMessage("Fecha inválida"),
  ],
  expenseController.createExpense
);

// Update expense
router.put(
  "/:id",
  auth,
  [
    body("title")
      .optional()
      .notEmpty()
      .trim()
      .withMessage("El título no puede estar vacío"),
    body("description")
      .optional()
      .notEmpty()
      .trim()
      .withMessage("La descripción no puede estar vacía"),
    body("amount")
      .optional()
      .isNumeric()
      .withMessage("El monto debe ser numérico"),
    body("category")
      .optional()
      .notEmpty()
      .withMessage("La categoría no puede estar vacía"),
    body("date").optional().isISO8601().withMessage("Fecha inválida"),
  ],
  expenseController.updateExpense
);

// Update expense status
router.put(
  "/:id/status",
  auth,
  admin,
  [body("status").notEmpty().withMessage("El estado es requerido")],
  expenseController.updateExpenseStatus
);

// Delete expense (admin only)
router.delete("/:id", auth, admin, expenseController.deleteExpense);

// Upload expense receipt/document
router.post("/:id/receipt", auth, admin, expenseController.uploadReceipt);

module.exports = router;
