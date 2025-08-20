const mongoose = require("mongoose");

const supportTicketSchema = new mongoose.Schema(
  {
    userName: {
      type: String,
      required: [true, "El nombre del usuario es requerido"],
      trim: true,
    },
    userEmail: {
      type: String,
      required: [true, "El email del usuario es requerido"],
      trim: true,
      lowercase: true,
    },
    userPhone: {
      type: String,
      trim: true,
    },
    communityName: {
      type: String,
      required: [true, "El nombre de la comunidad es requerido"],
      trim: true,
    },
    subject: {
      type: String,
      required: [true, "El asunto es requerido"],
      trim: true,
      minlength: [10, "El asunto debe tener al menos 10 caracteres"],
      maxlength: [200, "El asunto no puede exceder 200 caracteres"],
    },
    category: {
      type: String,
      required: [true, "La categoría es requerida"],
      enum: {
        values: ["technical", "bug", "feature", "account", "billing", "other"],
        message: "Categoría no válida",
      },
    },
    description: {
      type: String,
      required: [true, "La descripción es requerida"],
      trim: true,
      minlength: [20, "La descripción debe tener al menos 20 caracteres"],
      maxlength: [2000, "La descripción no puede exceder 2000 caracteres"],
    },
    reproductionSteps: {
      type: String,
      trim: true,
      maxlength: [1000, "Los pasos no pueden exceder 1000 caracteres"],
    },
    attachments: {
      type: [String], // Array de URLs de las imágenes
      validate: {
        validator: function (v) {
          return v.length <= 3; // Máximo 3 imágenes
        },
        message: "No se pueden adjuntar más de 3 imágenes",
      },
      default: [],
    },
    deviceType: {
      type: String,
      required: [true, "El tipo de dispositivo es requerido"],
      enum: {
        values: ["Android", "iOS"],
        message: "Tipo de dispositivo no válido",
      },
    },
    appVersion: {
      type: String,
      required: [true, "La versión de la app es requerida"],
      trim: true,
    },
    status: {
      type: String,
      enum: {
        values: ["pending", "in_progress", "resolved", "closed"],
        message: "Estado no válido",
      },
      default: "pending",
    },
    assignedTo: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },
    response: {
      type: String,
      trim: true,
      maxlength: [2000, "La respuesta no puede exceder 2000 caracteres"],
    },
    respondedAt: {
      type: Date,
    },
  },
  {
    timestamps: true, // Agrega createdAt y updatedAt automáticamente
  }
);

// Índices para mejorar el rendimiento de las consultas
supportTicketSchema.index({ userEmail: 1, createdAt: -1 });
supportTicketSchema.index({ status: 1, createdAt: -1 });
supportTicketSchema.index({ category: 1, createdAt: -1 });

// Método para obtener tickets del usuario
supportTicketSchema.statics.getUserTickets = function (userEmail) {
  return this.find({ userEmail }).sort({ createdAt: -1 });
};

// Método para obtener tickets por estado
supportTicketSchema.statics.getTicketsByStatus = function (status) {
  return this.find({ status }).sort({ createdAt: -1 });
};

// Método para asignar ticket
supportTicketSchema.methods.assignTo = function (userId) {
  this.assignedTo = userId;
  this.status = "in_progress";
  return this.save();
};

// Método para responder ticket
supportTicketSchema.methods.respond = function (response) {
  this.response = response;
  this.respondedAt = new Date();
  this.status = "resolved";
  return this.save();
};

// Método para cerrar ticket
supportTicketSchema.methods.close = function () {
  this.status = "closed";
  return this.save();
};

// Middleware pre-save para validaciones adicionales
supportTicketSchema.pre("save", function (next) {
  // Si hay pasos de reproducción, validar que no esté vacío
  if (this.reproductionSteps && this.reproductionSteps.trim().length === 0) {
    this.reproductionSteps = undefined;
  }

  // Si hay adjuntos, validar que no estén vacíos
  if (this.attachments && this.attachments.length > 0) {
    this.attachments = this.attachments.filter(
      (url) => url && url.trim().length > 0
    );
  }

  next();
});

module.exports = mongoose.model("SupportTicket", supportTicketSchema);
