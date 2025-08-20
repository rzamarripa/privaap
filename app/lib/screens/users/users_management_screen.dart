import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({Key? key}) : super(key: key);

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final userService = Provider.of<UserService>(context, listen: false);
    await userService.refresh();

    // Cerrar indicador de carga
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userService = Provider.of<UserService>(context);

    // Verificar que sea super admin
    if (authService.currentUser?.isSuperAdmin != true) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Acceso Denegado'),
          backgroundColor: Colors.red,
        ),
        body: const Center(
          child: Text(
            'Solo los super administradores pueden acceder a esta pantalla',
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1A237E),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 20),
              _buildUserStats(userService),
              const SizedBox(height: 20),
              _buildUsersList(userService),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCreateUserDialog();
        },
        backgroundColor: const Color(0xFF4CAF50),
        heroTag: 'users_management_fab', // Tag único para evitar conflicto de Hero
        child: const FaIcon(FontAwesomeIcons.plus, color: Colors.white),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9C27B0).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
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
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.users,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestión de Usuarios',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Administra todos los usuarios del sistema',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
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
  }

  Widget _buildUserStats(UserService userService) {
    final totalUsers = userService.users.length;
    final activeUsers = userService.activeUsers.length;
    final admins = userService.getUsersByRole(UserRole.administrador).length;
    final residents = userService.getUsersByRole(UserRole.residente).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estadísticas de Usuarios',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildStatCard(
              title: 'Total Usuarios',
              value: totalUsers.toString(),
              icon: FontAwesomeIcons.users,
              color: const Color(0xFF2196F3),
              trend: 'Sistema',
            ),
            _buildStatCard(
              title: 'Usuarios Activos',
              value: activeUsers.toString(),
              icon: FontAwesomeIcons.checkCircle,
              color: const Color(0xFF4CAF50),
              trend: 'Activos',
            ),
            _buildStatCard(
              title: 'Administradores',
              value: admins.toString(),
              icon: FontAwesomeIcons.userShield,
              color: const Color(0xFF9C27B0),
              trend: 'Admins',
            ),
            _buildStatCard(
              title: 'Residentes',
              value: residents.toString(),
              icon: FontAwesomeIcons.user,
              color: const Color(0xFFFF9800),
              trend: 'Residentes',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FaIcon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const Spacer(),
              Text(
                trend,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(UserService userService) {
    final users = userService.users;

    if (users.isEmpty) {
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
              FontAwesomeIcons.users,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay usuarios registrados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Crea el primer usuario para comenzar',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                _showCreateUserDialog();
              },
              icon: const FaIcon(FontAwesomeIcons.plus),
              label: const Text('Crear Primer Usuario'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Usuarios Registrados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
            ),
            Text(
              '${users.length} usuarios',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return _buildUserCard(user);
          },
        ),
      ],
    );
  }

  Widget _buildUserCard(User user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _getRoleColor(user.role).withValues(alpha: 0.1),
                child: FaIcon(
                  _getRoleIcon(user.role),
                  color: _getRoleColor(user.role),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    Text(
                      user.email,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: user.isActive
                      ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                      : const Color(0xFFF44336).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: user.isActive
                        ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
                        : const Color(0xFFF44336).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  user.isActive ? 'Activo' : 'Inactivo',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: user.isActive ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getRoleColor(user.role).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getRoleColor(user.role).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _getRoleLabel(user.role),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _getRoleColor(user.role),
                  ),
                ),
              ),
              if (user.house != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Casa: ${user.house}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              // Si el ancho es menor a 400px, usar solo iconos
              if (constraints.maxWidth < 400) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      height: 36,
                      child: Tooltip(
                        message: 'Editar usuario',
                        child: OutlinedButton(
                          onPressed: () {
                            _showEditUserDialog(user);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2196F3),
                            side: const BorderSide(color: Color(0xFF2196F3)),
                            padding: const EdgeInsets.all(8),
                          ),
                          child: const FaIcon(FontAwesomeIcons.edit, size: 16),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 36,
                      child: Tooltip(
                        message: user.isActive ? 'Desactivar usuario' : 'Activar usuario',
                        child: OutlinedButton(
                          onPressed: () {
                            _toggleUserStatus(user);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: user.isActive ? const Color(0xFFFF9800) : const Color(0xFF4CAF50),
                            side: BorderSide(
                              color: user.isActive ? const Color(0xFFFF9800) : const Color(0xFF4CAF50),
                            ),
                            padding: const EdgeInsets.all(8),
                          ),
                          child: FaIcon(
                            user.isActive ? FontAwesomeIcons.ban : FontAwesomeIcons.check,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 36,
                      child: Tooltip(
                        message: 'Cambiar rol',
                        child: OutlinedButton(
                          onPressed: () {
                            _showChangeRoleDialog(user);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF9C27B0),
                            side: const BorderSide(color: Color(0xFF9C27B0)),
                            padding: const EdgeInsets.all(8),
                          ),
                          child: const FaIcon(FontAwesomeIcons.userCog, size: 16),
                        ),
                      ),
                    ),
                  ],
                );
              }

              // Para pantallas más grandes, usar iconos + texto
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    height: 36,
                    child: Tooltip(
                      message: 'Editar usuario',
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showEditUserDialog(user);
                        },
                        icon: const FaIcon(FontAwesomeIcons.edit, size: 14),
                        label: const Text('Editar', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2196F3),
                          side: const BorderSide(color: Color(0xFF2196F3)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 36,
                    child: Tooltip(
                      message: user.isActive ? 'Desactivar usuario' : 'Activar usuario',
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _toggleUserStatus(user);
                        },
                        icon: FaIcon(
                          user.isActive ? FontAwesomeIcons.ban : FontAwesomeIcons.check,
                          size: 14,
                        ),
                        label: Text(
                          user.isActive ? 'Desactivar' : 'Activar',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: user.isActive ? const Color(0xFFFF9800) : const Color(0xFF4CAF50),
                          side: BorderSide(
                            color: user.isActive ? const Color(0xFFFF9800) : const Color(0xFF4CAF50),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 36,
                    child: Tooltip(
                      message: 'Cambiar rol',
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showChangeRoleDialog(user);
                        },
                        icon: const FaIcon(FontAwesomeIcons.userCog, size: 14),
                        label: const Text('Rol', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF9C27B0),
                          side: const BorderSide(color: Color(0xFF9C27B0)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return const Color(0xFFFF9800);
      case UserRole.administrador:
        return const Color(0xFF9C27B0);
      case UserRole.residente:
        return const Color(0xFF2196F3);
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return FontAwesomeIcons.crown;
      case UserRole.administrador:
        return FontAwesomeIcons.userShield;
      case UserRole.residente:
        return FontAwesomeIcons.user;
    }
  }

  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.administrador:
        return 'Administrador';
      case UserRole.residente:
        return 'Residente';
    }
  }

  void _toggleUserStatus(User user) async {
    final userService = Provider.of<UserService>(context, listen: false);
    final newStatus = !user.isActive;

    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final result = await userService.toggleUserStatus(user.id, newStatus);

    // Cerrar indicador de carga
    if (mounted) {
      Navigator.pop(context);

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: const Color(0xFFF44336),
          ),
        );
      }
    }
  }

  void _showCreateUserDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final houseController = TextEditingController();
    UserRole selectedRole = UserRole.residente;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                const FaIcon(FontAwesomeIcons.plus, color: Color(0xFF4CAF50)),
                const SizedBox(width: 12),
                const Text('Crear Usuario'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: houseController,
                    decoration: const InputDecoration(
                      labelText: 'Casa/Habitación',
                      border: OutlineInputBorder(),
                      hintText: 'Opcional',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Rol del usuario:'),
                  const SizedBox(height: 8),
                  ...UserRole.values.where((role) => role != UserRole.superAdmin).map((role) => RadioListTile<UserRole>(
                        title: Text(_getRoleLabel(role)),
                        value: role,
                        groupValue: selectedRole,
                        onChanged: (UserRole? value) {
                          setState(() {
                            selectedRole = value!;
                          });
                        },
                      )),
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
                  if (nameController.text.trim().isEmpty ||
                      emailController.text.trim().isEmpty ||
                      phoneController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Por favor completa todos los campos obligatorios'),
                        backgroundColor: Color(0xFFFF9800),
                      ),
                    );
                    return;
                  }

                  if (!_isValidEmail(emailController.text.trim())) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Por favor ingresa un email válido'),
                        backgroundColor: Color(0xFFFF9800),
                      ),
                    );
                    return;
                  }

                  if (!_isValidPhone(phoneController.text.trim())) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Por favor ingresa un teléfono válido (mínimo 10 dígitos)'),
                        backgroundColor: Color(0xFFFF9800),
                      ),
                    );
                    return;
                  }

                  final result = await _createUser({
                    'name': nameController.text.trim(),
                    'email': emailController.text.trim(),
                    'phoneNumber': phoneController.text.trim(),
                    'house': houseController.text.trim().isEmpty ? null : houseController.text.trim(),
                    'role': selectedRole.toString().split('.').last,
                  });
                  
                  // Solo cerrar el modal si la operación fue exitosa
                  if (result['success']) {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Crear Usuario'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _createUser(Map<String, dynamic> userData) async {
    final userService = Provider.of<UserService>(context, listen: false);

    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final result = await userService.createUser(userData);

    // Cerrar indicador de carga
    if (mounted) {
      Navigator.pop(context);

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: const Color(0xFFF44336),
          ),
        );
      }
    }
    
    return result;
  }

  void _showEditUserDialog(User user) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final phoneController = TextEditingController(text: user.phoneNumber);
    final houseController = TextEditingController(text: user.house ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                const FaIcon(FontAwesomeIcons.edit, color: Color(0xFF2196F3)),
                const SizedBox(width: 12),
                const Text('Editar Usuario'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: houseController,
                    decoration: const InputDecoration(
                      labelText: 'Casa/Habitación',
                      border: OutlineInputBorder(),
                      hintText: 'Opcional',
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
                  if (nameController.text.trim().isEmpty ||
                      emailController.text.trim().isEmpty ||
                      phoneController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Por favor completa todos los campos obligatorios'),
                        backgroundColor: Color(0xFFFF9800),
                      ),
                    );
                    return;
                  }

                  if (!_isValidEmail(emailController.text.trim())) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Por favor ingresa un email válido'),
                        backgroundColor: Color(0xFFFF9800),
                      ),
                    );
                    return;
                  }

                  if (!_isValidPhone(phoneController.text.trim())) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Por favor ingresa un teléfono válido (mínimo 10 dígitos)'),
                        backgroundColor: Color(0xFFFF9800),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(context);
                  await _updateUser(user, {
                    'name': nameController.text.trim(),
                    'email': emailController.text.trim(),
                    'phoneNumber': phoneController.text.trim(),
                    'house': houseController.text.trim().isEmpty ? null : houseController.text.trim(),
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _updateUser(User user, Map<String, dynamic> updates) async {
    final userService = Provider.of<UserService>(context, listen: false);

    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final result = await userService.updateUser(user.id, updates);

    // Cerrar indicador de carga
    if (mounted) {
      Navigator.pop(context);

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: const Color(0xFFF44336),
          ),
        );
      }
    }
  }

  void _showChangeRoleDialog(User user) {
    UserRole selectedRole = user.role;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                const FaIcon(FontAwesomeIcons.userCog, color: Color(0xFF9C27B0)),
                const SizedBox(width: 12),
                const Text('Cambiar Rol'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Usuario: ${user.name}'),
                const SizedBox(height: 16),
                const Text('Selecciona el nuevo rol:'),
                const SizedBox(height: 16),
                ...UserRole.values.map((role) => RadioListTile<UserRole>(
                      title: Text(_getRoleLabel(role)),
                      value: role,
                      groupValue: selectedRole,
                      onChanged: (UserRole? value) {
                        setState(() {
                          selectedRole = value!;
                        });
                      },
                    )),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  if (selectedRole != user.role) {
                    await _changeUserRole(user, selectedRole);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9C27B0),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Cambiar Rol'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _changeUserRole(User user, UserRole newRole) async {
    final userService = Provider.of<UserService>(context, listen: false);

    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final result = await userService.changeUserRole(user.id, newRole);

    // Cerrar indicador de carga
    if (mounted) {
      Navigator.pop(context);

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: const Color(0xFFF44336),
          ),
        );
      }
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    return RegExp(r'^\+?[\d\s\-\(\)]+$').hasMatch(phone) && phone.replaceAll(RegExp(r'[\s\-\(\)]'), '').length >= 10;
  }
}
