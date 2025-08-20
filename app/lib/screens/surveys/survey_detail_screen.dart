import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/survey_service.dart';
import '../../models/survey_model.dart';
import 'edit_survey_screen.dart';

class SurveyDetailScreen extends StatefulWidget {
  final Survey survey;

  const SurveyDetailScreen({
    super.key,
    required this.survey,
  });

  @override
  State<SurveyDetailScreen> createState() => _SurveyDetailScreenState();
}

class _SurveyDetailScreenState extends State<SurveyDetailScreen> {
  List<String> _selectedOptions = [];
  bool _isSubmitting = false;
  late Survey _survey; // Estado local para la encuesta

  @override
  void initState() {
    super.initState();
    _survey = widget.survey; // Inicializar con la encuesta del widget

    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.id ?? '';

    // Si el usuario ya votó, mostrar sus opciones seleccionadas
    if (_survey.hasUserVoted(userId)) {
      final userVote = _survey.votes.firstWhere(
        (vote) => vote.userId == userId,
      );
      _selectedOptions = List.from(userVote.selectedOptions);
    }
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: build() llamado - Pregunta: ${_survey.question}');
    print('DEBUG: build() llamado - Opciones: ${_survey.options.map((o) => '${o.emoji} ${o.text}').join(', ')}');

    final authService = Provider.of<AuthService>(context);
    final userId = authService.currentUser?.id ?? '';
    final hasVoted = _survey.hasUserVoted(userId);
    final isExpired = _survey.expiresAt != null && _survey.expiresAt!.isBefore(DateTime.now());
    final canVote = !hasVoted && !isExpired && _survey.isActive;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 20, color: Color(0xFF2196F3)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (authService.isAdmin)
            PopupMenuButton<String>(
              icon: const FaIcon(FontAwesomeIcons.ellipsisVertical, size: 20, color: Color(0xFF2196F3)),
              onSelected: (value) {
                if (value == 'edit') {
                  _editSurvey();
                } else if (value == 'close') {
                  _closeSurvey();
                } else if (value == 'delete') {
                  _showDeleteDialog();
                }
              },
              itemBuilder: (context) => [
                if (_survey.isActive)
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        FaIcon(FontAwesomeIcons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('Editar encuesta'),
                      ],
                    ),
                  ),
                if (_survey.isActive)
                  const PopupMenuItem(
                    value: 'close',
                    child: Row(
                      children: [
                        FaIcon(FontAwesomeIcons.stop, size: 16),
                        SizedBox(width: 8),
                        Text('Cerrar encuesta'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      FaIcon(FontAwesomeIcons.trash, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Eliminar', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSurveyHeader(),
            _buildSurveyOptions(canVote, hasVoted),
            if (hasVoted || isExpired || !widget.survey.isActive) _buildResults(),
          ],
        ),
      ),
      bottomNavigationBar: canVote && _selectedOptions.isNotEmpty ? _buildVoteButton() : null,
    );
  }

  Widget _buildSurveyHeader() {
    final isExpired = widget.survey.expiresAt != null && widget.survey.expiresAt!.isBefore(DateTime.now());
    final authService = Provider.of<AuthService>(context, listen: false);
    final hasVoted = widget.survey.hasUserVoted(authService.currentUser?.id ?? '');

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Primera fila: Pregunta y estado
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.survey.question,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (isExpired)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'FINALIZADA',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                )
              else if (hasVoted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'VOTADO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Segunda fila: Fechas
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const FaIcon(
                    FontAwesomeIcons.calendar,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Creada el ${DateFormat('dd MMMM yyyy').format(widget.survey.createdAt)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              if (widget.survey.expiresAt != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.clock,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isExpired
                          ? 'Finalizada'
                          : 'Expira el ${DateFormat('dd MMM yyyy').format(widget.survey.expiresAt!)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isExpired ? Colors.red : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Tercera fila: Estadísticas y configuraciones
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
                      '${widget.survey.getTotalVotes()} votos',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2196F3),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.survey.allowMultipleAnswers)
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
              if (widget.survey.isAnonymous)
                Container(
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
        ],
      ),
    );
  }

