# Life Management Super App

A comprehensive personal life management system built with Flutter, combining productivity, finance, health, lifestyle, and AI-powered tools into a single unified platform.

## Features

### ✅ 51 Functional Modules
- **Core (4)**: Dashboard, AI Assistant, Settings, Analytics
- **Financial (9)**: Finance Tracker, Investments, Crypto, Bills, Subscriptions, Budget, Debt, Assets, Receipts
- **Productivity (7)**: Tasks, Goals, Habits, Time Tracking, Projects, Journal, Notes
- **Health & Wellness (4)**: Health Tracker, Medical History, Meal Planning, Mood Tracking
- **Lifestyle & Learning (8)**: Learning, Reading, Media, Hobbies, Travel, Events, Reflections, Skills
- **Social & Contacts (5)**: Contacts, Birthdays, Family, Links, Social Events
- **Work & Business (4)**: Job Applications, Contracts, Tax Documents, Voice Notes
- **Home & Lifestyle (4)**: Vehicles, Plants, Home Maintenance, Recipes
- **Additional (6)**: Password Manager, Weather, News, Notifications, Profile, Search

### 🔧 Technology Stack

**Frontend:**
- Flutter 3.x (Android, iOS, Web)
- Material 3 + Cupertino Design
- Riverpod (State Management)
- GoRouter (Navigation)
- Hive (Offline Storage)

**Backend:**
- Supabase (PostgreSQL + Auth + Storage)
- Edge Functions (TypeScript/Deno)
- Row Level Security (RLS)

**Integrations:**
- Gemini AI (AI Assistant)
- Firebase (Push Notifications)
- OpenWeather API
- NewsAPI
- CoinGecko (Crypto Prices)

## Getting Started

### Prerequisites
- Flutter SDK 3.0+
- Android Studio (for Android)
- Xcode (for iOS, macOS only)
- Node.js 18+ (for Edge Functions)

### Installation

1. **Install Dependencies**
```bash
flutter pub get
```

2. **Configure Environment Variables**
```bash
# Copy .env.example to .env and fill in your API keys
cp .env.example .env
```

Required API Keys:
- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_ANON_KEY` - Supabase anonymous key
- `GEMINI_API_KEY` - Google Gemini AI API key
- `OPENWEATHER_API_KEY` - OpenWeather API key
- `NEWS_API_KEY` - NewsAPI key

3. **Set Up Supabase Database**
```bash
# Import the database schema
psql -h your-db-host -U postgres -d your-database -f supabase/schema.sql
```

4. **Deploy Edge Functions**
```bash
cd supabase/functions
supabase functions deploy crypto-prices
supabase functions deploy gemini-assistant
```

5. **Configure Firebase**
- Download `google-services.json` (Android) and place in `android/app/`
- Download `GoogleService-Info.plist` (iOS) and place in `ios/Runner/`

### Running the App

**Mobile (Android/iOS)**
```bash
flutter run
```

**Web**
```bash
flutter run -d chrome
```

## Building for Production

### Android (Google Play Store)

1. **Create Keystore**
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. **Configure key.properties**
Create `android/key.properties`:
```
storePassword=your_password
keyPassword=your_password
keyAlias=upload
storeFile=/path/to/upload-keystore.jks
```

3. **Build Release**
```bash
# APK
flutter build apk --release

# App Bundle (recommended)
flutter build appbundle --release
```

### iOS (Apple App Store)

1. **Configure in Xcode**
- Open `ios/Runner.xcworkspace`
- Update Bundle Identifier
- Configure Signing & Capabilities

2. **Build and Archive**
```bash
flutter build ios --release
```

3. **Upload via Xcode**
- Product → Archive
- Distribute App → App Store Connect

### Web

```bash
flutter build web --release
```

Deploy to:
- Firebase Hosting: `firebase deploy`
- Vercel: `vercel --prod`
- Netlify: `netlify deploy --prod --dir=build/web`

## Architecture

### Database (52 Tables)
All tables include RLS policies ensuring user data isolation:
- Core tables (profiles, settings, notifications)
- Financial tables (entries, investments, crypto, bills)
- Productivity tables (tasks, goals, habits, projects)
- Health tables (entries, medical, meals, mood)
- Lifestyle tables (learning, reading, media, travel)
- Social tables (contacts, family, relationships)
- System tables (chat sessions, categories)

### Features
- **Offline-First**: Full offline support with automatic sync
- **Security**: AES encryption, biometric auth, RLS policies
- **AI-Powered**: Gemini AI for insights and assistance
- **Cross-Platform**: Runs on Android, iOS, and Web
- **Real-time Sync**: Automatic background synchronization
- **Material 3**: Modern, adaptive UI design

## Project Structure

```
lib/
├── core/              # Core utilities and configuration
├── features/          # Feature modules
│   ├── auth/          # Authentication
│   ├── dashboard/     # Dashboard
│   ├── finance/       # Finance tracking
│   ├── tasks/         # Task management
│   └── ...            # Other modules
├── models/            # Data models
├── providers/         # Riverpod providers
├── routes/            # Navigation routes
└── services/          # Business logic services

supabase/
├── schema.sql         # Database schema
└── functions/         # Edge functions
    ├── crypto-prices/
    └── gemini-assistant/
```

## Documentation

For detailed documentation, visit the documentation server:
```bash
npm start
```

Then open http://localhost:5000

## License

This project is licensed under the MIT License.

## Support

For issues and feature requests, please create an issue in the repository.
