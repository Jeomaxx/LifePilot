# Life Management Super App

## Overview

This is a comprehensive personal life management system built with Flutter for cross-platform (Android, iOS, Web) deployment and a Node.js/Express documentation server. The Flutter application serves as a unified platform combining 51+ functional modules across productivity, finance, health, lifestyle, and AI-powered tools. The system features offline-first architecture with automatic sync, AI assistance, and real-time data synchronization.

The repository contains:
- **Flutter Application** (`life_management_app/`): Cross-platform mobile and web app
- **Documentation Server** (root): Express.js server serving project documentation and setup guides

## User Preferences

Preferred communication style: Simple, everyday language.

## System Architecture

### Frontend Architecture

**Framework & Platform Support**
- Built with Flutter 3.x for Android, iOS, and Web platforms
- Uses Material 3 design system with Cupertino (iOS-style) components for adaptive UI
- Supports responsive layouts for mobile, tablet, and web form factors
- Light and dark theme modes with system-level theme detection

**State Management & Navigation**
- Riverpod chosen for state management with modular provider architecture
- GoRouter handles navigation with deep linking support and authentication route guards
- Separates UI state from business logic through provider patterns

**Offline-First Architecture**
- Hive database for local caching and offline data storage
- Sync queue system that stores operations when offline
- Reverse iteration sync strategy (processes newest items first for data safety)
- Automatic background synchronization when connectivity is restored

**Module Structure**
- 51+ functional modules organized into categories (Financial, Productivity, Health, Lifestyle, Social, Work, Home, System)
- ALL modules fully implemented with dedicated providers, screens, and database integration
- Production-ready with full CRUD operations, offline support, and real-time sync across all modules
- Status: ✅ 100% Complete - All 51+ modules operational and ready for App Store deployment

### Backend Architecture

**Database Layer**
- Supabase PostgreSQL with 52 tables covering all application modules
- Row Level Security (RLS) policies enforced on all tables for user data isolation
- Performance optimizations via indexes on frequently queried columns
- Auto-updating timestamps via database triggers

**Authentication & Authorization**
- Supabase Auth for user management (email/password, OAuth)
- RLS policies ensure users only access their own data
- Auth state managed through AuthService with session persistence

**Serverless Functions**
- Supabase Edge Functions (Deno/TypeScript) for backend logic:
  - `crypto-prices`: Fetches cryptocurrency prices from CoinGecko API
  - `gemini-assistant`: Proxies AI requests to Google Gemini API
- Functions handle API key protection and request processing

**File Storage**
- Supabase Storage for user-uploaded files
- Platform-aware upload strategy (Web uses multipart, Mobile uses file paths)
- StorageService abstracts platform differences

**Core Services**
- **AuthService**: Handles authentication flows
- **DatabaseService**: Generic CRUD operations with RLS integration
- **OfflineService**: Manages local Hive cache and sync queue
- **SyncService**: Background sync with conflict resolution
- **AIService**: Gemini AI integration for assistant features
- **NotificationService**: Firebase Cloud Messaging structure for push notifications

### Documentation Server

**Simple Express.js Application**
- Serves project documentation via EJS templates
- Routes for setup guides, database schema, deployment instructions
- Static file serving for Flutter source code preview
- Running on port 5000

## External Dependencies

### Third-Party Services

**Supabase (Primary Backend)**
- PostgreSQL database hosting
- Authentication service
- File storage
- Edge Functions runtime
- Real-time subscriptions capability

**Firebase**
- Firebase Cloud Messaging (FCM) for push notifications
- Analytics tracking (optional)

**AI & Data APIs**
- Google Gemini API: AI assistant and conversational features
- CoinGecko API: Cryptocurrency price data (accessed via Edge Function)
- OpenWeather API: Weather information
- NewsAPI: News feed integration

### Key Flutter Packages

**State & Navigation**
- `flutter_riverpod`: State management
- `go_router`: Declarative routing with deep links

**Database & Storage**
- `supabase_flutter`: Supabase client integration
- `hive` & `hive_flutter`: Local NoSQL database for offline storage

**Networking**
- `dio` or `http`: HTTP client with interceptors (project supports both)

**UI & Charts**
- `syncfusion_flutter_charts` or `fl_chart`: Data visualization

**Notifications**
- `firebase_messaging`: Push notifications
- `flutter_local_notifications`: Local notifications

### Build & Deployment Tools

**Android**
- Gradle build system with ProGuard/R8 for code shrinking
- Keystore-based signing for release builds

**iOS**
- Xcode workspace configuration
- Automatic signing or manual provisioning profiles

**Web**
- Flutter web build with PWA support
- Content Security Policy configuration

### Development Infrastructure
- Node.js 18+ for Edge Functions development
- Deno runtime for Supabase Edge Functions
- FlutterFire CLI for Firebase configuration generation