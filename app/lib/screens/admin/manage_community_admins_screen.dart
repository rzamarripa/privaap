import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/community_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../services/community_service.dart';
import '../../utils/snackbar_utils.dart';

class ManageCommunityAdminsScreen extends StatefulWidget {
  final Community community;

  const ManageCommunityAdminsScreen({
    Key? key,
    required this.community,
  }) : super(key: key);

  @override
  State<ManageCommunityAdminsScreen> createState() => _ManageCommunityAdminsScreenState();
}

class _ManageCommunityAdminsScreenState extends State<ManageCommunityAdminsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _houseController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  List<User> _availableUsers = [];
  List<User> _currentAdmins = [];

  @override
  void initState() {
    super.initState();
    // Usar un delay mínimo para evitar problemas de setState durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissionsAndLoadData();
    });
  }

  Future<void> _checkPermissionsAndLoadData() async {
    // Verificar permisos antes de cargar datos
    if (!mounted) return;

    final authService = Provider.of<AuthService>(context, listen: false);

    if (authService.currentUser?.isSuperAdmin != true) {
      // Si no es super admin, mostrar error y regresar
      if (mounted) {
        SnackbarUtils.showErrorSnackBar(
          context,
          '❌ ACCESO DENEGADO: Solo los super administradores pueden gestionar administradores',
        );
        Navigator.of(context).pop();
        return;
      }
    }

    // Si tiene permisos, cargar datos
    await _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _houseController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userService = Provider.of<UserService>(context, listen: false);

      // Cargar usuarios disponibles (residentes que pueden ser promovidos a admin)
      await userService.loadUsers();

      if (!mounted) return;

      // Filtrar usuarios que pueden ser administradores
      _availableUsers = userService.users
          .where(
              (user) => user.role == UserRole.residente && user.communityId == null) // Usuarios sin comunidad asignada
          .toList();

      // Cargar administradores actuales de la comunidad
      _currentAdmins = userService.users
          .where((user) => user.role == UserRole.administrador && widget.community.adminIds.contains(user.id))
          .toList();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Administradores - ${widget.community.name}'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1A237E),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 20),
                  _buildCurrentAdminsSection(),
                  const SizedBox(height: 20),
                  _buildAddAdminSection(),
                  const SizedBox(height: 20),
                  _buildAvailableUsersSection(),
                ],
              ),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const FaIcon(
              FontAwesomeIcons.userShield,
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
                  'Administradores de ${widget.community.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gestiona los administradores de esta privada',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentAdminsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Administradores Actuales',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
            ),
            Text(
              '${_currentAdmins.length} admin${_currentAdmins.length != 1 ? 's' : ''}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_currentAdmins.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Column(
              children: [
                FaIcon(
                  FontAwesomeIcons.userShield,
                  size: 48,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No hay administradores asignados',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Agrega administradores para gestionar esta privada',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _currentAdmins.length,
            itemBuilder: (context, index) {
              final admin = _currentAdmins[index];
              return _buildAdminCard(admin);
            },
          ),
      ],
    );
  }

  Widget _buildAdminCard(User admin) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF9C27B0).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const FaIcon(
              FontAwesomeIcons.userShield,
              color: Color(0xFF9C27B0),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  admin.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A237E),
                  ),
                ),
                Text(
                  admin.email,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                if (admin.house != null)
                  Text(
                    'Casa: ${admin.house}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _removeAdmin(admin),
            icon: const FaIcon(
              FontAwesomeIcons.userMinus,
              color: Color(0xFFF44336),
              size: 20,
            ),
            tooltip: 'Remover como administrador',
          ),
        ],
      ),
    );
  }

  Widget _buildAddAdminSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Crear Nuevo Administrador',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E),
          ),
        ),
        const SizedBox(height: 16),
        Container(
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
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre *',
                          hintText: 'Nombre completo',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El nombre es obligatorio';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono *',
                          hintText: '10 dígitos',
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El teléfono es obligatorio';
                          }
                          if (value.length != 10) {
                            return 'El teléfono debe tener 10 dígitos';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email *',
                          hintText: 'correo@ejemplo.com',
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El email es obligatorio';
                          }
                          if (!value.contains('@')) {
                            return 'Ingrese un email válido';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _houseController,
                        decoration: const InputDecoration(
                          labelText: 'Casa',
                          hintText: 'Ej: A-101',
                          prefixIcon: Icon(Icons.home),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña *',
                    hintText: 'Mínimo 6 caracteres',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La contraseña es obligatoria';
                    }
                    if (value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _createAdmin,
                    icon: const FaIcon(FontAwesomeIcons.userPlus, size: 20),
                    label: const Text(
                      'Crear Administrador',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9C27B0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: const Color(0xFF9C27B0).withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableUsersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Usuarios Disponibles para Promover',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E),
          ),
        ),
        const SizedBox(height: 16),
        if (_availableUsers.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
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
                  'No hay usuarios disponibles',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Todos los usuarios ya están asignados a comunidades',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _availableUsers.length,
            itemBuilder: (context, index) {
              final user = _availableUsers[index];
              return _buildAvailableUserCard(user);
            },
          ),
      ],
    );
  }

  Widget _buildAvailableUserCard(User user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const FaIcon(
              FontAwesomeIcons.user,
              color: Color(0xFF4CAF50),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
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
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                if (user.house != null)
                  Text(
                    'Casa: ${user.house}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _promoteUserToAdmin(user),
            icon: const FaIcon(FontAwesomeIcons.arrowUp, size: 14),
            label: const Text(
              'Promover',
              style: TextStyle(fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createAdmin() async {
    if (!mounted) return;

    // Verificar que el formulario esté disponible antes de validar
    if (_formKey.currentState == null) {
      print('=== DEBUG: FormKey no disponible ===');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userService = Provider.of<UserService>(context, listen: false);

      // Preparar datos del usuario
      final userData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'password': _passwordController.text,
        'role': 'administrador',
        'house': _houseController.text.trim().isEmpty ? null : _houseController.text.trim(),
        'communityId': widget.community.id,
        'isActive': true,
        // NO enviar createdAt - la API lo genera automáticamente
      };

      // Debug: imprimir datos que se envían
      print('=== DEBUG: Datos enviados a la API ===');
      print('userData: $userData');
      print('=====================================');

      // Verificar que todos los controladores estén disponibles
      if (_nameController.text.isEmpty ||
          _emailController.text.isEmpty ||
          _phoneController.text.isEmpty ||
          _passwordController.text.isEmpty) {
        print('=== DEBUG: Error - Controllers vacíos ===');
        print('name: "${_nameController.text}"');
        print('email: "${_emailController.text}"');
        print('phone: "${_phoneController.text}"');
        print('password: "${_passwordController.text}"');
        return;
      }

      // Crear nuevo usuario administrador
      final result = await userService.createUser(userData);

      // Debug: imprimir respuesta
      print('=== DEBUG: Respuesta de la API ===');
      print('result: $result');
      print('==================================');

      if (!mounted) return;

      if (result['success']) {
        // Guardar el nombre del usuario antes de limpiar los controladores
        final userName = _nameController.text.trim();

        // Agregar a la comunidad
        final communityService = Provider.of<CommunityService>(context, listen: false);
        await communityService.addAdminToCommunity(widget.community.id, result['userId']);

        // Limpiar formulario
        if (_formKey.currentState != null) {
          _formKey.currentState!.reset();
        }
        _nameController.clear();
        _emailController.clear();
        _phoneController.clear();
        _houseController.clear();
        _passwordController.clear();

        // Recargar datos
        await _loadData();

        if (mounted) {
          SnackbarUtils.showSuccessSnackBar(
            context,
            '✅ ADMINISTRADOR CREADO: El administrador "$userName" ha sido creado exitosamente y asignado a la comunidad.',
          );
        }
      } else {
        if (mounted) {
          String errorMessage = result['message'] ?? 'Error desconocido';
          String errorTitle = 'Error al crear administrador';

          // Determinar el tipo de error para mostrar el título y mensaje apropiados
          if (errorMessage.contains('email ya está registrado')) {
            errorTitle = SnackbarUtils.createErrorTitle('email');
            errorMessage = SnackbarUtils.createValidationErrorMessage('email', _emailController.text.trim());
          } else if (errorMessage.contains('número de teléfono ya está registrado')) {
            errorTitle = SnackbarUtils.createErrorTitle('phone');
            errorMessage = SnackbarUtils.createValidationErrorMessage('phone', _phoneController.text.trim());
          } else if (errorMessage.contains('Datos inválidos enviados al servidor') ||
              errorMessage.contains('Los datos ingresados no son válidos')) {
            errorTitle = SnackbarUtils.createErrorTitle('validation');
            errorMessage =
                'Los datos ingresados no son válidos.\n\n💡 Verifica que todos los campos obligatorios estén completos y con el formato correcto.';
          } else if (errorMessage.contains('Error interno del servidor') ||
              errorMessage.contains('Error del servidor')) {
            errorTitle = SnackbarUtils.createErrorTitle('server');
            errorMessage =
                'Ha ocurrido un error interno en el servidor.\n\n💡 Intenta nuevamente o contacta al administrador del sistema.';
          } else if (errorMessage.contains('Error de conexión')) {
            errorTitle = SnackbarUtils.createErrorTitle('connection');
            errorMessage =
                'No se pudo conectar con el servidor.\n\n💡 Verifica tu conexión a internet e intenta nuevamente.';
          } else {
            errorTitle = SnackbarUtils.createErrorTitle('default');
            errorMessage = 'Error: $errorMessage\n\n💡 Intenta nuevamente o contacta al administrador del sistema.';
          }

          SnackbarUtils.showErrorSnackBar(
            context,
            '$errorTitle: $errorMessage',
          );
        }
      }
    } catch (e) {
      print('=== DEBUG: Error en _createAdmin ===');
      print('Error: $e');
      print('===================================');

      if (mounted) {
        SnackbarUtils.showErrorSnackBar(
          context,
          '❌ ERROR INESPERADO: Error al crear administrador: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Mostrar usuarios existentes
  Future<void> _showExistingUsers() async {
    try {
      final userService = Provider.of<UserService>(context, listen: false);
      await userService.loadUsers();

      if (!mounted) return;

      final users = userService.users;
      final existingEmails = users.map((u) => u.email).toList();
      final existingPhones = users.map((u) => u.phoneNumber).toList();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Usuarios Existentes'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Emails registrados:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...existingEmails.map((email) => Text('• $email')),
                const SizedBox(height: 16),
                const Text(
                  'Teléfonos registrados:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...existingPhones.map((phone) => Text('• $phone')),
                const SizedBox(height: 16),
                const Text(
                  '💡 Sugerencia: Usa un email y teléfono diferentes para crear el nuevo administrador.',
                  style: TextStyle(
                    color: Colors.blue,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar usuarios: $e'),
            backgroundColor: const Color(0xFFF44336),
          ),
        );
      }
    }
  }

  Future<void> _promoteUserToAdmin(User user) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userService = Provider.of<UserService>(context, listen: false);
      final communityService = Provider.of<CommunityService>(context, listen: false);

      // Cambiar rol a administrador
      final result = await userService.changeUserRole(user.id, UserRole.administrador);

      if (!mounted) return;

      if (result['success']) {
        // Asignar a la comunidad
        await communityService.addAdminToCommunity(widget.community.id, user.id);

        // Recargar datos
        await _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${user.name} promovido a administrador exitosamente'),
              backgroundColor: const Color(0xFF4CAF50),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al promover usuario: ${result['message'] ?? 'Error desconocido'}'),
              backgroundColor: const Color(0xFFF44336),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al promover usuario: $e'),
            backgroundColor: const Color(0xFFF44336),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeAdmin(User admin) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final communityService = Provider.of<CommunityService>(context, listen: false);

      // Remover de la comunidad
      final result = await communityService.removeAdminFromCommunity(widget.community.id, admin.id);

      if (!mounted) return;

      if (result['success']) {
        // Recargar datos
        await _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${admin.name} removido como administrador exitosamente'),
              backgroundColor: const Color(0xFF4CAF50),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al remover administrador: ${result['message'] ?? 'Error desconocido'}'),
              backgroundColor: const Color(0xFFF44336),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al remover administrador: $e'),
            backgroundColor: const Color(0xFFF44336),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
