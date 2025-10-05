# Production Deployment Checklist

## Pre-Deployment Setup

### ✅ 1. API Keys & Configuration
- [ ] Configure Supabase project
  - [ ] Set `SUPABASE_URL` in environment
  - [ ] Set `SUPABASE_ANON_KEY` in environment
  - [ ] Import database schema from `supabase/schema.sql`
  - [ ] Deploy edge functions (crypto-prices, gemini-assistant)

- [ ] Configure Firebase (see FIREBASE_SETUP.md)
  - [ ] Place `google-services.json` in `android/app/`
  - [ ] Place `GoogleService-Info.plist` in `ios/Runner/`
  - [ ] Update `lib/firebase_options.dart` with real credentials
  - [ ] Enable FCM in Firebase Console

- [ ] Configure API Keys
  - [ ] Get Gemini API key from Google AI Studio
  - [ ] Get OpenWeather API key
  - [ ] Get NewsAPI key
  - [ ] Update `lib/core/config/env_config.dart` or use build flags

### ✅ 2. Security Configuration
- [ ] Generate Android keystore
  ```bash
  keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
  ```
- [ ] Create `android/key.properties` with keystore details
- [ ] Configure iOS signing in Xcode
- [ ] Verify RLS policies in Supabase
- [ ] Enable SSL/HTTPS for all API endpoints
- [ ] Configure Content Security Policy for web

### ✅ 3. Build Configuration

#### Android
- [ ] Update `android/app/build.gradle`:
  - [ ] Set correct `applicationId`
  - [ ] Update `versionCode` and `versionName`
  - [ ] Verify signing configuration
  - [ ] Enable minification and shrinking

- [ ] Create ProGuard rules if needed
- [ ] Test on physical Android device
- [ ] Verify all permissions in `AndroidManifest.xml`

#### iOS
- [ ] Open `ios/Runner.xcworkspace` in Xcode
- [ ] Update Bundle Identifier
- [ ] Configure signing & capabilities
  - [ ] Push Notifications
  - [ ] Background Modes
  - [ ] Camera (for receipts)
  - [ ] Photo Library
  - [ ] Face ID
- [ ] Update version and build number
- [ ] Test on physical iOS device
- [ ] Verify all permissions in `Info.plist`

#### Web
- [ ] Update `web/index.html` meta tags
- [ ] Configure favicon and app icons
- [ ] Set up SSL certificate for hosting
- [ ] Configure CORS if needed

## Build for Production

### Android (Google Play Store)

1. **Build App Bundle (Recommended)**
   ```bash
   flutter build appbundle --release \
     --dart-define=SUPABASE_URL=your_url \
     --dart-define=SUPABASE_ANON_KEY=your_key \
     --dart-define=GEMINI_API_KEY=your_key \
     --obfuscate \
     --split-debug-info=build/app/outputs/symbols
   ```

2. **Build APK (Alternative)**
   ```bash
   flutter build apk --release \
     --dart-define=SUPABASE_URL=your_url \
     --dart-define=SUPABASE_ANON_KEY=your_key
   ```

3. **Upload to Play Console**
   - [ ] Create app in Google Play Console
   - [ ] Upload app bundle/APK
   - [ ] Complete store listing
   - [ ] Add screenshots (multiple devices)
   - [ ] Set content rating
   - [ ] Configure pricing & distribution
   - [ ] Submit for review

### iOS (Apple App Store)

1. **Build iOS Release**
   ```bash
   flutter build ios --release \
     --dart-define=SUPABASE_URL=your_url \
     --dart-define=SUPABASE_ANON_KEY=your_key
   ```

2. **Archive in Xcode**
   - [ ] Open `ios/Runner.xcworkspace`
   - [ ] Select "Any iOS Device"
   - [ ] Product → Archive
   - [ ] Distribute App → App Store Connect

3. **Upload to App Store Connect**
   - [ ] Create app in App Store Connect
   - [ ] Upload build via Xcode
   - [ ] Complete app information
   - [ ] Add screenshots (all device sizes)
   - [ ] Set pricing & availability
   - [ ] Configure age rating
   - [ ] Submit for review

