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
      print('AuthState changed from $previous to $next'); // Debugging
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
        // Always allow invoice routes
        if (state.matchedLocation.startsWith('/invoice/')) {
          return null;
        }

        // If unauthenticated or in register-loading state, only allow /register and /login
        if (authState == AuthState.unauthenticated ||
            authState == AuthState.registerLoding) {
          if (state.matchedLocation == '/register' ||
              state.matchedLocation == '/login') {
            return null;
          }
          if (authState == AuthState.registerLoding) {
            return '/register';
          }
          if (authState == AuthState.registerError) {
            return '/register';
          }
          if (authState == AuthState.registerSuccess) {
            return '/login';
          }
        }

        // If in error or loading state (and not already on /login), redirect to login
        if ((authState == AuthState.error ||
                authState == AuthState.loading ||
                authState == AuthState.unauthenticated) &&
            state.matchedLocation != '/login') {
          return '/login';
        }

        // Prevent authenticated users from accessing the login page
        if (authState == AuthState.authenticated &&
            state.matchedLocation == '/login') {
          return '/';
        }

        // No redirection needed
        return null;
      });
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
