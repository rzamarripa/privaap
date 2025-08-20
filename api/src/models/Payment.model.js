const mongoose = require('mongoose');

const paymentSchema = new mongoose.Schema({
  monthlyFeeId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'MonthlyFee',
    required: true
  },
  amount: {
    type: Number,
    required: true,
    min: 0
  },
  paidDate: {
    type: Date,
    required: true
  },
  paymentMethod: {
    type: String,
    required: true,
    enum: ['efectivo', 'transferencia', 'cheque', 'tarjeta', 'otro'],
    default: 'efectivo'
  },
  receiptNumber: {
    type: String,
    trim: true
  },
  notes: {
    type: String,
    trim: true
  },
  isCancelled: {
    type: Boolean,
    default: false
  },
  cancelledAt: {
    type: Date
  },
  cancelledBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  cancellationReason: {
    type: String,
    trim: true
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  }
}, {
  timestamps: true
});

// Índices para búsquedas frecuentes
paymentSchema.index({ monthlyFeeId: 1 });
paymentSchema.index({ paidDate: -1 });
paymentSchema.index({ isCancelled: 1 });

// Virtual para obtener el estado del pago
paymentSchema.virtual('status').get(function() {
  return this.isCancelled ? 'cancelado' : 'activo';
});

// Método estático para obtener pagos activos de una mensualidad
paymentSchema.statics.getActivePayments = function(monthlyFeeId) {
  return this.find({ 
    monthlyFeeId, 
    isCancelled: false 
  }).sort({ paidDate: -1 });
};

// Método estático para calcular total pagado de una mensualidad
paymentSchema.statics.calculateTotalPaid = function(monthlyFeeId) {
  return this.aggregate([
    {
      $match: { 
        monthlyFeeId: new mongoose.Types.ObjectId(monthlyFeeId),
        isCancelled: false 
      }
    },
    {
      $group: {
        _id: null,
        totalPaid: { $sum: '$amount' },
        paymentCount: { $sum: 1 }
      }
    }
  ]);
};

// Método para cancelar un pago
paymentSchema.methods.cancel = function(userId, reason) {
  this.isCancelled = true;
  this.cancelledAt = new Date();
  this.cancelledBy = userId;
  this.cancellationReason = reason;
  return this.save();
};

// Middleware pre-save para validaciones
paymentSchema.pre('save', function(next) {
  // Si se está cancelando, asegurar que los campos están completos
  if (this.isCancelled && !this.cancelledAt) {
    this.cancelledAt = new Date();
  }
  
  // Validar que un pago cancelado no se puede reactivar
  if (this.isModified('isCancelled') && this.isCancelled === false && this.cancelledAt) {
    return next(new Error('No se puede reactivar un pago cancelado'));
  }
  
  next();
});

module.exports = mongoose.model('Payment', paymentSchema);