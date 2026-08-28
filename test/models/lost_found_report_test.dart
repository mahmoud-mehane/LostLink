import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lostlink/models/lost_found_report.dart';

void main() {
  final reportDate = DateTime.utc(2026, 8, 28);
  final createdAt = DateTime.utc(2026, 8, 29, 10, 30);

  test('serializes a lost report with optional GPS and description', () {
    const location = ReportLocation(
      latitude: 30.0444,
      longitude: 31.2357,
      description: 'Near the university gate',
    );
    final report = LostFoundReport(
      id: 'report-id',
      userId: 'user-id',
      type: ReportType.lost,
      category: ReportCategory.keys,
      description: 'Three keys on a blue keyring',
      color: 'Blue',
      date: reportDate,
      time: 'Around 5 PM',
      location: location,
      status: ReportStatus.active,
      createdAt: createdAt,
    );

    final data = report.toFirestore();

    expect(data['userId'], 'user-id');
    expect(data['type'], 'lost');
    expect(data['category'], 'Keys');
    expect(data['date'], Timestamp.fromDate(reportDate));
    expect(data['createdAt'], Timestamp.fromDate(createdAt));
    expect(data['imageUrl'], isNull);
    expect(data['location'], {
      'latitude': 30.0444,
      'longitude': 31.2357,
      'description': 'Near the university gate',
    });
  });

  test('deserializes a report when optional location and image are absent', () {
    final report = LostFoundReport.fromMap({
      'userId': 'user-id',
      'type': 'found',
      'category': 'Wallet',
      'description': 'Black wallet',
      'color': 'Black',
      'date': Timestamp.fromDate(reportDate),
      'time': 'Morning',
      'status': 'active',
      'createdAt': Timestamp.fromDate(createdAt),
    }, id: 'report-id');

    expect(report.id, 'report-id');
    expect(report.type, ReportType.found);
    expect(report.location, isNull);
    expect(report.imageUrl, isNull);
    expect(report.status, ReportStatus.active);
  });

  test('location supports GPS only and description only', () {
    expect(
      const ReportLocation(latitude: 30.0, longitude: 31.0).toFirestore(),
      {'latitude': 30.0, 'longitude': 31.0},
    );
    expect(
      const ReportLocation(description: 'At the train station').toFirestore(),
      {'description': 'At the train station'},
    );
    expect(const ReportLocation().isEmpty, isTrue);
  });

  test('creates the n8n payload with all required report fields', () {
    final report = LostFoundReport(
      id: 'report-id',
      userId: 'user-id',
      type: ReportType.found,
      category: ReportCategory.wallet,
      description: 'Black wallet',
      color: 'Black',
      date: reportDate,
      time: 'Morning',
      location: const ReportLocation(description: 'At the train station'),
      imageUrl: null,
      status: ReportStatus.active,
      createdAt: createdAt,
    );

    final payload = report.toWebhookPayload(
      createdAtFallback: DateTime.utc(2026),
    );

    expect(payload.keys.toSet(), {
      'userId', 'type', 'category', 'description', 'color', 'date', 'time',
      'location', 'imageUrl', 'status', 'createdAt',
    });
    expect(payload['location'], {'description': 'At the train station'});
    expect(payload['createdAt'], createdAt.toIso8601String());
  });
}
