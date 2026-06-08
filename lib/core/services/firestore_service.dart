import 'package:cloud_firestore/cloud_firestore.dart';

import '../../bootstrap/backend_bootstrap.dart';
import '../data/demo_data.dart';
import '../models/app_models.dart';

class FirestoreService {
  FirestoreService(this.backendState);

  final BackendState backendState;

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  bool get ready => backendState.firebaseReady;

  Stream<List<Appointment>> appointmentsForUser(AppUser user) {
    if (!ready) return Stream.value(_appointmentsForMockUser(user));

    Query<Map<String, dynamic>> query = _db.collection('appointments');
    if (user.role == AppRole.citizen) {
      query = query.where('patientId', isEqualTo: user.id);
    } else if (user.role == AppRole.professional) {
      query = query.where('providerEmail', isEqualTo: user.email);
    }

    return query.snapshots().map((event) {
      final items = event.docs.map((doc) => Appointment.fromMap(doc.id, doc.data())).toList();
      items.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      return items;
    });
  }

  Stream<List<Incident>> activeIncidents({AppUser? responder}) {
    if (!ready) return Stream.value(DemoData.incidents);

    return _db
        .collection('incidents')
        .where('status', whereIn: ['pending', 'dispatched', 'in-progress'])
        .snapshots()
        .map((event) {
      final items = event.docs.map((doc) => Incident.fromMap(doc.id, doc.data())).toList();
      items.sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
      return items;
    });
  }

  Stream<List<Facility>> facilities() {
    if (!ready) return Stream.value(DemoData.facilities);
    return _db
        .collection('facilities')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((event) => event.docs.map((doc) => Facility.fromMap(doc.id, doc.data())).toList());
  }

  Stream<List<Hotspot>> hotspots() {
    if (!ready) return Stream.value(DemoData.hotspots);
    return _db.collection('disease_hotspots').snapshots().map((event) {
      final items = event.docs.map((doc) => Hotspot.fromMap(doc.id, doc.data())).toList();
      items.sort((a, b) => b.cases.compareTo(a.cases));
      return items;
    });
  }

  Stream<List<AppUser>> pendingUsers() {
    if (!ready) {
      return Stream.value([
        const AppUser(
          id: 'pending-pro-001',
          authId: 'pending-pro-001',
          email: 'newdoctor@sagip.ph',
          fullName: 'Dr. Miguel Ramos',
          role: AppRole.professional,
          status: 'pending',
        ),
        const AppUser(
          id: 'pending-ems-001',
          authId: 'pending-ems-001',
          email: 'newems@sagip.ph',
          fullName: 'EMS Unit 07',
          role: AppRole.responder,
          status: 'pending',
        ),
      ]);
    }
    return _db
        .collection('users')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((event) => event.docs.map((doc) => AppUser.fromMap(doc.id, doc.data())).toList());
  }

  Future<void> bookAppointment(Appointment appointment) async {
    if (!ready) return;
    await _db.collection('appointments').add(appointment.toMap());
    await createNotification(
      userId: appointment.patientId,
      type: 'appointment',
      title: 'Appointment request sent',
      body: '${appointment.providerName} will review your ${appointment.type} request.',
      linkTo: 'appointments',
    );
  }

