import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_service.dart';
import '../../services/expense_service.dart';
import '../../services/blog_service.dart';
import '../../services/survey_service.dart';
import '../../services/user_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  String _biometricType = 'Biométrica';
  final BiometricService _biometricService = BiometricService();

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();

    // Verificar disponibilidad de autenticación biométrica
    _checkBiometricAvailability();
  }

  /// Verifica la disponibilidad de autenticación biométrica
  Future<void> _checkBiometricAvailability() async {
    final isAvailable = await _biometricService.isBiometricAvailable();
    final biometricType = await _biometricService.getBiometricType();
    final isEnabled = await _biometricService.isBiometricEnabled();

    if (mounted) {
      setState(() {
        _isBiometricAvailable = isAvailable;
        _biometricType = biometricType;
        _isBiometricEnabled = isEnabled;
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Configura la autenticación biométrica
  Future<void> _setupBiometric() async {
    try {
      setState(() => _isLoading = true);

      // Intentar configurar la biometría
      final success = await _biometricService.setupBiometric();

      if (success) {
        // Biometría configurada exitosamente
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$_biometricType configurado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );

          // Actualizar el estado local y verificar disponibilidad
          await _checkBiometricAvailability();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No se pudo configurar $_biometricType'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error configurando $_biometricType: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Maneja la autenticación biométrica
  Future<void> _handleBiometricAuth() async {
    try {
      setState(() => _isLoading = true);

      final result = await _biometricService.authenticate();

      if (result) {
        // Autenticación biométrica exitosa
        // Intentar hacer login con las credenciales guardadas
        final authService = Provider.of<AuthService>(context, listen: false);

        // Obtener credenciales guardadas
        final savedCredentials = await authService.getSavedCredentials();

        if (savedCredentials != null) {
          // Hacer login automático con las credenciales guardadas
          final success = await authService.login(
            savedCredentials['phoneNumber']!,
            savedCredentials['password']!,
          );

          if (success && mounted) {
            await _loadInitialDataAfterLogin();
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/home');
            }
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Las credenciales guardadas ya no son válidas'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No hay credenciales guardadas para login biométrico'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Autenticación $_biometricType falló'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en autenticación biométrica: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);

    bool success;
    if (_isLogin) {
      success = await authService.login(
        _phoneController.text,
        _passwordController.text,
      );
    } else {
      // Por simplicidad, usando valores predeterminados para registro
      success = await authService.register(
        phoneNumber: _phoneController.text,
        password: _passwordController.text,
        name: 'Nuevo Usuario',
        email: 'usuario@example.com',
      );
    }

    if (success) {
      // Mantener spinner mientras cargamos datos iniciales
      try {
        await _loadInitialDataAfterLogin();
      } catch (_) {
        // Ignorar errores de carga inicial
      }
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isLogin ? 'Credenciales incorrectas' : 'Error al registrar usuario'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadInitialDataAfterLogin() async {
    // Cargar datos clave en paralelo antes de ir al dashboard
    final expenseService = Provider.of<ExpenseService>(context, listen: false);
    final blogService = Provider.of<BlogService>(context, listen: false);
    final surveyService = Provider.of<SurveyService>(context, listen: false);
    final userService = Provider.of<UserService>(context, listen: false);

    await Future.wait([
      expenseService.loadExpenses(),
      blogService.loadPosts(),
      blogService.loadProposals(),
      surveyService.loadSurveys(),
      // Cargar usuarios puede fallar para residentes; no bloquear
      _safeLoadUsers(userService),
    ]);
  }

  Future<void> _safeLoadUsers(UserService userService) async {
    try {
      await userService.loadUsers();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: FadeTransition(
            opacity: _animation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 25,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Image.asset(
                          'assets/icons/icon.png',
                          width: 88,
                          height: 88,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'PrivApp',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A237E),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Gestión de Privadas',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  _isLogin ? 'Bienvenido' : 'Crear cuenta',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin ? 'Ingresa a tu cuenta para continuar' : 'Únete a nuestra comunidad',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 40),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Número de celular',
                          hintText: '10 dígitos',
                          prefixIcon: const Icon(
                            FontAwesomeIcons.phone,
                            size: 20,
                            color: Color(0xFF2196F3),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu número de celular';
                          }
                          if (value.length != 10) {
                            return 'El número debe tener 10 dígitos';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(
                            FontAwesomeIcons.lock,
                            size: 20,
                            color: Color(0xFF2196F3),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu contraseña';
                          }
                          if (value.length < 6) {
                            return 'La contraseña debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  _isLogin ? 'Iniciar sesión' : 'Registrarse',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Opción de autenticación biométrica
                      if (_isLogin && _isBiometricAvailable) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.grey[300],
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'O',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.grey[300],
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Información sobre autenticación biométrica
                        GestureDetector(
                          onTap: _isBiometricEnabled ? null : _setupBiometric,
                          child: MouseRegion(
                            cursor: _isBiometricEnabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _isBiometricEnabled ? Colors.blue[50] : Colors.blue[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _isBiometricEnabled ? Colors.blue[200]! : Colors.blue[300]!,
                                  width: _isBiometricEnabled ? 1 : 2,
                                ),
                                boxShadow: _isBiometricEnabled
                                    ? null
                                    : [
                                        BoxShadow(
                                          color: Colors.blue.withValues(alpha: 0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _isBiometricEnabled ? Icons.info_outline : Icons.touch_app,
                                        color: Colors.blue[600],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Autenticación $_biometricType',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                      if (!_isBiometricEnabled) ...[
                                        const Spacer(),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          color: Colors.blue[400],
                                          size: 16,
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (_isLoading && !_isBiometricEnabled) ...[
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Configurando...',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue[600],
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ] else ...[
                                    Text(
                                      _isBiometricEnabled
                                          ? 'Usa $_biometricType para iniciar sesión rápidamente'
                                          : 'Toca para configurar $_biometricType',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue[600],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (_isBiometricEnabled) ...[
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : _handleBiometricAuth,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color:
                                      _biometricType == 'Face ID' ? const Color(0xFF4CAF50) : const Color(0xFF2196F3),
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: Icon(
                                _biometricType == 'Face ID' ? FontAwesomeIcons.faceSmile : FontAwesomeIcons.fingerprint,
                                color: _biometricType == 'Face ID' ? const Color(0xFF4CAF50) : const Color(0xFF2196F3),
                                size: 20,
                              ),
                              label: Text(
                                'Iniciar sesión con $_biometricType',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      _biometricType == 'Face ID' ? const Color(0xFF4CAF50) : const Color(0xFF2196F3),
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                      ],

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isLogin ? '¿No tienes cuenta?' : '¿Ya tienes cuenta?',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isLogin = !_isLogin;
                                _formKey.currentState?.reset();
                              });
                            },
                            child: Text(
                              _isLogin ? 'Regístrate' : 'Inicia sesión',
                              style: const TextStyle(
                                color: Color(0xFF2196F3),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
