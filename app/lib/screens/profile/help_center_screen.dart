import 'package:flutter/material.dart';
import 'contact_support_screen.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Centro de Ayuda'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    Icons.help_outline,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '¿En qué podemos ayudarte?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Encuentra respuestas a las preguntas más frecuentes sobre el uso de la aplicación.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildFAQItem(
              '¿Cómo puedo cambiar mi contraseña?',
              'Ve a Configuración > Seguridad > Cambiar Contraseña. Ingresa tu contraseña actual y la nueva contraseña dos veces para confirmar.',
            ),
            _buildFAQItem(
              '¿Cómo habilito la autenticación biométrica?',
              'Ve a Configuración > Seguridad > Autenticación biométrica y activa el toggle. Luego sigue las instrucciones de tu dispositivo.',
            ),
            _buildFAQItem(
              '¿Qué hago si olvidé mi contraseña?',
              'Contacta al administrador de tu comunidad para que pueda restablecer tu contraseña desde el panel de administración.',
            ),
            _buildFAQItem(
              '¿Cómo puedo ver los gastos de mi comunidad?',
              'En la pantalla principal, toca "Gastos" en la barra de navegación inferior. Allí podrás ver todos los gastos registrados.',
            ),
            _buildFAQItem(
              '¿Cómo participo en las encuestas?',
              'Ve a la sección "Encuestas" desde el menú principal. Selecciona una encuesta activa y responde las preguntas.',
            ),
            _buildFAQItem(
              '¿Puedo comentar en las publicaciones del blog?',
              'Sí, en la pantalla de detalle de cualquier publicación del blog podrás agregar comentarios y ver los de otros usuarios.',
            ),
            _buildFAQItem(
              '¿Cómo cambio mi información personal?',
              'Ve a tu Perfil y toca el botón de editar (lápiz). Modifica los campos que desees y guarda los cambios.',
            ),
            _buildFAQItem(
              '¿Qué significa cada rol de usuario?',
              'Super Admin: Acceso completo a todas las funciones. Administrador: Gestiona su comunidad. Residente: Acceso limitado a funciones básicas.',
            ),
            _buildFAQItem(
              '¿Cómo reporto un problema técnico?',
              'Usa la opción "Contactar Soporte" en Configuración > Ayuda y Soporte para enviar un mensaje al equipo técnico.',
            ),
            _buildFAQItem(
              '¿Puedo cambiar el idioma de la aplicación?',
              'Actualmente la aplicación solo está disponible en español. No es posible cambiar el idioma.',
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFF2196F3),
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '¿No encontraste la respuesta?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Contacta directamente con nuestro equipo de soporte técnico.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ContactSupportScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.headset),
                    label: const Text('Contactar Soporte'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.question_mark_rounded,
                color: Color(0xFF2196F3),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1A237E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: Color(0xFF4CAF50),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  answer,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
