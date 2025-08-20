import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/expense_service.dart';
import '../services/blog_service.dart';
import '../services/survey_service.dart';
import '../services/user_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late AuthService _authService;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();

    // Diferir la verificación de auth hasta después del build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAuth();
    });
  }

  void _initializeAuth() {
    _authService = Provider.of<AuthService>(context, listen: false);

    // Agregar listener para cambios en el estado de autenticación
    _authService.addListener(_onAuthStateChanged);

    // Verificar estado inicial
    _checkAuthStatus();
  }

  void _onAuthStateChanged() {
    if (_authService.shouldRedirectToLogin && mounted) {
      // Limpiar la bandera
      _authService.clearRedirectFlag();

      // Redirigir al login y limpiar toda la pila de navegación
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    }
  }

  Future<void> _checkAuthStatus() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.checkAuthStatus();

    // Si el usuario está autenticado, cargar datos iniciales
    if (authService.isAuthenticated) {
      await _loadInitialData();
    }

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      if (authService.isAuthenticated) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  Future<void> _loadInitialData() async {
    try {
      final expenseService = Provider.of<ExpenseService>(context, listen: false);
      final blogService = Provider.of<BlogService>(context, listen: false);
      final surveyService = Provider.of<SurveyService>(context, listen: false);
      final userService = Provider.of<UserService>(context, listen: false);

      // Cargar datos en paralelo
      await Future.wait([
        expenseService.loadExpenses(),
        blogService.loadPosts(),
        blogService.loadProposals(),
        surveyService.loadSurveys(),
        userService.loadUsers(),
      ]);
    } catch (e) {
      // Continuar aunque falle la carga de datos
      debugPrint('Error cargando datos iniciales: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _authService.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1976D2),
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Image.asset(
                    'assets/icons/icon.jpg',
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback al icono original si no se encuentra la imagen
                      return const Icon(
                        Icons.home_work_rounded,
                        size: 80,
                        color: Color(0xFF1976D2),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Control Privada',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Gestión inteligente para tu comunidad',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 50),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
