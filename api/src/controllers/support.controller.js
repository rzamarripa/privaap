const SupportTicket = require("../models/SupportTicket.model");
const { validationResult } = require("express-validator");

// Crear un nuevo ticket de soporte
exports.createTicket = async (req, res) => {
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

    // Crear el ticket
    const ticket = new SupportTicket(req.body);
    await ticket.save();

    // Enviar respuesta exitosa
    res.status(201).json({
      success: true,
      message: "Ticket creado exitosamente",
      data: {
        id: ticket._id,
        subject: ticket.subject,
        category: ticket.category,
        status: ticket.status,
        createdAt: ticket.createdAt,
      },
    });
  } catch (error) {
    console.error("Error al crear ticket:", error);

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

// Obtener todos los tickets (para administradores)
exports.getAllTickets = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 20,
      status,
      category,
      sortBy = "createdAt",
      sortOrder = "desc",
    } = req.query;

    // Construir filtros
    const filters = {};
    if (status) filters.status = status;
    if (category) filters.category = category;

    // Construir ordenamiento
    const sort = {};
    sort[sortBy] = sortOrder === "desc" ? -1 : 1;

    // Ejecutar consulta con paginación
    const tickets = await SupportTicket.find(filters)
      .sort(sort)
      .limit(limit * 1)
      .skip((page - 1) * limit)
      .populate("assignedTo", "name email")
      .exec();

    // Contar total de tickets
    const total = await SupportTicket.countDocuments(filters);

    res.json({
      success: true,
      data: {
        tickets,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(total / limit),
          totalTickets: total,
          hasNext: page * limit < total,
          hasPrev: page > 1,
        },
      },
    });
  } catch (error) {
    console.error("Error al obtener tickets:", error);
    res.status(500).json({
      success: false,
      error: "Error interno del servidor",
    });
  }
};

// Obtener tickets del usuario autenticado
exports.getUserTickets = async (req, res) => {
  try {
    const userEmail = req.user.email;
    const tickets = await SupportTicket.getUserTickets(userEmail);

    res.json({
      success: true,
      data: tickets,
    });
  } catch (error) {
    console.error("Error al obtener tickets del usuario:", error);
    res.status(500).json({
      success: false,
      error: "Error interno del servidor",
    });
  }
};

// Obtener un ticket específico por ID
exports.getTicketById = async (req, res) => {
  try {
    const { id } = req.params;
    const ticket = await SupportTicket.findById(id).populate(
      "assignedTo",
      "name email"
    );

    if (!ticket) {
      return res.status(404).json({
        success: false,
        error: "Ticket no encontrado",
      });
    }

    // Verificar que el usuario solo pueda ver sus propios tickets (a menos que sea admin)
    if (req.user.role !== "superAdmin" && req.user.role !== "administrador") {
      if (ticket.userEmail !== req.user.email) {
        return res.status(403).json({
          success: false,
          error: "No tienes permisos para ver este ticket",
        });
      }
    }

    res.json({
      success: true,
      data: ticket,
    });
  } catch (error) {
    console.error("Error al obtener ticket:", error);

    if (error.name === "CastError") {
      return res.status(400).json({
        success: false,
        error: "ID de ticket inválido",
      });
    }

    res.status(500).json({
      success: false,
      error: "Error interno del servidor",
    });
  }
};

