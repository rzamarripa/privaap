const errorHandler = (err, req, res, next) => {
  let error = { ...err };
  error.message = err.message;

  // Log to console for dev
  console.error(err);

  // Mongoose bad ObjectId
  if (err.name === "CastError") {
    const message = "Recurso no encontrado";
    error = { message, statusCode: 404 };
  }

  // Mongoose duplicate key - Mejorar mensajes para campos específicos
  if (err.code === 11000) {
    const field = Object.keys(err.keyValue)[0];
    let message;

    // Mensajes más específicos para campos comunes
    if (field === "email") {
      message = "El email ya está registrado";
    } else if (field === "phoneNumber") {
      message = "El número de teléfono ya está registrado";
    } else if (field === "name") {
      message = "El nombre ya está registrado";
    } else {
      message = `Ya existe un registro con ese ${field}`;
    }

    error = { message, statusCode: 400 };
  }

  // Mongoose validation error
  if (err.name === "ValidationError") {
    const message = Object.values(err.errors)
      .map((val) => val.message)
      .join(", ");
    error = { message, statusCode: 400 };
  }

  res.status(error.statusCode || 500).json({
    success: false,
    error: error.message || "Error del servidor",
  });
};

module.exports = errorHandler;