### Web

1. **Build Web Release**
   ```bash
   flutter build web --release \
     --dart-define=SUPABASE_URL=your_url \
     --dart-define=SUPABASE_ANON_KEY=your_key
   ```

2. **Deploy to Hosting**

   **Firebase Hosting:**
   ```bash
   firebase init hosting
   firebase deploy
   ```

   **Vercel:**
   ```bash
   vercel --prod
   ```

   **Netlify:**
   ```bash
   netlify deploy --prod --dir=build/web
   ```

## Testing Checklist

### Functionality Testing
- [ ] User authentication (signup, login, logout)
- [ ] All 51 modules load correctly
- [ ] CRUD operations work for all tables
- [ ] Offline mode works
- [ ] Data syncs when back online
- [ ] Push notifications received
- [ ] AI assistant responds correctly
- [ ] File uploads work (receipts, documents)
- [ ] Search functionality works
- [ ] Charts and analytics display correctly

### Security Testing
- [ ] RLS policies prevent unauthorized access
- [ ] Passwords are hashed properly
- [ ] Biometric authentication works
- [ ] Encrypted data remains secure
- [ ] API keys not exposed in client code
- [ ] HTTPS enforced for all requests

### Performance Testing
- [ ] App launches in < 3 seconds
- [ ] Smooth scrolling (60 FPS)
- [ ] Images load efficiently
- [ ] Database queries optimized
- [ ] No memory leaks
- [ ] Battery usage acceptable

### Compatibility Testing
- [ ] Test on Android 8.0+
- [ ] Test on iOS 12.0+
- [ ] Test on various screen sizes
- [ ] Test on tablets
- [ ] Test web on Chrome, Safari, Firefox
- [ ] Test offline mode on all platforms

## App Store Requirements

### Google Play Store
- [ ] Target SDK 33 or higher
- [ ] Privacy policy URL
- [ ] App description (4000 chars max)
- [ ] Feature graphic (1024x500)
- [ ] Screenshots (phone, tablet, 7-inch tablet)
- [ ] App icon (512x512)
- [ ] Content rating questionnaire
- [ ] Data safety section completed

### Apple App Store
- [ ] App Privacy details
- [ ] App icons (all sizes)
- [ ] Screenshots (all device sizes)
- [ ] App description (4000 chars max)
- [ ] Keywords (100 chars max)
- [ ] Support URL
- [ ] Marketing URL (optional)
- [ ] Age rating

## Post-Deployment

### Monitoring
- [ ] Set up crash reporting (Firebase Crashlytics)
- [ ] Configure analytics tracking
- [ ] Monitor error rates
- [ ] Track user engagement
- [ ] Monitor API usage and costs

### User Support
- [ ] Create user documentation
- [ ] Set up support email
- [ ] Create FAQ page
- [ ] Set up in-app feedback mechanism

### Maintenance
- [ ] Plan for regular updates
- [ ] Monitor dependency updates
- [ ] Track and fix reported bugs
- [ ] Plan feature roadmap
- [ ] Monitor server costs

## Environment Variables Summary

Required for deployment:
```bash
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key
GEMINI_API_KEY=your_gemini_key
OPENWEATHER_API_KEY=your_weather_key (optional)
NEWS_API_KEY=your_news_key (optional)
```

## Final Checks

- [ ] All API keys configured
- [ ] Firebase fully set up
- [ ] Database schema imported
- [ ] Edge functions deployed
- [ ] App tested on real devices
- [ ] All features working
- [ ] Store listings complete
- [ ] Legal documents ready (privacy policy, terms)
- [ ] Support infrastructure ready

## Launch! 🚀

Once all checklist items are complete:
1. Submit to app stores
2. Monitor for approval status
3. Prepare for user feedback
4. Plan post-launch updates

## Resources

- [Flutter Deployment Docs](https://docs.flutter.dev/deployment)
- [Google Play Console](https://play.google.com/console)
- [App Store Connect](https://appstoreconnect.apple.com)
- [Firebase Console](https://console.firebase.google.com)
- [Supabase Dashboard](https://app.supabase.com)