  Widget _buildSurveyOptions(bool canVote, bool hasVoted) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            canVote ? 'Selecciona tu respuesta:' : 'Opciones:',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 16),
          ...widget.survey.options.map((option) => _buildOptionCard(
                option,
                canVote,
                hasVoted,
              )),
        ],
      ),
    );
  }

  Widget _buildOptionCard(SurveyOption option, bool canVote, bool hasVoted) {
    final isSelected = _selectedOptions.contains(option.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: canVote ? () => _toggleOption(option.id) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2196F3).withValues(alpha: 0.1) : const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF2196F3) : const Color(0xFFE0E0E0),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              if (canVote)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: widget.survey.allowMultipleAnswers ? BoxShape.rectangle : BoxShape.circle,
                    borderRadius: widget.survey.allowMultipleAnswers ? BorderRadius.circular(4) : null,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF2196F3) : Colors.grey,
                      width: 2,
                    ),
                    color: isSelected ? const Color(0xFF2196F3) : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),
              if (canVote) const SizedBox(width: 12),
              if (option.emoji != null) ...[
                Text(
                  option.emoji!,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  option.text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? const Color(0xFF2196F3) : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    final votesByOption = widget.survey.getVotesByOption();
    final totalVotes = widget.survey.getTotalVotes();

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Resultados',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
              Text(
                '$totalVotes votos totales',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...widget.survey.options.map((option) {
            final votes = votesByOption[option.id] ?? 0;
            final percentage = totalVotes > 0 ? (votes / totalVotes) : 0.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (option.emoji != null) ...[
                        Text(
                          option.emoji!,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          option.text,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '$votes votos (${(percentage * 100).toInt()}%)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF2196F3),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildVoteButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitVote,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
            child: _isSubmitting
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    'Votar (${_selectedOptions.length} ${widget.survey.allowMultipleAnswers ? 'opciones' : 'opción'})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _toggleOption(String optionId) {
    setState(() {
      if (widget.survey.allowMultipleAnswers) {
        if (_selectedOptions.contains(optionId)) {
          _selectedOptions.remove(optionId);
        } else {
          _selectedOptions.add(optionId);
        }
      } else {
        _selectedOptions = [optionId];
      }
    });
  }

  Future<void> _submitVote() async {
    if (_selectedOptions.isEmpty) return;

    setState(() => _isSubmitting = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.id ?? '';

    final surveyService = Provider.of<SurveyService>(context, listen: false);
    final success = await surveyService.voteSurvey(
      surveyId: widget.survey.id,
      userId: userId,
      selectedOptions: _selectedOptions,
    );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Voto registrado exitosamente!'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
      setState(() {}); // Refresh UI to show results
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al registrar el voto'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _closeSurvey() async {
    final surveyService = Provider.of<SurveyService>(context, listen: false);
    final success = await surveyService.closeSurvey(widget.survey.id);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Encuesta cerrada exitosamente. Ahora aparece en la pestaña "Finalizadas"'),
          backgroundColor: Color(0xFF4CAF50),
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al cerrar la encuesta'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Encuesta'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar esta encuesta? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSurvey();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSurvey() async {
    final surveyService = Provider.of<SurveyService>(context, listen: false);
    final success = await surveyService.deleteSurvey(widget.survey.id);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Encuesta eliminada exitosamente'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al eliminar la encuesta'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editSurvey() async {
    print('DEBUG: Editando encuesta: ${_survey.question}');
    print('DEBUG: Opciones actuales: ${_survey.options.map((o) => '${o.emoji} ${o.text}').join(', ')}');
    print('DEBUG: ID de encuesta: ${_survey.id}');

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditSurveyScreen(survey: _survey),
      ),
    );

    print('DEBUG: Resultado recibido: $result');
    print('DEBUG: Tipo de resultado: ${result.runtimeType}');

    // Si se recibió una encuesta actualizada, actualizar la UI
    if (result != null && result is Survey) {
      print('DEBUG: Encuesta actualizada recibida: ${result.question}');
      print('DEBUG: Nuevas opciones: ${result.options.map((o) => '${o.emoji} ${o.text}').join(', ')}');
      print('DEBUG: ID de encuesta recibida: ${result.id}');

      setState(() {
        // Actualizar la encuesta local
        _survey = result;
        print('DEBUG: _survey actualizada en setState');
        print('DEBUG: _survey después de setState: ${_survey.question}');
      });

      // Forzar reconstrucción adicional
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            print('DEBUG: Forzando reconstrucción adicional');
          });
        }
      });

      // Mostrar mensaje de confirmación
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Encuesta actualizada exitosamente'),
            backgroundColor: Color(0xFF4CAF50),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      print('DEBUG: No se recibió encuesta actualizada, result: $result');
      print('DEBUG: Tipo de result: ${result.runtimeType}');
    }
  }
}
