import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/expense_service.dart';
import '../../services/biometric_service.dart';
import 'help_center_screen.dart';
import 'contact_support_screen.dart';
import 'my_tickets_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _biometricAuth = false;
  final BiometricService _biometricService = BiometricService();
  bool _isBiometricAvailable = false;
  String _biometricType = 'Biométrica';

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
    _loadBiometricSettings();
  }

  /// Verifica la disponibilidad de autenticación biométrica
  Future<void> _checkBiometricAvailability() async {
    final isAvailable = await _biometricService.isBiometricAvailable();
    final biometricType = await _biometricService.getBiometricType();

    if (mounted) {
      setState(() {
        _isBiometricAvailable = isAvailable;
        _biometricType = biometricType;
      });
    }
  }

  /// Carga la configuración de autenticación biométrica
  Future<void> _loadBiometricSettings() async {
    final isEnabled = await _biometricService.isBiometricEnabled();

    if (mounted) {
      setState(() {
        _biometricAuth = isEnabled;
      });
    }
  }

  /// Maneja el cambio en la autenticación biométrica
  Future<void> _onBiometricChanged(bool value) async {
    if (value) {
      // Habilitar autenticación biométrica
      final success = await _biometricService.setupBiometric();

      if (success) {
        setState(() {
          _biometricAuth = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Autenticación $_biometricType habilitada'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No se pudo habilitar la autenticación $_biometricType'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // Deshabilitar autenticación biométrica
      final success = await _biometricService.disableBiometric();

      if (success) {
        setState(() {
          _biometricAuth = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Autenticación $_biometricType deshabilitada'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Configuración'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 20, color: Color(0xFF2196F3)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSection(
              title: 'Notificaciones',
              icon: FontAwesomeIcons.bell,
              children: [
                _buildSwitchTile(
                  title: 'Notificaciones Push',
                  subtitle: 'Recibir notificaciones en el dispositivo',
                  value: _pushNotifications,
                  onChanged: (value) {
                    setState(() => _pushNotifications = value);
                  },
                  icon: FontAwesomeIcons.mobileScreen,
                ),
                _buildSwitchTile(
                  title: 'Notificaciones por Email',
                  subtitle: 'Recibir notificaciones por correo electrónico',
                  value: _emailNotifications,
                  onChanged: (value) {
                    setState(() => _emailNotifications = value);
                  },
                  icon: FontAwesomeIcons.envelope,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Seguridad',
              icon: FontAwesomeIcons.shield,
              children: [
                _buildSwitchTile(
                  title: 'Autenticación $_biometricType',
                  subtitle: _isBiometricAvailable
                      ? 'Usar $_biometricType para acceder a la aplicación'
                      : 'No disponible en este dispositivo',
                  value: _biometricAuth,
                  onChanged: _isBiometricAvailable ? (value) => _onBiometricChanged(value) : null,
                  icon: _biometricType == 'Face ID' ? FontAwesomeIcons.faceSmile : FontAwesomeIcons.fingerprint,
                ),
                if (_isBiometricAvailable && _biometricAuth) ...[
                  const SizedBox(height: 8),
                  _buildActionTile(
                    title: 'Probar $_biometricType',
                    subtitle: 'Verificar que la autenticación funcione correctamente',
                    icon: FontAwesomeIcons.circleCheck,
                    onTap: () => _testBiometricAuth(),
                  ),
                ],
                _buildActionTile(
                  title: 'Cambiar Contraseña',
                  subtitle: 'Actualizar contraseña de acceso',
                  icon: FontAwesomeIcons.key,
                  onTap: () => _showChangePasswordDialog(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Ayuda y Soporte',
              icon: FontAwesomeIcons.circleQuestion,
              children: [
                _buildActionTile(
                  title: 'Centro de Ayuda',
                  subtitle: 'Preguntas frecuentes y respuestas',
                  icon: FontAwesomeIcons.circleInfo,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HelpCenterScreen(),
                    ),
                  ),
                ),
                _buildActionTile(
                  title: 'Contactar Soporte',
                  subtitle: 'Enviar mensaje al equipo de soporte',
                  icon: FontAwesomeIcons.headset,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ContactSupportScreen(),
                      ),
                    );
                  },
                ),
                _buildActionTile(
                  title: 'Mis Tickets',
                  subtitle: 'Ver tickets de soporte enviados',
                  icon: FontAwesomeIcons.ticket,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyTicketsScreen(),
                      ),
                    );
                  },
                ),
                _buildActionTile(
                  title: 'Mensualidades',
                  subtitle: 'Consulta pagos pendientes y pagados',
                  icon: FontAwesomeIcons.pesoSign,
                  onTap: () => Navigator.pushNamed(context, '/monthly-fees'),
                ),
                _buildActionTile(
                  title: 'Acerca de',
                  subtitle: 'Información de la aplicación',
                  icon: FontAwesomeIcons.circleInfo,
                  onTap: () => _showAboutDialog(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Cuenta',
              icon: FontAwesomeIcons.userGear,
              children: [
                _buildActionTile(
                  title: 'Cerrar Sesión',
                  subtitle: 'Salir de la aplicación',
                  icon: FontAwesomeIcons.rightFromBracket,
                  onTap: () => _showLogoutDialog(),
                  isDestructive: true,
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Prueba la autenticación biométrica
  Future<void> _testBiometricAuth() async {
    try {
      final result = await _biometricService.authenticate();

      if (mounted) {
        if (result) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Autenticación $_biometricType exitosa'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
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
                    child: Text('Autenticación $_biometricType falló'),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al probar autenticación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                FaIcon(
                  icon,
                  size: 20,
                  color: const Color(0xFF2196F3),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    ValueChanged<bool>? onChanged,
    required IconData icon,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: FaIcon(
        icon,
        size: 20,
        color: Colors.grey[600],
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      trailing: onChanged != null
          ? Switch(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF2196F3),
              activeTrackColor: const Color(0xFF2196F3).withValues(alpha: 0.3),
              inactiveThumbColor: Colors.grey[400],
              inactiveTrackColor: Colors.grey[300],
            )
          : Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.block,
                color: Colors.grey[500],
                size: 20,
              ),
            ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: FaIcon(
        icon,
        size: 20,
        color: isDestructive ? Colors.red : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      trailing: FaIcon(
        FontAwesomeIcons.chevronRight,
        size: 16,
        color: isDestructive ? Colors.red : Colors.grey,
      ),
      onTap: onTap,
    );
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña actual',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nueva contraseña',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmar nueva contraseña',
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
            onPressed: () {
              // TODO: Implement password change
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Contraseña actualizada exitosamente'),
                  backgroundColor: Color(0xFF4CAF50),
                ),
              );
            },
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2196F3),
                    const Color(0xFF1976D2),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.home,
                size: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Acerca de'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'PrivApp',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Versión 1.0.0',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Sistema de gestión para comunidades residenciales privadas. '
              'Permite la administración de gastos, encuestas, blog comunitario y más.',
            ),
            SizedBox(height: 16),
            Text(
              '© 2025 MaSoft. Todos los derechos reservados.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final authService = Provider.of<AuthService>(context, listen: false);
              final expenseService = Provider.of<ExpenseService>(context, listen: false);
              
              // Limpiar gastos antes de hacer logout
              expenseService.clearExpenses();
              
              await authService.logout();

              if (context.mounted) {
                // Limpiar toda la pila de navegación y redirigir al login
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}
