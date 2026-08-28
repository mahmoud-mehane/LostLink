import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../repositories/report_repository.dart';
import '../services/auth_service.dart';
import '../services/n8n_webhook_service.dart';
import '../services/user_profile_repository.dart';

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return UserProfileRepository(FirebaseFirestore.instance);
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    FirebaseAuth.instance,
    ref.watch(userProfileRepositoryProvider),
  );
});

final n8nWebhookServiceProvider = Provider<N8nWebhookService>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return N8nWebhookService(client, AppConfig.reportWebhookUrl);
});

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(
    FirebaseFirestore.instance,
    ref.watch(authServiceProvider),
    ref.watch(n8nWebhookServiceProvider),
  );
});

/// Current Firebase user for later UID-scoped profiles and reports.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges();
});

/// Prevents Home until registration has created the required profile document.
final registrationInProgressProvider = StateProvider<bool>((ref) => false);
