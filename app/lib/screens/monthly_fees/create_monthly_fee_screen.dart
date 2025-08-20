import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/monthly_fee_service.dart';
import '../../services/auth_service.dart';
import '../../services/house_service.dart';
import '../../services/user_service.dart';
import '../../models/monthly_fee_model.dart';
import '../../models/house_model.dart';
import '../../models/user_model.dart';
import '../../utils/snackbar_utils.dart';

class CreateMonthlyFeeScreen extends StatefulWidget {
  const CreateMonthlyFeeScreen({super.key});

  @override
  State<CreateMonthlyFeeScreen> createState() => _CreateMonthlyFeeScreenState();
}

class _CreateMonthlyFeeScreenState extends State<CreateMonthlyFeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _monthlyFeeService = MonthlyFeeService();

  // Controllers
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  // Variables de estado
  String? _selectedHouseId;
  String _selectedStatus = 'pendiente';
  String _selectedPaymentMethod = 'efectivo';
  String _selectedMonth = ''; // Mes seleccionado en formato YYYY-MM
  bool _isLoading = false;

  // Listas de datos
  List<House> _houseList = [];

  House? _getSelectedHouse() {
    if (_selectedHouseId == null) return null;
    try {
      return _houseList.firstWhere((h) => h.id == _selectedHouseId);
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    // Inicializar mes actual
    final now = DateTime.now();
    _selectedMonth = "${now.year}-${now.month.toString().padLeft(2, '0')}";

    // Usar addPostFrameCallback para evitar llamadas durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Obtener el usuario actual y su comunidad
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;

      if (user == null) {
        SnackbarUtils.showErrorSnackBar(context, 'Usuario no autenticado');
        return;
      }

      // Si es super admin, mostrar selector de comunidad
      if (user.isSuperAdmin) {
        // TODO: Implementar selector de comunidad para super admin
        SnackbarUtils.showErrorSnackBar(context, 'Funcionalidad para super admin próximamente');
        return;
      }

      // Si es administrador de comunidad, usar su comunidad
      if (user.role == UserRole.administrador && user.communityId != null) {
        _selectedHouseId = user.communityId;

        // Cargar información de la comunidad
        final houseService = Provider.of<HouseService>(context, listen: false);
        await houseService.loadHousesByCommunity(user.communityId!);
        _houseList = houseService.getHousesByCommunity(user.communityId!).where((house) => house.isActive).toList();

        // Fallback: si no hay casas activas, intentar derivarlas de usuarios activos con número de casa
        if (_houseList.isEmpty) {
          final userService = Provider.of<UserService>(context, listen: false);
          await userService.loadUsers();
          final activeUsersInCommunity = userService
              .getUsersByCommunity(user.communityId!)
              .where((u) => u.isActive && (u.house != null && u.house!.trim().isNotEmpty))
              .toList();

          if (activeUsersInCommunity.isNotEmpty) {
            // Construir una lista temporal de casas a partir de usuarios
            final Map<String, House> tempHouses = {};
            for (final u in activeUsersInCommunity) {
              final houseNumber = u.house!.trim();
              // Evitar duplicados por número de casa
              if (!tempHouses.containsKey(houseNumber)) {
                tempHouses[houseNumber] = House(
                  id: 'temp-$houseNumber',
                  communityId: user.communityId!,
                  houseNumber: houseNumber,
                  description: null,
                  monthlyFee: 0,
                  currentUserId: u.id,
                  currentUserName: u.name,
                  isActive: true,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
              }
            }
            _houseList = tempHouses.values.toList();
          }
        }

        // Ordenar casas alfabéticamente por número de casa
        _houseList.sort((a, b) => a.houseNumber.compareTo(b.houseNumber));

        if (_houseList.isNotEmpty) {
          _selectedHouseId = _houseList.first.id;
        }

        print('Casas cargadas: ${_houseList.length}');
      } else {
        SnackbarUtils.showErrorSnackBar(context, 'No tienes permisos para crear mensualidades');
        return;
      }
    } catch (e) {
      print('Error loading initial data: $e');
      SnackbarUtils.showErrorSnackBar(context, 'Error al cargar datos iniciales: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedHouseId == null) {
      SnackbarUtils.showErrorSnackBar(context, 'Por favor selecciona una casa');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;

      if (user == null) {
        SnackbarUtils.showErrorSnackBar(context, 'Usuario no autenticado');
        return;
      }

      final monthlyFee = MonthlyFee(
        id: '', // Se generará en el backend
        communityId: user.communityId!,
        houseId: _selectedHouseId!,
        month: _selectedMonth,
        amount: double.parse(_amountController.text),
        amountPaid: 0,
        status: MonthlyFeeStatus.pendiente,
        dueDate: DateTime.now(), // Fecha de vencimiento por defecto
        paidDate: null,
        paymentMethod: null,
        receiptNumber: null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = await _monthlyFeeService.createMonthlyFee(monthlyFee);

      if (result['success']) {
        SnackbarUtils.showSuccessSnackBar(context, 'Mensualidad creada exitosamente');
        Navigator.pop(context, true); // Retorna true para indicar éxito
      } else {
        SnackbarUtils.showErrorSnackBar(context, result['message'] ?? 'Error al crear la mensualidad');
      }
    } catch (e) {
      SnackbarUtils.showErrorSnackBar(context, 'Error inesperado: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Mensualidad'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionTitle('Información General'),
                    const SizedBox(height: 16),

                    // Casa
                    if (_houseList.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          border: Border.all(color: Colors.orange.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No hay casas activas en esta comunidad. Debes tener casas registradas para crear mensualidades.',
                                style: TextStyle(color: Colors.orange.shade700),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      _buildDropdownField(
                        label: 'Casa *',
                        value: _selectedHouseId,
                        items: _houseList.map((house) {
                          return DropdownMenuItem<String>(
                            value: house.id,
                            child: Text(house.displayName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedHouseId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) return 'Selecciona una casa';
                          return null;
                        },
                      ),

                    const SizedBox(height: 16),

                    // Información de la casa seleccionada
                    if (_selectedHouseId != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          border: Border.all(color: Colors.blue.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Información de la Casa',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Monto fijo: \$${_getSelectedHouse()?.monthlyFee.toStringAsFixed(2) ?? '0.00'}'),
                            if (_getSelectedHouse()?.hasCurrentUser == true)
                              Text('Inquilino actual: ${_getSelectedHouse()?.currentUserName}'),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Monto
                    _buildTextField(
                      controller: _amountController,
                      label: 'Monto *',
                      hint: _getSelectedHouse()?.monthlyFee.toStringAsFixed(2) ?? '0.00',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa el monto';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Ingresa un monto válido';
                        }
                        if (double.parse(value) <= 0) {
                          return 'El monto debe ser mayor a 0';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Mes
                    _buildDropdownField(
                      label: 'Mes *',
                      value: _selectedMonth,
                      items: _getMonthOptions(),
                      onChanged: (value) {
                        setState(() {
                          _selectedMonth = value!;
                        });
                      },
                      validator: (value) {
                        if (value == null) return 'Selecciona un mes';
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    _buildSectionTitle('Configuración Adicional'),
                    const SizedBox(height: 16),

                    // Estado
                    _buildDropdownField(
                      label: 'Estado',
                      value: _selectedStatus,
                      items: [
                        DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                        DropdownMenuItem(value: 'pagado', child: Text('Pagado')),
                        DropdownMenuItem(value: 'vencido', child: Text('Vencido')),
                        DropdownMenuItem(value: 'parcial', child: Text('Parcial')),
                        DropdownMenuItem(value: 'exento', child: Text('Exento')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value!;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Método de pago
                    _buildDropdownField(
                      label: 'Método de Pago',
                      value: _selectedPaymentMethod,
                      items: [
                        DropdownMenuItem(value: 'efectivo', child: Text('Efectivo')),
                        DropdownMenuItem(value: 'transferencia', child: Text('Transferencia')),
                        DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                        DropdownMenuItem(value: 'tarjeta', child: Text('Tarjeta')),
                        DropdownMenuItem(value: 'otro', child: Text('Otro')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedPaymentMethod = value!;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Notas
                    _buildTextField(
                      controller: _notesController,
                      label: 'Notas',
                      hint: 'Notas adicionales (opcional)',
                      maxLines: 3,
                      maxLength: 500,
                    ),

                    const SizedBox(height: 32),

                    // Botón de envío
                    ElevatedButton(
                      onPressed: (_isLoading || _houseList.isEmpty) ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              _houseList.isEmpty ? 'No hay casas disponibles' : 'Crear Mensualidad',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2196F3),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? prefix,
    Widget? suffix,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefix != null
            ? IconTheme(
                data: const IconThemeData(color: Color(0xFF2196F3)),
                child: prefix,
              )
            : null,
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
        ),
      ),
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      maxLength: maxLength,
      validator: validator,
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    ValueChanged<String?>? onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
        ),
      ),
      items: items,
      onChanged: onChanged,
      validator: validator,
      dropdownColor: Colors.white,
      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2196F3)),
    );
  }

  List<DropdownMenuItem<String>> _getMonthOptions() {
    final List<DropdownMenuItem<String>> options = [];
    final currentYear = DateTime.now().year;

    // Años: anterior, actual y siguiente
    for (int year = currentYear - 1; year <= currentYear + 1; year++) {
      for (int month = 1; month <= 12; month++) {
        final monthDate = DateTime(year, month, 1);
        options.add(
          DropdownMenuItem(
            value: '${monthDate.year}-${monthDate.month.toString().padLeft(2, '0')}',
            child: Text('${monthDate.month.toString().padLeft(2, '0')} - ${monthDate.year}'),
          ),
        );
      }
    }
    return options;
  }
}
