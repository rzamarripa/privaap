import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/survey_service.dart';
import '../../models/survey_model.dart';
import 'create_survey_screen.dart';
import 'survey_detail_screen.dart';
import 'edit_survey_screen.dart';

enum TabType { activas, misVotos, finalizadas }

class SurveysScreen extends StatefulWidget {
  const SurveysScreen({super.key});

  @override
  State<SurveysScreen> createState() => _SurveysScreenState();
}

class _SurveysScreenState extends State<SurveysScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Agregar listener para detectar cambios de pestaña
    _tabController.addListener(() {
      setState(() {}); // Forzar rebuild cuando cambie la pestaña
    });

    // Cargar encuestas al inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final surveyService = Provider.of<SurveyService>(context, listen: false);
      surveyService.loadSurveys();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final surveyService = Provider.of<SurveyService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Encuestas'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (authService.isAdmin)
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.plus, size: 20, color: Color(0xFF2196F3)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateSurveyScreen(),
                  ),
                );
              },
            ),
          IconButton(
            icon: surveyService.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF2196F3),
                    ),
                  )
                : const FaIcon(FontAwesomeIcons.arrowsRotate, size: 20, color: Color(0xFF2196F3)),
            onPressed: surveyService.isLoading
                ? null
                : () async {
                    await surveyService.refresh();
                  },
            tooltip: 'Actualizar encuestas',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2196F3),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF2196F3),
          tabs: const [
            Tab(text: 'Activas'),
            Tab(text: 'Mis Votos'),
            Tab(text: 'Finalizadas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await surveyService.loadSurveys();
            },
            color: const Color(0xFF2196F3),
            child: _buildSurveysList(surveyService.activeSurveys, TabType.activas),
          ),
          RefreshIndicator(
            onRefresh: () async {
              await surveyService.loadSurveys();
            },
            color: const Color(0xFF2196F3),
            child: _buildSurveysList(surveyService.votedSurveys(authService.currentUser?.id ?? ''), TabType.misVotos),
          ),
          RefreshIndicator(
            onRefresh: () async {
              await surveyService.loadSurveys();
            },
            color: const Color(0xFF2196F3),
            child: _buildSurveysList(surveyService.expiredSurveys, TabType.finalizadas),
          ),
        ],
      ),
    );
  }

  Widget _buildSurveysList(List<Survey> surveys, TabType tabType) {
    final surveyService = Provider.of<SurveyService>(context);

    if (surveyService.isLoading && surveys.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF2196F3),
            ),
            SizedBox(height: 16),
            Text(
              'Cargando encuestas...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (surveys.isEmpty) {
      // Mostrar mensaje específico según el tipo de pestaña
      String message;
      IconData icon;

      switch (tabType) {
        case TabType.activas:
          message = 'No hay encuestas activas disponibles';
          icon = FontAwesomeIcons.squarePollVertical;
          break;
        case TabType.misVotos:
          message = 'No has votado en ninguna encuesta';
          icon = FontAwesomeIcons.checkCircle;
          break;
        case TabType.finalizadas:
          message = 'No hay encuestas finalizadas';
          icon = FontAwesomeIcons.flagCheckered;
          break;
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
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            if (tabType == TabType.finalizadas) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2196F3).withValues(alpha: 0.3)),
                ),
                child: const Text(
                  'Las encuestas cerradas manualmente o expiradas aparecen aquí. Puedes ver los resultados completos pero no votar.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1976D2),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final surveyService = Provider.of<SurveyService>(context, listen: false);
        await surveyService.refresh();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: surveys.length,
        itemBuilder: (context, index) {
          return _buildSurveyCard(surveys[index]);
        },
      ),
    );
  }

  Widget _buildSurveyCard(Survey survey) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final hasVoted = survey.hasUserVoted(authService.currentUser?.id ?? '');
    final totalVotes = survey.getTotalVotes();
    final isExpired = survey.expiresAt != null && survey.expiresAt!.isBefore(DateTime.now());

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
              builder: (context) => SurveyDetailScreen(survey: survey),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      survey.question,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                  ),
                  if (authService.isAdmin && survey.isActive)
                    IconButton(
                      onPressed: () => _editSurvey(survey),
                      icon: const FaIcon(
                        FontAwesomeIcons.edit,
                        size: 16,
                        color: Color(0xFF2196F3),
                      ),
                      tooltip: 'Editar encuesta',
                    ),
                  if (isExpired)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'FINALIZADA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  else if (hasVoted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'VOTADO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const FaIcon(
                    FontAwesomeIcons.calendar,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Creada el ${DateFormat('dd MMM yyyy').format(survey.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (survey.expiresAt != null) ...[
                    const SizedBox(width: 16),
                    const FaIcon(
                      FontAwesomeIcons.clock,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isExpired ? 'Finalizada' : 'Expira el ${DateFormat('dd MMM').format(survey.expiresAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isExpired ? Colors.red : Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.users,
                          size: 12,
                          color: Color(0xFF2196F3),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$totalVotes votos',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2196F3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (survey.allowMultipleAnswers)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Múltiple selección',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFF9800),
                        ),
                      ),
                    ),
                  if (survey.isAnonymous)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9C27B0).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Anónima',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF9C27B0),
                        ),
                      ),
                    ),
                ],
              ),
              if (hasVoted && !survey.isAnonymous) ...[
                const SizedBox(height: 16),
                _buildMiniResults(survey),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniResults(Survey survey) {
    final votesByOption = survey.getVotesByOption();
    final totalVotes = survey.getTotalVotes();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tu voto:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        ...survey.options.map((option) {
          final votes = votesByOption[option.id] ?? 0;
          final percentage = totalVotes > 0 ? (votes / totalVotes) : 0.0;

          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                if (option.emoji != null) ...[
                  Text(option.emoji!, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    option.text,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${(percentage * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2196F3),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  void _editSurvey(Survey survey) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditSurveyScreen(survey: survey),
      ),
    );
  }
}
