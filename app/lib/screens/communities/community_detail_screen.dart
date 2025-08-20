import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/community_model.dart';
import '../../models/user_model.dart';
import '../../models/house_model.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
import '../../services/house_service.dart';
import '../../services/community_service.dart';
import '../../config/theme/app_theme.dart';

class CommunityDetailScreen extends StatefulWidget {
  final Community community;

  const CommunityDetailScreen({
    Key? key,
    required this.community,
  }) : super(key: key);

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<User> _users = [];
  List<User> _admins = [];
  List<User> _residents = [];
  List<House> _houses = [];
  bool _isLoadingHouses = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Usar addPostFrameCallback para evitar setState durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCommunityData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCommunityData() async {
    if (!mounted) return;

    try {
      final userService = Provider.of<UserService>(context, listen: false);
      final houseService = Provider.of<HouseService>(context, listen: false);

      await userService.refresh();
      await _loadHouses();

      if (!mounted) return;

      // Filtrar usuarios por comunidad
      final allUsers = userService.users;

      // Debug logs
      print('=== DEBUG: Cargando datos de comunidad ===');
      print('ID de la comunidad: ${widget.community.id}');
      print('Total de usuarios en el sistema: ${allUsers.length}');

      // Mostrar todos los usuarios para debug
      for (var user in allUsers) {
        print('Usuario: ${user.name} - ${user.email} - Role: ${user.role} - CommunityID: ${user.communityId}');
      }

      print('Usuarios de la comunidad: ${allUsers.where((user) => user.communityId == widget.community.id).length}');

      if (mounted) {
        setState(() {
          // Filtrado directo en una sola operación para evitar problemas
          _users = allUsers.where((user) => user.communityId == widget.community.id).toList();

          // Filtrado directo de administradores y residentes
          _admins = allUsers
              .where((user) => user.communityId == widget.community.id && user.role == UserRole.administrador)
              .toList();

          _residents = allUsers
              .where((user) => user.communityId == widget.community.id && user.role == UserRole.residente)
              .toList();
        });

        // Debug logs después del setState
        print('Usuarios filtrados por comunidad: ${_users.length}');
        print('Administradores encontrados: ${_admins.length}');
        print('Residentes encontrados: ${_residents.length}');

        // Verificación adicional del filtrado directo
        print('=== Verificación de filtrado directo ===');
        final directAdmins = allUsers
            .where((user) => user.communityId == widget.community.id && user.role == UserRole.administrador)
            .toList();
        print('Administradores por filtrado directo: ${directAdmins.length}');

        final directResidents = allUsers
            .where((user) => user.communityId == widget.community.id && user.role == UserRole.residente)
            .toList();
        print('Residentes por filtrado directo: ${directResidents.length}');

        // Verificación detallada de roles y comparaciones
        print('=== Verificación detallada de roles ===');
        for (var user in _users) {
          print('Usuario: ${user.name}');
          print('  - Role: ${user.role}');
          print('  - Role.toString(): ${user.role.toString()}');
          print('  - Role.toString().split(".").last: ${user.role.toString().split(".").last}');
          print('  - user.role == UserRole.administrador: ${user.role == UserRole.administrador}');
          print('  - user.role == UserRole.residente: ${user.role == UserRole.residente}');
          print('  - user.role == UserRole.superAdmin: ${user.role == UserRole.superAdmin}');
          print('  - user.isAdmin: ${user.isAdmin}');
          print('  - user.isResident: ${user.isResident}');
          print('  - user.isSuperAdmin: ${user.isSuperAdmin}');
          print('  ---');
        }

        // Mostrar detalles de cada usuario de la comunidad
        print('=== Usuarios de la comunidad ${widget.community.name} ===');
        for (var user in _users) {
          print('Usuario: ${user.name} - ${user.email} - Role: ${user.role} - CommunityID: ${user.communityId}');
        }

        // Mostrar detalles de cada administrador
        print('=== Administradores encontrados ===');
        for (var admin in _admins) {
          print('Admin: ${admin.name} - ${admin.email} - Role: ${admin.role}');
        }

        // Verificar la comparación de roles
        print('=== Verificación de roles ===');
        print('UserRole.administrador: ${UserRole.administrador}');
        print('Comparación directa: ${_users.where((user) => user.role == UserRole.administrador).length}');
        print(
            'Comparación por string: ${_users.where((user) => user.role.toString() == 'UserRole.administrador').length}');
      }
    } catch (e) {
      print('Error loading community data: $e');
    }
  }

  Future<void> _loadHouses() async {
    if (!mounted) return;

    setState(() {
      _isLoadingHouses = true;
    });

    try {
      final houseService = Provider.of<HouseService>(context, listen: false);
      await houseService.loadHousesByCommunity(widget.community.id);

      if (mounted) {
        setState(() {
          _houses = houseService.getHousesByCommunity(widget.community.id);
          _isLoadingHouses = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingHouses = false;
        });
      }
      print('Error loading houses: $e');
    }
  }

