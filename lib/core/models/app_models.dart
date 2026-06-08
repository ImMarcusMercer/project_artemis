import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _date(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}

enum AppRole { citizen, responder, professional, admin }

extension AppRoleX on AppRole {
  String get id => name;
  String get label {
    switch (this) {
      case AppRole.citizen:
        return 'Citizen';
      case AppRole.responder:
        return 'Responder';
      case AppRole.professional:
        return 'Professional';
      case AppRole.admin:
        return 'Admin';
    }
  }

  String get emoji {
    switch (this) {
      case AppRole.citizen:
        return '👤';
      case AppRole.responder:
        return '🚑';
      case AppRole.professional:
        return '👩‍⚕️';
      case AppRole.admin:
        return '🏛️';
    }
  }

  static AppRole from(String? value) {
    return AppRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => AppRole.citizen,
    );
  }
}

class AppUser {
  const AppUser({
    required this.id,
    required this.authId,
    required this.email,
    required this.fullName,
    required this.role,
    required this.status,
    this.phone,
    this.address,
    this.avatarUrl,
    this.age,
    this.sex,
    this.bloodType,
    this.allergies,
    this.emergencyContact,
    this.medicalConditions = const [],
  });

  final String id;
  final String authId;
  final String email;
  final String fullName;
  final AppRole role;
  final String status;
  final String? phone;
  final String? address;
  final String? avatarUrl;
  final String? age;
  final String? sex;
  final String? bloodType;
  final String? allergies;
  final String? emergencyContact;
  final List<String> medicalConditions;

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Map<String, dynamic> toMap() => {
        'authId': authId,
        'email': email,
        'fullName': fullName,
        'role': role.name,
        'status': status,
        'phone': phone,
        'address': address,
        'avatarUrl': avatarUrl,
        'age': age,
        'sex': sex,
        'bloodType': bloodType,
        'allergies': allergies,
        'emergencyContact': emergencyContact,
        'medicalConditions': medicalConditions,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory AppUser.fromMap(String id, Map<String, dynamic> map) {
    return AppUser(
      id: id,
      authId: (map['authId'] ?? id).toString(),
      email: (map['email'] ?? '').toString(),
      fullName: (map['fullName'] ?? map['name'] ?? 'ResQ User').toString(),
      role: AppRoleX.from(map['role']?.toString()),
      status: (map['status'] ?? 'approved').toString(),
      phone: map['phone']?.toString(),
      address: map['address']?.toString(),
      avatarUrl: map['avatarUrl']?.toString(),
      age: map['age']?.toString(),
      sex: map['sex']?.toString(),
      bloodType: map['bloodType']?.toString(),
      allergies: map['allergies']?.toString(),
      emergencyContact: map['emergencyContact']?.toString(),
      medicalConditions: List<String>.from(map['medicalConditions'] ?? const []),
    );
  }

  AppUser copyWith({String? avatarUrl, String? status}) {
    return AppUser(
      id: id,
      authId: authId,
      email: email,
      fullName: fullName,
      role: role,
      status: status ?? this.status,
      phone: phone,
      address: address,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      age: age,
      sex: sex,
      bloodType: bloodType,
      allergies: allergies,
      emergencyContact: emergencyContact,
      medicalConditions: medicalConditions,
    );
  }
}

class Appointment {
  const Appointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.providerName,
    required this.providerSpecialty,
    required this.facilityName,
    required this.scheduledAt,
    required this.type,
    required this.status,
    required this.reason,
    this.providerId,
    this.providerEmail,
    this.facilityId,
    this.contactNumber,
    this.teleconsultUrl,
    this.declineReason,
  });

  final String id;
  final String patientId;
  final String? providerId;
  final String? providerEmail;
  final String? facilityId;
  final String patientName;
  final String providerName;
  final String providerSpecialty;
  final String facilityName;
  final DateTime scheduledAt;
  final String type;
  final String status;
  final String reason;
  final String? contactNumber;
  final String? teleconsultUrl;
  final String? declineReason;

  Map<String, dynamic> toMap() => {
        'patientId': patientId,
        'providerId': providerId,
        'providerEmail': providerEmail,
        'facilityId': facilityId,
        'patientName': patientName,
        'providerName': providerName,
        'providerSpecialty': providerSpecialty,
        'facilityName': facilityName,
        'scheduledAt': Timestamp.fromDate(scheduledAt),
        'type': type,
        'status': status,
        'reason': reason,
        'contactNumber': contactNumber,
        'teleconsultUrl': teleconsultUrl,
        'declineReason': declineReason,
        'bookedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory Appointment.fromMap(String id, Map<String, dynamic> map) {
    return Appointment(
      id: id,
      patientId: (map['patientId'] ?? '').toString(),
      providerId: map['providerId']?.toString(),
      providerEmail: map['providerEmail']?.toString(),
      facilityId: map['facilityId']?.toString(),
      patientName: (map['patientName'] ?? 'Patient').toString(),
      providerName: (map['providerName'] ?? 'Provider').toString(),
      providerSpecialty: (map['providerSpecialty'] ?? 'General Medicine').toString(),
      facilityName: (map['facilityName'] ?? 'Health Facility').toString(),
      scheduledAt: _date(map['scheduledAt']),
      type: (map['type'] ?? 'in-person').toString(),
      status: (map['status'] ?? 'pending').toString(),
      reason: (map['reason'] ?? map['reasonForVisit'] ?? '').toString(),
      contactNumber: map['contactNumber']?.toString(),
      teleconsultUrl: map['teleconsultUrl']?.toString(),
      declineReason: map['declineReason']?.toString(),
    );
  }
}

