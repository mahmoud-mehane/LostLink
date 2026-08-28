import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/lost_found_report.dart';
import '../services/auth_service.dart';
import '../services/n8n_webhook_service.dart';

class ReportRepository {
  ReportRepository(this._firestore, this._authService, this._n8nWebhookService);

  final FirebaseFirestore _firestore;
  final AuthService _authService;
  final N8nWebhookService _n8nWebhookService;

  Future<String> createLostReport({
    required ReportCategory category,
    required String description,
    required String color,
    required DateTime date,
    required String time,
    ReportLocation? location,
    String? imageUrl,
  }) {
    return _createReport(
      type: ReportType.lost,
      category: category,
      description: description,
      color: color,
      date: date,
      time: time,
      location: location,
      imageUrl: imageUrl,
    );
  }

  Future<String> createFoundReport({
    required ReportCategory category,
    required String description,
    required String color,
    required DateTime date,
    required String time,
    ReportLocation? location,
    String? imageUrl,
  }) {
    return _createReport(
      type: ReportType.found,
      category: category,
      description: description,
      color: color,
      date: date,
      time: time,
      location: location,
      imageUrl: imageUrl,
    );
  }

  Future<LostFoundReport?> getReport({
    required ReportType type,
    required String reportId,
  }) async {
    _requireCurrentUserId();
    try {
      final document = await _collection(type).doc(reportId).get();
      return document.exists ? LostFoundReport.fromFirestore(document) : null;
    } on FirebaseException {
      throw const ReportFailure('We could not load this report. Please try again.');
    }
  }

  Future<List<LostFoundReport>> getCurrentUserReports({
    ReportType? type,
  }) async {
    final userId = _requireCurrentUserId();
    try {
      final types = type == null ? ReportType.values : [type];
      final snapshots = await Future.wait(
        types.map(
          (reportType) => _collection(reportType)
              .where('userId', isEqualTo: userId)
              .get(),
        ),
      );
      final reports = snapshots
          .expand((snapshot) => snapshot.docs)
          .map(LostFoundReport.fromFirestore)
          .toList();
      reports.sort((a, b) {
        final aCreatedAt = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bCreatedAt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bCreatedAt.compareTo(aCreatedAt);
      });
      return reports;
    } on FirebaseException {
      throw const ReportFailure('We could not load your reports. Please try again.');
    }
  }

  Future<void> updateReportStatus({
    required ReportType type,
    required String reportId,
    required ReportStatus status,
  }) async {
    _requireCurrentUserId();
    try {
      await _collection(type).doc(reportId).update({
        'status': status.firestoreValue,
      });
    } on FirebaseException {
      throw const ReportFailure('We could not update this report. Please try again.');
    }
  }

  Future<String> _createReport({
    required ReportType type,
    required ReportCategory category,
    required String description,
    required String color,
    required DateTime date,
    required String time,
    required ReportLocation? location,
    required String? imageUrl,
  }) async {
    final userId = _requireCurrentUserId();
    final document = _collection(type).doc();
    final report = LostFoundReport(
      id: document.id,
      userId: userId,
      type: type,
      category: category,
      description: description,
      color: color,
      date: date,
      time: time,
      location: location,
      imageUrl: imageUrl,
      status: ReportStatus.active,
    );
    try {
      await document.set(report.toFirestore());
    } on FirebaseException {
      throw const ReportFailure('We could not create your report. Please try again.');
    }

    await _notifyN8n(document, report);
    return document.id;
  }

  Future<void> _notifyN8n(
    DocumentReference<Map<String, dynamic>> document,
    LostFoundReport fallbackReport,
  ) async {
    var report = fallbackReport;
    try {
      final snapshot = await document.get(const GetOptions(source: Source.server));
      if (snapshot.exists) report = LostFoundReport.fromFirestore(snapshot);
    } catch (_) {
      // The report has already been saved; use the original data as a fallback.
    }

    try {
      await _n8nWebhookService.sendReport(
        report,
        createdAtFallback: DateTime.now().toUtc(),
      );
    } on WebhookFailure {
      // n8n is non-critical to report persistence. Its failure is intentionally
      // isolated so users retain the report saved in Firestore.
    }
  }

  CollectionReference<Map<String, dynamic>> _collection(ReportType type) {
    return _firestore.collection(
      type == ReportType.lost ? 'lostItems' : 'foundItems',
    );
  }

  String _requireCurrentUserId() {
    final user = _authService.currentUser;
    if (user == null) {
      throw const ReportFailure('You must be signed in to manage reports.');
    }
    return user.uid;
  }
}

class ReportFailure implements Exception {
  const ReportFailure(this.message);

  final String message;
}
