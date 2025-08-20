import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../services/survey_service.dart';
import '../../services/auth_service.dart';
import '../../models/survey_model.dart';
import '../../models/user_model.dart';

class CreateSurveyScreen extends StatefulWidget {
  const CreateSurveyScreen({super.key});

  @override
  State<CreateSurveyScreen> createState() => _CreateSurveyScreenState();
}

class _CreateSurveyScreenState extends State<CreateSurveyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  final List<String> _optionEmojis = ['', ''];

  bool _allowMultipleAnswers = false;
  bool _isAnonymous = false;
  bool _hasExpiration = false;
  DateTime? _expirationDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _questionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;

    // Verificar que el usuario sea administrador
    if (currentUser == null || currentUser.role != UserRole.administrador) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text('Acceso Denegado'),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FaIcon(
                FontAwesomeIcons.lock,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Acceso Denegado',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Solo los administradores pueden crear encuestas',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Nueva Encuesta'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 20, color: Color(0xFF2196F3)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleSubmit,
            child: Text(
              'Crear',
              style: TextStyle(
                color: _isLoading ? Colors.grey : const Color(0xFF2196F3),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pregunta',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _questionController,
                      decoration: const InputDecoration(
                        labelText: 'Escribe tu pregunta',
                        hintText: '¿Cuál es tu pregunta para la comunidad?',
                        prefixIcon: Icon(
                          FontAwesomeIcons.circleQuestion,
                          size: 20,
                          color: Color(0xFF2196F3),
                        ),
                        filled: true,
                        fillColor: Color(0xFFF8F9FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa una pregunta';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Opciones de respuesta',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addOption,
                          icon: const FaIcon(FontAwesomeIcons.plus, size: 14),
                          label: const Text('Agregar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._buildOptionInputs(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configuración',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildToggleOption(
                      title: 'Permitir múltiples respuestas',
                      subtitle: 'Los usuarios pueden seleccionar más de una opción',
                      value: _allowMultipleAnswers,
                      icon: FontAwesomeIcons.listCheck,
                      onChanged: (value) {
                        setState(() {
                          _allowMultipleAnswers = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildToggleOption(
                      title: 'Encuesta anónima',
                      subtitle: 'Los votos no mostrarán quién votó',
                      value: _isAnonymous,
                      icon: FontAwesomeIcons.userSecret,
                      onChanged: (value) {
                        setState(() {
                          _isAnonymous = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildToggleOption(
                      title: 'Fecha de expiración',
                      subtitle: 'La encuesta se cerrará automáticamente',
                      value: _hasExpiration,
                      icon: FontAwesomeIcons.clock,
                      onChanged: (value) {
                        setState(() {
                          _hasExpiration = value;
                          if (!value) _expirationDate = null;
                        });
                      },
                    ),
                    if (_hasExpiration) ...[
                      const SizedBox(height: 16),
                      _buildDatePicker(),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),
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
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Crear Encuesta',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
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
      child: child,
    );
  }

  List<Widget> _buildOptionInputs() {
    return _optionControllers.asMap().entries.map((entry) {
      int index = entry.key;
      TextEditingController controller = entry.value;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _selectEmoji(index),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Center(
                  child: Text(
                    _optionEmojis[index].isEmpty ? '😀' : _optionEmojis[index],
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Opción ${index + 1}',
                  filled: true,
                  fillColor: const Color(0xFFF8F9FA),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa una opción';
                  }
                  return null;
                },
              ),
            ),
            if (_optionControllers.length > 2)
              IconButton(
                onPressed: () => _removeOption(index),
                icon: const FaIcon(
                  FontAwesomeIcons.trash,
                  size: 16,
                  color: Colors.red,
                ),
              ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildToggleOption({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        FaIcon(
          icon,
          size: 20,
          color: const Color(0xFF2196F3),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF2196F3),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _expirationDate ?? DateTime.now().add(const Duration(days: 7)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF2196F3),
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() {
            _expirationDate = picked;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            const FaIcon(
              FontAwesomeIcons.calendar,
              size: 20,
              color: Color(0xFF2196F3),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _expirationDate == null
                    ? 'Seleccionar fecha de expiración'
                    : 'Expira el ${DateFormat('dd MMMM yyyy').format(_expirationDate!)}',
                style: TextStyle(
                  fontSize: 16,
                  color: _expirationDate == null ? Colors.grey[600] : Colors.black,
                ),
              ),
            ),
            const FaIcon(
              FontAwesomeIcons.chevronDown,
              size: 16,
              color: Color(0xFF2196F3),
            ),
          ],
        ),
      ),
    );
  }

  void _addOption() {
    if (_optionControllers.length < 6) {
      setState(() {
        _optionControllers.add(TextEditingController());
        _optionEmojis.add('');
      });
    }
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
        _optionEmojis.removeAt(index);
      });
    }
  }

  void _selectEmoji(int index) {
    final emojis = ['😀', '😍', '👍', '👎', '❤️', '🔥', '💯', '🎉', '🤔', '😢', '😡', '👏'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecciona un emoji'),
        content: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: emojis
              .map((emoji) => GestureDetector(
                    onTap: () {
                      setState(() {
                        _optionEmojis[index] = emoji;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(emoji, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validación adicional para fecha de expiración
    if (_hasExpiration && _expirationDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una fecha de expiración'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    final options = _optionControllers.asMap().entries.map((entry) {
      return SurveyOption(
        id: 'opt${entry.key + 1}',
        text: entry.value.text,
        emoji: _optionEmojis[entry.key].isNotEmpty ? _optionEmojis[entry.key] : null,
      );
    }).toList();

    final survey = Survey(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      question: _questionController.text,
      options: options,
      createdAt: DateTime.now(),
      expiresAt: _hasExpiration ? _expirationDate : null,
      createdBy: user?.id ?? '1',
      allowMultipleAnswers: _allowMultipleAnswers,
      isAnonymous: _isAnonymous,
    );

    final surveyService = Provider.of<SurveyService>(context, listen: false);
    final result = await surveyService.createSurvey(survey);

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Error desconocido'),
          backgroundColor: result['success'] ? const Color(0xFF4CAF50) : Colors.red,
        ),
      );

      if (result['success']) {
        Navigator.pop(context);
      }
    }
  }
}
