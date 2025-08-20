const mongoose = require("mongoose");

const monthlyFeeSchema = new mongoose.Schema(
  {
    communityId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Community",
      required: [true, "El ID de la comunidad es requerido"],
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: [true, "El ID del usuario es requerido"],
    },
    houseId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "House",
      required: [true, "El ID de la casa es requerido"],
    },
    month: {
      type: String,
      required: [true, "El mes es requerido"],
      validate: {
        validator: function (v) {
          // Validar formato YYYY-MM
          return /^\d{4}-\d{2}$/.test(v);
        },
        message: "El formato del mes debe ser YYYY-MM (ejemplo: 2024-01)",
      },
    },
    amount: {
      type: Number,
      required: [true, "El monto es requerido"],
      min: [0, "El monto no puede ser negativo"],
    },
    amountPaid: {
      type: Number,
      default: 0,
      min: [0, "El monto pagado no puede ser negativo"],
    },
    status: {
      type: String,
      enum: {
        values: ["pendiente", "pagado", "vencido", "parcial", "exento"],
        message:
          "Estado no válido. Estados permitidos: pendiente, pagado, vencido, parcial, exento",
      },
      default: "pendiente",
    },
    dueDate: {
      type: Date,
      required: [true, "La fecha de vencimiento es requerida"],
    },
    paidDate: {
      type: Date,
      default: null,
    },
    paymentMethod: {
      type: String,
      enum: {
        values: ["efectivo", "transferencia", "cheque", "tarjeta", "otro"],
        message: "Método de pago no válido",
      },
    },
    receiptNumber: {
      type: String,
      trim: true,
      maxlength: [50, "El número de recibo no puede exceder 50 caracteres"],
    },
    notes: {
      type: String,
      trim: true,
      maxlength: [500, "Las notas no pueden exceder 500 caracteres"],
    },
    isRecurring: {
      type: Boolean,
      default: true,
    },
    discountAmount: {
      type: Number,
      default: 0,
      min: [0, "El descuento no puede ser negativo"],
    },
    lateFeeAmount: {
      type: Number,
      default: 0,
      min: [0, "La penalización no puede ser negativa"],
    },
  },
  {
    timestamps: true, // Agrega createdAt y updatedAt automáticamente
  }
);

// Índices para mejorar el rendimiento de las consultas
monthlyFeeSchema.index({ communityId: 1, month: 1 });
monthlyFeeSchema.index({ userId: 1, month: 1 });
monthlyFeeSchema.index({ houseId: 1, month: 1 });
monthlyFeeSchema.index({ status: 1, dueDate: 1 });
monthlyFeeSchema.index({ dueDate: 1 });
// Índice único para evitar duplicados: una mensualidad por casa por mes
monthlyFeeSchema.index(
  { communityId: 1, houseId: 1, month: 1 },
  { unique: true }
);

// Métodos de instancia
monthlyFeeSchema.methods.calculateRemainingAmount = function () {
  return (
    this.amount - this.amountPaid + this.discountAmount - this.lateFeeAmount
  );
};

monthlyFeeSchema.methods.isFullyPaid = function () {
  return this.calculateRemainingAmount() <= 0;
};

monthlyFeeSchema.methods.isOverdue = function () {
  return new Date() > this.dueDate && !this.isFullyPaid();
};

monthlyFeeSchema.methods.isPartialPayment = function () {
  return this.amountPaid > 0 && !this.isFullyPaid();
};

monthlyFeeSchema.methods.updateStatus = function () {
  if (this.isFullyPaid()) {
    this.status = "pagado";
  } else if (this.isOverdue()) {
    this.status = "vencido";
  } else if (this.isPartialPayment()) {
    this.status = "parcial";
  } else {
    this.status = "pendiente";
  }
  // No llamar a save() aquí para evitar bucles infinitos
  return this;
};

