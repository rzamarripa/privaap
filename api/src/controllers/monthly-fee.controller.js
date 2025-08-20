const MonthlyFee = require("../models/MonthlyFee.model");
const Community = require("../models/Community.model");
const User = require("../models/User.model");
const { validationResult } = require("express-validator");

// Obtener todas las mensualidades (con filtros)
exports.getAllMonthlyFees = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 20,
      status,
      month,
      communityId,
      userId,
      sortBy = "month",
      sortOrder = "desc",
    } = req.query;

    // Construir filtros
    const filters = {};
    if (status) filters.status = status;
    if (month) filters.month = month;
    if (communityId) filters.communityId = communityId;
    if (userId) filters.userId = userId;

    // Construir ordenamiento
    const sort = {};
    sort[sortBy] = sortOrder === "desc" ? -1 : 1;

    // Ejecutar consulta con paginación
    const monthlyFees = await MonthlyFee.find(filters)
      .populate("communityId", "name monthlyFee currency")
      .populate("userId", "name email")
      .sort(sort)
      .limit(limit * 1)
      .skip((page - 1) * limit)
      .exec();

    // Contar total de mensualidades
    const total = await MonthlyFee.countDocuments(filters);

    res.json({
      success: true,
      data: {
        monthlyFees,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(total / limit),
          totalMonthlyFees: total,
          hasNext: page * limit < total,
          hasPrev: page > 1,
        },
      },
    });
  } catch (error) {
    console.error("Error al obtener mensualidades:", error);
    res.status(500).json({
      success: false,
      error: "Error interno del servidor",
    });
  }
};

// Obtener mensualidades del usuario autenticado
exports.getUserMonthlyFees = async (req, res) => {
  try {
    const userId = req.user._id;
    const { status, month, communityId } = req.query;

    const options = {};
    if (status) options.status = status;
    if (month) options.month = month;
    if (communityId) options.communityId = communityId;

    const monthlyFees = await MonthlyFee.getMonthlyFeesByUser(userId, options);

    res.json({
      success: true,
      data: monthlyFees,
    });
  } catch (error) {
    console.error("Error al obtener mensualidades del usuario:", error);
    res.status(500).json({
      success: false,
      error: "Error interno del servidor",
    });
  }
};

// Obtener mensualidades por comunidad (para administradores)
exports.getCommunityMonthlyFees = async (req, res) => {
  try {
    const { communityId } = req.params;
    const { status, month, userId } = req.query;

    // Verificar que el usuario tenga acceso a esta comunidad
    if (req.user.role !== "superAdmin" && req.user.role !== "administrador") {
      return res.status(403).json({
        success: false,
        error: "No tienes permisos para ver mensualidades de esta comunidad",
      });
    }

    const options = {};
    if (status) options.status = status;
    if (month) options.month = month;
    if (userId) options.userId = userId;

    const monthlyFees = await MonthlyFee.getMonthlyFeesByCommunity(
      communityId,
      options
    );

    res.json({
      success: true,
      data: monthlyFees,
    });
  } catch (error) {
    console.error("Error al obtener mensualidades de la comunidad:", error);
    res.status(500).json({
      success: false,
      error: "Error interno del servidor",
    });
  }
};

// Obtener una mensualidad específica por ID
exports.getMonthlyFeeById = async (req, res) => {
  try {
    const { id } = req.params;
    const monthlyFee = await MonthlyFee.findById(id)
      .populate("communityId", "name monthlyFee currency")
      .populate("userId", "name email");

    if (!monthlyFee) {
      return res.status(404).json({
        success: false,
        error: "Mensualidad no encontrada",
      });
    }

    // Verificar que el usuario solo pueda ver sus propias mensualidades (a menos que sea admin)
    if (req.user.role !== "superAdmin" && req.user.role !== "administrador") {
      if (monthlyFee.userId.toString() !== req.user._id.toString()) {
        return res.status(403).json({
          success: false,
          error: "No tienes permisos para ver esta mensualidad",
        });
      }
    }

    res.json({
      success: true,
      data: monthlyFee,
    });
  } catch (error) {
    console.error("Error al obtener mensualidad:", error);

    if (error.name === "CastError") {
      return res.status(400).json({
        success: false,
        error: "ID de mensualidad inválido",
      });
    }

    res.status(500).json({
      success: false,
      error: "Error interno del servidor",
    });
  }
};

