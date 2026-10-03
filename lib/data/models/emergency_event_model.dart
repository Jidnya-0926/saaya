import 'package:hive/hive.dart';

part 'emergency_event_model.g.dart';

@HiveType(typeId: 1)
class EmergencyEventModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime timestamp;

  @HiveField(2)
  final String triggerType; // Button, Voice, etc.

  @HiveField(3)
  final int contactsNotifiedCount;

  @HiveField(4)
  final String locationSummary;

  @HiveField(5)
  final String resolutionStatus; // Active, Resolved, Cancelled

  @HiveField(6)
  final int durationSeconds;

  EmergencyEventModel({
    required this.id,
    required this.timestamp,
    required this.triggerType,
    required this.contactsNotifiedCount,
    required this.locationSummary,
    required this.resolutionStatus,
    required this.durationSeconds,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'triggerType': triggerType,
        'contactsNotifiedCount': contactsNotifiedCount,
        'locationSummary': locationSummary,
        'resolutionStatus': resolutionStatus,
        'durationSeconds': durationSeconds,
      };

  factory EmergencyEventModel.fromJson(Map<String, dynamic> json) =>
      EmergencyEventModel(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        triggerType: json['triggerType'] as String,
        contactsNotifiedCount: json['contactsNotifiedCount'] as int,
        locationSummary: json['locationSummary'] as String,
        resolutionStatus: json['resolutionStatus'] as String,
        durationSeconds: json['durationSeconds'] as int,
      );
}
