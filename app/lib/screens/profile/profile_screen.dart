import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/blog_service.dart';
import '../../services/survey_service.dart';
import '../../services/expense_service.dart';
import '../../services/community_service.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditingProfile = false;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _houseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Cargar datos del usuario cuando se inicializa
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recargar datos cuando cambien las dependencias (AuthService)
    print('🔄 DEBUG didChangeDependencies - Recargando datos...');
    _loadUserData();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('🔄 DEBUG didUpdateWidget - Recargando datos...');
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _houseController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    print('🔍 DEBUG _loadUserData - User: ${user?.name}, Casa: ${user?.house}, Role: ${user?.role}');
    if (user != null) {
      print('✅ DEBUG _loadUserData - Usuario encontrado, forzando rebuild...');
      // Forzar rebuild del widget para que se llenen los controladores en _buildProfileForm
      if (mounted) {
        setState(() {});
      }
    } else {
      print('❌ DEBUG _loadUserData - Usuario es null');
    }
  }

  Future<void> _refreshUserData() async {
    print('🔄 DEBUG _refreshUserData - Iniciando refresh...');

    try {
      // Forzar recarga del usuario desde la API
      final authService = Provider.of<AuthService>(context, listen: false);
      final success = await authService.refreshCurrentUser();

      if (success) {
        print('✅ DEBUG _refreshUserData - Refresh completado exitosamente');
        // Verificar que el usuario se haya actualizado
        final updatedUser = authService.currentUser;
        print('✅ DEBUG _refreshUserData - Usuario actualizado: ${updatedUser?.name}, Casa: ${updatedUser?.house}');
        
        // Forzar rebuild del widget con los datos actualizados
        if (mounted) {
          setState(() {});
        }
      } else {
        print('❌ DEBUG _refreshUserData - Refresh falló');
      }
    } catch (e) {
      print('💥 DEBUG _refreshUserData - Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    print('🏗️ DEBUG build - User: ${user?.name}, Casa: ${user?.house}, Role: ${user?.role}');

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: Color(0xFF2196F3),
            ),
            onPressed: _refreshUserData,
          ),
          IconButton(
            icon: const FaIcon(
              FontAwesomeIcons.gear,
              size: 20,
              color: Color(0xFF2196F3),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildProfileHeader(user),
                const SizedBox(height: 24),
                _buildProfileForm(user),
                const SizedBox(height: 24),
                _buildStatsCards(user),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildEditFAB(),
    );
  }

  Widget _buildEditFAB() {
    if (_isEditingProfile) {
      // Durante la edición, mostrar botones de guardar y cancelar
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "cancel",
            onPressed: _cancelEdit,
            backgroundColor: Colors.grey[600],
            child: const FaIcon(
              FontAwesomeIcons.xmark,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: "save",
            onPressed: _saveProfile,
            backgroundColor: const Color(0xFF4CAF50),
            child: const FaIcon(
              FontAwesomeIcons.check,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      );
    } else {
      // Cuando no está editando, mostrar botón de editar
      return FloatingActionButton(
        onPressed: _startEdit,
        backgroundColor: const Color(0xFF2196F3),
        child: const FaIcon(
          FontAwesomeIcons.pen,
          color: Colors.white,
          size: 20,
        ),
      );
    }
  }

  void _startEdit() {
    setState(() {
      _isEditingProfile = true;
    });
    // Mostrar mensaje informativo
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Modo de edición activado. Modifica los campos y guarda los cambios.'),
        backgroundColor: Color(0xFF2196F3),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _cancelEdit() {
    // Restaurar valores originales
    _forceUpdateControllers();

    setState(() {
      _isEditingProfile = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edición cancelada. Se restauraron los valores originales.'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _forceUpdateControllers() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
      _phoneController.text = user.phoneNumber;
      _houseController.text = user.house ?? '';

      print('🔄 DEBUG _forceUpdateControllers - Controladores actualizados:');
      print('   Nombre: "${_nameController.text}"');
      print('   Email: "${_emailController.text}"');
      print('   Teléfono: "${_phoneController.text}"');
      print('   Casa: "${_houseController.text}"');
      print('   User.house original: ${user.house}');
      print('   User.house es null: ${user.house == null}');
    }
  }

  Widget _buildProfileHeader(User user) {
    print('🏠 DEBUG _buildProfileHeader - User: ${user.name}, Casa: ${user.house}, Role: ${user.role}');
    print('🏠 DEBUG _buildProfileHeader - User object: $user');
    print('🏠 DEBUG _buildProfileHeader - User house type: ${user.house.runtimeType}');
    print('🏠 DEBUG _buildProfileHeader - User house value: "${user.house}"');
    return Container(
      padding: const EdgeInsets.all(24),
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
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF2196F3),
                  const Color(0xFF1976D2),
                ],
              ),
            ),
            child: Center(
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: user.role == UserRole.superAdmin
                  ? const Color(0xFFFFD700).withValues(alpha: 0.1)
                  : user.role == UserRole.administrador
                      ? const Color(0xFFFF5722).withValues(alpha: 0.1)
                      : const Color(0xFF4CAF50).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaIcon(
                  user.role == UserRole.superAdmin
                      ? FontAwesomeIcons.crown
                      : user.role == UserRole.administrador
                          ? FontAwesomeIcons.userTie
                          : FontAwesomeIcons.user,
                  size: 14,
                  color: user.role == UserRole.superAdmin
                      ? const Color(0xFFFFD700)
                      : user.role == UserRole.administrador
                          ? const Color(0xFFFF5722)
                          : const Color(0xFF4CAF50),
                ),
                const SizedBox(width: 6),
                Text(
                  user.role == UserRole.superAdmin
                      ? 'Super Admin'
                      : user.role == UserRole.administrador
                          ? 'Administrador'
                          : 'Residente',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: user.role == UserRole.superAdmin
                        ? const Color(0xFFFFD700)
                        : user.role == UserRole.administrador
                            ? const Color(0xFFFF5722)
                            : const Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FaIcon(
                  FontAwesomeIcons.building,
                  size: 18,
                  color: Color(0xFF2196F3),
                ),
                const SizedBox(width: 8),
                Text(
                  'Casa: ${user.house ?? 'No asignado'}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1A237E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm(User user) {
    print('🏗️ DEBUG _buildProfileForm - Iniciando construcción del formulario...');

    // Solo llenar los controladores si no están en modo edición o si están vacíos
    if (!_isEditingProfile || _nameController.text.isEmpty) {
      _nameController.text = user.name;
    }
    if (!_isEditingProfile || _emailController.text.isEmpty) {
      _emailController.text = user.email;
    }
    if (!_isEditingProfile || _phoneController.text.isEmpty) {
      _phoneController.text = user.phoneNumber;
    }
    if (!_isEditingProfile || _houseController.text.isEmpty) {
      _houseController.text = user.house ?? '';
    }

    print('📝 DEBUG _buildProfileForm - Controladores llenados:');
    print('   Nombre: "${_nameController.text}"');
    print('   Email: "${_emailController.text}"');
    print('   Teléfono: "${_phoneController.text}"');
    print('   Casa: "${_houseController.text}"');

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información Personal',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 20),
          _isEditingProfile
              ? _buildEditableField(
                  controller: _nameController,
                  label: 'Nombre completo',
                  icon: FontAwesomeIcons.user,
                  iconColor: const Color(0xFF2196F3),
                )
              : _buildInfoCard(
                  label: 'Nombre completo',
                  value: _nameController.text,
                  icon: FontAwesomeIcons.user,
                  iconColor: const Color(0xFF2196F3),
                ),
          const SizedBox(height: 16),
          _isEditingProfile
              ? _buildEditableField(
                  controller: _emailController,
                  label: 'Correo electrónico',
                  icon: FontAwesomeIcons.envelope,
                  iconColor: const Color(0xFF2196F3),
                )
              : _buildInfoCard(
                  label: 'Correo electrónico',
                  value: _emailController.text,
                  icon: FontAwesomeIcons.envelope,
                  iconColor: const Color(0xFF4CAF50),
                ),
          const SizedBox(height: 16),
          _buildInfoCard(
            label: 'Teléfono',
            value: _phoneController.text,
            icon: FontAwesomeIcons.phone,
            iconColor: const Color(0xFFFF9800),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            label: 'Casa',
            value: _houseController.text.isNotEmpty ? _houseController.text : 'No asignado',
            icon: FontAwesomeIcons.building,
            iconColor: const Color(0xFF9C27B0),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String label,
    required String value,
    required IconData icon,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (iconColor ?? const Color(0xFF2196F3)).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: FaIcon(
                icon,
                size: 20,
                color: iconColor ?? const Color(0xFF2196F3),
              ),
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
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1A237E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    Color? iconColor,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2196F3).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    (iconColor ?? const Color(0xFF2196F3)).withValues(alpha: 0.15),
                    (iconColor ?? const Color(0xFF2196F3)).withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: (iconColor ?? const Color(0xFF2196F3)).withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Center(
                child: FaIcon(
                  icon,
                  size: 22,
                  color: iconColor ?? const Color(0xFF2196F3),
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: controller,
                    keyboardType: keyboardType,
                    style: const TextStyle(
                      fontSize: 17,
                      color: Color(0xFF1A237E),
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.2,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 5),
                      isDense: true,
                      hintText: 'Introduce $label',
                      hintStyle: TextStyle(
                        fontSize: 17,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                    cursorColor: const Color(0xFF2196F3),
                    cursorWidth: 2,
                    cursorHeight: 22,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards(User user) {
    // Si es super admin, mostrar estadísticas del sistema
    if (user.role == UserRole.superAdmin) {
      return _buildSuperAdminStats();
    }

    // Para otros roles, mostrar estadísticas personales
    final blogService = Provider.of<BlogService>(context);
    final surveyService = Provider.of<SurveyService>(context);
    final expenseService = Provider.of<ExpenseService>(context);

    // Calculate dynamic statistics
    final userPosts = blogService.posts.where((post) => post.authorName == user.name).length;
    final userVotes = surveyService.surveys.where((survey) => survey.hasUserVoted(user.id)).length;
    final userExpenses = expenseService.expenses.where((expense) => expense.createdBy == user.id).length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Posts',
            value: userPosts.toString(),
            icon: FontAwesomeIcons.newspaper,
            color: const Color(0xFF2196F3),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Votos',
            value: userVotes.toString(),
            icon: FontAwesomeIcons.squarePollVertical,
            color: const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Gastos',
            value: userExpenses.toString(),
            icon: FontAwesomeIcons.receipt,
            color: const Color(0xFFFF9800),
          ),
        ),
      ],
    );
  }

  Widget _buildSuperAdminStats() {
    final communityService = Provider.of<CommunityService>(context);
    final userService = Provider.of<UserService>(context);

    // Obtener estadísticas reales del sistema
    final totalCommunities = communityService.communities.length;
    final totalHouses =
        communityService.communities.fold<int>(0, (sum, community) => sum + (community.totalHouses ?? 0));
    final totalUsers = userService.users.length;
    final totalAdmins = userService.users.where((user) => user.role == UserRole.administrador).length;
    final totalResidents = userService.users.where((user) => user.role == UserRole.residente).length;
    final activeUsers = userService.users.where((user) => user.isActive == true).length;

    // Si no hay datos, mostrar mensaje
    if (totalCommunities == 0 && totalUsers == 0) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            const FaIcon(
              FontAwesomeIcons.circleInfo,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay datos del sistema disponibles',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Usa el botón de refresh para cargar las estadísticas',
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Estadísticas del Sistema',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
            ),
            IconButton(
              onPressed: () {
                // Refresh de las estadísticas del sistema
                final communityService = Provider.of<CommunityService>(context, listen: false);
                final userService = Provider.of<UserService>(context, listen: false);
                communityService.refresh();
                userService.refresh();
                setState(() {});
              },
              icon: const FaIcon(
                FontAwesomeIcons.arrowsRotate,
                size: 16,
                color: Color(0xFF1A237E),
              ),
              tooltip: 'Actualizar estadísticas',
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Privadas',
                value: totalCommunities.toString(),
                icon: FontAwesomeIcons.building,
                color: const Color(0xFF2196F3),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Casas',
                value: totalHouses.toString(),
                icon: FontAwesomeIcons.house,
                color: const Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Usuarios',
                value: totalUsers.toString(),
                icon: FontAwesomeIcons.users,
                color: const Color(0xFFFF9800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Administradores',
                value: totalAdmins.toString(),
                icon: FontAwesomeIcons.userTie,
                color: const Color(0xFF9C27B0),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Residentes',
                value: totalResidents.toString(),
                icon: FontAwesomeIcons.user,
                color: const Color(0xFF607D8B),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Activos',
                value: activeUsers.toString(),
                icon: FontAwesomeIcons.circleCheck,
                color: const Color(0xFF4CAF50),
              ),
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
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: FaIcon(
                icon,
                size: 20,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 12),
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
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    // Validaciones
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre no puede estar vacío'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_emailController.text.trim().isEmpty || !_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Introduce un email válido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El teléfono no puede estar vacío'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validación básica del teléfono (solo números y algunos caracteres permitidos)
    final phoneRegex = RegExp(r'^[0-9+\-\s\(\)]+$');
    if (!phoneRegex.hasMatch(_phoneController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Introduce un número de teléfono válido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Mostrar loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 16),
            Text('Guardando cambios...'),
          ],
        ),
        backgroundColor: Color(0xFF2196F3),
        duration: Duration(seconds: 10),
      ),
    );

    final authService = Provider.of<AuthService>(context, listen: false);

    print('💾 DEBUG _saveProfile - Guardando perfil:');
    print('   Nombre: ${_nameController.text}');
    print('   Email: ${_emailController.text}');
    print('   Teléfono: ${_phoneController.text}');
    print('   Casa: "${_houseController.text}"');
    print('   Casa isEmpty: ${_houseController.text.trim().isEmpty}');
    print('   Casa a enviar: ${_houseController.text.trim().isNotEmpty ? _houseController.text.trim() : "NULL"}');

    final success = await authService.updateProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      house: _houseController.text.trim().isNotEmpty ? _houseController.text.trim() : null,
    );

    // Ocultar loading
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 16),
              Text('Perfil actualizado exitosamente'),
            ],
          ),
          backgroundColor: Color(0xFF4CAF50),
          duration: Duration(seconds: 3),
        ),
      );
      setState(() => _isEditingProfile = false);
      // Forzar actualización de controladores después de guardar
      _forceUpdateControllers();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 16),
              Text('Error al actualizar el perfil'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}