  void _showRegisterHouseDialog() {
    final TextEditingController houseNumberController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Nueva Casa'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Comunidad: ${widget.community.name}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: houseNumberController,
                decoration: const InputDecoration(
                  labelText: 'Número de Casa *',
                  hintText: 'Ej: 1, 2, A, B, etc.',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El número de casa es obligatorio';
                  }
                  if (value.trim().length > 10) {
                    return 'El número de casa no puede exceder 10 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Casas registradas: ${_houses.length} / ${widget.community.totalHouses}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
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
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                await _registerHouse(houseNumberController.text.trim());
              }
            },
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _registerHouse(String houseNumber) async {
    try {
      final houseService = Provider.of<HouseService>(context, listen: false);

      final result = await houseService.createHouse({
        'houseNumber': houseNumber,
        'communityId': widget.community.id,
      });

      if (result['success'] && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Casa $houseNumber registrada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Recargar casas
        await _loadHouses();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: ${result['message']}'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(widget.community.name),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1A237E),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF2196F3)),
            onPressed: _loadCommunityData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1A237E),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF1A237E),
          tabs: const [
            Tab(icon: Icon(Icons.info), text: 'Información'),
            Tab(icon: Icon(Icons.home), text: 'Casas'),
            Tab(icon: Icon(Icons.people), text: 'Usuarios'),
            Tab(icon: Icon(Icons.people), text: 'Administradores'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(),
          _buildUnitsTab(),
          _buildUsersTab(),
          _buildAdminsTab(),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    return RefreshIndicator(
      onRefresh: _loadCommunityData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 16),
            _buildInfoCard(),
            const SizedBox(height: 16),
            _buildStatsCard(),
            const SizedBox(height: 16),
            _buildSettingsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.community.isActive
              ? [const Color(0xFF2196F3), const Color(0xFF1976D2)]
              : [const Color(0xFF9E9E9E), const Color(0xFF757575)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                (widget.community.isActive ? const Color(0xFF2196F3) : const Color(0xFF9E9E9E)).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: FaIcon(
              widget.community.isActive ? FontAwesomeIcons.building : FontAwesomeIcons.buildingShield,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.community.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.community.isActive ? 'Privada Activa' : 'Privada Inactiva',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (!widget.community.isActive) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Esta privada está temporalmente deshabilitada',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.circleInfo,
                color: Color(0xFF1A237E),
                size: 18,
              ),
              const SizedBox(width: 10),
              const Text(
                'Información General',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Dirección', widget.community.address, Icons.location_on),
          const SizedBox(height: 12),
          _buildInfoRow('Descripción', widget.community.description, Icons.description),
          const SizedBox(height: 12),
          _buildInfoRow(
              'Mensualidad', '${widget.community.monthlyFee} ${widget.community.currency}', Icons.attach_money),
          const SizedBox(height: 12),
          _buildInfoRow('Total de Casas', '${widget.community.totalHouses}', Icons.home),
          const SizedBox(height: 12),
          _buildInfoRow('Fecha de Creación', _formatDate(widget.community.createdAt), Icons.calendar_today),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF1A237E), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF424242),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.chartBar,
                color: Color(0xFF1A237E),
                size: 18,
              ),
              const SizedBox(width: 10),
              const Text(
                'Estadísticas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total Usuarios',
                  '${_users.length}',
                  FontAwesomeIcons.users,
                  const Color(0xFF2196F3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Administradores',
                  '${_admins.length}',
                  FontAwesomeIcons.userGear,
                  const Color(0xFF9C27B0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Residentes',
                  '${_residents.length}',
                  FontAwesomeIcons.user,
                  const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Ocupación',
                  '${_users.length}/${widget.community.totalHouses}',
                  FontAwesomeIcons.house,
                  const Color(0xFFFF9800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          FaIcon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.gear,
                color: Color(0xFF1A237E),
                size: 18,
              ),
              const SizedBox(width: 10),
              const Text(
                'Configuración',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingsRow('ID de la Privada', widget.community.id, Icons.fingerprint),
          const SizedBox(height: 12),
          _buildSettingsRow('Super Admin ID', widget.community.superAdminId, Icons.admin_panel_settings),
          const SizedBox(height: 12),
          _buildSettingsRow('Configuraciones', '${widget.community.settings.length} configuraciones', Icons.settings),
        ],
      ),
    );
  }

  Widget _buildSettingsRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF1A237E), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF424242),
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUnitsTab() {
    return RefreshIndicator(
      onRefresh: _loadCommunityData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUnitsHeader(),
            const SizedBox(height: 16),
            _buildUnitsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitsHeader() {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final canManageHouses = user?.isSuperAdmin == true || user?.isAdmin == true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.house,
                color: Color(0xFF1A237E),
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Casas de la Privada',
                  style: AppTextStyles.subtitle1.copyWith(
                    color: const Color(0xFF1A237E),
                  ),
                ),
              ),
              if (canManageHouses)
                ElevatedButton.icon(
                  onPressed: _showRegisterHouseDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Registrar Casa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total de casas: ${widget.community.totalHouses}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ),
              Text(
                'Registradas: ${_houses.length}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: const Color(0xFF4CAF50),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnitsList() {
    if (_isLoadingHouses) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_houses.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const FaIcon(
              FontAwesomeIcons.house,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay casas registradas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Esta privada puede tener hasta ${widget.community.totalHouses} casas',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showRegisterHouseDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Registrar Primera Casa'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _houses.map((house) {
        final houseNumber = house.houseNumber ?? house.id ?? 'N/A';

        // Obtener usuarios asignados a esta casa
        final assignedUsers = _users
            .where((user) => user.communityId == widget.community.id && user.house == houseNumber.toString())
            .toList();

        final isOccupied = assignedUsers.isNotEmpty;

        // Debug: Verificar el cálculo
        print(
            '🏠 DEBUG Casa $houseNumber: communityId=${widget.community.id}, assignedUsers=${assignedUsers.length}, isOccupied=$isOccupied');
        if (assignedUsers.isNotEmpty) {
          print('👥 Usuarios asignados: ${assignedUsers.map((u) => '${u.name} (${u.house})').join(', ')}');
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isOccupied ? const Color(0xFFE8F5E8) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isOccupied ? const Color(0xFF4CAF50).withValues(alpha: 0.3) : const Color(0xFFE0E0E0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icono de la casa
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isOccupied
                      ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                      : const Color(0xFFE0E0E0).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isOccupied ? const Color(0xFF4CAF50).withValues(alpha: 0.3) : const Color(0xFFE0E0E0),
                    width: 1,
                  ),
                ),
                child: Icon(
                  FontAwesomeIcons.house,
                  color: isOccupied ? const Color(0xFF4CAF50) : const Color(0xFF9E9E9E),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Información de la casa
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Casa $houseNumber',
                          style: AppTextStyles.heading2.copyWith(
                            color: isOccupied ? const Color(0xFF2E7D32) : const Color(0xFF424242),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOccupied ? const Color(0xFF4CAF50).withValues(alpha: 0.1) : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isOccupied ? 'Ocupada' : 'Libre',
                        style: AppTextStyles.overline.copyWith(
                          color: isOccupied ? const Color(0xFF4CAF50) : const Color(0xFF9E9E9E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Botón de acción
              Container(
                decoration: BoxDecoration(
                  color: isOccupied ? const Color(0xFF4CAF50) : const Color(0xFF2196F3),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (isOccupied ? const Color(0xFF4CAF50) : const Color(0xFF2196F3)).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () {
                    print(
                        '🔍 DEBUG: Casa $houseNumber - isOccupied: $isOccupied, assignedUsers: ${assignedUsers.length}');
                    if (isOccupied) {
                      print('✅ Gestionando usuarios existentes de la casa $houseNumber');
                      _showManageUnitUsersDialog(houseNumber.toString(), assignedUsers);
                    } else {
                      print('➕ Agregando usuario a la casa $houseNumber');
                      _showUnifiedUserDialog(houseNumber.toString());
                    }
                  },
                  icon: Icon(
                    isOccupied ? Icons.people : Icons.person_add,
                    color: Colors.white,
                    size: 20,
                  ),
                  tooltip: isOccupied ? 'Gestionar usuarios de la casa' : 'Agregar usuario a la casa',
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUsersTab() {
    return RefreshIndicator(
      onRefresh: _loadCommunityData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUsersHeader(),
            const SizedBox(height: 16),
            _buildUsersList(),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.users,
                color: Color(0xFF1A237E),
                size: 18,
              ),
              const SizedBox(width: 10),
              const Text(
                'Usuarios de la Privada',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Total de usuarios: ${_users.length}',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    if (_users.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          children: [
            FaIcon(
              FontAwesomeIcons.users,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No hay usuarios registrados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Los usuarios aparecerán aquí cuando se registren',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: _users.map((user) {
        final roleColor = user.role == UserRole.administrador ? const Color(0xFF9C27B0) : const Color(0xFF4CAF50);

        final roleIcon = user.role == UserRole.administrador ? FontAwesomeIcons.userGear : FontAwesomeIcons.user;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: roleColor.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FaIcon(roleIcon, color: roleColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: AppTextStyles.heading2.copyWith(
                        color: const Color(0xFF1A237E),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user.email,
                      style: AppTextStyles.bodyMedium,
                    ),
                    Text(
                      'Tel: ${user.phoneNumber}',
                      style: AppTextStyles.bodyMedium,
                    ),
                    if (user.house != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Casa: ${user.house}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1A237E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    Text(
                      'Rol: ${user.role == UserRole.administrador ? 'Administrador' : 'Residente'}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: user.role == UserRole.administrador ? const Color(0xFF9C27B0) : const Color(0xFF1A237E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  user.role == UserRole.administrador ? 'Admin' : 'Residente',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: roleColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              
              // Menú de opciones
              PopupMenuButton<String>(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.more_vert,
                    color: Color(0xFF666666),
                    size: 20,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'promote_to_admin':
                      if (user.role == UserRole.residente) {
                        _showChangeRoleDialog(user);
                      }
                      break;
                    case 'demote_to_resident':
                      if (user.role == UserRole.administrador) {
                        _showDemoteToResidentDialog(user);
                      }
                      break;
                    case 'change_password':
                      _showChangePasswordDialog(user);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (user.role == UserRole.residente)
                    PopupMenuItem(
                      value: 'promote_to_admin',
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E5F5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings,
                              color: Color(0xFF9C27B0),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Subir a administrador',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (user.role == UserRole.administrador)
                    PopupMenuItem(
                      value: 'demote_to_resident',
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Color(0xFF4CAF50),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Convertir a residente',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'change_password',
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.lock_reset,
                            color: Color(0xFF1976D2),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Cambiar contraseña',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAdminsTab() {
    return RefreshIndicator(
      onRefresh: _loadCommunityData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAdminsHeader(),
            const SizedBox(height: 16),
            _buildAdminsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminsHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.userGear,
                color: Color(0xFF1A237E),
                size: 18,
              ),
              const SizedBox(width: 10),
              const Text(
                'Administradores de la Privada',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Total de administradores: ${_admins.length}',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminsList() {
    if (_admins.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          children: [
            FaIcon(
              FontAwesomeIcons.userGear,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No hay administradores asignados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Los administradores aparecerán aquí cuando se asignen',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: _admins.map((admin) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF9C27B0).withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF9C27B0).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.userGear,
                  color: Color(0xFF9C27B0),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      admin.name,
                      style: AppTextStyles.heading2.copyWith(
                        color: const Color(0xFF1A237E),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      admin.email,
                      style: AppTextStyles.bodyMedium,
                    ),
                    Text(
                      'Tel: ${admin.phoneNumber}',
                      style: AppTextStyles.bodyMedium,
                    ),
                    if (admin.house != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Casa: ${admin.house}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1A237E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    Text(
                      'Rol: ${admin.role == UserRole.administrador ? 'Administrador' : 'Residente'}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: admin.role == UserRole.administrador ? const Color(0xFF9C27B0) : const Color(0xFF1A237E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF9C27B0).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Administrador',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF9C27B0),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Construir tarjeta de usuario con mejor diseño
  Widget _buildUserCard(User user, String unitNumber) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar del usuario
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _getUserAvatarColor(user.name),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: _getUserAvatarColor(user.name).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  user.name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Información del usuario
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: 16,
                        color: const Color(0xFF666666),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          user.email,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 16,
                        color: const Color(0xFF666666),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        user.phoneNumber,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getRoleColor(user.role).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getRoleColor(user.role).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _getRoleText(user.role),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getRoleColor(user.role),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Menú de opciones
            PopupMenuButton<String>(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.more_vert,
                  color: Color(0xFF666666),
                  size: 20,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onSelected: (value) {
                print('🔄 DEBUG Popup onSelected - Valor seleccionado: $value');
                switch (value) {
                  case 'remove':
                    print('🔄 DEBUG Popup onSelected - Ejecutando remove');
                    _removeUserFromUnit(user.id, unitNumber);
                    Navigator.of(context).pop();
                    break;
                  case 'change_role':
                    print('🔄 DEBUG Popup onSelected - Ejecutando change_role');
                    Navigator.of(context).pop(); // Cerrar popup primero
                    _showChangeRoleDialog(user); // Luego mostrar diálogo
                    break;
                  case 'change_password':
                    print('🔄 DEBUG Popup onSelected - Ejecutando change_password');
                    Navigator.of(context).pop(); // Cerrar popup primero
                    _showChangePasswordDialog(user); // Luego mostrar diálogo
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person_remove,
                          color: Color(0xFFD32F2F),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Remover de la casa',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (user.role == UserRole.residente)
                  PopupMenuItem(
                    value: 'change_role',
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E5F5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings,
                            color: Color(0xFF9C27B0),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Promover a administrador',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'change_password',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.lock_reset,
                          color: Color(0xFF1976D2),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Cambiar contraseña',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
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
    );
  }

  // Construir tarjeta de usuario disponible para agregar
  Widget _buildAvailableUserCard(User user, String unitNumber) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0).withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getUserAvatarColor(user.name).withValues(alpha: 0.1),
          child: Text(
            user.name[0].toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF1A237E),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            Text('Tel: ${user.phoneNumber}'),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: const Color(0xFF1A237E).withValues(alpha: 0.6),
          size: 16,
        ),
        onTap: () {
          Navigator.of(context).pop();
          _assignUserToUnit(user.id, unitNumber);
        },
      ),
    );
  }

  // Obtener color para el avatar del usuario
  Color _getUserAvatarColor(String name) {
    final colors = [
      const Color(0xFF1A237E), // Azul oscuro
      const Color(0xFF0D47A1), // Azul
      const Color(0xFF1565C0), // Azul medio
      const Color(0xFF1976D2), // Azul claro
      const Color(0xFF388E3C), // Verde
      const Color(0xFF2E7D32), // Verde oscuro
      const Color(0xFF7B1FA2), // Púrpura
      const Color(0xFF6A1B9A), // Púrpura oscuro
      const Color(0xFFC62828), // Rojo
      const Color(0xFFD84315), // Naranja
    ];

    // Usar el hash del nombre para seleccionar un color consistente
    final hash = name.hashCode;
    return colors[hash.abs() % colors.length];
  }

  // Obtener color para el rol del usuario
  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return const Color(0xFFD32F2F); // Rojo
      case UserRole.administrador:
        return const Color(0xFF9C27B0); // Púrpura
      case UserRole.residente:
        return const Color(0xFF1A237E); // Azul
      default:
        return const Color(0xFF666666); // Gris
    }
  }

  // Obtener texto para el rol del usuario
  String _getRoleText(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.administrador:
        return 'Administrador';
      case UserRole.residente:
        return 'Residente';
      default:
        return 'Usuario';
    }
  }

  // Mostrar diálogo unificado para agregar/crear usuario a una casa
  // Permite a administradores y super admins crear usuarios
  // Los residentes solo pueden asignar usuarios existentes
  Future<void> _showUnifiedUserDialog(String unitNumber) async {
    // Verificar que la casa realmente esté libre
    final assignedUsers =
        _users.where((user) => user.communityId == widget.community.id && user.house == unitNumber).toList();

    if (assignedUsers.isNotEmpty) {
      print('⚠️ ERROR: Se intentó abrir _showUnifiedUserDialog para una casa ocupada: $unitNumber');
      print('👥 Usuarios asignados: ${assignedUsers.map((u) => '${u.name} (${u.house})').join(', ')}');
      // En lugar de mostrar el modal, ir directamente a gestionar usuarios
      _showManageUnitUsersDialog(unitNumber, assignedUsers);
      return;
    }

    print('✅ Casa $unitNumber está libre, mostrando modal para agregar usuario');

    // Obtener el usuario actual para verificar permisos
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;

    // Verificar si el usuario actual puede crear usuarios
    final canCreateUsers = currentUser?.isSuperAdmin == true || currentUser?.role == UserRole.administrador;

    // Obtener usuarios disponibles (sin casa asignada)
    final availableUsers = _users
        .where(
            (user) => user.communityId == widget.community.id && user.house == null && user.role == UserRole.residente)
        .toList();

    // Controllers para crear usuario
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    bool isCreatingUser = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.95,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Color(0xFFE0E0E0),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isCreatingUser ? Icons.person_add : Icons.person_add,
                          color: const Color(0xFF4CAF50),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    isCreatingUser ? 'Crear Nuevo Usuario' : 'Agregar Usuario',
                                    style: AppTextStyles.heading1,
                                  ),
                                ),
                                if (isCreatingUser && availableUsers.isNotEmpty) ...[
                                  TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        isCreatingUser = false;
                                      });
                                    },
                                    icon: const Icon(Icons.arrow_back, size: 16),
                                    label: const Text('Volver'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF2196F3),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (!isCreatingUser && canCreateUsers) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: currentUser?.isSuperAdmin == true
                                      ? const Color(0xFFD32F2F).withValues(alpha: 0.1)
                                      : const Color(0xFF9C27B0).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: currentUser?.isSuperAdmin == true
                                        ? const Color(0xFFD32F2F)
                                        : const Color(0xFF9C27B0),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  currentUser?.isSuperAdmin == true ? 'Super Admin' : 'Administrador',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: currentUser?.isSuperAdmin == true
                                        ? const Color(0xFFD32F2F)
                                        : const Color(0xFF9C27B0),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              'Casa $unitNumber',
                              style: AppTextStyles.subtitle2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Contenido
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        if (!isCreatingUser) ...[
                          // Información sobre usuarios disponibles
                          // Solo mostrar la sección de información cuando hay usuarios disponibles
                          if (availableUsers.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2196F3),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Icon(Icons.info_outline, color: Colors.white, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Usuarios Disponibles',
                                          style: AppTextStyles.infoText.copyWith(fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Selecciona un usuario para asignar a esta casa:',
                                          style: AppTextStyles.infoText,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          const SizedBox(height: 20),

                          // Lista de usuarios disponibles
                          if (availableUsers.isNotEmpty) ...[
                            ...availableUsers.map((user) => _buildAvailableUserCard(user, unitNumber)),
                            const SizedBox(height: 16),

                            // Botón para alternar a modo crear usuario
                            if (canCreateUsers) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E8),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF4CAF50),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: const Icon(
                                            Icons.person_add,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            '¿Quieres crear un usuario nuevo?',
                                            style: AppTextStyles.infoText.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF2E7D32),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            isCreatingUser = true;
                                          });
                                        },
                                        icon: const Icon(Icons.person_add, color: Colors.white),
                                        label: const Text(
                                          'Crear Nuevo Usuario',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF4CAF50),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ] else if (canCreateUsers) ...[
                            // Si no hay usuarios disponibles pero el usuario puede crear, mostrar botón para crear
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E8),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4CAF50),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Icon(
                                          Icons.info_outline,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'No hay usuarios disponibles para asignar',
                                          style: AppTextStyles.infoText.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF2E7D32),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          isCreatingUser = true;
                                        });
                                      },
                                      icon: const Icon(Icons.person_add, color: Colors.white),
                                      label: const Text(
                                        'Crear Nuevo Usuario',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF4CAF50),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ] else ...[
                            // Usuario sin permisos para crear
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF9800),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Icon(
                                      Icons.info_outline,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Para crear nuevos usuarios, contacta a un administrador o super administrador de la comunidad.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: const Color(0xFFE65100),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ] else if (canCreateUsers && availableUsers.isEmpty) ...[
                          // Formulario para crear usuario cuando no hay usuarios disponibles
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E8),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4CAF50),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.info_outline,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Se creará un nuevo usuario y se asignará automáticamente a la Casa $unitNumber',
                                    style: AppTextStyles.successText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          Form(
                            key: formKey,
                            child: Column(
                              children: [
                                // Campo Nombre
                                TextFormField(
                                  controller: nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Nombre completo',
                                    hintText: 'Ingresa el nombre completo',
                                    prefixIcon: Container(
                                      margin: const EdgeInsets.all(8),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1A237E).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.person_outline,
                                        color: Color(0xFF1A237E),
                                        size: 20,
                                      ),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'El nombre es requerido';
                                    }
                                    if (value.trim().length < 2) {
                                      return 'El nombre debe tener al menos 2 caracteres';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Campo Email
                                TextFormField(
                                  controller: emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    labelText: 'Correo electrónico',
                                    hintText: 'ejemplo@email.com',
                                    prefixIcon: Container(
                                      margin: const EdgeInsets.all(8),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1A237E).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.email_outlined,
                                        color: Color(0xFF1A237E),
                                        size: 20,
                                      ),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'El email es requerido';
                                    }
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                      return 'Ingresa un email válido';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Campo Teléfono
                                TextFormField(
                                  controller: phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    labelText: 'Número de teléfono',
                                    hintText: '6671234567',
                                    prefixIcon: Container(
                                      margin: const EdgeInsets.all(8),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1A237E).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.phone_outlined,
                                        color: Color(0xFF1A237E),
                                        size: 20,
                                      ),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'El teléfono es requerido';
                                    }
                                    if (value.trim().length < 10) {
                                      return 'El teléfono debe tener al menos 10 dígitos';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Campo Contraseña
                                TextFormField(
                                  controller: passwordController,
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    labelText: 'Contraseña',
                                    hintText: 'Mínimo 6 caracteres',
                                    prefixIcon: Container(
                                      margin: const EdgeInsets.all(8),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1A237E).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.lock_outline,
                                        color: Color(0xFF1A237E),
                                        size: 20,
                                      ),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'La contraseña es requerida';
                                    }
                                    if (value.trim().length < 6) {
                                      return 'La contraseña debe tener al menos 6 caracteres';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Botones de acción
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Color(0xFFE0E0E0),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (isCreatingUser)
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                isCreatingUser = false;
                              });
                            },
                            child: Text(
                              'Volver',
                              style: AppTextStyles.bodyLarge,
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              'Cancelar',
                              style: AppTextStyles.bodyLarge,
                            ),
                          ),
                        ),
                      const SizedBox(width: 16),
                      if (!isCreatingUser && availableUsers.isEmpty && canCreateUsers)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                isCreatingUser = true;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2196F3),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text(
                              'Crear',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      if (isCreatingUser)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                try {
                                  // Mostrar indicador de carga
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );

                                  // Crear el usuario
                                  final userService = Provider.of<UserService>(context, listen: false);
                                  final userData = {
                                    'name': nameController.text.trim(),
                                    'email': emailController.text.trim(),
                                    'phoneNumber': phoneController.text.trim(),
                                    'password': passwordController.text,
                                    'role': 'residente',
                                    'communityId': widget.community.id,
                                    'house': unitNumber,
                                  };

                                  final result = await userService.createUser(userData);
                                  final success = result['success'] == true;

                                  // Cerrar indicador de carga
                                  Navigator.of(context).pop();

                                  if (success) {
                                    // Cerrar diálogo de creación
                                    Navigator.of(context).pop();

                                    // Mostrar mensaje de éxito
                                    final successMessage = result['message'] ?? 'Usuario creado exitosamente en la Casa $unitNumber';
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(successMessage),
                                        backgroundColor: Colors.green,
                                      ),
                                    );

                                    // Recargar datos de la comunidad
                                    _loadCommunityData();
                                  } else {
                                    // Mostrar mensaje de error específico
                                    final errorMessage = result['message'] ?? 'Error al crear el usuario. Intenta nuevamente.';
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(errorMessage),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  // Cerrar indicador de carga
                                  Navigator.of(context).pop();

                                  // Mostrar mensaje de error
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9C27B0),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            icon: const Icon(Icons.person_add, size: 18),
                            label: const Text(
                              'Crear',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
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

  // Asignar usuario existente a una casa
  Future<void> _assignUserToUnit(String userId, String unitNumber) async {
    try {
      final userService = Provider.of<UserService>(context, listen: false);
      final result = await userService.assignUserToCommunity(userId, widget.community.id, unitNumber);

      if (result['success']) {
        if (mounted) {
          // Obtener el nombre del usuario para mostrar en el mensaje
          final user = userService.getUserById(userId);
          final userName = user?.name ?? 'Usuario';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('$userName asignado exitosamente a la casa $unitNumber'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );

          // Recargar datos para mostrar la actualización
          await _loadCommunityData();
        }
      } else {
        if (mounted) {
          String errorMessage = result['message'] ?? 'Error desconocido al asignar usuario';

          // Mapear errores específicos
          if (errorMessage.contains('no encontrado')) {
            errorMessage = '❌ Usuario no encontrado en el sistema';
          } else if (errorMessage.contains('ya asignado')) {
            errorMessage = '❌ El usuario ya está asignado a otra casa';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(errorMessage)),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Error de conexión: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // Cambiar usuario en una casa
  Future<void> _changeUserInUnit(String oldUserId, String newUserId, String unitNumber) async {
    try {
      final userService = Provider.of<UserService>(context, listen: false);

      // Primero liberar la casa del usuario anterior
      await userService.removeUserFromCommunity(oldUserId);

      // Luego asignar el nuevo usuario
      final result = await userService.assignUserToCommunity(newUserId, widget.community.id, unitNumber);

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Usuario cambiado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          _loadCommunityData(); // Recargar datos
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Error al cambiar usuario'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Remover usuario de una casa
  Future<void> _removeUserFromUnit(String userId, String unitNumber) async {
    try {
      final userService = Provider.of<UserService>(context, listen: false);
      final result = await userService.removeUserFromCommunity(userId);

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Casa liberada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          _loadCommunityData(); // Recargar datos
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Error al liberar casa'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Crear y asignar nuevo usuario
  Future<void> _createAndAssignUser(String name, String email, String phone, String password, String unitNumber) async {
    try {
      final userService = Provider.of<UserService>(context, listen: false);

      // Debug: Mostrar datos que se van a enviar
      final userData = {
        'name': name,
        'email': email,
        'phoneNumber': phone,
        'password': password,
        'role': 'residente',
        'communityId': widget.community.id,
        'house': unitNumber,
        'isActive': true,
      };

      print('🔍 DEBUG _createAndAssignUser - Datos a enviar: $userData');
      print('🔍 DEBUG _createAndAssignUser - Community ID: ${widget.community.id}');
      print('🔍 DEBUG _createAndAssignUser - House Number: $unitNumber');

      // Crear el usuario
      final createResult = await userService.createUser(userData);

      if (createResult['success']) {
        if (mounted) {
          // Mostrar mensaje de éxito
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Usuario "$name" creado y asignado exitosamente a la casa $unitNumber',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Ver',
                textColor: Colors.white,
                onPressed: () {
                  // Cambiar a la pestaña de usuarios para mostrar el nuevo usuario
                  _tabController.animateTo(2); // Pestaña de usuarios
                },
              ),
            ),
          );

          // Recargar datos para mostrar el nuevo usuario
          await _loadCommunityData();
        }
      } else {
        if (mounted) {
          // Mostrar mensaje de error específico
          String errorMessage = createResult['message'] ?? 'Error desconocido al crear usuario';

          // Mapear errores específicos a mensajes más amigables
          if (errorMessage.contains('email ya está registrado')) {
            errorMessage = '❌ El email "$email" ya está registrado en el sistema';
          } else if (errorMessage.contains('número de teléfono ya está registrado')) {
            errorMessage = '❌ El teléfono "$phone" ya está registrado en el sistema';
          } else if (errorMessage.contains('Datos de entrada inválidos')) {
            errorMessage = '❌ Los datos ingresados no son válidos. Verifica la información.';
          } else if (errorMessage.contains('Error del servidor')) {
            errorMessage = '❌ Error del servidor. Intenta nuevamente.';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(errorMessage)),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 6),
              action: SnackBarAction(
                label: 'Reintentar',
                textColor: Colors.white,
                onPressed: () {
                  // Mostrar nuevamente el diálogo de creación
                  _showUnifiedUserDialog(unitNumber);
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Error de conexión: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.white,
              onPressed: () {
                // Mostrar nuevamente el diálogo de creación
                _showUnifiedUserDialog(unitNumber);
              },
            ),
          ),
        );
      }
    }
  }

  // Mostrar diálogo para gestionar usuarios de una casa
  Future<void> _showManageUnitUsersDialog(String unitNumber, List<User> assignedUsers) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.95,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Título
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0xFFE0E0E0),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A237E).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.people,
                        color: Color(0xFF1A237E),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gestionar Usuarios',
                            style: AppTextStyles.heading1,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Casa $unitNumber',
                            style: AppTextStyles.subtitle2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Contenido
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Información de usuarios asignados
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.info_outline,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Usuarios actualmente asignados a esta casa:',
                                style: AppTextStyles.successText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Lista de usuarios
                      if (assignedUsers.isNotEmpty) ...[
                        ...assignedUsers.map((user) => _buildUserCard(user, unitNumber)),
                        const SizedBox(height: 16),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFE0E0E0),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 48,
                                color: const Color(0xFF9E9E9E),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No hay usuarios asignados',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF666666),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Esta casa está disponible para asignar usuarios',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: const Color(0xFF9E9E9E),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),

              // Botones de acción
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Color(0xFFE0E0E0),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cerrar',
                        style: AppTextStyles.bodyLarge,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Cerrar este modal y abrir directamente el formulario de creación
                        Navigator.of(context).pop();
                        _showCreateUserForm(unitNumber);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.person_add, size: 20),
                      label: Text(
                        'Agregar Usuario',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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
    );
  }

  // Mostrar formulario directo para crear usuario
  Future<void> _showCreateUserForm(String unitNumber) async {
    // Obtener el usuario actual para verificar permisos
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;

    // Verificar si el usuario actual puede crear usuarios
    final canCreateUsers = currentUser?.isSuperAdmin == true || currentUser?.role == UserRole.administrador;

    if (!canCreateUsers) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes permisos para crear usuarios'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Controllers para crear usuario
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.95,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Color(0xFFE0E0E0),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person_add,
                          color: Color(0xFF4CAF50),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Crear Nuevo Usuario',
                              style: AppTextStyles.heading1,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: currentUser?.isSuperAdmin == true
                                    ? const Color(0xFFD32F2F).withValues(alpha: 0.1)
                                    : const Color(0xFF9C27B0).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: currentUser?.isSuperAdmin == true
                                      ? const Color(0xFFD32F2F)
                                      : const Color(0xFF9C27B0),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                currentUser?.isSuperAdmin == true ? 'Super Admin' : 'Administrador',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: currentUser?.isSuperAdmin == true
                                      ? const Color(0xFFD32F2F)
                                      : const Color(0xFF9C27B0),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Casa $unitNumber',
                              style: AppTextStyles.subtitle2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Formulario
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nombre
                          TextFormField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre completo',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'El nombre es requerido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Email
                          TextFormField(
                            controller: emailController,
                            decoration: const InputDecoration(
                              labelText: 'Correo electrónico',
                              prefixIcon: Icon(Icons.email),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'El email es requerido';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                return 'Ingresa un email válido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Teléfono
                          TextFormField(
                            controller: phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Teléfono',
                              prefixIcon: Icon(Icons.phone),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'El teléfono es requerido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Contraseña
                          TextFormField(
                            controller: passwordController,
                            decoration: const InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: Icon(Icons.lock),
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'La contraseña es requerida';
                              }
                              if (value.length < 6) {
                                return 'La contraseña debe tener al menos 6 caracteres';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Botones
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cancelar'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    if (formKey.currentState!.validate()) {
                                      await _createAndAssignUser(
                                        nameController.text.trim(),
                                        emailController.text.trim(),
                                        phoneController.text.trim(),
                                        passwordController.text,
                                        unitNumber,
                                      );
                                      Navigator.of(context).pop();
                                    }
                                  },
                                  icon: const Icon(Icons.person_add),
                                  label: const Text('Crear Usuario'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4CAF50),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Mostrar diálogo para cambiar rol de usuario
  Future<void> _showChangeRoleDialog(User user) async {
    print('🔄 DEBUG _showChangeRoleDialog - Iniciando diálogo para usuario: ${user.name}');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.admin_panel_settings, color: const Color(0xFF9C27B0)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Promover a Administrador',
                style: const TextStyle(fontSize: 20), // Reducir tamaño de fuente
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de que quieres promover a "${user.name}" a administrador?',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF9C27B0).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF9C27B0).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: const Color(0xFF9C27B0), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Los administradores pueden gestionar la comunidad, ver reportes y administrar otros usuarios.',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF9C27B0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              await _promoteUserToAdmin(user);
            },
            icon: const Icon(Icons.admin_panel_settings),
            label: const Text('Promover'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9C27B0),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Promover usuario a administrador
  Future<void> _promoteUserToAdmin(User user) async {
    try {
      print('🔄 DEBUG _promoteUserToAdmin - Iniciando promoción de usuario: ${user.name} (ID: ${user.id})');
      print('🔄 DEBUG _promoteUserToAdmin - Rol actual: ${user.role}');

      final userService = Provider.of<UserService>(context, listen: false);
      print('🔄 DEBUG _promoteUserToAdmin - UserService obtenido correctamente');

      print('🔄 DEBUG _promoteUserToAdmin - Llamando a changeUserRole...');
      final result = await userService.changeUserRole(user.id, UserRole.administrador);
      print('🔄 DEBUG _promoteUserToAdmin - Resultado de changeUserRole: $result');

      if (result['success']) {
        // IMPORTANTE: También asignar el usuario a la comunidad
        final communityService = Provider.of<CommunityService>(context, listen: false);
        print('🔄 DEBUG _promoteUserToAdmin - Asignando usuario a la comunidad...');
        await communityService.addAdminToCommunity(widget.community.id, user.id);
        print('🔄 DEBUG _promoteUserToAdmin - Usuario asignado a la comunidad correctamente');
        print('🔄 DEBUG _promoteUserToAdmin - Promoción exitosa, mostrando SnackBar...');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('${user.name} promovido a administrador exitosamente'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );

          // Recargar datos para mostrar la actualización
          print('🔄 DEBUG _promoteUserToAdmin - Recargando datos de la comunidad...');
          await _loadCommunityData();
          print('�� DEBUG _promoteUserToAdmin - Datos recargados correctamente');
        }
      } else {
        print('🔄 DEBUG _promoteUserToAdmin - Promoción fallida: ${result['message']}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(result['message'] ?? 'Error al promover usuario'),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      print('🔄 DEBUG _promoteUserToAdmin - Excepción capturada: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Error: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // Mostrar diálogo para convertir administrador a residente
  Future<void> _showDemoteToResidentDialog(User user) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.person, color: const Color(0xFF4CAF50)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Convertir a Residente',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de que quieres convertir a "${user.name}" en residente?',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: const Color(0xFF4CAF50), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'El usuario perderá sus privilegios de administrador y solo podrá gestionar su propia información.',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              await _demoteAdminToResident(user);
            },
            icon: const Icon(Icons.person),
            label: const Text('Convertir'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Convertir administrador a residente
  Future<void> _demoteAdminToResident(User user) async {
    try {
      final userService = Provider.of<UserService>(context, listen: false);
      final result = await userService.changeUserRole(user.id, UserRole.residente);

      if (result['success']) {
        // IMPORTANTE: También remover el usuario de la comunidad
        final communityService = Provider.of<CommunityService>(context, listen: false);
        await communityService.removeAdminFromCommunity(widget.community.id, user.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('${user.name} convertido a residente exitosamente'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );

          // Recargar datos para mostrar la actualización
          await _loadCommunityData();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(result['message'] ?? 'Error al convertir usuario'),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Error: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // Mostrar diálogo para cambiar contraseña
  Future<void> _showChangePasswordDialog(User user) async {
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    bool isObscured = true;
    bool isConfirmObscured = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.lock_reset, color: const Color(0xFF1976D2)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cambiar Contraseña',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cambiar contraseña de "${user.name}"',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              
              // Campo de nueva contraseña
              TextField(
                controller: passwordController,
                obscureText: isObscured,
                decoration: InputDecoration(
                  labelText: 'Nueva contraseña',
                  hintText: 'Ingrese la nueva contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isObscured ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        isObscured = !isObscured;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Campo de confirmar contraseña
              TextField(
                controller: confirmPasswordController,
                obscureText: isConfirmObscured,
                decoration: InputDecoration(
                  labelText: 'Confirmar contraseña',
                  hintText: 'Confirme la nueva contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isConfirmObscured ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        isConfirmObscured = !isConfirmObscured;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Información sobre los requisitos
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF1976D2).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: const Color(0xFF1976D2), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'La contraseña debe tener al menos 6 caracteres.',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF1976D2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final newPassword = passwordController.text.trim();
                final confirmPassword = confirmPasswordController.text.trim();

                // Validaciones
                if (newPassword.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor ingrese una contraseña'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (newPassword.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('La contraseña debe tener al menos 6 caracteres'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (newPassword != confirmPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Las contraseñas no coinciden'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.of(context).pop();
                await _changeUserPassword(user, newPassword);
              },
              icon: const Icon(Icons.lock_reset),
              label: const Text('Cambiar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Cambiar contraseña de usuario
  Future<void> _changeUserPassword(User user, String newPassword) async {
    try {
      final userService = Provider.of<UserService>(context, listen: false);
      
      final result = await userService.changeUserPassword(user.id, newPassword);

      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Contraseña de ${user.name} actualizada exitosamente'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(result['message'] ?? 'Error al cambiar contraseña'),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Error: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