// Actualizar un ticket (para administradores)
exports.updateTicket = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, assignedTo, response } = req.body;

    // Verificar que solo los administradores puedan actualizar tickets
    if (req.user.role !== "superAdmin" && req.user.role !== "administrador") {
      return res.status(403).json({
        success: false,
        error: "No tienes permisos para actualizar tickets",
      });
    }

    const ticket = await SupportTicket.findById(id);
    if (!ticket) {
      return res.status(404).json({
        success: false,
        error: "Ticket no encontrado",
      });
    }

    // Actualizar campos permitidos
    if (status) ticket.status = status;
    if (assignedTo) ticket.assignedTo = assignedTo;
    if (response) {
      ticket.response = response;
      ticket.respondedAt = new Date();
    }

    await ticket.save();

    res.json({
      success: true,
      message: "Ticket actualizado exitosamente",
      data: ticket,
    });
  } catch (error) {
    console.error("Error al actualizar ticket:", error);

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

// Asignar ticket a un usuario
exports.assignTicket = async (req, res) => {
  try {
    const { id } = req.params;
    const { assignedTo } = req.body;

    // Verificar permisos
    if (req.user.role !== "superAdmin" && req.user.role !== "administrador") {
      return res.status(403).json({
        success: false,
        error: "No tienes permisos para asignar tickets",
      });
    }

    const ticket = await SupportTicket.findById(id);
    if (!ticket) {
      return res.status(404).json({
        success: false,
        error: "Ticket no encontrado",
      });
    }

    await ticket.assignTo(assignedTo);

    res.json({
      success: true,
      message: "Ticket asignado exitosamente",
      data: ticket,
    });
  } catch (error) {
    console.error("Error al asignar ticket:", error);
    res.status(500).json({
      success: false,
      error: "Error interno del servidor",
    });
  }
};

// Responder a un ticket
exports.respondToTicket = async (req, res) => {
  try {
    const { id } = req.params;
    const { response } = req.body;

    // Verificar permisos
    if (req.user.role !== "superAdmin" && req.user.role !== "administrador") {
      return res.status(403).json({
        success: false,
        error: "No tienes permisos para responder tickets",
      });
    }

    if (!response || response.trim().length === 0) {
      return res.status(400).json({
        success: false,
        error: "La respuesta es requerida",
      });
    }

    const ticket = await SupportTicket.findById(id);
    if (!ticket) {
      return res.status(404).json({
        success: false,
        error: "Ticket no encontrado",
      });
    }

    await ticket.respond(response);

    res.json({
      success: true,
      message: "Respuesta enviada exitosamente",
      data: ticket,
    });
  } catch (error) {
    console.error("Error al responder ticket:", error);
    res.status(500).json({
      success: false,
      error: "Error interno del servidor",
    });
  }
};

// Cerrar un ticket
exports.closeTicket = async (req, res) => {
  try {
    const { id } = req.params;

    // Verificar permisos
    if (req.user.role !== "superAdmin" && req.user.role !== "administrador") {
      return res.status(403).json({
        success: false,
        error: "No tienes permisos para cerrar tickets",
      });
    }

    const ticket = await SupportTicket.findById(id);
    if (!ticket) {
      return res.status(404).json({
        success: false,
        error: "Ticket no encontrado",
      });
    }

    await ticket.close();

    res.json({
      success: true,
      message: "Ticket cerrado exitosamente",
      data: ticket,
    });
  } catch (error) {
    console.error("Error al cerrar ticket:", error);
    res.status(500).json({
      success: false,
      error: "Error interno del servidor",
    });
  }
};

// Obtener estadísticas de tickets
exports.getTicketStats = async (req, res) => {
  try {
    // Verificar permisos
    if (req.user.role !== "superAdmin" && req.user.role !== "administrador") {
      return res.status(403).json({
        success: false,
        error: "No tienes permisos para ver estadísticas",
      });
    }

    const stats = await SupportTicket.aggregate([
      {
        $group: {
          _id: "$status",
          count: { $sum: 1 },
        },
      },
    ]);

    const totalTickets = await SupportTicket.countDocuments();
    const pendingTickets = await SupportTicket.countDocuments({
      status: "pending",
    });
    const resolvedTickets = await SupportTicket.countDocuments({
      status: "resolved",
    });

    res.json({
      success: true,
      data: {
        total: totalTickets,
        pending: pendingTickets,
        resolved: resolvedTickets,
        byStatus: stats,
      },
    });
  } catch (error) {
    console.error("Error al obtener estadísticas:", error);
    res.status(500).json({
      success: false,
      error: "Error interno del servidor",
    });
  }
};
