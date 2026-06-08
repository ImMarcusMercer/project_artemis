# Firebase Setup Guide for Artemis

## What's Been Configured

✅ **Dependencies Added** - Firebase packages installed in pubspec.yaml:
- firebase_core: Core Firebase functionality
- cloud_firestore: Firestore database
- firebase_auth: Authentication
- firebase_storage: File storage
- flutter_dotenv: Environment variable management

✅ **Project Structure** - Created Firebase integration files:
- `lib/firebase_service.dart` - Firebase initialization with .env loading
- `lib/firebase_options.dart` - Platform-specific Firebase config from .env
- `main.dart` - Updated to initialize Firebase on app startup
- `android/app/google-services.json` - Android Firebase config template
- `.env` - Environment variables (excluded from git)
- `.env.example` - Template showing required variables
- `.gitignore` - Updated to exclude .env

## Environment Variables Setup

### 1. Copy .env.example to .env
```bash
cp .env.example .env
```

### 2. Fill in Firebase credentials in .env
Edit `.env` and add your Firebase project values:

```env
FIREBASE_PROJECT_ID=your_actual_project_id
FIREBASE_PROJECT_NUMBER=123456789012
FIREBASE_API_KEY=AIzaSyDxxxxxxxxxxxx
FIREBASE_APP_ID=1:123456789012:web:abcdefxxxxxxxx
FIREBASE_MESSAGING_SENDER_ID=123456789012
FIREBASE_STORAGE_BUCKET=your_project_id.appspot.com

FIREBASE_ANDROID_API_KEY=AIzaSyDxxxxxxxxxxxx
FIREBASE_ANDROID_APP_ID=1:123456789012:android:abcdefxxxxxxxx
FIREBASE_IOS_API_KEY=AIzaSyDxxxxxxxxxxxx
FIREBASE_IOS_APP_ID=1:123456789012:ios:abcdefxxxxxxxx
FIREBASE_WEB_API_KEY=AIzaSyDxxxxxxxxxxxx
FIREBASE_WEB_APP_ID=1:123456789012:web:abcdefxxxxxxxx
```

⚠️ **IMPORTANT**: `.env` is in `.gitignore` - Never commit real credentials!

## Next Steps to Complete Setup

### 1. Create Firebase Project
- Go to [Firebase Console](https://console.firebase.google.com/)
- Create a new project or select existing one
- Enable required services (Firestore, Auth, Storage, etc.)

### 2. Configure Android
- In Firebase Console, add an Android app
- Download `google-services.json`
- Replace the template in `android/app/google-services.json` with the real one

### 3. Configure iOS (Optional)
- In Firebase Console, add an iOS app
- Download `GoogleService-Info.plist`
- Place in `ios/Runner/GoogleService-Info.plist`

### 4. Configure Web (Optional)
- In Firebase Console, add a Web app
- Credentials will be added to `.env`

## How It Works

1. **Runtime Loading**: When the app starts, `firebase_service.dart` loads the `.env` file
2. **Environment Access**: `firebase_options.dart` reads values using `dotenv.env['KEY_NAME']`
3. **Security**: Credentials are only in `.env` (excluded from git), not in source code
4. **Flexibility**: Easy to switch between dev/staging/prod by changing `.env`

## Testing Firebase Connection
```dart
import 'package:cloud_firestore/cloud_firestore.dart';

// Test Firestore connection
FirebaseFirestore.instance.collection('test').add({
  'message': 'Hello Firebase',
  'timestamp': DateTime.now(),
});
```

## Troubleshooting

- **"NOT_SET" errors**: Check `.env` file is present and properly filled
- **Module not found**: Run `flutter pub get` after updating dependencies
- **Ensure `WidgetsFlutterBinding.ensureInitialized()` is called before Firebase init
- Check that `google-services.json` is in `android/app/`
- Verify package names match between Firebase Console and your app

## Security Best Practices

✅ Do:
- Add `.env` to `.gitignore` (already done)
- Use `.env.example` as a template for team members
- Rotate API keys periodically
- Use Firebase security rules to restrict data access

❌ Don't:
- Commit `.env` to version control
- Share `.env` in Slack or email
- Use production credentials in development

For more details, see [FlutterFire Documentation](https://firebase.flutter.dev)
