import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/expense_service.dart';
import '../../models/expense_model.dart';
import '../../utils/snackbar_utils.dart';
import 'edit_expense_screen.dart'; // Added import for EditExpenseScreen

class ExpenseDetailScreen extends StatefulWidget {
  final Expense expense;

  const ExpenseDetailScreen({
    super.key,
    required this.expense,
  });

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'es_MX',
    symbol: '\$',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (widget.expense.status) {
      case ExpenseStatus.pendiente:
        statusColor = const Color(0xFFFF9800);
        statusIcon = FontAwesomeIcons.clock;
        statusText = 'PENDIENTE';
        break;
      case ExpenseStatus.aprobado:
        statusColor = const Color(0xFF2196F3);
        statusIcon = FontAwesomeIcons.thumbsUp; // Cambiado de checkCircle a thumbsUp
        statusText = 'APROBADO';
        break;
      case ExpenseStatus.pagado:
        statusColor = const Color(0xFF4CAF50);
        statusIcon = FontAwesomeIcons.checkDouble;
        statusText = 'PAGADO';
        break;
      case ExpenseStatus.rechazado:
        statusColor = const Color(0xFFF44336);
        statusIcon = FontAwesomeIcons.xmark;
        statusText = 'RECHAZADO';
        break;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Detalle del Gasto',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A237E),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const FaIcon(
              FontAwesomeIcons.arrowLeft,
              size: 18,
              color: Color(0xFF64748B),
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (authService.isAdmin)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: PopupMenuButton<String>(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.ellipsisVertical,
                    size: 18,
                    color: Color(0xFF64748B),
                  ),
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditDialog();
                  } else if (value == 'delete') {
                    _showDeleteDialog();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        FaIcon(FontAwesomeIcons.penToSquare, size: 16, color: Colors.blue),
                        SizedBox(width: 12),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        FaIcon(FontAwesomeIcons.trash, size: 16, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Eliminar', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Tarjeta principal del gasto con gradiente
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    statusColor,
                    statusColor.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: FaIcon(
                            statusIcon,
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.expense.title,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  statusText,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Monto Total',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _currencyFormat.format(widget.expense.amount),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailsCard(),
            const SizedBox(height: 16),
            if (authService.isAdmin && widget.expense.status == ExpenseStatus.pendiente) _buildActionButtons(),
            if (authService.isAdmin && widget.expense.status == ExpenseStatus.aprobado) _buildPaymentButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.circleInfo,
                  size: 20,
                  color: Color(0xFF1976D2),
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Información Detallada',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildDetailRow(
            icon: FontAwesomeIcons.folder,
            iconColor: const Color(0xFFFF9800),
            iconBgColor: const Color(0xFFFFF3E0),
            label: 'Categoría',
            value: _getCategoryName(widget.expense.category),
          ),
          const SizedBox(height: 20),
          _buildDetailRow(
            icon: FontAwesomeIcons.calendar,
            iconColor: const Color(0xFF4CAF50),
            iconBgColor: const Color(0xFFE8F5E8),
            label: 'Fecha',
            value: DateFormat('EEEE, dd MMMM yyyy', 'es_ES').format(widget.expense.date),
          ),
          const SizedBox(height: 20),
          _buildDetailRow(
            icon: FontAwesomeIcons.user,
            iconColor: const Color(0xFF9C27B0),
            iconBgColor: const Color(0xFFF3E5F5),
            label: 'Creado por',
            value: 'Administrador', // TODO: Get actual user name
          ),
          const SizedBox(height: 24),
          Container(
            height: 1,
            color: const Color(0xFFE0E0E0),
          ),
          const SizedBox(height: 24),
          _buildDetailRow(
            icon: FontAwesomeIcons.fileLines,
            iconColor: const Color(0xFF607D8B),
            iconBgColor: const Color(0xFFECEFF1),
            label: 'Descripción',
            value: widget.expense.description,
            isDescription: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
    Color? iconBgColor,
    bool isDescription = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconBgColor ?? const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(10),
          ),
          child: FaIcon(
            icon,
            size: 16,
            color: iconColor ?? const Color(0xFF1976D2),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              if (isDescription)
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Color(0xFF2C3E50),
                  ),
                )
              else
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2C3E50),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _getCategoryName(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.mantenimiento:
        return 'Mantenimiento';
      case ExpenseCategory.seguridad:
        return 'Seguridad';
      case ExpenseCategory.limpieza:
        return 'Limpieza';
      case ExpenseCategory.servicios:
        return 'Servicios';
      case ExpenseCategory.mejoras:
        return 'Mejoras';
      case ExpenseCategory.administrativos:
        return 'Administrativos';
      case ExpenseCategory.otros:
        return 'Otros';
    }
  }

  Widget _buildActionButtons() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.clock,
                  size: 20,
                  color: Color(0xFFFF9800),
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Acciones Pendientes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showApproveConfirmation(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                  icon: const FaIcon(FontAwesomeIcons.check, size: 18),
                  label: const Text(
                    'Aprobar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showRejectConfirmation(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF44336),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                  icon: const FaIcon(FontAwesomeIcons.xmark, size: 18),
                  label: const Text(
                    'Rechazar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.creditCard,
                  size: 20,
                  color: Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Acciones',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showPaymentConfirmation(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                  icon: const FaIcon(FontAwesomeIcons.creditCard, size: 18),
                  label: const Text(
                    'Pagado',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showRejectConfirmation(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF44336),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                  icon: const FaIcon(FontAwesomeIcons.xmark, size: 18),
                  label: const Text(
                    'Rechazar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _updateExpenseStatus(ExpenseStatus newStatus) async {
    final expenseService = Provider.of<ExpenseService>(context, listen: false);

    final result = await expenseService.updateExpenseStatus(
      widget.expense.id,
      newStatus,
    );

    if (result['success'] && mounted) {
      String message;

      switch (newStatus) {
        case ExpenseStatus.aprobado:
          message = 'Gasto aprobado exitosamente';
          break;
        case ExpenseStatus.rechazado:
          message = 'Gasto rechazado';
          break;
        case ExpenseStatus.pagado:
          message = 'Gasto marcado como pagado';
          break;
        default:
          message = 'Estado actualizado exitosamente';
      }

      SnackbarUtils.showInfoSnackBar(
        context,
        'ℹ️ INFORMACIÓN: ${result['message'] ?? message}',
      );
      Navigator.pop(context);
    } else if (mounted) {
      SnackbarUtils.showErrorSnackBar(
        context,
        '❌ ERROR: ${result['message'] ?? 'Error al actualizar el gasto'}',
      );
    }
  }

  void _showEditDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditExpenseScreen(expense: widget.expense),
      ),
    ).then((updatedExpense) {
      if (updatedExpense != null && updatedExpense is Expense) {
        // Actualizar la UI con el gasto editado
        setState(() {
          // El gasto se actualizará automáticamente desde el servicio
        });

        // Mostrar mensaje de éxito
        SnackbarUtils.showSuccessSnackBar(
          context,
          '✅ GASTO ACTUALIZADO: Gasto actualizado exitosamente',
        );
      }
    });
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const FaIcon(
                FontAwesomeIcons.trash,
                size: 20,
                color: Color(0xFFF44336),
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              'Eliminar Gasto',
              style: TextStyle(
                color: Color(0xFF1A237E),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro de que quieres eliminar este gasto?\n\n'
          'Gasto: ${widget.expense.title}\n'
          'Monto: ${_currencyFormat.format(widget.expense.amount)}\n\n'
          'Esta acción no se puede deshacer.',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteExpense();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF44336),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _deleteExpense() async {
    final expenseService = Provider.of<ExpenseService>(context, listen: false);

    final result = await expenseService.deleteExpense(widget.expense.id);

    if (result['success'] && mounted) {
      SnackbarUtils.showSuccessSnackBar(
        context,
        '✅ GASTO ELIMINADO: ${result['message'] ?? 'Gasto eliminado exitosamente'}',
      );
      Navigator.pop(context);
    } else if (mounted) {
      SnackbarUtils.showErrorSnackBar(
        context,
        '❌ ERROR: ${result['message'] ?? 'Error al eliminar el gasto'}',
      );
    }
  }

  void _showPaymentConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const FaIcon(
                FontAwesomeIcons.creditCard,
                size: 20,
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              'Confirmar Pago',
              style: TextStyle(
                color: Color(0xFF1A237E),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro de que quieres marcar este gasto como pagado?\n\n'
          'Gasto: ${widget.expense.title}\n'
          'Monto: ${_currencyFormat.format(widget.expense.amount)}',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateExpenseStatus(ExpenseStatus.pagado);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _showRejectConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const FaIcon(
                FontAwesomeIcons.xmark,
                size: 20,
                color: Color(0xFFF44336),
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              'Confirmar Rechazo',
              style: TextStyle(
                color: Color(0xFF1A237E),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro de que quieres rechazar este gasto?\n\n'
          'Gasto: ${widget.expense.title}\n'
          'Monto: ${_currencyFormat.format(widget.expense.amount)}\n\n'
          'Esta acción no se puede deshacer.',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateExpenseStatus(ExpenseStatus.rechazado);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF44336),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _showApproveConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const FaIcon(
                FontAwesomeIcons.check,
                size: 20,
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              'Confirmar Aprobar',
              style: TextStyle(
                color: Color(0xFF1A237E),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro de que quieres aprobar este gasto?\n\n'
          'Gasto: ${widget.expense.title}\n'
          'Monto: ${_currencyFormat.format(widget.expense.amount)}\n\n'
          'Esta acción no se puede deshacer.',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateExpenseStatus(ExpenseStatus.aprobado);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}
