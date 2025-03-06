import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

enum AuthState { idle, loading, authenticated, unauthenticated, error }

class AuthClass extends StateNotifier<AuthState> {
  AuthClass() : super(AuthState.unauthenticated);

  String? _token;
  String? get token => _token;
  String? _error;
  String? get error => _error; // ✅ Proper getter

  Future<void> register(String email, String password, String Name,
      String CompanyName, String Address, String Phone) async {
    state = AuthState.loading;

    try {
      final uri = Uri.parse(
          'https://cloud-invoice-backend.onrender.com/client/createUser');
      final response = await http.post(uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "Email": email,
            "Password": password,
            "Name": Name,
            "companyName": CompanyName,
            "Address": Address,
            "Phone": Phone
          }));
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        _token = responseData["access_token"];
        state = AuthState.authenticated;
      } else {
        state = AuthState.unauthenticated;
      }
    } catch (e) {
      _error = e.toString();
      state = AuthState.error;
    }
  }

  Future<void> login(String email, String password) async {
    state = AuthState.loading;

    try {
      final uri = Uri.parse(
          'https://cloud-invoice-backend.onrender.com/client/login?email=$email&password=$password');
      final response =
          await http.get(uri, headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        _token = responseData["access_token"];

        if (_token != null && _token!.isNotEmpty) {
          state = AuthState.authenticated;
        } else {
          state = AuthState.unauthenticated;
        }
      } else {
        state = AuthState.unauthenticated;
      }
    } catch (e) {
      _error = e.toString();
      state = AuthState.error;
    }
  }

  void logout() {
    _token = null; // ✅ Clear token on logout
    state = AuthState.unauthenticated;
  }
}

// 🔹 Auth Provider
final authProvider = StateNotifierProvider<AuthClass, AuthState>((ref) {
  return AuthClass();
});

// class AuthStateListener extends ChangeNotifier {
//   AuthStateListener(this.ref) {
//     // Subscribe to authProvider changes
//     ref.listen<AuthState>(authProvider, (previous, next) {
//       // Notify listeners (e.g., GoRouter) on state change
//       notifyListeners();
//     });
//   }

//   final Ref ref;
// }

// final authStateListenerProvider = Provider((ref) {
//   return AuthStateListener(ref);
// });
