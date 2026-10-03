import 'package:hive/hive.dart';

part 'contact_model.g.dart';

@HiveType(typeId: 0)
class ContactModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String phoneNumber;

  @HiveField(3)
  final String relationship;

  @HiveField(4)
  final int priority;

  @HiveField(5)
  final String? email;

  @HiveField(6)
  final bool isPrimary;

  ContactModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.relationship,
    required this.priority,
    this.email,
    this.isPrimary = false,
  });

  ContactModel copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? relationship,
    int? priority,
    String? email,
    bool? isPrimary,
  }) {
    return ContactModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      relationship: relationship ?? this.relationship,
      priority: priority ?? this.priority,
      email: email ?? this.email,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phoneNumber': phoneNumber,
        'relationship': relationship,
        'priority': priority,
        'email': email,
        'isPrimary': isPrimary,
      };

  factory ContactModel.fromJson(Map<String, dynamic> json) => ContactModel(
        id: json['id'] as String,
        name: json['name'] as String,
        phoneNumber: json['phoneNumber'] as String,
        relationship: json['relationship'] as String,
        priority: json['priority'] as int,
        email: json['email'] as String?,
        isPrimary: json['isPrimary'] as bool? ?? false,
      );
}
