import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice/providers/authProvider.dart';

// StateProvider to track password visibility
final passwordVisibilityProvider = StateProvider<bool>((ref) => true);

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);
    final isPasswordHidden =
        ref.watch(passwordVisibilityProvider); // Watch state

    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
              enableInteractiveSelection: true, // Allows copy-paste
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              obscureText: isPasswordHidden, // Toggles visibility
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: authState == AuthState.loading
                  ? null
                  : () {
                      authNotifier.login(
                        emailController.text.trim(),
                        passwordController.text.trim(),
                      );
                    },
              child: authState == AuthState.loading
                  ? const CircularProgressIndicator()
                  : const Text("Login"),
            ),
            if (authState == AuthState.error)
              Text("${authNotifier.error}",
                  style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                print("clicked");
                GoRouter.of(context)
                    .push("/register"); // Navigate to the register page
              },
              child: const Text(
                "Register Now",
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
