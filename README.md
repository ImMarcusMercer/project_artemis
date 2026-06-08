# Artemis v1.1 — ResQ Health & Emergency Response App

This is the Flutter refactor of the ResQ healthcare emergency response mockup, integrated into the original Artemis v1.0 Flutter project.

The app keeps the same role-based prototype flow:

- Citizen dashboard
- One-tap SOS flow
- AI-assisted symptom triage mock logic
- Doctor recommendation / appointment booking flow
- Mental wellness hub
- Clinic finder
- Health and risk map
- Responder live incident dashboard
- Professional appointment queue and consultation view
- Admin monitoring, hotspot, reports, and user approval screens

## Backend direction

Artemis v1.1 uses:

- Firebase Auth for authentication
- Cloud Firestore as the primary database
- Supabase Storage only for image/file management
- `.env` placeholders for credentials

If Firebase credentials are not supplied yet, the app runs in mock mode so the UI can still be presented.

## Project structure

```text
lib/
  main.dart
  firebase_options.dart
  bootstrap/
    backend_bootstrap.dart
  app/
    artemis_app.dart
    theme/app_theme.dart
  core/
    constants/app_colors.dart
    data/demo_data.dart
    models/app_models.dart
    services/auth_service.dart
    services/firestore_service.dart
    services/supabase_file_service.dart
    widgets/resq_widgets.dart
  features/
    landing/landing_page.dart
    auth/auth_screen.dart
    shell/web_layout.dart
    citizen/
    responder/
    professional/
    admin/
```

## Setup

1. Install dependencies:

```bash
flutter pub get
```

2. Copy `.env.example` to `.env` and replace placeholders:

```bash
cp .env.example .env
```

3. Create a Firebase project and enable:

- Authentication → Email/Password
- Cloud Firestore

4. Add Firebase app credentials to `.env`.

5. Create a Supabase project and bucket for file/image uploads.

Default bucket name:

```text
artemis-files
```

6. Add Supabase credentials to `.env`:

```text
SUPABASE_URL=
SUPABASE_ANON_KEY=
SUPABASE_STORAGE_BUCKET=artemis-files
```

7. Deploy Firestore rules:

```bash
firebase deploy --only firestore:rules
```

8. Run the app:

```bash
flutter run
```

## Demo accounts

The mock UI uses these demo emails:

```text
Citizen: juan@example.com / password123
Responder: responder@sagip.ph / password123
Professional: doctor@sagip.ph / password123
Admin: admin@sagip.ph / password123
```

In real Firebase mode, these users must be created in Firebase Authentication first or registered using the app. Their profile documents are stored in `users/{uid}`.

## Firestore seed data

Login as an admin and click **Seed Demo Data** on the Admin Overview page. This writes demo users, facilities, and hotspot records to Firestore.

## Important implementation notes

- This is still a high-fidelity prototype, not a medically validated system.
- The triage module uses local rule-based mock logic, not real medical AI.
- Real emergency dispatch requires integration with LGU/EMS workflows, SMS/call APIs, GPS permissions, and responder verification.
- User role security should eventually be mirrored to Firebase custom claims through Cloud Functions.
- Supabase is intentionally used only for file/image storage. Do not use Supabase as the primary auth/database layer for this version.
