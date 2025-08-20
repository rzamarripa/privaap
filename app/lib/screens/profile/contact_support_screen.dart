import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../models/support_ticket_model.dart';
import '../../services/support_service.dart';
import '../../services/auth_service.dart';

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _reproductionStepsController = TextEditingController();

  SupportCategory _selectedCategory = SupportCategory.technical;
  final List<File> _attachments = [];
  bool _isLoading = false;

  late final SupportService _supportService;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _supportService = SupportService();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    _reproductionStepsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_attachments.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Máximo 3 imágenes permitidas'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null && mounted) {
        setState(() {
          _attachments.add(File(image.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeAttachment(int index) async {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    // Validaciones adicionales para asegurar compatibilidad con backend
    final subject = _subjectController.text.trim();
    final description = _descriptionController.text.trim();

    if (subject.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El asunto debe tener al menos 10 caracteres'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (description.length < 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La descripción debe tener al menos 20 caracteres'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        throw Exception('Usuario no autenticado');
      }

      // Crear el ticket
      final ticket = SupportTicket(
        userName: currentUser.name,
        userEmail: currentUser.email,
        userPhone: currentUser.phoneNumber,
        communityName: currentUser.communityId ?? 'No asignada',
        subject: _subjectController.text.trim(),
        category: _selectedCategory.name,
        description: _descriptionController.text.trim(),
        reproductionSteps:
            _reproductionStepsController.text.trim().isEmpty ? null : _reproductionStepsController.text.trim(),
        attachments: [],
        deviceType: Platform.isAndroid ? 'Android' : 'iOS',
        appVersion: '1.0.0', // TODO: Obtener versión real de la app
        createdAt: DateTime.now(),
      );

      // Subir imágenes si las hay
      List<String> uploadedUrls = [];
      if (_attachments.isNotEmpty) {
        try {
          debugPrint('🔍 DEBUG ContactSupportScreen - Subiendo ${_attachments.length} imágenes...');
          uploadedUrls = await _supportService.uploadMultipleAttachments(_attachments);
          debugPrint('✅ DEBUG ContactSupportScreen - ${uploadedUrls.length} imágenes subidas exitosamente');
        } catch (e) {
          debugPrint('❌ ERROR ContactSupportScreen - Error al subir imágenes: $e');
          // Mostrar error específico para Firebase
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al subir imágenes: ${e.toString().replaceAll('Exception: ', '')}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          // No continuar si las imágenes no se pudieron subir
          return;
        }
      }

      // Actualizar el ticket con las URLs de las imágenes
      final finalTicket = ticket.copyWith(attachments: uploadedUrls);

      // Enviar el ticket
      debugPrint('🔍 DEBUG ContactSupportScreen - Enviando ticket final: ${finalTicket.toJson()}');
      final success = await _supportService.submitSupportTicket(finalTicket);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket enviado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('❌ ERROR ContactSupportScreen - Error al enviar ticket: $e');
      if (mounted) {
        // Extraer mensaje de error más específico si está disponible
        String errorMessage = 'Error al enviar ticket';
        if (e.toString().contains('Datos de entrada inválidos')) {
          errorMessage = 'Por favor verifica que todos los campos estén completados correctamente';
        } else if (e.toString().contains('Error de conexión')) {
          errorMessage = 'Error de conexión. Verifica tu internet';
        } else {
          errorMessage = 'Error al enviar ticket: ${e.toString().replaceAll('Exception: ', '')}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contactar Soporte'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header informativo
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF2196F3),
                      const Color(0xFF1976D2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.headset,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '¿Necesitas ayuda?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Describe tu problema y nuestro equipo te ayudará lo antes posible.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Categoría
              Text(
                'Categoría *',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<SupportCategory>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Selecciona una categoría',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                items: SupportCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Text(category.icon),
                        const SizedBox(width: 8),
                        Text(category.label),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
                validator: (value) {
                  if (value == null) {
                    return 'Selecciona una categoría';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Asunto
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: 'Asunto *',
                  hintText: 'Describe brevemente tu problema',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.subject),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El asunto es requerido';
                  }
                  if (value.trim().length < 10) {
                    return 'El asunto debe tener al menos 10 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Descripción
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Descripción del problema *',
                  hintText: 'Explica detalladamente qué está pasando',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La descripción es requerida';
                  }
                  if (value.trim().length < 20) {
                    return 'La descripción debe tener al menos 20 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Pasos para reproducir
              TextFormField(
                controller: _reproductionStepsController,
                decoration: InputDecoration(
                  labelText: 'Pasos para reproducir (opcional)',
                  hintText: '1. Ve a la pantalla...\n2. Toca el botón...\n3. Observa que...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.list),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              // Adjuntos
              Text(
                'Adjuntos (opcional)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Puedes adjuntar hasta 3 imágenes para ayudar a entender el problema',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),

              // Botón para agregar imágenes
              if (_attachments.length < 3)
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Agregar imagen'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),

              // Lista de imágenes adjuntas
              if (_attachments.isNotEmpty) ...[
                const SizedBox(height: 16),
                ...(_attachments.asMap().entries.map((entry) {
                  final index = entry.key;
                  final file = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.file(
                            file,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                file.path.split('/').last,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                '${(file.lengthSync() / 1024).toStringAsFixed(1)} KB',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _removeAttachment(index),
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Eliminar imagen',
                        ),
                      ],
                    ),
                  );
                }).toList()),
              ],

              const SizedBox(height: 32),

              // Botón de envío
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitTicket,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(_isLoading ? 'Enviando...' : 'Enviar Ticket'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Información adicional
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Información del ticket',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Tu información personal se incluirá automáticamente\n'
                      '• Recibirás una confirmación por email\n'
                      '• Nuestro equipo responderá en 24-48 horas\n'
                      '• Puedes revisar el estado de tu ticket en tu perfil',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                        height: 1.4,
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
}