// Crear una nueva mensualidad
exports.createMonthlyFee = async (req, res) => {
  try {
    // Validar errores de validación
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        error: "Datos de entrada inválidos",
        details: errors.array(),
      });
    }

    // Verificar que solo los administradores puedan crear mensualidades
    if (req.user.role !== "superAdmin" && req.user.role !== "administrador") {
      return res.status(403).json({
        success: false,
        error: "No tienes permisos para crear mensualidades",
      });
    }

    // Verificar que la comunidad existe
    const community = await Community.findById(req.body.communityId);
    if (!community) {
      return res.status(404).json({
        success: false,
        error: "Comunidad no encontrada",
      });
    }

    // Verificar que el usuario existe
    const user = await User.findById(req.body.userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        error: "Usuario no encontrado",
      });
    }

    // Verificar que no exista una mensualidad para la misma casa, comunidad y mes
    const existingFee = await MonthlyFee.findOne({
      communityId: req.body.communityId,
      houseId: req.body.houseId,
      month: req.body.month,
    });

    if (existingFee) {
      return res.status(400).json({
        success: false,
        error: "Ya existe una mensualidad para esta casa en este mes",
      });
    }

    // Crear la mensualidad
    const monthlyFee = new MonthlyFee(req.body);
    await monthlyFee.save();

    // Poblar referencias para la respuesta
    await monthlyFee.populate("communityId", "name monthlyFee currency");
    await monthlyFee.populate("userId", "name email");

    res.status(201).json({
      success: true,
      message: "Mensualidad creada exitosamente",
      data: monthlyFee,
    });
  } catch (error) {
    console.error("Error al crear mensualidad:", error);

    if (error.name === "ValidationError") {
      return res.status(400).json({
        success: false,
        error: "Datos de entrada inválidos",
        details: Object.values(error.errors).map((err) => ({
          field: err.path,
          message: err.message,
        })),
      });
    }

    res.status(500).json({
      success: false,
      error: "Error interno del servidor",
    });
  }
};

// Actualizar una mensualidad
exports.updateMonthlyFee = async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;

    // Verificar que solo los administradores puedan actualizar mensualidades
    if (req.user.role !== "superAdmin" && req.user.role !== "administrador") {
      return res.status(403).json({
        success: false,
        error: "No tienes permisos para actualizar mensualidades",
      });
    }

    const monthlyFee = await MonthlyFee.findById(id);
    if (!monthlyFee) {
      return res.status(404).json({
        success: false,
        error: "Mensualidad no encontrada",
      });
    }

    // Actualizar campos permitidos
    const allowedUpdates = [
      "amount",
      "amountPaid",
      "status",
      "dueDate",
      "paidDate",
      "paymentMethod",
      "receiptNumber",
      "notes",
      "discountAmount",
      "lateFeeAmount",
      "isRecurring",
    ];

    allowedUpdates.forEach((field) => {
      if (updates[field] !== undefined) {
        monthlyFee[field] = updates[field];
      }
    });

    // Si se actualiza el monto pagado, actualizar la fecha de pago
    if (updates.amountPaid !== undefined) {
      if (updates.amountPaid > 0) {
        monthlyFee.paidDate = new Date();
      } else {
        monthlyFee.paidDate = null;
      }
    }

    // Guardar y actualizar estado automáticamente
    await monthlyFee.save();

    // Poblar referencias para la respuesta
    await monthlyFee.populate("communityId", "name monthlyFee currency");
    await monthlyFee.populate("userId", "name email");

    res.json({
      success: true,
      message: "Mensualidad actualizada exitosamente",
      data: monthlyFee,
    });
  } catch (error) {
    console.error("Error al actualizar mensualidad:", error);

    if (error.name === "ValidationError") {
      return res.status(400).json({
        success: false,
        error: "Datos de entrada inválidos",
        details: Object.values(error.errors).map((err) => ({
          field: err.path,
          message: err.message,
        })),
      });
    }

    res.status(500).json({
      success: false,
      error: "Error interno del servidor",
    });
  }
};

