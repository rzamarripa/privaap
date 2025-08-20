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
    final isAdmin = user?.role == UserRole.administrador;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MonthlyFeeService>(create: (_) => MonthlyFeeService()),
      ],
      child: BiometricAuthWrapper(
        child: Scaffold(
          drawer: (isAdmin && !isSuperAdmin) ? _buildAdminDrawer(context, user) : null,
          body: _getCurrentScreens()[_selectedIndex],
          floatingActionButton: (isAdmin && !isSuperAdmin) ? _buildAdminFAB(context) : null,
          bottomNavigationBar: (isAdmin && !isSuperAdmin) 
              ? _buildAdminBottomBar(context) 
              : Container(
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

  Widget? _buildAdminFAB(BuildContext context) {
    switch (_selectedIndex) {
      case 1: // Gastos
        return FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, '/add-expense'),
          backgroundColor: const Color(0xFF2196F3),
          tooltip: 'Agregar gasto',
          child: const Icon(Icons.add, color: Colors.white),
        );
      case 2: // Mensualidades 
        return FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, '/create-monthly-fee'),
          backgroundColor: const Color(0xFF2196F3),
          tooltip: 'Crear mensualidad',
          child: const Icon(Icons.add, color: Colors.white),
        );
      case 3: // Encuestas
        return FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, '/create-survey'),
          backgroundColor: const Color(0xFF2196F3),
          tooltip: 'Crear encuesta',
          child: const Icon(Icons.poll, color: Colors.white),
        );
      case 4: // Blog
        return FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, '/create-post'),
          backgroundColor: const Color(0xFF2196F3),
          tooltip: 'Crear post',
          child: const Icon(Icons.edit, color: Colors.white),
        );
      default:
        return null;
    }
  }

  // Drawer para administradores con todas las opciones
  Widget _buildAdminDrawer(BuildContext context, user) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header del drawer
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: Icon(
                        FontAwesomeIcons.userTie,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      user?.name ?? 'Administrador',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Administrador',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              // Opciones del drawer
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  children: [
                    _buildDrawerItem(
                      icon: FontAwesomeIcons.house,
                      title: 'Inicio',
                      isSelected: _selectedIndex == 0,
                      onTap: () {
                        Navigator.pop(context);
                        _onNavItemTapped(0);
                      },
                    ),
                    _buildDrawerItem(
                      icon: FontAwesomeIcons.creditCard,
                      title: 'Gastos',
                      isSelected: _selectedIndex == 1,
                      onTap: () {
                        Navigator.pop(context);
                        _onNavItemTapped(1);
                      },
                    ),
                    _buildDrawerItem(
                      icon: FontAwesomeIcons.calendar,
                      title: 'Mensualidades',
                      isSelected: _selectedIndex == 2,
                      onTap: () {
                        Navigator.pop(context);
                        _onNavItemTapped(2);
                      },
                    ),
                    _buildDrawerItem(
                      icon: FontAwesomeIcons.squarePollVertical,
                      title: 'Encuestas',
                      isSelected: _selectedIndex == 3,
                      onTap: () {
                        Navigator.pop(context);
                        _onNavItemTapped(3);
                      },
                    ),
                    _buildDrawerItem(
                      icon: FontAwesomeIcons.blog,
                      title: 'Blog',
                      isSelected: _selectedIndex == 4,
                      onTap: () {
                        Navigator.pop(context);
                        _onNavItemTapped(4);
                      },
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              // Perfil al final
              _buildDrawerItem(
                icon: FontAwesomeIcons.user,
                title: 'Perfil',
                isSelected: _selectedIndex == 5,
                onTap: () {
                  Navigator.pop(context);
                  _onNavItemTapped(5);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        leading: FaIcon(
          icon,
          color: Colors.white,
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  // Bottom bar simplificado para administradores (solo las 4 más importantes)
  Widget _buildAdminBottomBar(BuildContext context) {
    final mainItems = [
      NavigationItem(icon: FontAwesomeIcons.house, label: 'Inicio'),
      NavigationItem(icon: FontAwesomeIcons.creditCard, label: 'Gastos'),
      NavigationItem(icon: FontAwesomeIcons.calendar, label: 'Mensual.'),
      NavigationItem(icon: FontAwesomeIcons.user, label: 'Perfil'),
    ];

    final mainIndices = [0, 1, 2, 5]; // Mapeo a los índices reales

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              mainItems.length,
              (index) => Expanded(
                child: _buildEnhancedNavItem(
                  item: mainItems[index],
                  isSelected: _selectedIndex == mainIndices[index],
                  onTap: () => _onNavItemTapped(mainIndices[index]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedNavItem({
    required NavigationItem item,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2196F3).withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: isSelected
                    ? Border.all(color: const Color(0xFF2196F3).withValues(alpha: 0.3), width: 1.5)
                    : null,
              ),
              transform: Matrix4.identity()..scale(isSelected ? 1.05 : 1.0),
              child: FaIcon(
                item.icon,
                size: 24, // Iconos más grandes
                color: isSelected ? const Color(0xFF2196F3) : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 12, // Texto más legible
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
    );
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
