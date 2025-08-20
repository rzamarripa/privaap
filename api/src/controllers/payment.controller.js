const Payment = require('../models/Payment.model');
const MonthlyFee = require('../models/MonthlyFee.model');
const mongoose = require('mongoose');

// Crear un nuevo pago
const createPayment = async (req, res) => {
  try {
    const { monthlyFeeId, amount, paymentMethod, receiptNumber, notes, paidDate } = req.body;
    const userId = req.user.id;

    // Validar que la mensualidad existe
    const monthlyFee = await MonthlyFee.findById(monthlyFeeId);
    if (!monthlyFee) {
      return res.status(404).json({ message: 'Mensualidad no encontrada' });
    }

    // Calcular total ya pagado
    const totalPaidResult = await Payment.calculateTotalPaid(monthlyFeeId);
    const currentTotalPaid = totalPaidResult[0]?.totalPaid || 0;
    
    // Validar que el nuevo pago no exceda el monto total
    const remainingAmount = monthlyFee.amount - currentTotalPaid;
    if (amount > remainingAmount) {
      return res.status(400).json({ 
        message: `El monto excede lo pendiente. Restante: $${remainingAmount}` 
      });
    }

    // Crear el pago
    const payment = new Payment({
      monthlyFeeId,
      amount,
      paymentMethod,
      receiptNumber,
      notes,
      paidDate: paidDate || new Date(),
      createdBy: userId
    });

    await payment.save();

    // Actualizar la mensualidad
    const newTotalPaid = currentTotalPaid + amount;
    const newStatus = newTotalPaid >= monthlyFee.amount ? 'pagado' : 'abonado';
    
    await MonthlyFee.findByIdAndUpdate(monthlyFeeId, {
      amountPaid: newTotalPaid,
      status: newStatus,
      ...(newStatus === 'pagado' && { paidDate: payment.paidDate })
    });

    // Poblate el pago con información del creador
    await payment.populate('createdBy', 'name email');

    res.status(201).json({
      message: 'Pago registrado correctamente',
      data: payment
    });
  } catch (error) {
    console.error('Error creating payment:', error);
    res.status(500).json({ message: 'Error interno del servidor' });
  }
};

// Obtener pagos de una mensualidad
const getPaymentsByMonthlyFee = async (req, res) => {
  try {
    const { monthlyFeeId } = req.params;

    // Validar que la mensualidad existe
    const monthlyFee = await MonthlyFee.findById(monthlyFeeId);
    if (!monthlyFee) {
      return res.status(404).json({ message: 'Mensualidad no encontrada' });
    }

    const payments = await Payment.find({ monthlyFeeId })
      .populate('createdBy', 'name email')
      .populate('cancelledBy', 'name email')
      .sort({ paidDate: -1 });

    res.json({
      message: 'Pagos obtenidos correctamente',
      data: payments
    });
  } catch (error) {
    console.error('Error getting payments:', error);
    res.status(500).json({ message: 'Error interno del servidor' });
  }
};

// Obtener un pago específico
const getPayment = async (req, res) => {
  try {
    const { paymentId } = req.params;

    const payment = await Payment.findById(paymentId)
      .populate('createdBy', 'name email')
      .populate('cancelledBy', 'name email')
      .populate('monthlyFeeId');

    if (!payment) {
      return res.status(404).json({ message: 'Pago no encontrado' });
    }

    res.json({
      message: 'Pago obtenido correctamente',
      data: payment
    });
  } catch (error) {
    console.error('Error getting payment:', error);
    res.status(500).json({ message: 'Error interno del servidor' });
  }
};

// Cancelar un pago
const cancelPayment = async (req, res) => {
  try {
    const { paymentId } = req.params;
    const { reason } = req.body;
    const userId = req.user.id;

    const payment = await Payment.findById(paymentId);
    if (!payment) {
      return res.status(404).json({ message: 'Pago no encontrado' });
    }

    if (payment.isCancelled) {
      return res.status(400).json({ message: 'El pago ya está cancelado' });
    }

    // Cancelar el pago
    await payment.cancel(userId, reason);

    // Recalcular totales de la mensualidad
    const monthlyFeeId = payment.monthlyFeeId;
    const totalPaidResult = await Payment.calculateTotalPaid(monthlyFeeId);
    const newTotalPaid = totalPaidResult[0]?.totalPaid || 0;
    
    // Obtener la mensualidad
    const monthlyFee = await MonthlyFee.findById(monthlyFeeId);
    const newStatus = newTotalPaid === 0 ? 'pendiente' : 
                     newTotalPaid >= monthlyFee.amount ? 'pagado' : 'abonado';
    
    await MonthlyFee.findByIdAndUpdate(monthlyFeeId, {
      amountPaid: newTotalPaid,
      status: newStatus,
      ...(newStatus !== 'pagado' && { paidDate: null })
    });

    // Populate el pago actualizado
    await payment.populate('createdBy', 'name email');
    await payment.populate('cancelledBy', 'name email');

    res.json({
      message: 'Pago cancelado correctamente',
      data: payment
    });
  } catch (error) {
    console.error('Error canceling payment:', error);
    res.status(500).json({ message: 'Error interno del servidor' });
  }
};

// Obtener resumen de pagos de una mensualidad
const getPaymentSummary = async (req, res) => {
  try {
    const { monthlyFeeId } = req.params;

    // Validar que la mensualidad existe
    const monthlyFee = await MonthlyFee.findById(monthlyFeeId);
    if (!monthlyFee) {
      return res.status(404).json({ message: 'Mensualidad no encontrada' });
    }

    // Obtener estadísticas
    const stats = await Payment.aggregate([
      {
        $match: { 
          monthlyFeeId: new mongoose.Types.ObjectId(monthlyFeeId)
        }
      },
      {
        $group: {
          _id: '$isCancelled',
          totalAmount: { $sum: '$amount' },
          paymentCount: { $sum: 1 }
        }
      }
    ]);

    const activePayments = stats.find(s => s._id === false) || { totalAmount: 0, paymentCount: 0 };
    const cancelledPayments = stats.find(s => s._id === true) || { totalAmount: 0, paymentCount: 0 };

    const summary = {
      monthlyFeeAmount: monthlyFee.amount,
      totalPaid: activePayments.totalAmount,
      totalCancelled: cancelledPayments.totalAmount,
      remainingAmount: monthlyFee.amount - activePayments.totalAmount,
      activePaymentCount: activePayments.paymentCount,
      cancelledPaymentCount: cancelledPayments.paymentCount,
      status: monthlyFee.status
    };

    res.json({
      message: 'Resumen obtenido correctamente',
      data: summary
    });
  } catch (error) {
    console.error('Error getting payment summary:', error);
    res.status(500).json({ message: 'Error interno del servidor' });
  }
};

module.exports = {
  createPayment,
  getPaymentsByMonthlyFee,
  getPayment,
  cancelPayment,
  getPaymentSummary
};