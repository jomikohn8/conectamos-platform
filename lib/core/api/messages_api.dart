import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:conectamos_platform/core/api/api_client.dart';

class MessagesApi {
  static Future<List<Map<String, dynamic>>> listConversations() async {
    final response = await ApiClient.instance.get(
      '/messages',
      queryParameters: {'limit': 500},
    );
    final messages = List<Map<String, dynamic>>.from(response.data);

    final Map<String, Map<String, dynamic>> byChat = {};
    for (final msg in messages) {
      final chatId = msg['chat_id'] as String? ?? '';
      if (!byChat.containsKey(chatId)) {
        byChat[chatId] = msg;
      }
    }
    return byChat.values.toList();
  }

  static Future<List<Map<String, dynamic>>> listMessages({
    String? chatId,
    int limit = 100,
  }) async {
    final response = await ApiClient.instance.get(
      '/messages',
      queryParameters: {
        'chat_id': ?chatId,
        'limit': limit,
      },
    );
    return List<Map<String, dynamic>>.from(response.data);
  }

  static Future<Map<String, dynamic>> sendMessage({
    required String to,
    required String text,
    String? phoneNumberId,
  }) async {
    final response = await ApiClient.instance.post(
      '/messages/send',
      queryParameters: {
        'to': to,
        'text': text,
        'phone_number_id': ?phoneNumberId,
      },
    );
    return Map<String, dynamic>.from(response.data);
  }

  static Future<void> markRead(String waMessageId) async {
    try {
      await ApiClient.instance.post(
        '/messages/read',
        data: {'message_id': waMessageId},
      );
    } catch (_) {}
  }

  static Future<void> sendTyping(String waMessageId) async {
    try {
      await ApiClient.instance.post(
        '/messages/typing',
        data: {'message_id': waMessageId},
      );
    } catch (_) {}
  }

  /// Envía un mensaje outbound a través del backend.
  /// El backend llama a Meta Graph API y persiste el registro en wa_messages.
  static Future<void> sendWhatsAppMessage({
    required String to,
    required String text,
    required String tenantId,
    String? sentByUserId,
  }) async {
    await ApiClient.instance.post(
      '/messages/send',
      data: {
        'to':               to,
        'message':          text,
        'tenant_id':        tenantId,
        'sent_by_user_id': ?sentByUserId,
      },
    );
  }

  /// Envía un archivo multimedia (imagen, audio, documento) vía multipart.
  static Future<void> sendMedia({
    required String to,
    required Uint8List fileBytes,
    required String filename,
    required String tenantId,
    String? caption,
    String? sentByUserId,
  }) async {
    final formData = FormData.fromMap({
      'to': to,
      'tenant_id': tenantId,
      'file': MultipartFile.fromBytes(fileBytes, filename: filename),
      if (caption != null && caption.isNotEmpty) 'caption': caption,
      'sent_by_user_id': ?sentByUserId,
    });
    await ApiClient.instance.post('/messages/send/media', data: formData);
  }

  /// Envía una ubicación de Google Maps parseando la URL.
  static Future<void> sendLocation({
    required String to,
    required String tenantId,
    required String googleMapsUrl,
    String? sentByUserId,
  }) async {
    await ApiClient.instance.post(
      '/messages/send/location',
      data: {
        'to':              to,
        'tenant_id':       tenantId,
        'google_maps_url': googleMapsUrl,
        'sent_by_user_id': ?sentByUserId,
      },
    );
  }

  /// Envía una solicitud de ubicación interactiva.
  static Future<void> sendLocationRequest({
    required String to,
    required String tenantId,
    String? sentByUserId,
  }) async {
    await ApiClient.instance.post(
      '/messages/send/location-request',
      data: {
        'to':              to,
        'tenant_id':       tenantId,
        'sent_by_user_id': ?sentByUserId,
      },
    );
  }
}
