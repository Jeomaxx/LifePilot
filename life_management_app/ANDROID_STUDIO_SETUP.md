# Running Flutter App on Android Studio Emulator

## Prerequisites

1. **Flutter SDK** (3.0.0 or higher)
   - Download from: https://docs.flutter.dev/get-started/install
   - Add Flutter to your system PATH

2. **Android Studio**
   - Download from: https://developer.android.com/studio
   - Install Android SDK (API 33 or higher)
   - Install Android Emulator

3. **JDK 17**
   - Android Studio usually includes this

## Setup Steps

### 1. Install Flutter Dependencies

```bash
cd life_management_app
flutter pub get
```

This will install all 30+ packages from pubspec.yaml including:
- flutter_riverpod (state management)
- supabase_flutter (backend)
- go_router (navigation)
- fl_chart (charts)
- firebase packages (notifications)
- And many more...

### 2. Configure Local Properties

Create `android/local.properties` file:

```properties
flutter.sdk=/path/to/your/flutter/sdk
flutter.versionCode=1
flutter.versionName=1.0.0
```

Replace `/path/to/your/flutter/sdk` with your actual Flutter SDK path.

### 3. Configure Environment Variables

Create `lib/core/config/env_config.dart` or use build arguments:

**Option A: Update env_config.dart**
Replace the default values with your actual API keys.

**Option B: Use build arguments** (Recommended)
```bash
flutter run --dart-define=SUPABASE_URL=your_url \
           --dart-define=SUPABASE_ANON_KEY=your_key \
           --dart-define=GEMINI_API_KEY=your_key
```

### 4. Set Up Firebase (Optional - for push notifications)

1. Download `google-services.json` from Firebase Console
2. Place it in `android/app/google-services.json`
3. Update `lib/firebase_options.dart` with your credentials

Or skip Firebase temporarily - the app will still run without it.

### 5. Create Android Emulator

In Android Studio:
1. Tools → Device Manager
2. Create Device
3. Select a phone (e.g., Pixel 6)
4. Download a system image (API 33+)
5. Finish and start the emulator

### 6. Run the App

**Option 1: From Terminal**
```bash
cd life_management_app

# Check for devices
flutter devices

# Run on emulator
flutter run
```

**Option 2: From Android Studio**
1. Open `life_management_app` folder in Android Studio
2. Wait for indexing to complete
3. Select your emulator from device dropdown
4. Click Run button (green play icon)

**Option 3: VS Code**
1. Open `life_management_app` folder
2. Install Flutter extension
3. Press F5 or Run → Start Debugging

## Troubleshooting

### "Flutter SDK not found"
- Set flutter.sdk in `android/local.properties`
- Or add Flutter to system PATH

### "Gradle sync failed"
```bash
cd android
./gradlew clean
./gradlew build
```

### "Dependencies not found"
```bash
flutter pub get
flutter pub upgrade
```

### "Execution failed for task ':app:processDebugGoogleServices'"
- This means google-services.json is missing
- Either add it or comment out the Firebase plugin in `android/app/build.gradle`:
  ```gradle
  // apply plugin: 'com.google.gms.google-services'
  ```

### "Minimum supported Gradle version"
Update `android/gradle/wrapper/gradle-wrapper.properties`:
```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.0-all.zip
```

### Font files not found
The app references Inter font family. Either:
1. Download Inter fonts and place in `assets/fonts/`
2. Or comment out the fonts section in `pubspec.yaml`

## Running Without Backend

If you don't have Supabase configured yet:

1. The app will show errors on authentication screens
2. You can still navigate and see UI for all 51+ modules
3. Data won't persist without backend

To test UI only, you can temporarily mock the auth service.

## Quick Test

After setup, you should see:
1. Login screen on first launch
2. Ability to navigate through all screens
3. Material 3 UI with smooth animations
4. Dark/Light theme switching

## Performance Tips

1. Use release mode for better performance:
   ```bash
   flutter run --release
   ```

2. Enable hot reload during development (Debug mode):
   - Press 'r' in terminal to hot reload
   - Press 'R' to hot restart

3. Profile performance:
   ```bash
   flutter run --profile
   ```

## Build APK for Testing

```bash
flutter build apk --debug
```

The APK will be at: `build/app/outputs/flutter-apk/app-debug.apk`

## Next Steps

Once running successfully:
1. Configure your Supabase backend
2. Set up Firebase notifications
3. Add real API keys
4. Test all 51+ features
5. Build for release and deploy!

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Android Studio Setup](https://developer.android.com/studio/run/emulator)
- [Flutter Run on Android](https://docs.flutter.dev/get-started/test-drive)