  Future<void> updateAppointmentStatus({
    required String appointmentId,
    required String status,
    String? declineReason,
    String? teleconsultUrl,
  }) async {
    if (!ready) return;
    await _db.collection('appointments').doc(appointmentId).update({
      'status': status,
      'declineReason': declineReason,
      'teleconsultUrl': teleconsultUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createSosAlert({
    required AppUser user,
    required String message,
    required String address,
    String priority = 'CRITICAL',
  }) async {
    if (!ready) return;

    final sosRef = await _db.collection('sos_alerts').add({
      'userId': user.id,
      'message': message,
      'address': address,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _db.collection('incidents').add({
      'type': 'SOS Emergency',
      'priority': priority,
      'status': 'pending',
      'address': address,
      'barangay': _barangayFromAddress(address),
      'patientInfo': '${user.fullName}${user.age == null ? '' : ', ${user.age}'}${user.sex == null ? '' : ', ${user.sex}'}',
      'notes': message,
      'reportedBy': user.id,
      'sosAlertId': sosRef.id,
      'reportedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> submitSymptomCheck({
    required AppUser user,
    required List<String> symptoms,
    required String bodyArea,
    required SymptomResult result,
  }) async {
    if (!ready) return;
    await _db.collection('symptom_checks').add({
      'userId': user.id,
      'symptoms': symptoms,
      'bodyArea': bodyArea,
      'severity': result.severity,
      'recommendedSpecialty': result.specialty,
      'aiSummary': result.summary,
      'recommendations': result.recommendations,
      'checkedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveMentalHealthSession({
    required AppUser user,
    required int moodScore,
    required String moodLabel,
    required String journalEntry,
    required List<String> exercisesDone,
  }) async {
    if (!ready) return;
    await _db.collection('mental_health_sessions').add({
      'userId': user.id,
      'moodScore': moodScore,
      'moodLabel': moodLabel,
      'journalEntry': journalEntry,
      'exercisesDone': exercisesDone,
      'sessionAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptIncident({required String incidentId, required AppUser responder}) async {
    if (!ready) return;
    await _db.collection('incidents').doc(incidentId).update({
      'status': 'dispatched',
      'assignedResponderId': responder.id,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateIncidentStatus({required String incidentId, required String status}) async {
    if (!ready) return;
    final payload = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (status == 'resolved') payload['resolvedAt'] = FieldValue.serverTimestamp();
    await _db.collection('incidents').doc(incidentId).update(payload);
  }

  Future<void> submitIncidentReport({
    required Incident incident,
    required AppUser responder,
    required String actionsTaken,
    required String outcome,
  }) async {
    if (!ready) return;
    await _db.collection('incident_reports').add({
      'reportNo': 'R-${DateTime.now().millisecondsSinceEpoch}',
      'incidentId': incident.id,
      'filedBy': responder.id,
      'type': incident.type,
      'location': incident.address,
      'patientInfo': incident.patientInfo,
      'actionsTaken': actionsTaken,
      'outcome': outcome,
      'filedAt': FieldValue.serverTimestamp(),
    });
    await updateIncidentStatus(incidentId: incident.id, status: 'resolved');
  }

  Future<void> updateUserStatus({required String userId, required String status, required AppUser actor}) async {
    if (!ready) return;
    await _db.collection('users').doc(userId).update({
      'status': status,
      'approvedAt': status == 'approved' ? FieldValue.serverTimestamp() : null,
      'approvedBy': actor.id,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _db.collection('audit_logs').add({
      'actorId': actor.id,
      'action': status == 'approved' ? 'APPROVE_USER' : 'REJECT_USER',
      'targetType': 'user',
      'targetId': userId,
      'metadata': {'status': status},
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    String? linkTo,
  }) async {
    if (!ready) return;
    await _db.collection('notifications').add({
      'userId': userId,
      'type': type,
      'title': title,
      'body': body,
      'isRead': false,
      'linkTo': linkTo,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> seedDemoData() async {
    if (!ready) return;
    final batch = _db.batch();

    for (final user in DemoData.demoUsers.values) {
      batch.set(_db.collection('users').doc(user.id), {
        ...user.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    for (final facility in DemoData.facilities) {
      batch.set(_db.collection('facilities').doc(facility.id), {
        'name': facility.name,
        'type': facility.type,
        'address': facility.address,
        'phone': facility.phone,
        'services': facility.services,
        'distanceKm': facility.distanceKm,
        'latitude': facility.latitude,
        'longitude': facility.longitude,
        'isActive': true,
        'city': 'Batangas City',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    for (final hotspot in DemoData.hotspots) {
      batch.set(_db.collection('disease_hotspots').doc(hotspot.id), {
        'barangay': hotspot.barangay,
        'city': 'Batangas City',
        'disease': hotspot.disease,
        'cases': hotspot.cases,
        'level': hotspot.level,
        'trend': hotspot.trend,
        'weekStart': Timestamp.fromDate(DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1))),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  List<Appointment> _appointmentsForMockUser(AppUser user) {
    if (user.role == AppRole.professional) return DemoData.appointments;
    if (user.role == AppRole.admin) return DemoData.appointments;
    return DemoData.appointments.where((item) => item.patientId == 'demo-citizen').toList();
  }

  String _barangayFromAddress(String address) {
    final lower = address.toLowerCase();
    if (lower.contains('san jose')) return 'San Jose';
    if (lower.contains('poblacion')) return 'Poblacion 4';
    if (lower.contains('kumintang')) return 'Kumintang Ibaba';
    return 'Unspecified';
  }
}
