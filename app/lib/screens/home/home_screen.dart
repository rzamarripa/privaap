import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../widgets/biometric_auth_wrapper.dart';
import 'dashboard_screen.dart';
import '../expenses/expenses_screen.dart';
import '../surveys/surveys_screen.dart';
import '../blog/blog_screen.dart';
import '../profile/profile_screen.dart';
import '../communities/communities_screen.dart';
import '../monthly_fees/monthly_fees_screen.dart';
import '../../services/monthly_fee_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ExpensesScreen(),
    const MonthlyFeesScreen(),
    const SurveysScreen(),
    const BlogScreen(),
    const ProfileScreen(),
  ];

  final List<Widget> _superAdminScreens = [
    const DashboardScreen(),
    const CommunitiesScreen(), // TODO: Crear esta pantalla
    const ProfileScreen(),
  ];

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: FontAwesomeIcons.house,
      label: 'Inicio',
    ),
    NavigationItem(
      icon: FontAwesomeIcons.creditCard,
      label: 'Gastos',
    ),
    NavigationItem(
      icon: FontAwesomeIcons.calendar,
      label: 'Mensualidades',
    ),
    NavigationItem(
      icon: FontAwesomeIcons.squarePollVertical,
      label: 'Encuestas',
    ),
    NavigationItem(
      icon: FontAwesomeIcons.blog,
      label: 'Blog',
    ),
    NavigationItem(
      icon: FontAwesomeIcons.user,
      label: 'Perfil',
    ),
  ];

  final List<NavigationItem> _superAdminNavigationItems = [
    NavigationItem(
      icon: FontAwesomeIcons.house,
      label: 'Inicio',
    ),
    NavigationItem(
      icon: FontAwesomeIcons.building,
      label: 'Privadas',
    ),
    NavigationItem(
      icon: FontAwesomeIcons.user,
      label: 'Perfil',
    ),
  ];

  void _onNavItemTapped(int index) {
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });
      // Agregar feedback táctil
      HapticFeedback.lightImpact();

      // Log para debugging
      print('Navegando a: ${_getCurrentNavigationItems()[index].label}');
    }
  }

  List<NavigationItem> _getCurrentNavigationItems() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isSuperAdmin = authService.currentUser?.isSuperAdmin == true;
    print('🔄 DEBUG _getCurrentNavigationItems - isSuperAdmin: $isSuperAdmin');
    print('🔄 DEBUG _getCurrentNavigationItems - currentUser: ${authService.currentUser?.name}');
    print('🔄 DEBUG _getCurrentNavigationItems - currentUser role: ${authService.currentUser?.role}');
    if (isSuperAdmin) {
      print('🔄 DEBUG _getCurrentNavigationItems - Retornando _superAdminNavigationItems');
      return _superAdminNavigationItems;
    }
    print('🔄 DEBUG _getCurrentNavigationItems - Retornando _navigationItems');
    return _navigationItems;
  }

  List<Widget> _getCurrentScreens() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isSuperAdmin = authService.currentUser?.isSuperAdmin == true;
    print('🔄 DEBUG _getCurrentScreens - isSuperAdmin: $isSuperAdmin');
    print('🔄 DEBUG _getCurrentScreens - currentUser: ${authService.currentUser?.name}');
    if (isSuperAdmin) {
      print('🔄 DEBUG _getCurrentScreens - Retornando _superAdminScreens');
      return _superAdminScreens;
    }
    print('🔄 DEBUG _getCurrentScreens - Retornando _screens');
    return _screens;
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final isSuperAdmin = user?.isSuperAdmin == true;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MonthlyFeeService>(create: (_) => MonthlyFeeService()),
      ],
      child: BiometricAuthWrapper(
        child: Scaffold(
          body: _getCurrentScreens()[_selectedIndex],
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: _getCurrentNavigationItems().length == 6 ? 2 : 4,
                      vertical: 8,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isSmallScreen = constraints.maxWidth < 400;
                        final itemCount = _getCurrentNavigationItems().length;

                        // Para 6 opciones, usar espaciado más compacto con ancho fijo
                        if (itemCount == 6) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(
                              itemCount,
                              (index) => Flexible(
                                child: _buildNavItem(
                                  item: _getCurrentNavigationItems()[index],
                                  isSelected: _selectedIndex == index,
                                  onTap: () => _onNavItemTapped(index),
                                ),
                              ),
                            ),
                          );
                        }

                        // Para 4 opciones (super admin), mantener el espaciado original
                        return Row(
                          mainAxisAlignment:
                              isSmallScreen ? MainAxisAlignment.spaceEvenly : MainAxisAlignment.spaceAround,
                          children: List.generate(
                            itemCount,
                            (index) => Flexible(
                              child: _buildNavItem(
                                item: _getCurrentNavigationItems()[index],
                                isSelected: _selectedIndex == index,
                                onTap: () => _onNavItemTapped(index),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // floatingActionButton: _buildFAB(context, user), // Removido por solicitud del usuario
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required NavigationItem item,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final itemCount = _getCurrentNavigationItems().length;
    final isCompactMode = itemCount == 6;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Contenido del item
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: EdgeInsets.symmetric(
                horizontal: isCompactMode ? 4 : (MediaQuery.of(context).size.width < 400 ? 8 : 16),
                vertical: isCompactMode ? 6 : (MediaQuery.of(context).size.width < 400 ? 8 : 12)),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF2196F3).withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(isCompactMode ? 8 : 16),
              border: isSelected
                  ? Border.all(color: const Color(0xFF2196F3).withValues(alpha: 0.3), width: isCompactMode ? 1.0 : 1.5)
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  transform: Matrix4.identity()..scale(isSelected ? 1.1 : 1.0),
                  child: FaIcon(
                    item.icon,
                    size: _getIconSize(isCompactMode, isSelected),
                    color: isSelected ? const Color(0xFF2196F3) : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: _getFontSize(isCompactMode, isSelected),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? const Color(0xFF2196F3) : Colors.grey[600],
                  ),
                  child: Text(
                    item.label,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _getIconSize(bool isCompactMode, bool isSelected) {
    if (isCompactMode) {
      return isSelected ? 18 : 16;
    }
    return MediaQuery.of(context).size.width < 400 ? (isSelected ? 18 : 16) : (isSelected ? 22 : 20);
  }

  double _getFontSize(bool isCompactMode, bool isSelected) {
    if (isCompactMode) {
      // Para 6 opciones, usar tamaños más pequeños para evitar desbordamiento
      return isSelected ? 9 : 8;
    }
    return MediaQuery.of(context).size.width < 400 ? (isSelected ? 11 : 10) : (isSelected ? 13 : 12);
  }

  Widget? _buildFAB(BuildContext context, user) {
    if (user?.role != UserRole.administrador && user?.isSuperAdmin != true) return null;

    switch (_selectedIndex) {
      case 0: // Inicio
        return null;
      case 1: // Privadas (super admin) o Gastos (usuarios normales)
        if (user?.isSuperAdmin == true) {
          // Para super admin, mostrar FAB para crear privada
          return FloatingActionButton(
            onPressed: () {
              Navigator.pushNamed(context, '/create-community');
            },
            backgroundColor: const Color(0xFF2196F3),
            heroTag: 'communities_fab',
            child: const Icon(Icons.add),
          );
        } else {
          // Para usuarios normales, mostrar FAB para crear gasto
          return FloatingActionButton(
            onPressed: () {
              Navigator.pushNamed(context, '/add-expense');
            },
            backgroundColor: const Color(0xFF2196F3),
            heroTag: 'expenses_fab',
            child: const Icon(Icons.add),
          );
        }
      case 2: // Perfil (super admin) o Mensualidades (usuarios normales)
        if (user?.isSuperAdmin == true) {
          // Para super admin, no mostrar FAB en perfil
          return null;
        } else {
          // Para usuarios normales, mostrar FAB para crear mensualidad (si es admin)
          if (user?.role == UserRole.administrador) {
            return FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, '/create-monthly-fee');
              },
              backgroundColor: const Color(0xFF2196F3),
              heroTag: 'monthly_fees_fab',
              child: const Icon(Icons.add),
            );
          }
        }
        return null;
      case 3: // Encuestas (usuarios normales)
        if (user?.isSuperAdmin == true) {
          // Para super admin, este índice ya no existe
          return null;
        } else {
          // Para usuarios normales, mostrar FAB para crear encuesta
          return FloatingActionButton(
            onPressed: () {
              Navigator.pushNamed(context, '/create-survey');
            },
            backgroundColor: const Color(0xFF2196F3),
            heroTag: 'surveys_fab',
            child: const Icon(Icons.poll),
          );
        }
      case 4: // Perfil (usuarios normales) o Blog (usuarios normales)
        if (user?.isSuperAdmin == true) {
          // Para super admin, no mostrar FAB en perfil
          return null;
        } else {
          // Para usuarios normales, mostrar FAB para crear post
          return FloatingActionButton(
            onPressed: () {
              Navigator.pushNamed(context, '/create-post');
            },
            backgroundColor: const Color(0xFF2196F3),
            heroTag: 'blog_fab',
            child: const Icon(Icons.edit),
          );
        }
      case 5: // Perfil (usuarios normales)
        return null;
      default:
        return null;
    }
  }
}

class NavigationItem {
  final IconData icon;
  final String label;

  NavigationItem({
    required this.icon,
    required this.label,
  });
}
