import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/lost_found_report.dart';

class N8nWebhookService {
  N8nWebhookService(this._client, this._webhookUrl);

  final http.Client _client;
  final String _webhookUrl;

  Future<void> sendReport(
    LostFoundReport report, {
    required DateTime createdAtFallback,
  }) async {
    final uri = Uri.tryParse(_webhookUrl);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      throw const WebhookFailure();
    }

    try {
      final response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(
              report.toWebhookPayload(createdAtFallback: createdAtFallback),
            ),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const WebhookFailure();
      }
    } on WebhookFailure {
      rethrow;
    } catch (_) {
      throw const WebhookFailure();
    }
  }
}

class WebhookFailure implements Exception {
  const WebhookFailure();
}
