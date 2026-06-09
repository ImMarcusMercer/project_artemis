# Artemis v1.1 Firestore Schema Cleanup

The original SQL/Supabase schema was converted to Firestore collections because Firebase is now the primary auth and database layer. Supabase is reserved only for file/image storage.

## Core collections

### users/{uid}
Uses the Firebase Auth UID as the document ID.

```json
{
  "authId": "uid",
  "email": "juan@example.com",
  "fullName": "Juan Dela Cruz",
  "role": "citizen | responder | professional | admin",
  "status": "pending | approved | rejected | suspended",
  "phone": "+63...",
  "address": "Brgy. San Jose, Batangas City",
  "age": "29",
  "sex": "Male",
  "bloodType": "O+",
  "allergies": "Penicillin",
  "emergencyContact": "Maria Dela Cruz · +63...",
  "medicalConditions": ["Asthma"],
  "avatarUrl": "https://supabase-storage-url",
  "createdAt": "server timestamp",
  "updatedAt": "server timestamp",
  "approvedAt": "server timestamp",
  "approvedBy": "admin uid"
}
```

### facilities/{facilityId}
Publicly readable to signed-in users. Admin writes only.

```json
{
  "name": "Batangas Medical Center",
  "type": "Level 3 Hospital",
  "address": "Kumintang Ibaba, Batangas City",
  "city": "Batangas City",
  "barangay": "Kumintang Ibaba",
  "phone": "(043) ...",
  "services": ["Emergency", "Internal Medicine"],
  "latitude": 13.775,
  "longitude": 121.064,
  "distanceKm": 2.4,
  "isActive": true,
  "createdAt": "server timestamp"
}
```

### appointments/{appointmentId}
Cleaned from separate `date` + `time` fields to one `scheduledAt` timestamp. Provider/facility names are retained as display snapshots for mockup stability, but providerId/facilityId should be used for real joins. For the prototype, `providerEmail` is also stored so demo bookings can route to a professional account even before fixed provider UIDs exist.

```json
{
  "patientId": "uid",
  "providerId": "uid, optional if providerEmail is used",
  "providerEmail": "doctor@sagip.ph",
  "facilityId": "facility id",
  "patientName": "Juan Dela Cruz",
  "providerName": "Dr. Andrea Reyes",
  "providerSpecialty": "Internal Medicine",
  "facilityName": "Batangas Medical Center",
  "scheduledAt": "timestamp",
  "type": "telemedicine | in-person",
  "status": "pending | accepted | declined | cancelled | completed",
  "reason": "Persistent cough and fever",
  "contactNumber": "+63...",
  "teleconsultUrl": "https://...",
  "declineReason": "optional",
  "bookedAt": "server timestamp",
  "updatedAt": "server timestamp"
}
```

### sos_alerts/{alertId}
Created by citizens; visible to the citizen, responders, and admins.

```json
{
  "userId": "uid",
  "message": "Emergency assistance needed",
  "address": "location text",
  "latitude": 13.7563,
  "longitude": 121.0583,
  "isActive": true,
  "acknowledgedBy": "responder uid",
  "acknowledgedAt": "timestamp",
  "createdAt": "server timestamp"
}
```

### incidents/{incidentId}
Created from SOS or responder/admin entry. Uses structured fields instead of one broad SQL `patient_info` field.

```json
{
  "type": "SOS Emergency",
  "priority": "CRITICAL | HIGH | MODERATE | LOW",
  "status": "pending | dispatched | in-progress | resolved",
  "address": "P. Burgos St.",
  "barangay": "Poblacion 4",
  "patientInfo": "snapshot text for prototype",
  "reportedBy": "citizen uid",
  "assignedResponderId": "responder uid",
  "notes": "caller notes",
  "reportedAt": "server timestamp",
  "resolvedAt": "timestamp",
  "updatedAt": "server timestamp"
}
```

### incident_reports/{reportId}
Responder report after incident handling.

```json
{
  "reportNo": "R-...",
  "incidentId": "incident id",
  "filedBy": "responder uid",
  "type": "Road Accident",
  "location": "address",
  "patientInfo": "snapshot",
  "actionsTaken": "First aid and transport",
  "outcome": "Stable | Critical | Deceased | Unknown",
  "filedAt": "server timestamp"
}
```

### symptom_checks/{checkId}
Prototype AI-assisted triage result.

```json
{
  "userId": "uid",
  "symptoms": ["Cough", "Fever"],
  "bodyArea": "Chest / respiratory",
  "severity": "critical | high | moderate | low",
  "recommendedSpecialty": "Internal Medicine",
  "aiSummary": "summary text",
  "recommendations": ["Monitor temperature"],
  "ledToAppointmentId": "optional appointment id",
  "checkedAt": "server timestamp"
}
```

### mental_health_sessions/{sessionId}
Strictly private to the citizen user.

```json
{
  "userId": "uid",
  "moodScore": 7,
  "moodLabel": "Positive",
  "journalEntry": "text",
  "exercisesDone": ["Breathing exercise"],
  "sessionAt": "server timestamp"
}
```

### disease_hotspots/{hotspotId}
Admin-managed hotspot records. Use deterministic IDs such as `batangas-city_san-jose_dengue_2026-06-08` to enforce uniqueness by city + barangay + disease + week.

```json
{
  "barangay": "San Jose",
  "city": "Batangas City",
  "disease": "Dengue",
  "cases": 47,
  "level": "HIGH | MODERATE | LOW",
  "trend": "up | down | stable",
  "weekStart": "timestamp",
  "updatedAt": "server timestamp"
}
```

### notifications/{notificationId}
User-specific notification stream.

```json
{
  "userId": "uid",
  "type": "alert | appointment | system | report",
  "title": "Appointment request sent",
  "body": "message",
  "isRead": false,
  "linkTo": "appointments",
  "createdAt": "server timestamp"
}
```

### audit_logs/{auditId}
Admin-only immutable logs.

```json
{
  "actorId": "admin uid",
  "action": "APPROVE_USER",
  "targetType": "user",
  "targetId": "uid",
  "metadata": {"status": "approved"},
  "createdAt": "server timestamp"
}
```

## Important cleanup decisions

1. Firebase Auth UID is the primary user ID. This removes the SQL `users.id` versus `auth_id` duplication.
2. Appointment `date` and `time` became one `scheduledAt` timestamp.
3. User role/status are stored in `users/{uid}` for app logic. For stronger security, also mirror role/status into Firebase custom claims using Cloud Functions.
4. Supabase Storage URL is stored in Firestore fields such as `avatarUrl`, but uploaded file bytes go to Supabase only.
5. Hotspot uniqueness should be enforced by deterministic document IDs because Firestore does not support SQL-style `UNIQUE` constraints.
