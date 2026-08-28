import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportType {
  lost('lost'),
  found('found');

  const ReportType(this.firestoreValue);

  final String firestoreValue;

  static ReportType fromFirestore(String value) => switch (value) {
        'lost' => ReportType.lost,
        'found' => ReportType.found,
        _ => throw FormatException('Unsupported report type: $value'),
      };
}

enum ReportCategory {
  phone('Phone'),
  wallet('Wallet'),
  keys('Keys'),
  bag('Bag'),
  idCard('ID / Card'),
  laptop('Laptop'),
  watch('Watch'),
  other('Other');

  const ReportCategory(this.firestoreValue);

  final String firestoreValue;

  static ReportCategory fromFirestore(String value) =>
      ReportCategory.values.firstWhere(
        (category) => category.firestoreValue == value,
        orElse: () => throw FormatException('Unsupported report category: $value'),
      );
}

enum ReportStatus {
  active('active'),
  matched('matched'),
  resolved('resolved');

  const ReportStatus(this.firestoreValue);

  final String firestoreValue;

  static ReportStatus fromFirestore(String value) =>
      ReportStatus.values.firstWhere(
        (status) => status.firestoreValue == value,
        orElse: () => throw FormatException('Unsupported report status: $value'),
      );
}

class ReportLocation {
  const ReportLocation({this.latitude, this.longitude, this.description});

  final double? latitude;
  final double? longitude;
  final String? description;

  bool get isEmpty => latitude == null && longitude == null && description == null;

  Map<String, dynamic> toFirestore() => {
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (description != null) 'description': description,
      };

  factory ReportLocation.fromFirestore(Map<String, dynamic>? data) {
    return ReportLocation(
      latitude: (data?['latitude'] as num?)?.toDouble(),
      longitude: (data?['longitude'] as num?)?.toDouble(),
      description: data?['description'] as String?,
    );
  }
}

class LostFoundReport {
  const LostFoundReport({
    required this.id,
    required this.userId,
    required this.type,
    required this.category,
    required this.description,
    required this.color,
    required this.date,
    required this.time,
    required this.status,
    this.location,
    this.imageUrl,
    this.createdAt,
  });

  final String id;
  final String userId;
  final ReportType type;
  final ReportCategory category;
  final String description;
  final String color;
  final DateTime date;
  final String time;
  final ReportLocation? location;
  final String? imageUrl;
  final ReportStatus status;
  final DateTime? createdAt;

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'type': type.firestoreValue,
        'category': category.firestoreValue,
        'description': description,
        'color': color,
        'date': Timestamp.fromDate(date),
        'time': time,
        if (location != null && !location!.isEmpty) 'location': location!.toFirestore(),
        'imageUrl': imageUrl,
        'status': status.firestoreValue,
        'createdAt': createdAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt!),
      };

  Map<String, dynamic> toWebhookPayload({
    required DateTime createdAtFallback,
  }) => {
        'userId': userId,
        'type': type.firestoreValue,
        'category': category.firestoreValue,
        'description': description,
        'color': color,
        'date': date.toIso8601String(),
        'time': time,
        'location': location == null || location!.isEmpty
            ? null
            : location!.toFirestore(),
        'imageUrl': imageUrl,
        'status': status.firestoreValue,
        'createdAt': (createdAt ?? createdAtFallback).toUtc().toIso8601String(),
      };

  factory LostFoundReport.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null) throw StateError('Report ${document.id} does not exist.');
    return LostFoundReport.fromMap(data, id: document.id);
  }

  factory LostFoundReport.fromMap(Map<String, dynamic> data, {required String id}) {
    return LostFoundReport(
      id: id,
      userId: data['userId'] as String,
      type: ReportType.fromFirestore(data['type'] as String),
      category: ReportCategory.fromFirestore(data['category'] as String),
      description: data['description'] as String,
      color: data['color'] as String,
      date: (data['date'] as Timestamp).toDate(),
      time: data['time'] as String,
      location: data['location'] is Map
          ? ReportLocation.fromFirestore(
              Map<String, dynamic>.from(data['location'] as Map),
            )
          : null,
      imageUrl: data['imageUrl'] as String?,
      status: ReportStatus.fromFirestore(data['status'] as String),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
