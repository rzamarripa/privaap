import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/expense_service.dart';
import '../../services/survey_service.dart';
import '../../services/blog_service.dart';
import '../../models/expense_model.dart';
import '../expenses/add_expense_screen.dart';
import '../surveys/create_survey_screen.dart';
import '../blog/create_post_screen.dart';
import '../admin/super_admin_dashboard_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'es_MX',
    symbol: '\$',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    // Cargar datos si aún no están disponibles
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final expenseService = Provider.of<ExpenseService>(context, listen: false);
      final surveyService = Provider.of<SurveyService>(context, listen: false);
      final blogService = Provider.of<BlogService>(context, listen: false);

      // Cargar sólo si las listas están vacías para evitar llamadas duplicadas
      final List<Future<void>> tasks = [];
      if (expenseService.expenses.isEmpty && !expenseService.isLoading) {
        tasks.add(expenseService.loadExpenses());
      }
      if (surveyService.surveys.isEmpty && !surveyService.isLoading) {
        tasks.add(surveyService.loadSurveys());
      }
      if (blogService.posts.isEmpty && !blogService.isLoading) {
        tasks.add(blogService.loadPosts());
      }

      if (tasks.isNotEmpty) {
        try {
          await Future.wait(tasks);
        } catch (_) {}
        if (mounted) setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final expenseService = Provider.of<ExpenseService>(context);

    // Si es super admin, redirigir a su dashboard específico
    if (authService.currentUser?.isSuperAdmin == true) {
      return const SuperAdminDashboardScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              expenseService.loadExpenses(),
              Provider.of<SurveyService>(context, listen: false).loadSurveys(),
              Provider.of<BlogService>(context, listen: false).refresh(),
            ]);
          },
          color: const Color(0xFF2196F3),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 8),
                    if (authService.currentUser != null)
                      _buildWelcomeHeader(authService.currentUser!.name)
                    else
                      _buildWelcomeHeader('Usuario'),
                    const SizedBox(height: 6),
                    _buildQuickStats(expenseService),
                    const SizedBox(height: 16),
                    _buildExpenseChart(expenseService),
                    const SizedBox(height: 20),
                    _buildAdminActions(),
                    const SizedBox(height: 20),
                    _buildRecentActivity(expenseService),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(String userName) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, $userName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bienvenido a tu comunidad',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  DateFormat('EEEE, dd MMMM yyyy', 'es_ES').format(DateTime.now()),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const FaIcon(
              FontAwesomeIcons.houseUser,
              color: Colors.white,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(ExpenseService expenseService) {
    final surveyService = Provider.of<SurveyService>(context);
    final activeSurveys = surveyService.activeSurveys.length;
    final recentSurveys = surveyService.surveys
        .where((s) => s.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 7))))
        .length;

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.6,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: [
          _buildStatCard(
            title: 'Gastos del Mes',
            value: _currencyFormat.format(expenseService.totalExpenses),
            icon: FontAwesomeIcons.creditCard,
            color: const Color(0xFF4CAF50),
            trend: '${expenseService.activeExpenses.length} activos',
          ),
          _buildStatCard(
            title: 'Gastos Pendientes',
            value: _currencyFormat.format(expenseService.totalPendingExpenses),
            icon: FontAwesomeIcons.clock,
            color: const Color(0xFFFF9800),
            trend: '${expenseService.pendingExpenses.length} items',
          ),
          _buildStatCard(
            title: 'Gastos Pagados',
            value: _currencyFormat.format(expenseService.totalPaidExpenses),
            icon: FontAwesomeIcons.checkDouble,
            color: const Color(0xFF2196F3),
            trend: '${expenseService.paidExpenses.length} items',
          ),
          _buildStatCard(
            title: 'Gastos Rechazados',
            value: _currencyFormat.format(expenseService.totalRejectedExpenses),
            icon: FontAwesomeIcons.xmark,
            color: const Color(0xFFF44336),
            trend: '${expenseService.rejectedExpenses.length} items',
          ),
          _buildStatCard(
            title: 'Encuestas Activas',
            value: activeSurveys.toString(),
            icon: FontAwesomeIcons.squarePollVertical,
            color: const Color(0xFF9C27B0),
            trend: '$recentSurveys nuevas',
          ),
        ],
      ),
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
      padding: const EdgeInsets.all(10),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FaIcon(icon, color: color, size: 18),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    trend,
                    style: TextStyle(
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseChart(ExpenseService expenseService) {
    final categoryExpenses = expenseService.getExpensesByCategory();

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Gastos por Categoría',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to detailed expenses
                },
                child: const Text('Ver todo'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (categoryExpenses.isNotEmpty)
            Container(
              height: 200,
              constraints: const BoxConstraints(
                minHeight: 200,
                maxHeight: 200,
              ),
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 50,
                  sections: _buildPieChartSections(categoryExpenses),
                ),
              ),
            )
          else
            Container(
              height: 200,
              constraints: const BoxConstraints(
                minHeight: 200,
                maxHeight: 200,
              ),
              child: const Center(
                child: Text(
                  'No hay datos de gastos',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          const SizedBox(height: 20),
          _buildChartLegend(categoryExpenses),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(Map<ExpenseCategory, double> data) {
    final colors = [
      const Color(0xFF2196F3),
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
      const Color(0xFFF44336),
      const Color(0xFF9C27B0),
    ];

    final total = data.values.fold(0.0, (sum, value) => sum + value);
    int colorIndex = 0;

    return data.entries.map((entry) {
      final percentage = (entry.value / total * 100);
      final color = colors[colorIndex % colors.length];
      colorIndex++;

      return PieChartSectionData(
        value: entry.value,
        color: color,
        title: '${percentage.toInt()}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildChartLegend(Map<ExpenseCategory, double> data) {
    final colors = [
      const Color(0xFF2196F3),
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
      const Color(0xFFF44336),
      const Color(0xFF9C27B0),
    ];

    int colorIndex = 0;

    return Column(
      children: data.entries.map((entry) {
        final color = colors[colorIndex % colors.length];
        colorIndex++;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getCategoryName(entry.key),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              Text(
                _currencyFormat.format(entry.value),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getCategoryName(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.mantenimiento:
        return 'Mantenimiento';
      case ExpenseCategory.seguridad:
        return 'Seguridad';
      case ExpenseCategory.limpieza:
        return 'Limpieza';
      case ExpenseCategory.servicios:
        return 'Servicios';
      case ExpenseCategory.mejoras:
        return 'Mejoras';
      case ExpenseCategory.administrativos:
        return 'Administrativos';
      case ExpenseCategory.otros:
        return 'Otros';
    }
  }

  Widget _buildRecentActivity(ExpenseService expenseService) {
    final recentExpenses = expenseService.expenses.take(5).toList();

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Actividad Reciente',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to full activity list
                },
                child: const Text('Ver todo'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...recentExpenses.map((expense) => _buildActivityItem(expense)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Expense expense) {
    Color statusColor;
    IconData statusIcon;

    switch (expense.status) {
      case ExpenseStatus.pendiente:
        statusColor = const Color(0xFFFF9800);
        statusIcon = FontAwesomeIcons.clock;
        break;
      case ExpenseStatus.aprobado:
        statusColor = const Color(0xFF2196F3);
        statusIcon = FontAwesomeIcons.thumbsUp;
        break;
      case ExpenseStatus.pagado:
        statusColor = const Color(0xFF4CAF50);
        statusIcon = FontAwesomeIcons.checkDouble;
        break;
      case ExpenseStatus.rechazado:
        statusColor = const Color(0xFFF44336);
        statusIcon = FontAwesomeIcons.xmark;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FaIcon(statusIcon, color: statusColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('dd MMM yyyy').format(expense.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _currencyFormat.format(expense.amount),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  expense.status.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActions() {
    final authService = Provider.of<AuthService>(context);
    final isSuperAdmin = authService.currentUser?.isSuperAdmin ?? false;

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
          Row(
            children: [
              const Text(
                'Acciones de Administrador',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
              if (isSuperAdmin)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'Super Admin',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF9800),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Acciones para super admin
          if (isSuperAdmin) ...[
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    title: 'Nueva Privada',
                    icon: FontAwesomeIcons.building,
                    color: const Color(0xFFFF9800),
                    onTap: () {
                      Navigator.pushNamed(context, '/create-community');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    title: 'Gestionar Privadas',
                    icon: FontAwesomeIcons.gear,
                    color: const Color(0xFF9C27B0),
                    onTap: () {
                      // TODO: Navegar a gestión de privadas
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Acciones para administradores
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  title: 'Nuevo Gasto',
                  icon: FontAwesomeIcons.plus,
                  color: const Color(0xFF4CAF50),
                  onTap: () {
                    Navigator.pushNamed(context, '/add-expense');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  title: 'Nueva Encuesta',
                  icon: FontAwesomeIcons.squarePollVertical,
                  color: const Color(0xFF9C27B0),
                  onTap: () {
                    Navigator.pushNamed(context, '/create-survey');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  title: 'Nuevo Post',
                  icon: FontAwesomeIcons.penToSquare,
                  color: const Color(0xFF2196F3),
                  onTap: () {
                    Navigator.pushNamed(context, '/create-post');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  title: 'Reportes',
                  icon: FontAwesomeIcons.chartLine,
                  color: const Color(0xFFFF9800),
                  onTap: () {
                    _showReportsDialog(context);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            FaIcon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showReportsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reportes'),
          content: const Text('Aquí irían los reportes de la aplicación.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
