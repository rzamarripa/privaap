const mongoose = require("mongoose");

const communitySchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, "El nombre de la comunidad es requerido"],
      trim: true,
      minlength: [2, "El nombre debe tener al menos 2 caracteres"],
      maxlength: [100, "El nombre no puede exceder 100 caracteres"],
    },
    address: {
      type: String,
      required: [true, "La dirección es requerida"],
      trim: true,
      minlength: [5, "La dirección debe tener al menos 5 caracteres"],
      maxlength: [200, "La dirección no puede exceder 200 caracteres"],
    },
    description: {
      type: String,
      trim: true,
      maxlength: [500, "La descripción no puede exceder 500 caracteres"],
      default: "",
    },
    monthlyFee: {
      type: Number,
      required: [true, "La mensualidad es requerida"],
      min: [0, "La mensualidad debe ser un número positivo"],
    },
    currency: {
      type: String,
      required: [true, "La moneda es requerida"],
      enum: {
        values: ["MXN", "USD", "EUR"],
        message: "Moneda no válida. Debe ser MXN, USD o EUR",
      },
      default: "MXN",
    },
    totalHouses: {
      type: Number,
      required: [true, "El total de casas es requerido"],
      min: [1, "Debe haber al menos 1 casa"],
      max: [1000, "No puede haber más de 1000 casas"],
    },
    superAdminId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: [true, "El super administrador es requerido"],
    },
    adminIds: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
      },
    ],
    isActive: {
      type: Boolean,
      default: true,
    },
    settings: {
      allowResidents: {
        type: Boolean,
        default: true,
      },
      requireApproval: {
        type: Boolean,
        default: true,
      },
      maxFileSize: {
        type: Number,
        default: 5 * 1024 * 1024, // 5MB en bytes
        min: [1024 * 1024, "El tamaño máximo de archivo debe ser al menos 1MB"],
        max: [
          50 * 1024 * 1024,
          "El tamaño máximo de archivo no puede exceder 50MB",
        ],
      },
      notificationPreferences: {
        email: {
          type: Boolean,
          default: true,
        },
        push: {
          type: Boolean,
          default: true,
        },
        sms: {
          type: Boolean,
          default: false,
        },
      },
    },
    createdAt: {
      type: Date,
      default: Date.now,
    },
    updatedAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

// Índices para mejorar el rendimiento de las consultas
communitySchema.index({ name: 1 });
communitySchema.index({ superAdminId: 1 });
communitySchema.index({ adminIds: 1 });
communitySchema.index({ isActive: 1 });
communitySchema.index({ createdAt: -1 });

// Virtual para obtener el total de administradores
communitySchema.virtual("totalAdmins").get(function () {
  return this.adminIds && Array.isArray(this.adminIds)
    ? this.adminIds.length
    : 0;
});

// Virtual para obtener el total de residentes (se calculará dinámicamente)
communitySchema.virtual("totalResidents").get(function () {
  // Este valor se calculará dinámicamente desde el modelo User
  return 0;
});

// Middleware para actualizar updatedAt antes de guardar
communitySchema.pre("save", function (next) {
  this.updatedAt = new Date();
  next();
});

// Método estático para buscar comunidades por super admin
communitySchema.statics.findBySuperAdmin = function (superAdminId) {
  return this.find({ superAdminId });
};

// Método estático para buscar comunidades activas
communitySchema.statics.findActive = function () {
  return this.find({ isActive: true });
};

// Método de instancia para agregar administrador
communitySchema.methods.addAdmin = function (adminId) {
  if (!this.adminIds.includes(adminId)) {
    this.adminIds.push(adminId);
    return this.save();
  }
  return Promise.resolve(this);
};

// Método de instancia para remover administrador
communitySchema.methods.removeAdmin = function (adminId) {
  this.adminIds = this.adminIds.filter((id) => !id.equals(adminId));
  return this.save();
};

// Método de instancia para verificar si un usuario es administrador
communitySchema.methods.isAdmin = function (userId) {
  return this.adminIds.some((id) => id.equals(userId));
};

// Método de instancia para verificar si un usuario es super admin
communitySchema.methods.isSuperAdmin = function (userId) {
  return this.superAdminId.equals(userId);
};

// Método de instancia para obtener información pública
communitySchema.methods.getPublicInfo = function () {
  return {
    id: this._id,
    name: this.name,
    address: this.address,
    description: this.description,
    monthlyFee: this.monthlyFee,
    currency: this.currency,
    totalHouses: this.totalHouses,
    isActive: this.isActive,
    createdAt: this.createdAt,
  };
};

const Community = mongoose.model("Community", communitySchema);

module.exports = Community;
