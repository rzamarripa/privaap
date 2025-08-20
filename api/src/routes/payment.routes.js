const express = require('express');
const router = express.Router();
const {
  createPayment,
  getPaymentsByMonthlyFee,
  getPayment,
  cancelPayment,
  getPaymentSummary
} = require('../controllers/payment.controller');
const auth = require('../middlewares/auth');
const admin = require('../middlewares/admin');
const { body, param } = require('express-validator');
const { validateRequest } = require('../middlewares/validation');

// Validaciones
const createPaymentValidation = [
  body('monthlyFeeId')
    .notEmpty()
    .withMessage('ID de mensualidad es requerido')
    .isMongoId()
    .withMessage('ID de mensualidad inválido'),
  body('amount')
    .isNumeric()
    .withMessage('El monto debe ser un número')
    .isFloat({ min: 0.01 })
    .withMessage('El monto debe ser mayor a 0'),
  body('paymentMethod')
    .isIn(['efectivo', 'transferencia', 'cheque', 'tarjeta', 'otro'])
    .withMessage('Método de pago inválido'),
  body('receiptNumber')
    .optional()
    .isString()
    .withMessage('Número de recibo debe ser texto'),
  body('notes')
    .optional()
    .isString()
    .withMessage('Las notas deben ser texto'),
  body('paidDate')
    .optional()
    .isISO8601()
    .withMessage('Fecha de pago inválida')
];

const paymentIdValidation = [
  param('paymentId')
    .isMongoId()
    .withMessage('ID de pago inválido')
];

const monthlyFeeIdValidation = [
  param('monthlyFeeId')
    .isMongoId()
    .withMessage('ID de mensualidad inválido')
];

const cancelPaymentValidation = [
  ...paymentIdValidation,
  body('reason')
    .notEmpty()
    .withMessage('La razón de cancelación es requerida')
    .isString()
    .withMessage('La razón debe ser texto')
    .isLength({ min: 5, max: 500 })
    .withMessage('La razón debe tener entre 5 y 500 caracteres')
];

// Rutas

// POST /api/payments - Crear un nuevo pago
router.post('/', 
  auth, 
  admin, 
  createPaymentValidation, 
  validateRequest, 
  createPayment
);

// GET /api/payments/monthly-fee/:monthlyFeeId - Obtener pagos de una mensualidad
router.get('/monthly-fee/:monthlyFeeId', 
  auth, 
  monthlyFeeIdValidation, 
  validateRequest, 
  getPaymentsByMonthlyFee
);

// GET /api/payments/monthly-fee/:monthlyFeeId/summary - Obtener resumen de pagos
router.get('/monthly-fee/:monthlyFeeId/summary', 
  auth, 
  monthlyFeeIdValidation, 
  validateRequest, 
  getPaymentSummary
);

// GET /api/payments/:paymentId - Obtener un pago específico
router.get('/:paymentId', 
  auth, 
  paymentIdValidation, 
  validateRequest, 
  getPayment
);

// PATCH /api/payments/:paymentId/cancel - Cancelar un pago
router.patch('/:paymentId/cancel', 
  auth, 
  admin, 
  cancelPaymentValidation, 
  validateRequest, 
  cancelPayment
);

module.exports = router;