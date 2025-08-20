const Expense = require('../models/Expense.model');

// @desc    Get all expenses
// @route   GET /api/expenses
// @access  Private
exports.getAllExpenses = async (req, res, next) => {
  try {
    const { status, category, startDate, endDate, sort = '-createdAt' } = req.query;
    
    // Build query
    const query = {};
    
    if (status) query.status = status;
    if (category) query.category = category;
    
    if (startDate || endDate) {
      query.date = {};
      if (startDate) query.date.$gte = new Date(startDate);
      if (endDate) query.date.$lte = new Date(endDate);
    }
    
    const expenses = await Expense.find(query)
      .populate('createdBy', 'name email')
      .populate('approvedBy', 'name email')
      .sort(sort);
    
    // Calculate totals
    const totals = {
      total: expenses.reduce((sum, expense) => sum + expense.amount, 0),
      byStatus: {},
      byCategory: {}
    };
    
    expenses.forEach(expense => {
      // By status
      if (!totals.byStatus[expense.status]) {
        totals.byStatus[expense.status] = 0;
      }
      totals.byStatus[expense.status] += expense.amount;
      
      // By category
      if (!totals.byCategory[expense.category]) {
        totals.byCategory[expense.category] = 0;
      }
      totals.byCategory[expense.category] += expense.amount;
    });
    
    // Transform expenses for Flutter compatibility
    const transformedExpenses = expenses.map(expense => ({
      ...expense.toObject(),
      id: expense._id
    }));
    
    res.status(200).json({
      success: true,
      count: expenses.length,
      totals,
      data: transformedExpenses
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Get single expense
// @route   GET /api/expenses/:id
// @access  Private
exports.getExpenseById = async (req, res, next) => {
  try {
    const expense = await Expense.findById(req.params.id)
      .populate('createdBy', 'name email')
      .populate('approvedBy', 'name email')
      .populate('comments.user', 'name');
    
    if (!expense) {
      return res.status(404).json({
        success: false,
        error: 'Gasto no encontrado'
      });
    }
    
    res.status(200).json({
      success: true,
      data: expense
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Create expense
// @route   POST /api/expenses
// @access  Private (Admin only)
exports.createExpense = async (req, res, next) => {
  try {
    // Validate that title is provided
    if (!req.body.title) {
      return res.status(400).json({
        success: false,
        message: 'El título es requerido'
      });
    }

    // Create expense data with correct field names
    const expenseData = {
      ...req.body,
      createdBy: req.user._id
    };
    
    const expense = await Expense.create(expenseData);
    
    // Transform response for Flutter compatibility
    const responseData = {
      ...expense.toObject(),
      id: expense._id
    };
    
    res.status(201).json({
      success: true,
      data: responseData
    });
  } catch (err) {
    // Handle Mongoose validation errors
    if (err.name === 'ValidationError') {
      const errorMessages = Object.values(err.errors).map(error => error.message).join(', ');
      return res.status(400).json({
        success: false,
        message: errorMessages
      });
    }
    next(err);
  }
};

// @desc    Update expense
// @route   PUT /api/expenses/:id
// @access  Private (Admin only)
exports.updateExpense = async (req, res, next) => {
  try {
    // Don't allow updating certain fields
    delete req.body.createdBy;
    delete req.body.approvedBy;
    delete req.body.approvedAt;
    
    const expense = await Expense.findByIdAndUpdate(
      req.params.id,
      req.body,
      {
        new: true,
        runValidators: true
      }
    );
    
    if (!expense) {
      return res.status(404).json({
        success: false,
        error: 'Gasto no encontrado'
      });
    }
    
    res.status(200).json({
      success: true,
      data: expense
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Delete expense
// @route   DELETE /api/expenses/:id
// @access  Private (Admin only)
exports.deleteExpense = async (req, res, next) => {
  try {
    const expense = await Expense.findById(req.params.id);
    
    if (!expense) {
      return res.status(404).json({
        success: false,
        error: 'Gasto no encontrado'
      });
    }
    
    await expense.deleteOne();
    
    res.status(200).json({
      success: true,
      data: {}
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Update expense status
// @route   PUT /api/expenses/:id/status
// @access  Private (Admin only)
exports.updateExpenseStatus = async (req, res, next) => {
  try {
    const { status } = req.body;
    
    if (!['pendiente', 'aprobado', 'rechazado', 'pagado'].includes(status)) {
      return res.status(400).json({
        success: false,
        error: 'Estado inválido'
      });
    }
    
    const updateData = { status };
    
    // If approving or rejecting, record who did it
    if (['aprobado', 'rechazado'].includes(status)) {
      updateData.approvedBy = req.user._id;
      updateData.approvedAt = new Date();
    }
    
    const expense = await Expense.findByIdAndUpdate(
      req.params.id,
      updateData,
      {
        new: true,
        runValidators: true
      }
    ).populate('createdBy', 'name email')
     .populate('approvedBy', 'name email');
    
    if (!expense) {
      return res.status(404).json({
        success: false,
        error: 'Gasto no encontrado'
      });
    }
    
    res.status(200).json({
      success: true,
      data: expense
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Add comment to expense
// @route   POST /api/expenses/:id/comments
// @access  Private
exports.addComment = async (req, res, next) => {
  try {
    const expense = await Expense.findById(req.params.id);
    
    if (!expense) {
      return res.status(404).json({
        success: false,
        error: 'Gasto no encontrado'
      });
    }
    
    expense.comments.push({
      user: req.user._id,
      text: req.body.text
    });
    
    await expense.save();
    
    const updatedExpense = await Expense.findById(expense._id)
      .populate('comments.user', 'name');
    
    res.status(200).json({
      success: true,
      data: updatedExpense.comments
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Get expenses by category
// @route   GET /api/expenses/category/:category
// @access  Private
exports.getExpensesByCategory = async (req, res, next) => {
  try {
    const { category } = req.params;
    const expenses = await Expense.find({ category })
      .populate('createdBy', 'name email')
      .sort('-createdAt');
    
    const total = expenses.reduce((sum, expense) => sum + expense.amount, 0);
    
    res.status(200).json({
      success: true,
      count: expenses.length,
      total,
      data: expenses
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Get expenses by date range
// @route   GET /api/expenses/date-range/:startDate/:endDate
// @access  Private
exports.getExpensesByDateRange = async (req, res, next) => {
  try {
    const { startDate, endDate } = req.params;
    
    const expenses = await Expense.find({
      date: {
        $gte: new Date(startDate),
        $lte: new Date(endDate)
      }
    })
      .populate('createdBy', 'name email')
      .sort('-date');
    
    const total = expenses.reduce((sum, expense) => sum + expense.amount, 0);
    
    res.status(200).json({
      success: true,
      count: expenses.length,
      total,
      data: expenses
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Get expense summary/statistics
// @route   GET /api/expenses/stats/summary
// @access  Private
exports.getExpenseSummary = async (req, res, next) => {
  try {
    const stats = await Expense.aggregate([
      {
        $group: {
          _id: null,
          totalExpenses: { $sum: 1 },
          totalAmount: { $sum: '$amount' },
          avgAmount: { $avg: '$amount' },
          minAmount: { $min: '$amount' },
          maxAmount: { $max: '$amount' }
        }
      }
    ]);
    
    const byCategory = await Expense.aggregate([
      {
        $group: {
          _id: '$category',
          count: { $sum: 1 },
          total: { $sum: '$amount' }
        }
      }
    ]);
    
    const byStatus = await Expense.aggregate([
      {
        $group: {
          _id: '$status',
          count: { $sum: 1 },
          total: { $sum: '$amount' }
        }
      }
    ]);
    
    const byMonth = await Expense.aggregate([
      {
        $group: {
          _id: {
            year: { $year: '$date' },
            month: { $month: '$date' }
          },
          count: { $sum: 1 },
          total: { $sum: '$amount' }
        }
      },
      { $sort: { '_id.year': -1, '_id.month': -1 } },
      { $limit: 12 }
    ]);
    
    res.status(200).json({
      success: true,
      data: {
        general: stats[0] || {
          totalExpenses: 0,
          totalAmount: 0,
          avgAmount: 0,
          minAmount: 0,
          maxAmount: 0
        },
        byCategory,
        byStatus,
        byMonth
      }
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Upload expense receipt/document
// @route   POST /api/expenses/:id/receipt
// @access  Private (Admin only)
exports.uploadReceipt = async (req, res, next) => {
  try {
    // TODO: Implement file upload logic
    res.status(501).json({
      success: false,
      error: 'Funcionalidad de carga de archivos pendiente de implementación'
    });
  } catch (err) {
    next(err);
  }
};
