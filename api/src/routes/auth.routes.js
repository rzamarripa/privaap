const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const authController = require('../controllers/auth.controller');
const auth = require('../middlewares/auth');

// Register
router.post('/register',
  [
    body('phoneNumber').isMobilePhone().withMessage('Número de teléfono inválido'),
    body('name').notEmpty().trim().withMessage('El nombre es requerido'),
    body('email').isEmail().normalizeEmail().withMessage('Email inválido'),
    body('password').isLength({ min: 6 }).withMessage('La contraseña debe tener al menos 6 caracteres'),
    body('role').optional().isIn(['administrador', 'residente']).withMessage('Rol inválido')
  ],
  authController.register
);

// Login
router.post('/login',
  [
    body('phoneNumber').isMobilePhone().withMessage('Número de teléfono inválido'),
    body('password').notEmpty().withMessage('La contraseña es requerida')
  ],
  authController.login
);

// Get current user
router.get('/me', auth, authController.getCurrentUser);

// Refresh token
router.post('/refresh-token', authController.refreshToken);

// Logout
router.post('/logout', auth, authController.logout);

// Forgot password
router.post('/forgot-password',
  [
    body('phoneNumber').isMobilePhone().withMessage('Número de teléfono inválido')
  ],
  authController.forgotPassword
);

// Reset password
router.post('/reset-password',
  [
    body('token').notEmpty().withMessage('Token es requerido'),
    body('password').isLength({ min: 6 }).withMessage('La contraseña debe tener al menos 6 caracteres')
  ],
  authController.resetPassword
);

module.exports = router;