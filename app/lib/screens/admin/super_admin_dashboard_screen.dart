import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/community_service.dart';
import '../../services/user_service.dart';
import '../../services/support_service.dart';
import '../../models/community_model.dart';
import '../../models/user_model.dart';
import '../../models/support_ticket_model.dart';

class SuperAdminDashboardScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const SuperAdminDashboardScreen({
    Key? key,
    this.onNavigateToTab,
  }) : super(key: key);

  @override
  State<SuperAdminDashboardScreen> createState() => _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> {
  final SupportService _supportService = SupportService();
  List<SupportTicket> _tickets = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    print('🔄 DEBUG Dashboard - _loadData iniciado');
    final communityService = Provider.of<CommunityService>(context, listen: false);
    final userService = Provider.of<UserService>(context, listen: false);

    print('🔍 DEBUG Dashboard - Estado inicial de communities: ${communityService.communities.length}');
    print('🔍 DEBUG Dashboard - Estado inicial de users: ${userService.users.length}');

    print('🔄 DEBUG Dashboard - Cargando datos en paralelo...');
    await Future.wait([
      communityService.refresh(),
      userService.refresh(),
      _loadTickets(),
    ]);

    print('🔍 DEBUG Dashboard - Después de refresh - communities: ${communityService.communities.length}');
    print('🔍 DEBUG Dashboard - Después de refresh - users: ${userService.users.length}');
    print('🔍 DEBUG Dashboard - Después de refresh - tickets: ${_tickets.length}');

    print('🔄 DEBUG Dashboard - Todos los datos cargados, forzando rebuild...');
    // Forzar rebuild después de cargar los datos
    if (mounted) {
      setState(() {});
      print('🔍 DEBUG Dashboard - Rebuild completado');
    } else {
      print('🔍 DEBUG Dashboard - Widget no está montado para rebuild');
    }
  }

  Future<void> _loadTickets() async {
    try {
      print('🔄 DEBUG Dashboard - Iniciando carga de tickets...');
      print('🔄 DEBUG Dashboard - Estado actual de _tickets: ${_tickets.length}');

      final tickets = await _supportService.getAllTickets();
      print('🔄 DEBUG Dashboard - Tickets cargados desde API: ${tickets.length}');

      if (tickets.isNotEmpty) {
        print('🔄 DEBUG Dashboard - Primer ticket: ${tickets.first.subject}');
        print('🔄 DEBUG Dashboard - Primer ticket status: ${tickets.first.status}');
        print('🔄 DEBUG Dashboard - Primer ticket ID: ${tickets.first.id}');
      } else {
        print('🔄 DEBUG Dashboard - Lista de tickets vacía desde API');
      }

      if (mounted) {
        print('🔄 DEBUG Dashboard - Widget está montado, actualizando estado...');
        setState(() {
          _tickets = tickets;
        });
        print('🔄 DEBUG Dashboard - Estado actualizado con ${_tickets.length} tickets');
        print('🔄 DEBUG Dashboard - _tickets después de setState: ${_tickets.length}');
      } else {
        print('🔄 DEBUG Dashboard - Widget no está montado, no se puede actualizar estado');
      }
    } catch (e) {
      print('❌ ERROR Dashboard - Error loading tickets: $e');
      print('❌ ERROR Dashboard - Stack trace: ${StackTrace.current}');
    }
  }

  int _getPendingTicketsCount() {
    print('🔍 DEBUG Dashboard - _getPendingTicketsCount llamado con ${_tickets.length} tickets');
    print('🔍 DEBUG Dashboard - Contenido de _tickets: ${_tickets.map((t) => '${t.subject}(${t.status})').toList()}');

    final pendingTickets =
        _tickets.where((ticket) => ticket.status == 'pending' || ticket.status == 'in_progress').toList();
    final count = pendingTickets.length;

    print(
        '🔍 DEBUG Dashboard - Tickets filtrados como pendientes: ${pendingTickets.map((t) => '${t.subject}(${t.status})').toList()}');
    print('🔍 DEBUG Dashboard - Tickets pendientes: $count (total tickets: ${_tickets.length})');
    return count;
  }

  int _getResolvedTicketsCount() {
    print('🔍 DEBUG Dashboard - _getResolvedTicketsCount llamado con ${_tickets.length} tickets');
    print('🔍 DEBUG Dashboard - Contenido de _tickets: ${_tickets.map((t) => '${t.subject}(${t.status})').toList()}');

    final resolvedTickets =
        _tickets.where((ticket) => ticket.status == 'resolved' || ticket.status == 'closed').toList();
    final count = resolvedTickets.length;

    print(
        '🔍 DEBUG Dashboard - Tickets filtrados como resueltos: ${resolvedTickets.map((t) => '${t.subject}(${t.status})').toList()}');
    print('🔍 DEBUG Dashboard - Tickets resueltos: $count (total tickets: ${_tickets.length})');
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final communityService = Provider.of<CommunityService>(context, listen: false);
    final userService = Provider.of<UserService>(context, listen: false);

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
            style: TextStyle(fontSize: 16, color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(28), // Aumentar padding general
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildWelcomeHeader(authService.currentUser!),
                  const SizedBox(height: 32), // Aumentar espaciado
                  _buildSystemStats(communityService, userService),
                  const SizedBox(height: 32), // Aumentar espaciado
                  _buildQuickActions(),
                  const SizedBox(height: 32), // Aumentar espaciado
                  _buildCommunitiesList(communityService),
                ]),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(User user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28), // Aumentar padding
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20), // Aumentar radio del borde
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withValues(alpha: 0.4), // Aumentar opacidad
            blurRadius: 15, // Aumentar blur
            offset: const Offset(0, 8), // Aumentar offset
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16), // Aumentar padding del icono
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25), // Aumentar opacidad
                  borderRadius: BorderRadius.circular(16), // Aumentar radio del borde
                ),
                child: const FaIcon(
                  FontAwesomeIcons.crown,
                  color: Colors.white,
                  size: 28, // Aumentar tamaño del icono
                ),
              ),
              const SizedBox(width: 20), // Aumentar espaciado
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bienvenido, ${user.name}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22, // Reducir de 26 a 22
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8), // Aumentar espaciado
                    const Text(
                      'Panel de Control del Sistema',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14, // Reducir de 16 a 14
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
  }

  Widget _buildSystemStats(CommunityService communityService, UserService userService) {
    print('🔍 DEBUG Dashboard - _buildSystemStats llamado con ${_tickets.length} tickets');
    print('🔍 DEBUG Dashboard - communities en _buildSystemStats: ${communityService.communities.length}');
    print('🔍 DEBUG Dashboard - users en _buildSystemStats: ${userService.users.length}');
    print(
        '🔍 DEBUG Dashboard - _tickets en _buildSystemStats: ${_tickets.map((t) => '${t.subject}(${t.status})').toList()}');
    print('🔍 DEBUG Dashboard - Llamando a _getPendingTicketsCount()...');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A237E).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const FaIcon(
                FontAwesomeIcons.chartBar,
                color: Color(0xFF1A237E),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Estadísticas del Sistema',
              style: TextStyle(
                fontSize: 18, // Reducir de 20 a 18
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20), // Aumentar espaciado
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1, // Ajustar proporción para evitar overflow
          children: [
            _buildStatCard(
              title: 'Total Privadas',
              value: '${communityService.communities.length}',
              icon: FontAwesomeIcons.building,
              color: const Color(0xFF2196F3),
              trend: 'Sistema',
            ),
            _buildStatCard(
              title: 'Privadas Activas',
              value: '${communityService.communities.where((c) => c.isActive).length}',
              icon: FontAwesomeIcons.circleCheck,
              color: const Color(0xFF4CAF50),
              trend: 'Operativas',
            ),
            _buildStatCard(
              title: 'Administradores',
              value: '${userService.users.where((u) => u.role == UserRole.administrador).length}',
              icon: FontAwesomeIcons.userShield,
              color: const Color(0xFF9C27B0),
              trend: 'Activos',
            ),
            _buildStatCard(
              title: 'Residentes',
              value: '${userService.users.where((u) => u.role == UserRole.residente).length}',
              icon: FontAwesomeIcons.users,
              color: const Color(0xFFFF9800),
              trend: 'Registrados',
            ),
            _buildStatCard(
              title: 'Tickets Pendientes',
              value: '${_getPendingTicketsCount()}',
              icon: FontAwesomeIcons.ticket,
              color: const Color(0xFFFF5722),
              trend: 'Soporte',
            ),
            _buildStatCard(
              title: 'Tickets Resueltos',
              value: '${_getResolvedTicketsCount()}',
              icon: FontAwesomeIcons.checkCircle,
              color: const Color(0xFF4CAF50),
              trend: 'Completados',
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: color.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header con icono y badge simplificado
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10), // Reducir padding del icono
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: FaIcon(
                    icon,
                    color: color,
                    size: 20, // Reducir tamaño del icono
                  ),
                ),
                const Spacer(),
                // Badge simplificado - solo texto gris
                Text(
                  trend,
                  style: const TextStyle(
                    fontSize: 10, // Reducir de 11 a 10
                    color: Color(0xFF757575), // Color gris
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Valor principal
            Text(
              value,
              style: TextStyle(
                fontSize: 28, // Reducir de 32 a 28
                fontWeight: FontWeight.w800,
                color: color,
                height: 1.1,
              ),
            ),

            const SizedBox(height: 6),

            // Título
            Text(
              title,
              style: const TextStyle(
                fontSize: 13, // Reducir de 14 a 13
                color: Color(0xFF424242),
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones Rápidas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                title: 'Nueva Privada',
                icon: FontAwesomeIcons.plus,
                color: const Color(0xFF4CAF50),
                onTap: () {
                  Navigator.pushNamed(context, '/create-community');
                },
              ),
            ),
            const SizedBox(width: 16), // Aumentar espaciado entre botones
            Expanded(
              child: _buildActionButton(
                title: 'Tickets de Soporte',
                icon: FontAwesomeIcons.headset,
                color: const Color(0xFFE91E63),
                onTap: () {
                  Navigator.pushNamed(context, '/support-tickets');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 100, // Aumentar altura para dar más espacio al texto
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                FaIcon(
                  icon,
                  color: color,
                  size: 26,
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 10, // Reducir un poco más el tamaño
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A237E),
                      height: 1.2, // Mejorar el espaciado de líneas
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommunitiesList(CommunityService communityService) {
    final communities = communityService.communities;

    print('🔍 DEBUG Dashboard - _buildCommunitiesList llamado');
    print('🔍 DEBUG Dashboard - communities.length: ${communities.length}');
    print('🔍 DEBUG Dashboard - communities: ${communities.map((c) => c.name).toList()}');

    if (communities.isEmpty) {
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
              FontAwesomeIcons.building,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay privadas registradas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Crea la primera privada para comenzar',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/create-community');
              },
              icon: const FaIcon(FontAwesomeIcons.plus),
              label: const Text('Crear Primera Privada'),
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
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const FaIcon(
                FontAwesomeIcons.building,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Privadas Registradas',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  Text(
                    '${communities.length} privada${communities.length != 1 ? 's' : ''} en el sistema',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Text(
                '${communities.length}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22), // Reducido de 24 a 22
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: communities.length,
          itemBuilder: (context, index) {
            final community = communities[index];
            return _buildCommunityCard(community);
          },
        ),
      ],
    );
  }

  Widget _buildCommunityCard(Community community) {
    return _CommunityCardWidget(community: community);
  }
}

class _CommunityCardWidget extends StatefulWidget {
  final Community community;

  const _CommunityCardWidget({required this.community});

  @override
  State<_CommunityCardWidget> createState() => _CommunityCardWidgetState();
}

class _CommunityCardWidgetState extends State<_CommunityCardWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _navigateToCommunityDetail(widget.community),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 18), // Reducido de 20 a 18
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isHovered ? 0.15 : 0.08),
                blurRadius: _isHovered ? 25 : 20,
                offset: Offset(0, _isHovered ? 12 : 8),
                spreadRadius: _isHovered ? 3 : 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // Header moderno con gradiente y estado
              Container(
                padding: const EdgeInsets.all(20), // Reducido para mejor proporción
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.community.isActive
                        ? [const Color(0xFF10B981), const Color(0xFF059669)]
                        : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10), // Reducido para mejor proporción
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: const FaIcon(
                        FontAwesomeIcons.building,
                        color: Colors.white,
                        size: 18, // Reducido para mejor proporción
                      ),
                    ),
                    const SizedBox(width: 12), // Reducido para mejor proporción
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.community.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2), // Reducido para mejor proporción
                          Text(
                            widget.community.address,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Reducido para mejor proporción
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6, // Reducido para mejor proporción
                            height: 6, // Reducido para mejor proporción
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(3), // Reducido para mejor proporción
                            ),
                          ),
                          const SizedBox(width: 6), // Reducido para mejor proporción
                          Text(
                            widget.community.isActive ? 'ACTIVA' : 'INACTIVA',
                            style: const TextStyle(
                              fontSize: 9, // Reducido para mejor proporción
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Contenido principal
              Padding(
                padding: const EdgeInsets.all(20), // Reducido para la nueva lista compacta
                child: Column(
                  children: [
                    // Lista compacta de estadísticas
                    Container(
                      padding: const EdgeInsets.all(16),
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
                          // Mensualidad
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const FaIcon(
                                  FontAwesomeIcons.moneyBillWave,
                                  size: 16,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Mensualidad',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '\$${widget.community.monthlyFee} ${widget.community.currency}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Casas
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const FaIcon(
                                  FontAwesomeIcons.house,
                                  size: 16,
                                  color: Color(0xFF3B82F6),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Casas',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '${widget.community.totalHouses} Total',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF3B82F6),
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

                    const SizedBox(height: 20), // Reducido para la nueva lista compacta

                    // Botón de acción moderno
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12), // Reducido para mejor proporción
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6), // Reducido para mejor proporción
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const FaIcon(
                              FontAwesomeIcons.arrowRight,
                              size: 14, // Reducido para mejor proporción
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                          const SizedBox(width: 10), // Reducido de 12 a 10
                          const Text(
                            'Ver Detalle Completo',
                            style: TextStyle(
                              fontSize: 14, // Reducido para mejor proporción
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                          ),
                        ],
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

  void _navigateToCommunityDetail(Community community) {
    Navigator.pushNamed(
      context,
      '/community-detail',
      arguments: community,
    );
  }
}
