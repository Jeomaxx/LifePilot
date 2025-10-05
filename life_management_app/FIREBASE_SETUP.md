# Firebase Configuration Guide

## Overview
This Flutter application uses Firebase for push notifications and analytics. You need to configure Firebase with your own project credentials.

## Setup Steps

### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Add project"
3. Enter project name (e.g., "Life Management App")
4. Follow the setup wizard

### 2. Add Apps to Firebase Project

#### For Android:
1. In Firebase Console, click "Add app" → Android
2. Register app with package name: `com.lifemanagement.app`
3. Download `google-services.json`
4. Place it in `android/app/google-services.json`

#### For iOS:
1. In Firebase Console, click "Add app" → iOS
2. Register app with bundle ID: `com.lifemanagement.app`
3. Download `GoogleService-Info.plist`
4. Place it in `ios/Runner/GoogleService-Info.plist`

#### For Web:
1. In Firebase Console, click "Add app" → Web
2. Register app
3. Copy the configuration values

### 3. Configure Firebase Options

**Option A: Using FlutterFire CLI (Recommended)**

Install FlutterFire CLI:
```bash
dart pub global activate flutterfire_cli
```

Run configuration:
```bash
flutterfire configure
```

This will automatically:
- Generate `lib/firebase_options.dart` with your real credentials
- Configure all platforms (Android, iOS, Web)

**Option B: Manual Configuration**

Update `lib/firebase_options.dart` with your Firebase project values:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_WEB_API_KEY',           // From Firebase Console → Project Settings → Web apps
  appId: '1:YOUR_APP_ID:web:YOUR_WEB_ID',
  messagingSenderId: 'YOUR_SENDER_ID',
  projectId: 'YOUR_PROJECT_ID',
  authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
  storageBucket: 'YOUR_PROJECT_ID.appspot.com',
);

static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_ANDROID_API_KEY',        // From google-services.json
  appId: '1:YOUR_APP_ID:android:YOUR_ANDROID_ID',
  messagingSenderId: 'YOUR_SENDER_ID',
  projectId: 'YOUR_PROJECT_ID',
  storageBucket: 'YOUR_PROJECT_ID.appspot.com',
);

static const FirebaseOptions ios = FirebaseOptions(
  apiKey: 'YOUR_IOS_API_KEY',            // From GoogleService-Info.plist
  appId: '1:YOUR_APP_ID:ios:YOUR_IOS_ID',
  messagingSenderId: 'YOUR_SENDER_ID',
  projectId: 'YOUR_PROJECT_ID',
  storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  iosBundleId: 'com.lifemanagement.app',
);
```

### 4. Enable Firebase Cloud Messaging (FCM)

1. In Firebase Console → Project Settings → Cloud Messaging
2. Enable Cloud Messaging API
3. Note the Server Key (for backend if needed)

### 5. Verify Configuration

Run the app to verify Firebase initializes correctly:

```bash
flutter run
```

Check logs for:
```
✓ Firebase initialized successfully
```

## Finding Your Firebase Configuration Values

### Web Configuration
- Go to Firebase Console → Project Settings
- Scroll to "Your apps" section
- Click on your Web app
- Copy the configuration values from `firebaseConfig`

### Android Configuration
- Open `android/app/google-services.json`
- Find values:
  - `project_info.project_id` → projectId
  - `client[0].client_info.mobilesdk_app_id` → appId
  - `client[0].api_key[0].current_key` → apiKey
  - `project_info.project_number` → messagingSenderId

### iOS Configuration
- Open `ios/Runner/GoogleService-Info.plist`
- Find values:
  - `PROJECT_ID` → projectId
  - `GOOGLE_APP_ID` → appId
  - `API_KEY` → apiKey
  - `GCM_SENDER_ID` → messagingSenderId

## Security Notes

⚠️ **Important:**
- Never commit `google-services.json` or `GoogleService-Info.plist` to public repositories
- These files are already in `.gitignore`
- Use environment-specific configurations for dev/staging/production
- Restrict API keys in Firebase Console

## Troubleshooting

### "No Firebase App '[DEFAULT]' has been created"
- Ensure `Firebase.initializeApp()` is called in `main()`
- Verify platform config files are in correct locations

### "Unable to find GoogleService-Info.plist"
- Check file is in `ios/Runner/` directory
- Clean and rebuild: `flutter clean && flutter run`

### Push Notifications Not Working
- Verify FCM is enabled in Firebase Console
- Check device has valid FCM token
- Test notifications from Firebase Console → Cloud Messaging

## Next Steps

After Firebase is configured:
1. Test push notifications
2. Verify analytics tracking
3. Configure app distribution
4. Set up performance monitoring (optional)
5. Enable crash reporting (optional)

## Support

For Firebase-specific issues, refer to:
- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev)
