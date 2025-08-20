import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/expense_service.dart';
import '../../models/expense_model.dart';
import 'add_expense_screen.dart';
import 'expense_detail_screen.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  ExpenseCategory? _selectedCategory;
  bool _showSearchBar = false;
  bool _showSummaryCards = true; // Nueva variable para controlar visibilidad

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'es_MX',
    symbol: '\$',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final expenseService = Provider.of<ExpenseService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Gastos de la Privada'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Botón para registrar nuevos gastos
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddExpenseScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.add,
              color: Color(0xFF2196F3),
            ),
            tooltip: 'Registrar Gasto',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF2196F3)),
            onSelected: (value) {
              if (value == 'search') {
                setState(() {
                  _showSearchBar = !_showSearchBar;
                  if (!_showSearchBar) {
                    _searchQuery = '';
                    _searchController.clear();
                  }
                });
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'search',
                child: Row(
                  children: [
                    Icon(
                      _showSearchBar ? Icons.close : Icons.search,
                      color: _showSearchBar ? Colors.red : const Color(0xFF2196F3),
                    ),
                    const SizedBox(width: 12),
                    Text(_showSearchBar ? 'Ocultar Búsqueda' : 'Mostrar Búsqueda'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2196F3),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF2196F3),
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          isScrollable: true,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          tabs: const [
            Tab(text: 'Todos'),
            Tab(text: 'Pendientes'),
            Tab(text: 'Aprobados'),
            Tab(text: 'Pagados'),
            Tab(text: 'Rechazados'),
          ],
        ),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await expenseService.loadExpenses();
            },
            color: const Color(0xFF2196F3),
            child: CustomScrollView(
              slivers: [
                if (_showSearchBar)
                  SliverToBoxAdapter(
                    child: _buildSearchBar(),
                  ),
                SliverToBoxAdapter(
                  child: _buildSummaryCards(expenseService),
                ),
                SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildExpensesList(expenseService.expenses),
                      _buildExpensesList(expenseService.pendingExpenses),
                      _buildExpensesList(expenseService.approvedExpenses),
                      _buildExpensesList(expenseService.paidExpenses),
                      _buildExpensesList(expenseService.rejectedExpenses),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Pestañita flotante siempre visible por separado
          _buildFloatingTab(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar gastos...',
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 16,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.only(right: 8),
            child: Icon(
              FontAwesomeIcons.magnifyingGlass,
              size: 18,
              color: const Color(0xFF2196F3),
            ),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFF2196F3),
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF1A237E),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildSummaryCards(ExpenseService expenseService) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      height: _showSummaryCards ? 190 : 0,
      margin: EdgeInsets.only(
        top: _showSummaryCards ? 16 : 0,
        left: _showSummaryCards ? 16 : 0,
        right: _showSummaryCards ? 16 : 0,
        bottom: _showSummaryCards ? 0 : 0,
      ),
      child: ClipRect(
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          offset:
              _showSummaryCards ? Offset.zero : const Offset(1.0, 0.0), // Se desliza hacia la derecha para ocultarse
          child: SizedBox(
            height: 190,
            child: (() {
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 2.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildSummaryCard(
                    title: 'Total',
                    amount: expenseService.totalExpenses,
                    color: const Color(0xFF2196F3),
                    icon: FontAwesomeIcons.receipt,
                  ),
                  _buildSummaryCard(
                    title: 'Pendientes',
                    amount: expenseService.totalPendingExpenses,
                    color: const Color(0xFFFF9800),
                    icon: FontAwesomeIcons.clock,
                  ),
                  _buildSummaryCard(
                    title: 'Aprobados',
                    amount: expenseService.approvedExpenses.fold(0.0, (sum, e) => sum + e.amount),
                    color: const Color(0xFF4CAF50),
                    icon: FontAwesomeIcons.circleCheck,
                  ),
                  _buildSummaryCard(
                    title: 'Pagados',
                    amount: expenseService.totalPaidExpenses,
                    color: const Color(0xFF9C27B0),
                    icon: FontAwesomeIcons.creditCard,
                  ),
                ],
              );
            })(),
          ),
        ),
      ),
    );
  }

  // Pestañita flotante siempre visible
  Widget _buildFloatingTab() {
    return Positioned(
      right: _showSummaryCards ? 0 : 0, // Pegada al borde cuando está oculto
      top: _showSummaryCards ? 50 : 50, // Sin padding superior cuando está oculto
      child: (() {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: 20,
          height: 50, // Misma altura que el panel
          decoration: BoxDecoration(
            color: const Color(0xFF2196F3),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(5),
              bottomLeft: const Radius.circular(5),
              topRight: Radius.zero, // Bordes redondeados cuando está oculto
              bottomRight: Radius.zero, // Bordes redondeados cuando está oculto
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(-2, 0),
              ),
              // Sombra adicional cuando está pegada al borde
              if (!_showSummaryCards)
                BoxShadow(
                  color: const Color(0xFF2196F3).withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 0),
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                bottomLeft: const Radius.circular(20),
                topRight: _showSummaryCards
                    ? Radius.zero
                    : const Radius.circular(20), // Bordes redondeados cuando está oculto
                bottomRight: _showSummaryCards
                    ? Radius.zero
                    : const Radius.circular(20), // Bordes redondeados cuando está oculto
              ),
              splashColor: Colors.white.withValues(alpha: 0.3),
              highlightColor: Colors.white.withValues(alpha: 0.1),
              onTap: () {
                setState(() {
                  _showSummaryCards = !_showSummaryCards;
                });
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedRotation(
                    turns: _showSummaryCards ? 0.0 : 0.5,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(
                      Icons.keyboard_arrow_right,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      })(),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(10), // Reducido de 12 a 10
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              FaIcon(
                icon,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _currencyFormat.format(amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesList(List<Expense> expenses) {
    List<Expense> filteredExpenses = expenses.where((expense) {
      final matchesSearch = expense.title.toLowerCase().contains(_searchQuery) ||
          expense.description.toLowerCase().contains(_searchQuery);
      final matchesCategory = _selectedCategory == null || expense.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    if (filteredExpenses.isEmpty) {
      String message;
      IconData icon;

      if (_searchQuery.isNotEmpty || _selectedCategory != null) {
        message = 'No se encontraron gastos con los filtros aplicados';
        icon = FontAwesomeIcons.filter;
      } else if (expenses.isEmpty) {
        message = 'No hay gastos registrados';
        icon = FontAwesomeIcons.receipt;
      } else {
        message = 'No hay gastos en esta categoría';
        icon = FontAwesomeIcons.folderOpen;
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              icon,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            if (_searchQuery.isNotEmpty || _selectedCategory != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _selectedCategory = null;
                    _searchController.clear();
                  });
                },
                child: const Text('Limpiar filtros'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final expenseService = Provider.of<ExpenseService>(context, listen: false);
        await expenseService.refresh();
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), // Cambiado de all(16) a fromLTRB(16, 8, 16, 16)
        itemCount: filteredExpenses.length,
        itemBuilder: (context, index) {
          return _buildExpenseCard(filteredExpenses[index]);
        },
      ),
    );
  }

  Widget _buildExpenseCard(Expense expense) {
    Color statusColor;
    IconData statusIcon;

    switch (expense.status) {
      case ExpenseStatus.pendiente:
        statusColor = const Color(0xFFFF9800);
        statusIcon = FontAwesomeIcons.clock;
        break;
      case ExpenseStatus.aprobado:
        statusColor = const Color(0xFF2196F3);
        statusIcon = FontAwesomeIcons.thumbsUp; // Cambiado de checkCircle a thumbsUp
        break;
      case ExpenseStatus.pagado:
        statusColor = const Color(0xFF4CAF50);
        statusIcon = FontAwesomeIcons.checkDouble; // Cambiado de checkCircle a checkDouble
        break;
      case ExpenseStatus.rechazado:
        statusColor = const Color(0xFFF44336);
        statusIcon = FontAwesomeIcons.xmark;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExpenseDetailScreen(expense: expense),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            // Si el ancho es muy pequeño, apilar verticalmente
                            if (constraints.maxWidth < 300) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(expense.category.icon),
                                      const SizedBox(width: 4),
                                      Text(
                                        expense.category.displayName,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('dd/MM/yyyy').format(expense.date),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              );
                            }

                            // Para pantallas más grandes, usar Row horizontal
                            return Row(
                              children: [
                                Text(expense.category.icon),
                                const SizedBox(width: 4),
                                Text(
                                  expense.category.displayName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  DateFormat('dd/MM/yyyy').format(expense.date),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            );
                          },
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
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
              if (expense.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  expense.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
