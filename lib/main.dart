import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice/CreateInvoice.dart';
import 'package:invoice/HomePage.dart';
import 'package:invoice/LoginPage.dart';
import 'package:invoice/RegisterPage.dart';
import 'package:invoice/invoice.dart';
import 'package:invoice/providers/authProvider.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

// AuthStateListener to notify GoRouter of auth state changes
class AuthStateListener extends ChangeNotifier {
  AuthStateListener(this.ref) {
    // Subscribe to authProvider changes
    ref.listen<AuthState>(authProvider, (previous, next) {
      // Notify listeners (e.g., GoRouter) on state change
      // print('AuthState changed from $previous to $next'); // Debugging
      notifyListeners();
    });
  }

  final Ref ref;
}

final authStateListenerProvider = Provider((ref) {
  return AuthStateListener(ref);
});

// GoRouter provider with authentication handling
final goRouterProvider = Provider<GoRouter>((ref) {
  final authStateListener = ref.watch(authStateListenerProvider);
  final authState = ref.watch(authProvider);

  return GoRouter(
    refreshListenable: authStateListener,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Homepage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/createInvoice',
        builder: (context, state) => const InvoiceCreatePage(),
      ),
      GoRoute(
        path: '/invoice/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? 'unknown';
          return InvoicePage(id: id);
        },
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) {
          // final id = state.pathParameters['id'] ?? 'unknown';
          return RegisterPage();
        },
      ),
    ],
    redirect: (context, state) {
      // Allow access to invoice route even if unauthenticated
      if (state.matchedLocation.startsWith('/invoice/')) {
        return null;
      }
      if (state.matchedLocation.contains('/register')) {
        return null;
      }

      // Redirect to login if unauthenticated and trying to access protected routes
      if (authState == AuthState.unauthenticated ||
          authState == AuthState.error && state.matchedLocation != '/login') {
        return '/login';
      }

      // If authenticated, prevent access to login page and redirect to home
      if (authState == AuthState.authenticated &&
          state.matchedLocation == '/login') {
        return '/';
      }

      return null; // No redirection needed
    },
  );
});

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Invoice App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: router, // Use GoRouter for navigation
    );
  }
}
