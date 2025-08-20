const { validationResult } = require('express-validator');

/**
 * Middleware para validar los resultados de express-validator
 * Si hay errores de validación, retorna un error 400 con los detalles
 */
const validateRequest = (req, res, next) => {
  const errors = validationResult(req);
  
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      error: 'Datos de entrada inválidos',
      details: errors.array().map(error => ({
        field: error.param,
        message: error.msg,
        value: error.value
      }))
    });
  }
  
  next();
};

module.exports = {
  validateRequest
};
