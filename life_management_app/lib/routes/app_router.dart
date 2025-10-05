import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/ai_assistant/screens/ai_assistant_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/settings/screens/password_manager_screen.dart';
import '../features/settings/screens/user_profile_screen.dart';
import '../features/analytics/screens/analytics_screen.dart';
import '../features/tasks/screens/tasks_screen.dart';
import '../features/goals/goals_screen.dart';

import '../features/finance/screens/finance_tracker_screen.dart';
import '../features/finance/screens/investments_screen.dart';
import '../features/finance/screens/crypto_portfolio_screen.dart';
import '../features/finance/screens/bills_screen.dart';
import '../features/finance/screens/subscriptions_screen.dart';
import '../features/finance/screens/budgets_screen.dart';
import '../features/finance/screens/debts_screen.dart';
import '../features/finance/screens/assets_screen.dart';
import '../features/finance/screens/receipts_screen.dart';

import '../features/productivity/screens/habits_screen.dart';
import '../features/productivity/screens/time_tracking_screen.dart';
import '../features/productivity/screens/projects_screen.dart';
import '../features/productivity/screens/journal_screen.dart';
import '../features/productivity/screens/notes_screen.dart';
import '../features/productivity/screens/voice_notes_screen.dart';

import '../features/health/health_screen.dart';
import '../features/health/screens/medical_history_screen.dart';
import '../features/health/screens/meal_planning_screen.dart';
import '../features/health/screens/mood_tracking_screen.dart';

import '../features/lifestyle/screens/learning_tracker_screen.dart';
import '../features/lifestyle/screens/reading_list_screen.dart';
import '../features/lifestyle/screens/media_tracker_screen.dart';
import '../features/lifestyle/screens/hobbies_tracker_screen.dart';
import '../features/lifestyle/screens/travel_planner_screen.dart';
import '../features/lifestyle/screens/events_planner_screen.dart';
import '../features/lifestyle/screens/daily_reflections_screen.dart';
import '../features/lifestyle/screens/skills_development_screen.dart';

import '../features/social/screens/contacts_screen.dart';
import '../features/social/screens/birthdays_screen.dart';
import '../features/social/screens/family_tree_screen.dart';
import '../features/social/screens/important_links_screen.dart';
import '../features/social/screens/social_events_screen.dart';

import '../features/work/screens/job_applications_screen.dart';
import '../features/work/screens/contracts_screen.dart';
import '../features/work/screens/tax_documents_screen.dart';
import '../features/work/screens/career_notes_screen.dart';

import '../features/home/screens/vehicles_screen.dart';
import '../features/home/screens/plant_care_screen.dart';
import '../features/home/screens/home_maintenance_screen.dart';
import '../features/home/screens/recipes_screen.dart';

import '../features/system/screens/notifications_center_screen.dart';
import '../features/system/screens/weather_screen.dart';
import '../features/system/screens/news_screen.dart';

import '../services/auth_service.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isLoggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';
      
      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }
      
      if (isLoggedIn && isLoggingIn) {
        return '/dashboard';
      }
      
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
      GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
      
      GoRoute(path: '/ai-assistant', builder: (context, state) => const AIAssistantScreen()),
      GoRoute(path: '/analytics', builder: (context, state) => const AnalyticsScreen()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      GoRoute(path: '/password-manager', builder: (context, state) => const PasswordManagerScreen()),
      GoRoute(path: '/user-profile', builder: (context, state) => const UserProfileScreen()),
      GoRoute(path: '/tasks', builder: (context, state) => const TasksScreen()),
      GoRoute(path: '/goals', builder: (context, state) => const GoalsScreen()),
      
      GoRoute(path: '/finance', builder: (context, state) => const FinanceTrackerScreen()),
      GoRoute(path: '/investments', builder: (context, state) => const InvestmentsScreen()),
      GoRoute(path: '/crypto', builder: (context, state) => const CryptoPortfolioScreen()),
      GoRoute(path: '/bills', builder: (context, state) => const BillsScreen()),
      GoRoute(path: '/subscriptions', builder: (context, state) => const SubscriptionsScreen()),
      GoRoute(path: '/budgets', builder: (context, state) => const BudgetsScreen()),
      GoRoute(path: '/debts', builder: (context, state) => const DebtsScreen()),
      GoRoute(path: '/assets', builder: (context, state) => const AssetsScreen()),
      GoRoute(path: '/receipts', builder: (context, state) => const ReceiptsScreen()),
      
      GoRoute(path: '/habits', builder: (context, state) => const HabitsScreen()),
      GoRoute(path: '/time-tracking', builder: (context, state) => const TimeTrackingScreen()),
      GoRoute(path: '/projects', builder: (context, state) => const ProjectsScreen()),
      GoRoute(path: '/journal', builder: (context, state) => const JournalScreen()),
      GoRoute(path: '/notes', builder: (context, state) => const NotesScreen()),
      GoRoute(path: '/voice-notes', builder: (context, state) => const VoiceNotesScreen()),
      
      GoRoute(path: '/health', builder: (context, state) => const HealthScreen()),
      GoRoute(path: '/medical-history', builder: (context, state) => const MedicalHistoryScreen()),
      GoRoute(path: '/meal-planning', builder: (context, state) => const MealPlanningScreen()),
      GoRoute(path: '/mood-tracking', builder: (context, state) => const MoodTrackingScreen()),
      
      GoRoute(path: '/learning', builder: (context, state) => const LearningTrackerScreen()),
      GoRoute(path: '/reading', builder: (context, state) => const ReadingListScreen()),
      GoRoute(path: '/media', builder: (context, state) => const MediaTrackerScreen()),
      GoRoute(path: '/hobbies', builder: (context, state) => const HobbiesTrackerScreen()),
      GoRoute(path: '/travel', builder: (context, state) => const TravelPlannerScreen()),
      GoRoute(path: '/events', builder: (context, state) => const EventsPlannerScreen()),
      GoRoute(path: '/reflections', builder: (context, state) => const DailyReflectionsScreen()),
      GoRoute(path: '/skills', builder: (context, state) => const SkillsDevelopmentScreen()),
      
      GoRoute(path: '/contacts', builder: (context, state) => const ContactsScreen()),
      GoRoute(path: '/birthdays', builder: (context, state) => const BirthdaysScreen()),
      GoRoute(path: '/family-tree', builder: (context, state) => const FamilyTreeScreen()),
      GoRoute(path: '/links', builder: (context, state) => const ImportantLinksScreen()),
      GoRoute(path: '/social-events', builder: (context, state) => const SocialEventsScreen()),
      
      GoRoute(path: '/job-applications', builder: (context, state) => const JobApplicationsScreen()),
      GoRoute(path: '/contracts', builder: (context, state) => const ContractsScreen()),
      GoRoute(path: '/tax-documents', builder: (context, state) => const TaxDocumentsScreen()),
      GoRoute(path: '/career-notes', builder: (context, state) => const CareerNotesScreen()),
      
      GoRoute(path: '/vehicles', builder: (context, state) => const VehiclesScreen()),
      GoRoute(path: '/plants', builder: (context, state) => const PlantCareScreen()),
      GoRoute(path: '/home-maintenance', builder: (context, state) => const HomeMaintenanceScreen()),
      GoRoute(path: '/recipes', builder: (context, state) => const RecipesScreen()),
      
      GoRoute(path: '/notifications', builder: (context, state) => const NotificationsCenterScreen()),
      GoRoute(path: '/weather', builder: (context, state) => const WeatherScreen()),
      GoRoute(path: '/news', builder: (context, state) => const NewsScreen()),
    ],
  );
});

final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.system;
});