class Incident {
  const Incident({
    required this.id,
    required this.type,
    required this.priority,
    required this.status,
    required this.address,
    required this.reportedAt,
    this.patientInfo,
    this.barangay,
    this.notes,
    this.reportedBy,
    this.assignedResponderId,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String type;
  final String priority;
  final String status;
  final String address;
  final DateTime reportedAt;
  final String? patientInfo;
  final String? barangay;
  final String? notes;
  final String? reportedBy;
  final String? assignedResponderId;
  final double? latitude;
  final double? longitude;

  Map<String, dynamic> toMap() => {
        'type': type,
        'priority': priority,
        'status': status,
        'address': address,
        'barangay': barangay,
        'patientInfo': patientInfo,
        'notes': notes,
        'reportedBy': reportedBy,
        'assignedResponderId': assignedResponderId,
        'latitude': latitude,
        'longitude': longitude,
        'reportedAt': Timestamp.fromDate(reportedAt),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory Incident.fromMap(String id, Map<String, dynamic> map) {
    return Incident(
      id: id,
      type: (map['type'] ?? 'Emergency').toString(),
      priority: (map['priority'] ?? 'MODERATE').toString(),
      status: (map['status'] ?? 'pending').toString(),
      address: (map['address'] ?? 'Unknown location').toString(),
      reportedAt: _date(map['reportedAt']),
      patientInfo: map['patientInfo']?.toString(),
      barangay: map['barangay']?.toString(),
      notes: map['notes']?.toString(),
      reportedBy: map['reportedBy']?.toString(),
      assignedResponderId: map['assignedResponderId']?.toString(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }
}

class Facility {
  const Facility({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.services,
    required this.distanceKm,
    this.phone,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;
  final String type;
  final String address;
  final List<String> services;
  final double distanceKm;
  final String? phone;
  final double? latitude;
  final double? longitude;

  factory Facility.fromMap(String id, Map<String, dynamic> map) {
    return Facility(
      id: id,
      name: (map['name'] ?? 'Health Facility').toString(),
      type: (map['type'] ?? 'Clinic').toString(),
      address: (map['address'] ?? '').toString(),
      services: List<String>.from(map['services'] ?? const []),
      distanceKm: ((map['distanceKm'] ?? 0) as num).toDouble(),
      phone: map['phone']?.toString(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }
}

class Hotspot {
  const Hotspot({
    required this.id,
    required this.barangay,
    required this.disease,
    required this.cases,
    required this.level,
    required this.trend,
  });

  final String id;
  final String barangay;
  final String disease;
  final int cases;
  final String level;
  final String trend;

  factory Hotspot.fromMap(String id, Map<String, dynamic> map) {
    return Hotspot(
      id: id,
      barangay: (map['barangay'] ?? '').toString(),
      disease: (map['disease'] ?? '').toString(),
      cases: ((map['cases'] ?? 0) as num).toInt(),
      level: (map['level'] ?? 'MODERATE').toString(),
      trend: (map['trend'] ?? 'stable').toString(),
    );
  }
}

class SymptomResult {
  const SymptomResult({
    required this.severity,
    required this.specialty,
    required this.summary,
    required this.recommendations,
  });

  final String severity;
  final String specialty;
  final String summary;
  final List<String> recommendations;
}
