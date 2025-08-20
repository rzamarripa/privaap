import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/firebase_service.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/admin/create_community_screen.dart';
import 'screens/admin/manage_community_admins_screen.dart';
import 'screens/admin/support_tickets_screen.dart';
import 'screens/profile/my_tickets_screen.dart';
import 'screens/communities/community_detail_screen.dart';
import 'screens/expenses/add_expense_screen.dart';
import 'screens/surveys/create_survey_screen.dart';
import 'screens/blog/create_post_screen.dart';
import 'models/community_model.dart';
import 'services/auth_service.dart';
import 'services/user_service.dart';
import 'services/expense_service.dart';
import 'services/survey_service.dart';
import 'services/blog_service.dart';
import 'services/community_service.dart';
import 'services/biometric_service.dart';
import 'services/api_service.dart'; // Added import for ApiService
import 'config/theme/app_theme.dart';
import 'services/monthly_fee_service.dart';
import 'screens/monthly_fees/monthly_fees_screen.dart';
import 'screens/monthly_fees/create_monthly_fee_screen.dart';
import 'screens/profile/contact_support_screen.dart';
import 'services/house_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);

  // Inicializar Firebase
  final firebaseService = FirebaseService();
  await firebaseService.initialize();

  // Inicializar servicios
  final apiService = ApiService();
  await apiService.loadAuthToken();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
        Provider<UserService>(create: (_) => UserService()),
        Provider<CommunityService>(create: (_) => CommunityService()),
        ChangeNotifierProvider<BlogService>(create: (_) => BlogService()),
        ChangeNotifierProvider<ExpenseService>(create: (_) => ExpenseService()),
        ChangeNotifierProvider<SurveyService>(create: (_) => SurveyService()),
        Provider<BiometricService>(create: (_) => BiometricService()),
        ChangeNotifierProvider<MonthlyFeeService>(create: (_) => MonthlyFeeService()),
        ChangeNotifierProvider<HouseService>(create: (_) => HouseService()),
      ],
      child: MaterialApp(
        title: 'PrivaAp',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/create-community': (context) => const CreateCommunityScreen(),
          '/monthly-fees': (context) => const MonthlyFeesScreen(),
          '/create-monthly-fee': (context) => const CreateMonthlyFeeScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/manage-community-admins') {
            final community = settings.arguments as Community;
            return MaterialPageRoute(
              builder: (context) => ManageCommunityAdminsScreen(community: community),
            );
          }
          if (settings.name == '/community-detail') {
            final community = settings.arguments as Community;
            return MaterialPageRoute(
              builder: (context) => CommunityDetailScreen(community: community),
            );
          }
          if (settings.name == '/add-expense') {
            return MaterialPageRoute(
              builder: (context) => const AddExpenseScreen(),
            );
          }
          if (settings.name == '/create-survey') {
            return MaterialPageRoute(
              builder: (context) => const CreateSurveyScreen(),
            );
          }
          if (settings.name == '/create-post') {
            return MaterialPageRoute(
              builder: (context) => const CreatePostScreen(),
            );
          }
          if (settings.name == '/support-tickets') {
            return MaterialPageRoute(
              builder: (context) => const SupportTicketsScreen(),
            );
          }
          if (settings.name == '/my-tickets') {
            return MaterialPageRoute(
              builder: (context) => const MyTicketsScreen(),
            );
          }
          if (settings.name == '/contact-support') {
            return MaterialPageRoute(
              builder: (context) => const ContactSupportScreen(),
            );
          }
          return null;
        },
      ),
    );
  }
}
