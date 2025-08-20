import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../services/monthly_fee_service.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/community_service.dart';
import '../../services/house_service.dart';
import '../../models/monthly_fee_model.dart';
import '../../models/payment_model.dart';
import '../../models/house_model.dart';
import '../../models/user_model.dart';
import 'register_payment_screen.dart';

class MonthlyFeesScreen extends StatefulWidget {
  const MonthlyFeesScreen({Key? key}) : super(key: key);

  @override
  State<MonthlyFeesScreen> createState() => _MonthlyFeesScreenState();
}

class _MonthlyFeesScreenState extends State<MonthlyFeesScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'es_MX',
    symbol: '\$',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Cargar datos inmediatamente sin esperar al frame callback
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final monthlyFeeService = Provider.of<MonthlyFeeService>(context, listen: false);
    final communityService = Provider.of<CommunityService>(context, listen: false);
    final houseService = Provider.of<HouseService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    // Cargar datos secuencialmente para evitar problemas de concurrencia
    await monthlyFeeService.refresh();
    await communityService.loadCommunities();

    final user = authService.currentUser;
    print('🔍 DEBUG initState: Usuario actual: ${user?.name}, CommunityId: ${user?.communityId}');
    print('🔍 DEBUG initState: isSuperAdmin: ${user?.isSuperAdmin}');
    print('🔍 DEBUG initState: isAdmin: ${user?.isAdmin}');
    print('🔍 DEBUG initState: house: ${user?.house}');
    print('🔍 DEBUG initState: Usuario completo: ${user?.toJson()}');

    // Forzar actualización del usuario desde la API
    print('🔄 DEBUG initState: Forzando actualización del usuario...');
    await authService.refreshCurrentUser();
    final updatedUser = authService.currentUser;
    print('🔍 DEBUG initState: Usuario ACTUALIZADO: ${updatedUser?.name}, CommunityId: ${updatedUser?.communityId}');
    print('🔍 DEBUG initState: Usuario ACTUALIZADO completo: ${updatedUser?.toJson()}');

    // Cargar casas según el tipo de usuario ACTUALIZADO
    if (updatedUser?.isSuperAdmin == true) {
      // Super admin: cargar todas las casas
      print('🔄 DEBUG: Cargando todas las casas para super admin');
      await houseService.loadHouses();
    } else if (updatedUser?.communityId != null) {
      // Admin de comunidad: cargar solo casas de su comunidad
      print('🔄 DEBUG: Cargando casas de la comunidad: ${updatedUser!.communityId}');
      await houseService.loadHousesByCommunity(updatedUser.communityId!);
    } else if (updatedUser?.isAdmin == true) {
      // Admin sin communityId: cargar todas las casas como fallback
      print('🔄 DEBUG: Admin sin communityId, cargando todas las casas como fallback');
      await houseService.loadHouses();
    } else {
      print('❌ DEBUG: Usuario no es admin ni tiene communityId');
    }

    print('🔍 DEBUG initState: Comunidades cargadas: ${communityService.communities.length}');
    print('🔍 DEBUG initState: Casas cargadas: ${houseService.houses.length}');

    // Forzar actualización de la UI una vez cargados los datos
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final monthlyFeeService = Provider.of<MonthlyFeeService>(context);
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Mensualidades'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await monthlyFeeService.refresh();
              final houseService = Provider.of<HouseService>(context, listen: false);
              final authService = Provider.of<AuthService>(context, listen: false);
              final user = authService.currentUser;

              // Recargar casas según el tipo de usuario
              if (user?.isSuperAdmin == true) {
                await houseService.loadHouses();
              } else if (user?.communityId != null) {
                await houseService.loadHousesByCommunity(user!.communityId!);
              } else if (user?.isAdmin == true) {
                // Admin sin communityId: cargar todas las casas como fallback
                await houseService.loadHouses();
              }
              setState(() {});
            },
            tooltip: 'Actualizar',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2196F3),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF2196F3),
          tabs: const [
            Tab(text: 'Pendientes'),
            Tab(text: 'Pagadas'),
            Tab(text: 'Vencidas'),
            Tab(text: 'Resumen'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filtros de mes y año
          _buildMonthYearFilter(),

          // Contenido de los tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPendingFeesTab(monthlyFeeService, user),
                _buildPaidFeesTab(monthlyFeeService, user),
                _buildOverdueFeesTab(monthlyFeeService, user),
                _buildSummaryTab(monthlyFeeService, user),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Filtros de mes y año
  Widget _buildMonthYearFilter() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtrar por Período',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Selector de mes
              Expanded(
                child: _buildMonthDropdown(),
              ),
              const SizedBox(width: 8),
              // Selector de año
              Expanded(
                child: _buildYearDropdown(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Selector de mes
  Widget _buildMonthDropdown() {
    final months = [
      {'name': 'Ene', 'value': 1},
      {'name': 'Feb', 'value': 2},
      {'name': 'Mar', 'value': 3},
      {'name': 'Abr', 'value': 4},
      {'name': 'May', 'value': 5},
      {'name': 'Jun', 'value': 6},
      {'name': 'Jul', 'value': 7},
      {'name': 'Ago', 'value': 8},
      {'name': 'Sep', 'value': 9},
      {'name': 'Oct', 'value': 10},
      {'name': 'Nov', 'value': 11},
      {'name': 'Dic', 'value': 12},
    ];

    return DropdownButtonFormField<int>(
      value: _selectedDate.month,
      decoration: InputDecoration(
        labelText: 'Mes',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.calendar_month, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: months.map((month) {
        return DropdownMenuItem<int>(
          value: month['value'] as int,
          child: Text(
            month['name'] as String,
            style: const TextStyle(fontSize: 14),
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedDate = DateTime(_selectedDate.year, value);
          });
        }
      },
    );
  }

  // Selector de año
  Widget _buildYearDropdown() {
    final currentYear = DateTime.now().year;
    final years = List.generate(5, (index) => currentYear - 2 + index);

    return DropdownButtonFormField<int>(
      value: _selectedDate.year,
      decoration: InputDecoration(
        labelText: 'Año',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.calendar_today, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: years.map((year) {
        return DropdownMenuItem<int>(
          value: year,
          child: Text(
            year.toString(),
            style: const TextStyle(fontSize: 14),
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedDate = DateTime(value, _selectedDate.month);
          });
        }
      },
    );
  }

  // Obtener nombre del mes en español
  String _getMonthName(int month) {
    final months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    return months[month - 1];
  }

  // Vista cuando no hay mensualidades - mostrar casas disponibles
  Widget _buildNoMonthlyFeesView(MonthlyFeeService monthlyFeeService, User? user) {
    // Obtener casas reales de la base de datos
    final houseService = Provider.of<HouseService>(context, listen: false);
    final userCommunityId = user?.communityId;
    List<House> housesToShow = [];

    print('🔍 DEBUG: Total casas en el servicio: ${houseService.houses.length}');
    print('🔍 DEBUG: userCommunityId = $userCommunityId');
    print('🔍 DEBUG: user?.isSuperAdmin = ${user?.isSuperAdmin}');

    if (userCommunityId != null) {
      // Si el usuario tiene comunidad, obtener casas reales de esa comunidad
      housesToShow = houseService.getHousesByCommunity(userCommunityId);
      print('🔍 DEBUG: Casas de la comunidad $userCommunityId: ${housesToShow.length}');

      // Mostrar información de debug para cada casa
      for (var house in housesToShow) {
        print('🏠 DEBUG: Casa ${house.houseNumber} - ID: ${house.id}, CommunityId: ${house.communityId}');
      }
    } else if (user?.isSuperAdmin == true) {
      // Si es super admin, mostrar todas las casas
      housesToShow = houseService.houses;
      print('🔍 DEBUG: Super admin - casas totales: ${housesToShow.length}');
    }

    print('🔍 DEBUG: housesToShow final: ${housesToShow.length}');

    if (housesToShow.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.home_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay casas disponibles',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            if (userCommunityId != null)
              const Text(
                'No hay casas registradas en tu comunidad',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              )
            else
              const Text(
                'No hay casas registradas en el sistema',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await monthlyFeeService.refresh();
        // Recargar casas reales de la base de datos
        final houseService = Provider.of<HouseService>(context, listen: false);
        final authService = Provider.of<AuthService>(context, listen: false);
        final currentUser = authService.currentUser;

        // Recargar casas según el tipo de usuario
        if (currentUser?.isSuperAdmin == true) {
          await houseService.loadHouses();
        } else if (currentUser?.communityId != null) {
          await houseService.loadHousesByCommunity(currentUser!.communityId!);
        } else if (currentUser?.isAdmin == true) {
          // Admin sin communityId: cargar todas las casas como fallback
          await houseService.loadHouses();
        }
        setState(() {});
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lista de casas disponibles
            Text(
              'Casas Disponibles (${housesToShow.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
            ),

            const SizedBox(height: 16),

            ...housesToShow.map((house) => _buildHouseCard(house, user)),
          ],
        ),
      ),
    );
  }

  // Verificar si existe una mensualidad para esta casa en el mes seleccionado
  MonthlyFee? _getExistingMonthlyFee(House house) {
    final monthlyFeeService = Provider.of<MonthlyFeeService>(context, listen: false);
    final selectedMonth = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}';

    print('🔍 DEBUG _getExistingMonthlyFee: Buscando mensualidad');
    print('🔍 DEBUG _getExistingMonthlyFee: selectedMonth = $selectedMonth');
    print('🔍 DEBUG _getExistingMonthlyFee: house.id = ${house.id}');
    print('🔍 DEBUG _getExistingMonthlyFee: Total mensualidades cargadas: ${monthlyFeeService.monthlyFees.length}');

    // Mostrar todas las mensualidades para debug
    for (var fee in monthlyFeeService.monthlyFees) {
      print('🔍 DEBUG Fee: month=${fee.month}, houseId=${fee.houseId}, status=${fee.status}');
    }

    try {
      // Buscar por mes seleccionado y houseId real de la casa
      final result = monthlyFeeService.monthlyFees.firstWhere(
        (fee) => fee.month == selectedMonth && fee.houseId == house.id,
      );
      print('🔍 DEBUG _getExistingMonthlyFee: Mensualidad encontrada: ${result.status}');
      return result;
    } catch (e) {
      print('🔍 DEBUG _getExistingMonthlyFee: No encontrada, error: $e');
      return null;
    }
  }

  // Widget para mostrar información de mensualidad existente
  Widget _buildExistingFeeInfo(MonthlyFee existingFee) {
    final Color statusColor = _getStatusColor(existingFee.status);
    final IconData statusIcon = _getStatusIcon(existingFee.status);
    final String statusText = _getStatusText(existingFee.status);

    // Calcular montos
    final double remainingAmount = existingFee.amount - existingFee.amountPaid;
    final double progressPercent = existingFee.amount > 0 ? existingFee.amountPaid / existingFee.amount : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withValues(alpha: 0.1),
            statusColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con estado
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    if (existingFee.status == MonthlyFeeStatus.abonado)
                      Text(
                        'Progreso: ${(progressPercent * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 11,
                          color: statusColor.withValues(alpha: 0.8),
                        ),
                      ),
                  ],
                ),
              ),
              if (existingFee.status == MonthlyFeeStatus.abonado)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        statusColor.withValues(alpha: 0.3),
                        statusColor.withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(progressPercent * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Información de montos mejorada
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MONTO TOTAL',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _currencyFormat.format(existingFee.amount),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'PAGADO',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green.shade600,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _currencyFormat.format(existingFee.amountPaid),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (remainingAmount > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          color: Colors.orange.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SALDO PENDIENTE',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              _currencyFormat.format(remainingAmount),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Barra de progreso mejorada para pagos parciales
          if (existingFee.status == MonthlyFeeStatus.abonado) ...[
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progreso del pago',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${_currencyFormat.format(existingFee.amountPaid)} de ${_currencyFormat.format(existingFee.amount)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.grey.shade200,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progressPercent,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      minHeight: 8,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Botones de acción
          if (existingFee.status != MonthlyFeeStatus.pagado) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showPaymentDialog(existingFee),
                    icon: const Icon(Icons.payment, size: 16),
                    label: Text(
                      existingFee.status == MonthlyFeeStatus.abonado ? 'Abonar Más' : 'Registrar Pago',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showPaymentHistory(existingFee),
                  icon: const Icon(Icons.history, size: 16),
                  label: const Text('Historial'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showPaymentHistory(existingFee),
                icon: const Icon(Icons.receipt, size: 16),
                label: const Text('Ver Historial de Pagos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Métodos auxiliares para obtener colores, iconos y textos según el estado
  Color _getStatusColor(MonthlyFeeStatus status) {
    switch (status) {
      case MonthlyFeeStatus.pendiente:
        return Colors.orange;
      case MonthlyFeeStatus.abonado:
        return Colors.blue;
      case MonthlyFeeStatus.pagado:
        return Colors.green;
      case MonthlyFeeStatus.vencido:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(MonthlyFeeStatus status) {
    switch (status) {
      case MonthlyFeeStatus.pendiente:
        return Icons.pending_actions;
      case MonthlyFeeStatus.abonado:
        return Icons.trending_up;
      case MonthlyFeeStatus.pagado:
        return Icons.check_circle;
      case MonthlyFeeStatus.vencido:
        return Icons.warning;
      default:
        return Icons.info;
    }
  }

  String _getStatusText(MonthlyFeeStatus status) {
    switch (status) {
      case MonthlyFeeStatus.pendiente:
        return 'Mensualidad Pendiente';
      case MonthlyFeeStatus.abonado:
        return 'Mensualidad Abonada';
      case MonthlyFeeStatus.pagado:
        return 'Mensualidad Pagada';
      case MonthlyFeeStatus.vencido:
        return 'Mensualidad Vencida';
      default:
        return 'Estado Desconocido';
    }
  }

  String _getStatusBadgeText(MonthlyFeeStatus status) {
    switch (status) {
      case MonthlyFeeStatus.pendiente:
        return 'PENDIENTE';
      case MonthlyFeeStatus.abonado:
        return 'ABONADO';
      case MonthlyFeeStatus.pagado:
        return 'PAGADO';
      case MonthlyFeeStatus.vencido:
        return 'VENCIDO';
      default:
        return 'ESTADO';
    }
  }

  // Mostrar diálogo para registrar un pago
  void _showPaymentDialog(MonthlyFee existingFee) {
    // Obtener el número de casa
    final houseService = Provider.of<HouseService>(context, listen: false);
    final house = houseService.houses.firstWhere(
      (h) => h.id == existingFee.houseId,
      orElse: () => House(
        id: existingFee.houseId,
        houseNumber: 'N/A',
        communityId: '',
        monthlyFee: 0,
        createdAt: DateTime.now(),
      ),
    );

    final TextEditingController amountController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    final TextEditingController receiptController = TextEditingController();
    String selectedPaymentMethod = 'efectivo';
    final double remainingAmount = existingFee.amount - existingFee.amountPaid;

    // Sugerir el monto restante
    amountController.text = remainingAmount.toStringAsFixed(0);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header del modal
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.green.shade600,
                        Colors.green.shade500,
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.payment,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Registrar Pago',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Casa ${house.houseNumber}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Contenido
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Información de la mensualidad
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.blue.shade50,
                              Colors.blue.shade50.withValues(alpha: 0.5),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.shade200,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'TOTAL',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Text(
                                      _currencyFormat.format(existingFee.amount),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'PAGADO',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.green.shade600,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Text(
                                      _currencyFormat.format(existingFee.amountPaid),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'PENDIENTE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.orange.shade700,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Text(
                                      _currencyFormat.format(remainingAmount),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (existingFee.amountPaid > 0) ...[
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: existingFee.amountPaid / existingFee.amount,
                                backgroundColor: Colors.grey.shade300,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
                                minHeight: 6,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Campo de monto
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Monto del pago',
                          prefixIcon: const Icon(Icons.attach_money),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          helperText: 'Máximo: ${_currencyFormat.format(remainingAmount)}',
                          helperStyle: TextStyle(color: Colors.green.shade600),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Método de pago
                      DropdownButtonFormField<String>(
                        value: selectedPaymentMethod,
                        decoration: InputDecoration(
                          labelText: 'Método de pago',
                          prefixIcon: const Icon(Icons.payment),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'efectivo',
                            child: Row(
                              children: [
                                Icon(Icons.money, size: 20, color: Colors.green),
                                SizedBox(width: 8),
                                Text('Efectivo'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'transferencia',
                            child: Row(
                              children: [
                                Icon(Icons.account_balance, size: 20, color: Colors.blue),
                                SizedBox(width: 8),
                                Text('Transferencia'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'cheque',
                            child: Row(
                              children: [
                                Icon(Icons.receipt_long, size: 20, color: Colors.purple),
                                SizedBox(width: 8),
                                Text('Cheque'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'tarjeta',
                            child: Row(
                              children: [
                                Icon(Icons.credit_card, size: 20, color: Colors.orange),
                                SizedBox(width: 8),
                                Text('Tarjeta'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'otro',
                            child: Row(
                              children: [
                                Icon(Icons.more_horiz, size: 20, color: Colors.grey),
                                SizedBox(width: 8),
                                Text('Otro'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            selectedPaymentMethod = value ?? 'efectivo';
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Número de recibo
                      TextField(
                        controller: receiptController,
                        decoration: InputDecoration(
                          labelText: 'Número de recibo (opcional)',
                          prefixIcon: const Icon(Icons.receipt),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Notas
                      TextField(
                        controller: notesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Notas (opcional)',
                          prefixIcon: const Icon(Icons.note_add),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                    ],
                  ),
                ),

                // Botones de acción
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final amount = double.tryParse(amountController.text) ?? 0;
                          if (amount <= 0 || amount > remainingAmount) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('El monto debe ser mayor a 0 y menor o igual al saldo pendiente'),
                                backgroundColor: Colors.red.shade600,
                              ),
                            );
                            return;
                          }

                          Navigator.pop(context);

                          // Registrar pago con el nuevo sistema de pagos parciales
                          await _registerPayment(
                            existingFee,
                            amount,
                            selectedPaymentMethod,
                            notesController.text,
                            receiptNumber: receiptController.text,
                          );
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Registrar Pago'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Mostrar historial de pagos
  void _showPaymentHistory(MonthlyFee existingFee) {
    // Obtener el número de casa
    final houseService = Provider.of<HouseService>(context, listen: false);
    final house = houseService.houses.firstWhere(
      (h) => h.id == existingFee.houseId,
      orElse: () => House(
        id: existingFee.houseId,
        houseNumber: 'N/A',
        communityId: '',
        monthlyFee: 0,
        createdAt: DateTime.now(),
      ),
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Historial de Pagos - Casa ${house.houseNumber}'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              children: [
                // Resumen
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total: ${_currencyFormat.format(existingFee.amount)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('Pagado: ${_currencyFormat.format(existingFee.amountPaid)}'),
                      Text('Pendiente: ${_currencyFormat.format(existingFee.amount - existingFee.amountPaid)}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Lista de pagos
                Expanded(
                  child: FutureBuilder<List<Payment>>(
                    future: _loadPaymentHistory(existingFee.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error al cargar historial: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }

                      final payments = snapshot.data ?? [];
                      if (payments.isEmpty) {
                        return const Center(
                          child: Text(
                            'No hay pagos registrados',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: payments.length,
                        itemBuilder: (context, index) {
                          final payment = payments[index];
                          return _buildPaymentHistoryItem(payment, existingFee, setDialogState);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }

  // Registrar un pago parcial
  Future<void> _registerPayment(
    MonthlyFee existingFee,
    double amount,
    String paymentMethod,
    String notes, {
    String receiptNumber = '',
  }) async {
    print('🔍 DEBUG: _registerPayment llamada con monto: $amount, método: $paymentMethod');
    print('🔍 DEBUG: _registerPayment - MonthlyFee ID: ${existingFee.id}');

    try {
      // Preparar datos del pago
      final paymentData = <String, dynamic>{
        'monthlyFeeId': existingFee.id,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'paidDate': DateTime.now().toIso8601String(),
      };

      // Solo agregar campos opcionales si no están vacíos
      if (notes.isNotEmpty) {
        paymentData['notes'] = notes;
      }
      if (receiptNumber.isNotEmpty) {
        paymentData['receiptNumber'] = receiptNumber;
      }

      // Llamar a la API para registrar el pago
      final apiService = ApiService();
      await apiService.loadAuthToken();
      final response = await apiService.post('/payments', body: paymentData);

      if (response.isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Pago registrado: ${_currencyFormat.format(amount)}',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Recargar datos
        final monthlyFeeService = Provider.of<MonthlyFeeService>(context, listen: false);
        await monthlyFeeService.refresh();
        setState(() {});
      } else {
        throw Exception(response.error ?? 'Error desconocido al registrar el pago');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al registrar pago: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Cargar historial de pagos de una mensualidad
  Future<List<Payment>> _loadPaymentHistory(String monthlyFeeId) async {
    try {
      final apiService = ApiService();
      await apiService.loadAuthToken();
      final response = await apiService.get('/payments/monthly-fee/$monthlyFeeId');

      if (response.isSuccess && response.data != null) {
        final List<dynamic> paymentList = response.data as List<dynamic>;
        return paymentList.map((payment) => Payment.fromJson(payment)).toList();
      }

      return [];
    } catch (e) {
      print('Error loading payment history: $e');
      return [];
    }
  }

  // Widget para mostrar un ítem del historial de pagos
  Widget _buildPaymentHistoryItem(Payment payment, MonthlyFee monthlyFee, StateSetter setDialogState) {
    final bool isCancelled = payment.isCancelled;
    final Color statusColor = isCancelled ? Colors.red : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con monto y estado
            Row(
              children: [
                Expanded(
                  child: Text(
                    _currencyFormat.format(payment.amount),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      decoration: isCancelled ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCancelled ? Icons.cancel : Icons.check_circle,
                        color: statusColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        payment.statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Información del pago
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Método: ${_getPaymentMethodText(payment.paymentMethod)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      Text(
                        'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(payment.paidDate)}',
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      if (payment.receiptNumber != null)
                        Text(
                          'Recibo: ${payment.receiptNumber}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      if (payment.notes != null && payment.notes!.isNotEmpty)
                        Text(
                          'Notas: ${payment.notes}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      if (isCancelled && payment.cancellationReason != null)
                        Text(
                          'Razón cancelación: ${payment.cancellationReason}',
                          style: const TextStyle(fontSize: 12, color: Colors.red),
                        ),
                    ],
                  ),
                ),
                // Botón de cancelar (solo para pagos activos)
                if (!isCancelled)
                  IconButton(
                    onPressed: () => _showCancelPaymentDialog(payment, monthlyFee, setDialogState),
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                    tooltip: 'Cancelar pago',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Obtener texto del método de pago
  String _getPaymentMethodText(String method) {
    switch (method) {
      case 'efectivo':
        return 'Efectivo';
      case 'transferencia':
        return 'Transferencia';
      case 'cheque':
        return 'Cheque';
      case 'tarjeta':
        return 'Tarjeta';
      case 'otro':
        return 'Otro';
      default:
        return method.toUpperCase();
    }
  }

  // Mostrar diálogo para cancelar un pago
  void _showCancelPaymentDialog(Payment payment, MonthlyFee monthlyFee, StateSetter setDialogState) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Pago'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monto: ${_currencyFormat.format(payment.amount)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Fecha: ${DateFormat('dd/MM/yyyy').format(payment.paidDate)}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Razón de la cancelación *',
                hintText: 'Explica por qué se cancela este pago...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().length < 5) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('La razón debe tener al menos 5 caracteres'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              await _cancelPayment(payment, reasonController.text.trim(), monthlyFee, setDialogState);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirmar Cancelación'),
          ),
        ],
      ),
    );
  }

  // Cancelar un pago
  Future<void> _cancelPayment(Payment payment, String reason, MonthlyFee monthlyFee, StateSetter setDialogState) async {
    try {
      final apiService = ApiService();
      await apiService.loadAuthToken();

      final response = await apiService.patch(
        '/payments/${payment.id}/cancel',
        body: {'reason': reason},
      );

      if (response.isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Pago cancelado: ${_currencyFormat.format(payment.amount)}',
            ),
            backgroundColor: Colors.orange,
          ),
        );

        // Actualizar el diálogo
        setDialogState(() {});

        // Recargar datos
        final monthlyFeeService = Provider.of<MonthlyFeeService>(context, listen: false);
        await monthlyFeeService.refresh();

        // También recargar casas según el tipo de usuario
        if (mounted) {
          final houseService = Provider.of<HouseService>(context, listen: false);
          final authService = Provider.of<AuthService>(context, listen: false);
          final user = authService.currentUser;

          if (user?.isSuperAdmin == true) {
            await houseService.loadHouses();
          } else if (user?.communityId != null) {
            await houseService.loadHousesByCommunity(user!.communityId!);
          } else if (user?.isAdmin == true) {
            // Admin sin communityId: cargar todas las casas como fallback
            await houseService.loadHouses();
          }
        }

        setState(() {});
      } else {
        throw Exception(response.error ?? 'Error desconocido al cancelar el pago');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al cancelar pago: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Tarjeta de casa individual
  Widget _buildHouseCard(House house, User? user) {
    // Obtener el monto de la comunidad
    final communityService = Provider.of<CommunityService>(context, listen: false);
    final community = communityService.getCommunityById(house.communityId);
    final communityMonthlyFee = community?.monthlyFee ?? house.monthlyFee;

    // Verificar si ya existe una mensualidad
    final existingFee = _getExistingMonthlyFee(house);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _onHouseTap(house, user),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con número de casa
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.home,
                        color: Color(0xFF2196F3),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Casa ${house.houseNumber}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A237E),
                            ),
                          ),
                          if (house.description != null)
                            Text(
                              house.description!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: existingFee != null
                            ? _getStatusColor(existingFee.status).withValues(alpha: 0.1)
                            : const Color(0xFF2196F3).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: existingFee != null
                              ? _getStatusColor(existingFee.status).withValues(alpha: 0.3)
                              : const Color(0xFF2196F3).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            existingFee != null ? _getStatusIcon(existingFee.status) : Icons.add_circle_outline,
                            color: existingFee != null ? _getStatusColor(existingFee.status) : const Color(0xFF2196F3),
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            existingFee != null ? _getStatusBadgeText(existingFee.status) : 'NUEVA',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color:
                                  existingFee != null ? _getStatusColor(existingFee.status) : const Color(0xFF2196F3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Información de la casa
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.attach_money, color: Colors.green.shade700, size: 20),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Cuota mensual',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      _currencyFormat.format(communityMonthlyFee),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1A237E),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (house.hasCurrentUser)
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(Icons.person, color: Colors.blue.shade700, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Residente',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Text(
                                          house.currentUserName ?? 'Asignado',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF2196F3),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Información de mensualidad existente o botón para crear
                if (user?.isAdmin == true)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 12),
                    child: existingFee != null
                        ? _buildExistingFeeInfo(existingFee)
                        : Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _onCreateMonthlyFee(house),
                                  icon: const Icon(Icons.payment, size: 16),
                                  label: const Text('Crear Mensualidad'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2196F3),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Acción al tocar una casa
  void _onHouseTap(House house, User? user) {
    if (user?.isAdmin == true) {
      final existingFee = _getExistingMonthlyFee(house);

      if (existingFee != null && existingFee.amountPaid > 0) {
        // Si hay mensualidad con pagos, mostrar historial
        _showPaymentHistory(existingFee);
      } else {
        // Si no hay mensualidad o no tiene pagos, permitir crear/registrar pago
        _onCreateMonthlyFee(house);
      }
    }
  }

  // Crear mensualidad para una casa con opción de registrar pago
  void _onCreateMonthlyFee(House house) {
    // Verificar si ya existe mensualidad
    final existingFee = _getExistingMonthlyFee(house);
    final bool hasExistingFee = existingFee != null;

    // Obtener el monto de la comunidad
    final communityService = Provider.of<CommunityService>(context, listen: false);
    final community = communityService.getCommunityById(house.communityId);
    final communityMonthlyFee = community?.monthlyFee ?? house.monthlyFee;

    final TextEditingController amountController = TextEditingController(
      text: hasExistingFee
          ? (existingFee.amount - existingFee.amountPaid).toStringAsFixed(0) // Monto pendiente
          : communityMonthlyFee.toStringAsFixed(0), // Monto completo
    );
    final TextEditingController receiptController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    bool registerPayment = hasExistingFee; // Si existe, por defecto registrar pago
    String paymentMethod = 'efectivo';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(hasExistingFee
              ? 'Registrar Pago - Casa ${house.houseNumber}'
              : 'Mensualidad - Casa ${house.houseNumber}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_month, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (hasExistingFee) ...[
                        Text(
                          'Total: ${_currencyFormat.format(existingFee.amount)}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Pagado: ${_currencyFormat.format(existingFee.amountPaid)}',
                          style: TextStyle(fontSize: 14, color: Colors.green.shade600),
                        ),
                        Text(
                          'Pendiente: ${_currencyFormat.format(existingFee.amount - existingFee.amountPaid)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ] else
                        Text(
                          'Monto sugerido: ${_currencyFormat.format(communityMonthlyFee)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade700,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Campo para el monto
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Monto de la mensualidad',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Checkbox para registrar pago inmediato (solo si no existe mensualidad)
                if (!hasExistingFee)
                  CheckboxListTile(
                    value: registerPayment,
                    onChanged: (value) {
                      setDialogState(() {
                        registerPayment = value ?? false;
                      });
                    },
                    title: const Text('Registrar pago inmediato'),
                    subtitle: const Text(
                      'Marcar como pagada al crear',
                      style: TextStyle(fontSize: 12),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    activeColor: const Color(0xFF4CAF50),
                  ),

                // Mostrar campos de pago si se activa el pago inmediato o si ya existe mensualidad
                if (registerPayment || hasExistingFee) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Información del Pago',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Método de pago
                        DropdownButtonFormField<String>(
                          value: paymentMethod,
                          decoration: InputDecoration(
                            labelText: 'Método de pago',
                            prefixIcon: const Icon(Icons.payment, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'efectivo', child: Text('Efectivo')),
                            DropdownMenuItem(value: 'transferencia', child: Text('Transferencia')),
                            DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                            DropdownMenuItem(value: 'tarjeta', child: Text('Tarjeta')),
                            DropdownMenuItem(value: 'otro', child: Text('Otro')),
                          ],
                          onChanged: (value) {
                            setDialogState(() {
                              paymentMethod = value ?? 'efectivo';
                            });
                          },
                        ),
                        const SizedBox(height: 12),

                        // Número de recibo
                        TextField(
                          controller: receiptController,
                          decoration: InputDecoration(
                            labelText: 'Número de recibo (opcional)',
                            prefixIcon: const Icon(Icons.receipt, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Notas
                        TextField(
                          controller: notesController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Notas (opcional)',
                            prefixIcon: const Icon(Icons.note, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade700, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'La mensualidad quedará como pendiente',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final amount = double.tryParse(amountController.text) ??
                    (hasExistingFee ? (existingFee!.amount - existingFee.amountPaid) : communityMonthlyFee);
                Navigator.pop(context);

                if (hasExistingFee) {
                  // Si ya existe mensualidad, registrar pago directamente
                  await _registerPayment(
                    existingFee!,
                    amount,
                    paymentMethod,
                    notesController.text,
                    receiptNumber: receiptController.text,
                  );
                } else {
                  // Si no existe, crear nueva mensualidad
                  _createMonthlyFeeWithPayment(
                    house,
                    amount,
                    registerPayment,
                    paymentMethod: paymentMethod,
                    receiptNumber: receiptController.text,
                    notes: notesController.text,
                  );
                }
              },
              icon: Icon(hasExistingFee ? Icons.payment : (registerPayment ? Icons.check_circle : Icons.add)),
              label: Text(hasExistingFee ? 'Registrar Pago' : (registerPayment ? 'Crear y Pagar' : 'Crear')),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    (hasExistingFee || registerPayment) ? const Color(0xFF4CAF50) : const Color(0xFF2196F3),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Crear mensualidad con opción de pago
  Future<void> _createMonthlyFeeWithPayment(
    House house,
    double amount,
    bool registerPayment, {
    String paymentMethod = 'efectivo',
    String receiptNumber = '',
    String notes = '',
  }) async {
    print('🔍 DEBUG: _createMonthlyFeeWithPayment llamada');
    print(
        '🔍 DEBUG: _createMonthlyFeeWithPayment - casa: ${house.houseNumber}, monto: $amount, registerPayment: $registerPayment');

    try {
      final monthlyFeeService = Provider.of<MonthlyFeeService>(context, listen: false);
      final selectedMonth = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}';

      // Obtener el monto real de la comunidad
      final communityService = Provider.of<CommunityService>(context, listen: false);
      final community = communityService.getCommunityById(house.communityId);
      final realMonthlyFeeAmount = community?.monthlyFee ?? house.monthlyFee;

      // Crear mensualidad con el monto especificado
      // Usar el userId del residente si existe, si no usar el ID del usuario actual (admin)
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;
      final userId = house.currentUserId ?? currentUser?.id ?? '';

      // Crear directamente con ApiService para tener control total
      final monthlyFeeData = <String, dynamic>{
        'communityId': house.communityId,
        'userId': userId, // ID del usuario (residente o admin)
        'houseId': house.id, // ID real de la casa
        'month': selectedMonth,
        'amount': realMonthlyFeeAmount, // SIEMPRE usar el monto real de la comunidad
        'amountPaid': 0.0, // Inicialmente sin pagos
        'status': 'pendiente', // Inicialmente pendiente
        'dueDate': DateTime(_selectedDate.year, _selectedDate.month, 15).toIso8601String(),
      };

      // Agregar campos opcionales si están presentes
      if (registerPayment) {
        if (receiptNumber.isNotEmpty) {
          monthlyFeeData['receiptNumber'] = receiptNumber;
        }
        if (notes.isNotEmpty) {
          monthlyFeeData['notes'] = notes;
        }
      }

      // Usar ApiService directamente para crear la mensualidad
      final apiService = ApiService();
      final response = await apiService.post('/monthly-fees', body: monthlyFeeData);

      if (response.isSuccess && mounted) {
        // Si se debe registrar pago inmediato, hacerlo ahora
        if (registerPayment && amount > 0) {
          print('🔍 DEBUG: Registrando pago inicial de $amount');

          // Recargar datos para obtener la mensualidad recién creada
          await monthlyFeeService.refresh();

          // Buscar la mensualidad que acabamos de crear
          final createdFee = monthlyFeeService.monthlyFees.firstWhere(
            (fee) => fee.month == selectedMonth && fee.houseId == house.id,
          );

          // Registrar el pago inicial usando el sistema de pagos
          await _registerPayment(
            createdFee,
            amount,
            paymentMethod,
            notes,
            receiptNumber: receiptNumber,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '✅ Mensualidad creada con pago inicial de ${_currencyFormat.format(amount)} - Casa ${house.houseNumber}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Mensualidad creada (pendiente) - Casa ${house.houseNumber}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }

        // Recargar datos finales
        await monthlyFeeService.refresh();
        setState(() {});
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: ${response.error ?? 'Error desconocido'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error inesperado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildPendingFeesTab(MonthlyFeeService monthlyFeeService, User? user) {
    final selectedMonth = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}';
    final pendingFees = monthlyFeeService.pendingFees.where((fee) => fee.month == selectedMonth).toList();

    if (pendingFees.isEmpty) {
      return _buildNoMonthlyFeesView(monthlyFeeService, user);
    }

    return RefreshIndicator(
      onRefresh: () => monthlyFeeService.refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pendingFees.length,
        itemBuilder: (context, index) {
          final fee = pendingFees[index];
          return _buildMonthlyFeeCard(fee, user);
        },
      ),
    );
  }

  Widget _buildPaidFeesTab(MonthlyFeeService monthlyFeeService, User? user) {
    final selectedMonth = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}';
    final paidFees = monthlyFeeService.paidFees.where((fee) => fee.month == selectedMonth).toList();

    if (paidFees.isEmpty) {
      return const Center(
        child: Text(
          'No hay mensualidades pagadas',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => monthlyFeeService.refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: paidFees.length,
        itemBuilder: (context, index) {
          final fee = paidFees[index];
          return _buildMonthlyFeeCard(fee, user);
        },
      ),
    );
  }

  Widget _buildOverdueFeesTab(MonthlyFeeService monthlyFeeService, User? user) {
    final selectedMonth = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}';
    final overdueFees = monthlyFeeService.overdueFees.where((fee) => fee.month == selectedMonth).toList();

    if (overdueFees.isEmpty) {
      return const Center(
        child: Text(
          'No hay mensualidades vencidas',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => monthlyFeeService.refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: overdueFees.length,
        itemBuilder: (context, index) {
          final fee = overdueFees[index];
          return _buildMonthlyFeeCard(fee, user);
        },
      ),
    );
  }

  Widget _buildSummaryTab(MonthlyFeeService monthlyFeeService, User? user) {
    final selectedMonth = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}';
    final monthFees = monthlyFeeService.monthlyFees.where((fee) => fee.month == selectedMonth).toList();

    final totalAmount = monthFees.fold(0.0, (sum, fee) => sum + fee.amount);
    final totalPaid = monthFees.fold(0.0, (sum, fee) => sum + fee.amountPaid);
    final totalPending = monthFees
        .where((fee) => fee.status == MonthlyFeeStatus.pendiente)
        .fold(0.0, (sum, fee) => sum + fee.remainingAmount);
    final totalOverdue = monthFees
        .where((fee) => fee.status == MonthlyFeeStatus.vencido)
        .fold(0.0, (sum, fee) => sum + fee.remainingAmount);

    return RefreshIndicator(
      onRefresh: () => monthlyFeeService.refresh(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del mes seleccionado
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Resumen de ${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${monthFees.length} mensualidades registradas',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _buildSummaryCard(
              'Total del Mes',
              totalAmount,
              FontAwesomeIcons.calendar,
              const Color(0xFF2196F3),
            ),
            const SizedBox(height: 16),
            _buildSummaryCard(
              'Total Pagado',
              totalPaid,
              FontAwesomeIcons.circleCheck,
              const Color(0xFF4CAF50),
            ),
            const SizedBox(height: 16),
            _buildSummaryCard(
              'Total Pendiente',
              totalPending,
              FontAwesomeIcons.clock,
              const Color(0xFFFF9800),
            ),
            const SizedBox(height: 16),
            _buildSummaryCard(
              'Total Vencido',
              totalOverdue,
              FontAwesomeIcons.triangleExclamation,
              const Color(0xFFF44336),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: FaIcon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A237E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currencyFormat.format(amount),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyFeeCard(MonthlyFee fee, User? user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mes: ${fee.month}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusChip(fee.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monto: ${_currencyFormat.format(fee.amount)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      if (fee.amountPaid > 0)
                        Text(
                          'Pagado: ${_currencyFormat.format(fee.amountPaid)}',
                          style: const TextStyle(fontSize: 14, color: Colors.green),
                        ),
                      if (fee.remainingAmount > 0)
                        Text(
                          'Pendiente: ${_currencyFormat.format(fee.remainingAmount)}',
                          style: const TextStyle(fontSize: 14, color: Colors.orange),
                        ),
                    ],
                  ),
                ),
                if (user?.isAdmin == true && fee.status != MonthlyFeeStatus.pagado)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RegisterPaymentScreen(
                            monthlyFee: fee,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Registrar Pago'),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Vence: ${DateFormat('dd/MM/yyyy').format(fee.dueDate)}',
                style: TextStyle(
                  fontSize: 12,
                  color: fee.isOverdue ? Colors.red : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(MonthlyFeeStatus status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case MonthlyFeeStatus.pendiente:
        color = const Color(0xFFFF9800);
        text = 'Pendiente';
        icon = FontAwesomeIcons.clock;
        break;
      case MonthlyFeeStatus.abonado:
        color = const Color(0xFF2196F3);
        text = 'Abonado';
        icon = FontAwesomeIcons.chartLine;
        break;
      case MonthlyFeeStatus.pagado:
        color = const Color(0xFF4CAF50);
        text = 'Pagado';
        icon = FontAwesomeIcons.circleCheck;
        break;
      case MonthlyFeeStatus.vencido:
        color = const Color(0xFFF44336);
        text = 'Vencido';
        icon = FontAwesomeIcons.triangleExclamation;
        break;
      case MonthlyFeeStatus.parcial:
        color = const Color(0xFF2196F3);
        text = 'Parcial';
        icon = FontAwesomeIcons.percent;
        break;
      case MonthlyFeeStatus.exento:
        color = const Color(0xFF9C27B0);
        text = 'Exento';
        icon = FontAwesomeIcons.ban;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
