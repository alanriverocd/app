import 'dart:convert';
import 'package:http/http.dart' as http;

/// Servicio para enviar correos vía EmailJS REST API.
///
/// Configuración requerida (obtener en https://www.emailjs.com):
///   - [serviceId]   → Dashboard → Email Services → tu servicio
///   - [templateId]  → Email Templates → tu plantilla
///   - [publicKey]   → Account → General → Public Key
///
/// Parámetros de la plantilla que debes definir en EmailJS:
///   {{to_email}}  — correo del destinatario
///   {{app_url}}   — URL de la app para que el cliente entre a registrarse
class EmailService {
  static const String _endpoint =
      'https://api.emailjs.com/api/v1.0/email/send';

  // ── Reemplaza estos valores con los tuyos de EmailJS ──────────────────────
  static const String serviceId = 'service_6qtc36b';
  static const String templateId = 'template_0t6uhqn';
  static const String publicKey = 'Yp8JpIbOpULMPWMJZ';
  // La URL donde tus clientes acceden a la app
  static const String appUrl = 'https://tu-app.web.app';
  // ──────────────────────────────────────────────────────────────────────────

  /// Envía correo de invitación al cliente pre-registrado.
  /// Lanza [Exception] si falla el envío.
  static Future<void> enviarInvitacion({
    required String emailDestino,
    String? nombreAdmin,
  }) async {
    if (serviceId == 'TU_SERVICE_ID') {
      // EmailJS no configurado: silenciosamente no envía (modo desarrollo)
      return;
    }

    final response = await http
        .post(
          Uri.parse(_endpoint),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'service_id': serviceId,
            'template_id': templateId,
            'user_id': publicKey,
            'template_params': {
              'to_email': emailDestino,
              'app_url': appUrl,
              'admin_nombre': nombreAdmin ?? 'El administrador',
            },
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception(
          'No se pudo enviar el correo de invitación (${response.statusCode})');
    }
  }
}