// Métodos estáticos
monthlyFeeSchema.statics.getMonthlyFeesByUser = function (
  userId,
  options = {}
) {
  const query = { userId };

  if (options.status) query.status = options.status;
  if (options.month) query.month = options.month;
  if (options.communityId) query.communityId = options.communityId;

  return this.find(query)
    .populate("communityId", "name monthlyFee currency")
    .populate("userId", "name email")
    .sort({ month: -1, dueDate: 1 });
};

monthlyFeeSchema.statics.getMonthlyFeesByCommunity = function (
  communityId,
  options = {}
) {
  const query = { communityId };

  if (options.status) query.status = options.status;
  if (options.month) query.month = options.month;
  if (options.userId) query.userId = options.userId;

  return this.find(query)
    .populate("communityId", "name monthlyFee currency")
    .populate("userId", "name email")
    .sort({ month: -1, dueDate: 1 });
};

monthlyFeeSchema.statics.getMonthlyFeesByMonth = function (
  month,
  communityId = null
) {
  const query = { month };
  if (communityId) query.communityId = communityId;

  return this.find(query)
    .populate("communityId", "name monthlyFee currency")
    .populate("userId", "name email")
    .sort({ dueDate: 1 });
};

monthlyFeeSchema.statics.generateMonthlyFeesForMonth = async function (
  communityId,
  month,
  users
) {
  const monthlyFees = [];

  for (const user of users) {
    // Verificar si ya existe una mensualidad para este usuario y mes
    const existingFee = await this.findOne({
      communityId,
      userId: user._id,
      month,
    });

    if (!existingFee) {
      const monthlyFee = new this({
        communityId,
        userId: user._id,
        month,
        amount: user.community?.monthlyFee || 0,
        dueDate: new Date(`${month}-01`), // Primer día del mes
        status: "pendiente",
      });

      monthlyFees.push(monthlyFee);
    }
  }

  if (monthlyFees.length > 0) {
    return await this.insertMany(monthlyFees);
  }

  return [];
};

monthlyFeeSchema.statics.getFinancialSummary = async function (
  communityId,
  month = null
) {
  const matchStage = { communityId };
  if (month) matchStage.month = month;

  const summary = await this.aggregate([
    { $match: matchStage },
    {
      $group: {
        _id: "$status",
        count: { $sum: 1 },
        totalAmount: { $sum: "$amount" },
        totalPaid: { $sum: "$amountPaid" },
        totalDiscounts: { $sum: "$discountAmount" },
        totalLateFees: { $sum: "$lateFeeAmount" },
      },
    },
  ]);

  return summary;
};

// Middleware pre-save para validaciones adicionales
monthlyFeeSchema.pre("save", function (next) {
  // Actualizar estado automáticamente sin llamar a save()
  if (this.isFullyPaid()) {
    this.status = "pagado";
  } else if (this.isOverdue()) {
    this.status = "vencido";
  } else if (this.isPartialPayment()) {
    this.status = "parcial";
  } else {
    this.status = "pendiente";
  }

  // Validar que el monto pagado no exceda el monto total
  if (this.amountPaid > this.amount) {
    return next(new Error("El monto pagado no puede exceder el monto total"));
  }

  // Validar que la fecha de pago no sea anterior a la fecha de vencimiento
  if (this.paidDate && this.paidDate < this.dueDate) {
    return next(
      new Error(
        "La fecha de pago no puede ser anterior a la fecha de vencimiento"
      )
    );
  }

  next();
});

// Middleware pre-update para validaciones
monthlyFeeSchema.pre("findOneAndUpdate", function (next) {
  const update = this.getUpdate();

  // Si se está actualizando el monto pagado, validar que no exceda el monto total
  if (update.amountPaid && update.amountPaid > update.amount) {
    return next(new Error("El monto pagado no puede exceder el monto total"));
  }

  next();
});

module.exports = mongoose.model("MonthlyFee", monthlyFeeSchema);
