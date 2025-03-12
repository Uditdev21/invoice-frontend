import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoice/providers/authProvider.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                    "Full Name", _nameController, "Enter your name"),
                _buildTextField(
                    "Email", _emailController, "Enter a valid email",
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail),
                _buildTextField("Company Name", _companyController,
                    "Enter your company name"),
                _buildTextField(
                    "Address", _addressController, "Enter your address"),
                _buildTextField(
                    "Phone", _phoneController, "Enter your phone number",
                    keyboardType: TextInputType.phone),
                _buildTextField(
                    "Password", _passwordController, "Enter your password",
                    isPassword: true),
                _buildTextField("Confirm Password", _confirmPasswordController,
                    "Re-enter your password",
                    isPassword: true, validator: _validatePasswordMatch),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: authState == AuthState.registerLoding
                        ? null
                        : () {
                            if (_formKey.currentState!.validate()) {
                              _registerUser();
                            }
                          },
                    child: authState == AuthState.registerLoding
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text("Register"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, String hint,
      {TextInputType keyboardType = TextInputType.text,
      bool isPassword = false,
      String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        validator: validator ?? _validateRequired,
      ),
    );
  }

  String? _validateRequired(String? value) {
    return (value == null || value.isEmpty) ? "This field is required" : null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return "Email is required";
    final emailRegEx =
        RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    return emailRegEx.hasMatch(value) ? null : "Enter a valid email";
  }

  String? _validatePasswordMatch(String? value) {
    if (value != _passwordController.text) return "Passwords do not match";
    return null;
  }

  void _registerUser() {
    ref.read(authProvider.notifier).register(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _nameController.text.trim(),
          _companyController.text.trim(),
          _addressController.text.trim(),
          _phoneController.text.trim(),
        );
  }
}