// Registrar un pago
exports.recordPayment = async (req, res) => {
  try {
    const { id } = req.params;
    const { amount, paymentMethod, receiptNumber, notes } = req.body;

    // Verificar que solo los administradores puedan registrar pagos
    if (req.user.role !== "superAdmin" && req.user.role !== "administrador") {
      return res.status(403).json({
        success: false,
        error: "No tienes permisos para registrar pagos",
      });
    }

    const monthlyFee = await MonthlyFee.findById(id);
    if (!monthlyFee) {
      return res.status(404).json({
        success: false,
        error: "Mensualidad no encontrada",
      });
    }

    // Validar que el monto del pago no exceda el monto pendiente
    const remainingAmount = monthlyFee.calculateRemainingAmount();
    if (amount > remainingAmount) {
      return res.status(400).json({
        success: false,
        error: `El monto del pago (${amount}) excede el monto pendiente (${remainingAmount})`,
      });
    }

    // Actualizar la mensualidad
    monthlyFee.amountPaid += amount;
    monthlyFee.paymentMethod = paymentMethod;
    monthlyFee.receiptNumber = receiptNumber;
    if (notes) monthlyFee.notes = notes;
    monthlyFee.paidDate = new Date();

    // Guardar y actualizar estado automáticamente
    await monthlyFee.save();

    // Poblar referencias para la respuesta
    await monthlyFee.populate("communityId", "name monthlyFee currency");
    await monthlyFee.populate("userId", "name email");

    res.json({
      success: true,
      message: "Pago registrado exitosamente",
      data: monthlyFee,
    });
  } catch (error) {
    console.error("Error al registrar pago:", error);
    res.status(500).json({
      success: false,
      error: "Error interno del servidor",
    });
  }
};

// Generar mensualidades para un mes específico
exports.generateMonthlyFeesForMonth = async (req, res) => {
  try {
    const { communityId, month } = req.body;

    // Verificar que solo los administradores puedan generar mensualidades
    if (req.user.role !== "superAdmin" && req.user.role !== "administrador") {
      return res.status(403).json({
        success: false,
        error: "No tienes permisos para generar mensualidades",
      });
    }

    // Verificar que la comunidad existe
    const community = await Community.findById(communityId);
    if (!community) {
      return res.status(404).json({
        success: false,
        error: "Comunidad no encontrada",
      });
    }

    // Obtener todos los usuarios de la comunidad
    const users = await User.find({ communityId }).populate(
      "community",
      "monthlyFee"
    );

    // Generar mensualidades
    const generatedFees = await MonthlyFee.generateMonthlyFeesForMonth(
      communityId,
      month,
      users
    );

    res.json({
      success: true,
      message: `${generatedFees.length} mensualidades generadas exitosamente para ${month}`,
      data: {
        count: generatedFees.length,
        month,
        communityId,
      },
    });
  } catch (error) {
    console.error("Error al generar mensualidades:", error);
    res.status(500).json({
      success: false,
      error: "Error interno del servidor",
    });
  }
};

// Obtener resumen financiero
exports.getFinancialSummary = async (req, res) => {
  try {
    const { communityId, month } = req.query;

    // Verificar que solo los administradores puedan ver resúmenes financieros
    if (req.user.role !== "superAdmin" && req.user.role !== "administrador") {
      return res.status(403).json({
        success: false,
        error: "No tienes permisos para ver resúmenes financieros",
      });
    }

    const summary = await MonthlyFee.getFinancialSummary(communityId, month);

    res.json({
      success: true,
      data: summary,
    });
  } catch (error) {
    console.error("Error al obtener resumen financiero:", error);
    res.status(500).json({
      success: false,
      error: "Error interno del servidor",
    });
  }
};

// Eliminar una mensualidad
exports.deleteMonthlyFee = async (req, res) => {
  try {
    const { id } = req.params;

    // Verificar que solo los super administradores puedan eliminar mensualidades
    if (req.user.role !== "superAdmin") {
      return res.status(403).json({
        success: false,
        error: "Solo los super administradores pueden eliminar mensualidades",
      });
    }

    const monthlyFee = await MonthlyFee.findById(id);
    if (!monthlyFee) {
      return res.status(404).json({
        success: false,
        error: "Mensualidad no encontrada",
      });
    }

    // Verificar que la mensualidad no tenga pagos registrados
    if (monthlyFee.amountPaid > 0) {
      return res.status(400).json({
        success: false,
        error:
          "No se puede eliminar una mensualidad que tiene pagos registrados",
      });
    }

    await MonthlyFee.findByIdAndDelete(id);

    res.json({
      success: true,
      message: "Mensualidad eliminada exitosamente",
    });
  } catch (error) {
    console.error("Error al eliminar mensualidad:", error);
    res.status(500).json({
      success: false,
      error: "Error interno del servidor",
    });
  }
};
