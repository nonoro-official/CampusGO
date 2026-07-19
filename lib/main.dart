import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campusgo/pages/auth/register_organizer.dart';
import 'package:campusgo/services/fcm_service.dart';
import 'package:campusgo/services/local_notification_service.dart';
import 'themes/theme.dart';
import 'firebase_options.dart';
import 'pages/wrapper.dart';
import 'pages/auth/login.dart';
import 'pages/auth/register.dart';
import 'pages/auth/forgot_password.dart';
import 'pages/dashboard/dashboard.dart';
import 'pages/splash/splash_screen.dart';
import 'pages/rewards/rewards.dart';
import 'pages/settings/menu.dart';
import 'pages/rewards/organizer/reward_inventory.dart';
import 'pages/messages/messages.dart';
import 'pages/rewards/organizer/redemption_orders.dart';
import 'pages/rewards/organizer/reward_listings.dart';
import 'pages/events/add_event_screen.dart';
import 'pages/events/event_list_screen.dart';
import 'pages/organizer/organizer_profile_screen.dart';
import 'pages/rewards/redemption_history.dart';
import 'models/organizer_model.dart';
import 'providers/theme_provider.dart';
import 'widgets/message_notification_listener.dart';
import 'pages/rewards/reward_qr_generator.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final ValueNotifier<String?> currentRouteNotifier = ValueNotifier<String?>(
  null,
);
final ValueNotifier<String?> currentChatReceiverNotifier =
    ValueNotifier<String?>(null);

class RouteNameObserver extends NavigatorObserver {
  final ValueNotifier<String?> routeNotifier;
  RouteNameObserver(this.routeNotifier);

  void _updateRoute(Route<dynamic>? route) {
    if (route == null) return;
    routeNotifier.value = route.settings.name;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _updateRoute(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _updateRoute(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _updateRoute(previousRoute);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Local Notifications for event reminders
  await LocalNotificationService.init();
  
  // Initialize FCM for cloud messages
  await FCMService.init();

  // Register background handler BEFORE runApp
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(darkModeProvider).value ?? false;

    return MaterialApp(
      navigatorKey: navigatorKey,
      navigatorObservers: [RouteNameObserver(currentRouteNotifier)],
      debugShowCheckedModeBanner: false,
      title: 'CampusGO',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) {
        return AnnotatedRegion(
          value: AppTheme.systemOverlayStyle(Theme.of(context).brightness),
          child: MessageNotificationListener(
            navigatorKey: navigatorKey,
            currentRouteNotifier: currentRouteNotifier,
            currentChatReceiverNotifier: currentChatReceiverNotifier,
            child: child!,
          ),
        );
      },
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/auth-wrapper': (context) => const Wrapper(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RedirectScreen(),
        '/register-organizer': (context) =>
            const RegisterOrganizerScreen(isCustomer: true),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/inventory': (context) => const InventoryScreen(),
        '/incoming-orders': (context) => const OrderList(),
        '/listings': (context) => const ListingScreen(),
        '/qr-generator': (context) => const QRGeneratorScreen(),
        '/history-customer': (context) =>
            const HistoryScreen(accountType: 'Customer'),
        '/history-organizer': (context) =>
            const HistoryScreen(accountType: 'Organizer'),
        '/dashboard': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;

          return DashboardScreen(
            accountType: 'Customer',
            openTab: args?['openTab'],
            backToProcessing: args?['backToProcessing'],
          );
        },
        '/organizer-dashboard': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;

          return DashboardScreen(
            accountType: 'Organizer',
            openTab: args?['openTab'],
            backToProcessing: args?['backToProcessing'],
          );
        },
        '/organizer-profile': (context) {
          final organizer =
              ModalRoute.of(context)!.settings.arguments as OrganizerModel;
          return OrganizerProfileScreen(organizer: organizer);
        },
        '/menu': (context) => const MenuScreen(),
        '/messages': (context) => MessagesScreen(),
        '/shops': (context) => const ShopsScreen(),
        '/add-event': (context) => const AddEventScreen(),
        '/events': (context) => const EventListScreen(),
      },
    );
  }
}
