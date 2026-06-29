import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campusgo/views/auth/register_business.dart';
import 'package:campusgo/services/fcm_service.dart';
import 'themes/theme.dart';
import 'firebase_options.dart';
import 'views/wrapper.dart';
import 'views/auth/login.dart';
import 'views/auth/register.dart';
import 'views/auth/forgot_password.dart';
import 'views/home/dashboards/dashboard.dart';
import 'views/splash/splash_screen.dart';
import 'views/home/dashboards/shops.dart';
import 'views/home/menu.dart';
import 'views/home/business/inventory.dart';
import 'views/home/messages.dart';
import 'views/home/business/orders.dart';
import 'views/home/business/listings.dart';
import 'views/home/vendor_profile_screen.dart';
import 'views/home/dashboards/history.dart';
import 'models/business_model.dart';
import 'widgets/message_notification_listener.dart';

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

  // Register background handler BEFORE runApp
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      navigatorObservers: [RouteNameObserver(currentRouteNotifier)],
      debugShowCheckedModeBanner: false,
      title: 'campusgo',
      theme: AppTheme.lightTheme,

      builder: (context, child) {
        return MessageNotificationListener(
          navigatorKey: navigatorKey,
          currentRouteNotifier: currentRouteNotifier,
          currentChatReceiverNotifier: currentChatReceiverNotifier,
          child: child!,
        );
      },

      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/auth-wrapper': (context) => const Wrapper(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RedirectScreen(),
        '/register-business': (context) =>
            RegisterBusinessScreen(isCustomer: true),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/inventory': (context) => const InventoryScreen(),
        '/incoming-orders': (context) => const OrderList(),
        '/listings': (context) => const ListingScreen(),
        '/history-customer': (context) =>
        const HistoryScreen(accountType: 'Customer'),
        '/history-vendor': (context) =>
        const HistoryScreen(accountType: 'Vendor'),
        '/dashboard': (context) {
          final args =
          ModalRoute.of(context)?.settings.arguments
          as Map<String, dynamic>?;

          return DashboardScreen(
            accountType: 'Customer',
            openTab: args?['openTab'],
            backToProcessing: args?['backToProcessing'],
          );
        },

        '/business-dashboard': (context) {
          final args =
          ModalRoute.of(context)?.settings.arguments
          as Map<String, dynamic>?;

          return DashboardScreen(
            accountType: 'Vendor',
            openTab: args?['openTab'],
            backToProcessing: args?['backToProcessing'],
          );
        },
        '/vendor-profile': (context) {
          final business =
          ModalRoute.of(context)!.settings.arguments as BusinessModel;
          return VendorProfileScreen(business: business);
        },
        '/menu': (context) => const MenuScreen(),
        '/messages': (context) => MessagesScreen(),
        '/shops': (context) {
          final args =
          ModalRoute.of(context)?.settings.arguments
          as Map<String, dynamic>?;
          return ShopsScreen(
            category: args?['category']?.toString() ?? 'Other',
          );
        },
      },
    );
  }
}
