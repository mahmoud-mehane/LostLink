class AppConfig {
  const AppConfig._();

  /// Override at build/run time with --dart-define=N8N_REPORT_WEBHOOK_URL=...
  static const reportWebhookUrl = String.fromEnvironment(
    'N8N_REPORT_WEBHOOK_URL',
    defaultValue: 'https://mahmoudmehane.app.n8n.cloud/webhook-test/lostlink/report',
  );
}
