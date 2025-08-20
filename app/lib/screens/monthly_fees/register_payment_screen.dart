import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../services/monthly_fee_service.dart';
import '../../services/house_service.dart';
import '../../models/monthly_fee_model.dart';
import '../../models/house_model.dart';
import '../../utils/snackbar_utils.dart';

class RegisterPaymentScreen extends StatefulWidget {
  final MonthlyFee monthlyFee;

  const RegisterPaymentScreen({
    Key? key,
    required this.monthlyFee,
  }) : super(key: key);

  @override
  State<RegisterPaymentScreen> createState() => _RegisterPaymentScreenState();
}

class _RegisterPaymentScreenState extends State<RegisterPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _paymentMethodController = TextEditingController();
  final _receiptNumberController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedPaymentMethod = 'Efectivo';
  bool _isLoading = false;

  final List<String> _paymentMethods = [
    'Efectivo',
    'Transferencia',
    'Tarjeta de Débito',
    'Tarjeta de Crédito',
    'Cheque',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-llenar el monto pendiente
    _amountController.text = widget.monthlyFee.remainingAmount.toString();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _paymentMethodController.dispose();
    _receiptNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Registrar Pago - ${widget.monthlyFee.month}'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 20, color: Color(0xFF2196F3)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Resumen de la mensualidad
              _buildMonthlyFeeSummary(currencyFormat),

              const SizedBox(height: 24),

              // Formulario de pago
              _buildPaymentForm(),

              const SizedBox(height: 32),

              // Botón de registro
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'REGISTRAR PAGO',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Resumen de la mensualidad
  Widget _buildMonthlyFeeSummary(NumberFormat currencyFormat) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.house,
                  color: Color(0xFF4CAF50),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mensualidad ${widget.monthlyFee.month}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    Consumer<HouseService>(
                      builder: (context, houseService, child) {
                        final house = houseService.houses.firstWhere(
                          (h) => h.id == widget.monthlyFee.houseId,
                          orElse: () => House(
                            id: widget.monthlyFee.houseId,
                            houseNumber: 'N/A',
                            communityId: '',
                            monthlyFee: 0,
                            createdAt: DateTime.now(),
                          ),
                        );
                        return Text(
                          'Casa ${house.houseNumber}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Información de la mensualidad
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Mensualidad Total',
                  currencyFormat.format(widget.monthlyFee.amount),
                  Icons.account_balance_wallet,
                  const Color(0xFF2196F3),
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Ya Pagado',
                  currencyFormat.format(widget.monthlyFee.amountPaid),
                  Icons.check_circle,
                  const Color(0xFF4CAF50),
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Pendiente',
                  currencyFormat.format(widget.monthlyFee.remainingAmount),
                  Icons.schedule,
                  const Color(0xFFFF9800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Item de resumen
  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Formulario de pago
  Widget _buildPaymentForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detalles del Pago',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),

          const SizedBox(height: 20),

          // Monto del pago
          TextFormField(
            controller: _amountController,
            decoration: InputDecoration(
              labelText: 'Monto del Pago',
              hintText: '0.00',
              prefixIcon: const Icon(Icons.attach_money),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa el monto del pago';
              }
              final amount = double.tryParse(value);
              if (amount == null || amount <= 0) {
                return 'Por favor ingresa un monto válido';
              }
              if (amount > widget.monthlyFee.remainingAmount) {
                return 'El monto no puede ser mayor al pendiente';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Método de pago
          DropdownButtonFormField<String>(
            value: _selectedPaymentMethod,
            decoration: InputDecoration(
              labelText: 'Método de Pago',
              prefixIcon: const Icon(Icons.payment),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: _paymentMethods.map((method) {
              return DropdownMenuItem<String>(
                value: method,
                child: Text(method),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedPaymentMethod = value!;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor selecciona un método de pago';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Número de recibo
          TextFormField(
            controller: _receiptNumberController,
            decoration: InputDecoration(
              labelText: 'Número de Recibo (Opcional)',
              hintText: 'Ej: R-001-2024',
              prefixIcon: const Icon(Icons.receipt),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Notas adicionales
          TextFormField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: 'Notas Adicionales (Opcional)',
              hintText: 'Información adicional sobre el pago...',
              prefixIcon: const Icon(Icons.note),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  // Manejar envío del formulario
  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final monthlyFeeService = Provider.of<MonthlyFeeService>(context, listen: false);

        final paymentAmount = double.parse(_amountController.text);
        final newAmountPaid = widget.monthlyFee.amountPaid + paymentAmount;

        // Determinar el nuevo estado
        MonthlyFeeStatus newStatus;
        if (newAmountPaid >= widget.monthlyFee.amount) {
          newStatus = MonthlyFeeStatus.pagado;
        } else {
          newStatus = MonthlyFeeStatus.parcial;
        }

        // Crear mensualidad actualizada
        final updatedMonthlyFee = widget.monthlyFee.copyWith(
          amountPaid: newAmountPaid,
          status: newStatus,
          paidDate: DateTime.now(),
          paymentMethod: _selectedPaymentMethod,
          receiptNumber: _receiptNumberController.text.isNotEmpty ? _receiptNumberController.text : null,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        );

        // Actualizar en el servicio
        final result = await monthlyFeeService.updateMonthlyFee(
          updatedMonthlyFee.id,
          {
            'amountPaid': updatedMonthlyFee.amountPaid,
            'status': updatedMonthlyFee.status.toString().split('.').last,
            'paidDate': updatedMonthlyFee.paidDate?.toIso8601String(),
            'paymentMethod': updatedMonthlyFee.paymentMethod,
            'receiptNumber': updatedMonthlyFee.receiptNumber,
            'notes': updatedMonthlyFee.notes,
          },
        );

        if (result['success'] && mounted) {
          SnackbarUtils.showSuccessSnackBar(
            context,
            '✅ PAGO REGISTRADO: El pago ha sido registrado exitosamente.',
          );
          Navigator.pop(context, updatedMonthlyFee);
        } else {
          SnackbarUtils.showErrorSnackBar(
            context,
            '❌ ERROR: No se pudo registrar el pago: ${result['message']}',
          );
        }
      } catch (e) {
        SnackbarUtils.showErrorSnackBar(
          context,
          '❌ ERROR: Error inesperado: $e',
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}
